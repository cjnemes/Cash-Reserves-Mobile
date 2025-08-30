#!/usr/bin/env python3
"""
Reserve Manager — a lightweight command-line tool to manage tiered reserves (core engine).

Features
- Tiers with targets, priorities, and purposes
- Accounts inside tiers with balances, APY, notes
- Account-level routing: preferred account, allocation weights, per-account caps
- Allocation plan (tier-level) and allocation plan (detailed per-account)
- Rebalancing suggestions, interest/yield forecast
- JSON persistence (path is injected by UI; default is ./reserve_manager.json)

CLI (optional)
$ python reserve_manager.py init
$ python reserve_manager.py status
$ python reserve_manager.py allocate --amount 50000
$ python reserve_manager.py allocate-detailed --amount 50000
$ python reserve_manager.py set-preferred-account --tier "Tier 3" --account "USDC (Coinbase)"
$ python reserve_manager.py set-account-weight --tier "Tier 4" --account "Bonds" --weight 2
$ python reserve_manager.py set-account-target --tier "Tier 4" --account "Bonds" --target 30000
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field, asdict
from datetime import date
from pathlib import Path
from typing import Dict, List, Optional, Tuple

CONFIG_FILE = Path("reserve_manager.json")

# ----------------------------- Data Models ----------------------------- #

@dataclass
class Account:
    name: str
    balance: float = 0.0
    apy_pct: float = 0.0  # annual percentage yield, e.g., 4.25 for 4.25%
    notes: str = ""
    alloc_weight: float = 1.0  # relative weight when distributing within a tier
    account_target: Optional[float] = None  # optional cap for this account

    def expected_growth(self, months: int) -> float:
        if self.apy_pct <= 0 or self.balance <= 0 or months <= 0:
            return 0.0
        r = self.apy_pct / 100.0
        return self.balance * ((1 + r/12) ** months - 1)

    @property
    def remaining_room(self) -> float:
        if self.account_target is None:
            return float("inf")
        return max(0.0, self.account_target - self.balance)

@dataclass
class Tier:
    name: str
    purpose: str
    target: float
    priority: int  # lower number = fund sooner
    accounts: List[Account] = field(default_factory=list)
    preferred_account: Optional[str] = None

    @property
    def total(self) -> float:
        return sum(a.balance for a in self.accounts)

    @property
    def gap(self) -> float:
        return max(0.0, self.target - self.total)

    def add_or_update_account(self, name: str, balance: float, apy_pct: Optional[float] = None, notes: str = "",
                              alloc_weight: Optional[float] = None, account_target: Optional[float] = None):
        for a in self.accounts:
            if a.name == name:
                a.balance = balance
                if apy_pct is not None:
                    a.apy_pct = apy_pct
                if notes:
                    a.notes = notes
                if alloc_weight is not None:
                    a.alloc_weight = alloc_weight
                if account_target is not None:
                    a.account_target = account_target
                return
        self.accounts.append(Account(name=name, balance=balance, apy_pct=apy_pct or 0.0, notes=notes,
                                     alloc_weight=alloc_weight or 1.0, account_target=account_target))

    def set_preferred(self, account_name: Optional[str]):
        if account_name is None:
            self.preferred_account = None
            return
        if not any(a.name == account_name for a in self.accounts):
            raise KeyError(f"Account '{account_name}' not found in {self.name}")
        self.preferred_account = account_name

    def allocate_into_accounts(self, amount: float) -> List[Tuple[str, float]]:
        """
        Split 'amount' across accounts using:
        1) Preferred account first (respecting its account_target if set)
        2) Then weighted split across remaining accounts that have room (respect account_target)
        Returns a list of (account_name, amount)
        """
        remaining = max(0.0, amount)
        moves: List[Tuple[str, float]] = []
        if remaining <= 0 or not self.accounts:
            return moves

        # Preferred account first
        if self.preferred_account:
            pa = next(a for a in self.accounts if a.name == self.preferred_account)
            room = pa.remaining_room
            if room > 0:
                add = min(remaining, room)
                if add > 0:
                    moves.append((pa.name, round(add, 2)))
                    remaining -= add

        # Weighted split among accounts with room (including preferred if it still has room)
        while remaining > 0:
            candidates = [a for a in self.accounts if a.remaining_room > 0]
            if not candidates:
                break
            total_w = sum(max(0.0, a.alloc_weight) for a in candidates)
            if total_w <= 0:
                a = candidates[0]
                add = min(remaining, a.remaining_room)
                moves.append((a.name, round(add, 2)))
                remaining -= add
                break
            progressed = False
            for a in candidates:
                share = remaining * (max(0.0, a.alloc_weight) / total_w)
                add = min(share, a.remaining_room)
                add = round(add, 2)
                if add > 0:
                    moves.append((a.name, add))
                    remaining -= add
                    progressed = True
            if not progressed:
                break
        return moves

@dataclass
class Plan:
    tiers: List[Tier] = field(default_factory=list)
    last_updated: str = field(default_factory=lambda: date.today().isoformat())

    def by_name(self, name: str) -> Tier:
        for t in self.tiers:
            if t.name == name:
                return t
        raise KeyError(f"Tier not found: {name}")

    def totals(self) -> Dict[str, float]:
        return {t.name: t.total for t in self.tiers}

    @property
    def total_reserves(self) -> float:
        return sum(t.total for t in self.tiers)

    def sorted_by_priority(self) -> List[Tier]:
        return sorted(self.tiers, key=lambda t: t.priority)

    def allocation_plan(self, new_cash: float) -> List[Tuple[str, float]]:
        """Greedy allocation to fill tier gaps by priority order (tier totals only)."""
        remaining = max(0.0, new_cash)
        moves: List[Tuple[str, float]] = []
        for tier in self.sorted_by_priority():
            if remaining <= 0:
                break
            need = tier.gap
            if need <= 0:
                continue
            amt = min(remaining, need)
            if amt > 0:
                moves.append((tier.name, round(amt, 2)))
                remaining -= amt
        if remaining > 0:
            growth = next((t for t in self.sorted_by_priority() if "Tier 4" in t.name or "Growth" in t.purpose), None)
            if growth:
                moves.append((growth.name, round(remaining, 2)))
        return moves

    def allocation_plan_detailed(self, new_cash: float) -> List[Tuple[str, str, float]]:
        """Greedy by tiers, then split into accounts using tier rules. Returns (tier, account, amount)."""
        remaining = max(0.0, new_cash)
        moves: List[Tuple[str, str, float]] = []
        for tier in self.sorted_by_priority():
            if remaining <= 0:
                break
            need = tier.gap
            if need <= 0:
                continue
            amt = min(remaining, need)
            if amt > 0:
                splits = tier.allocate_into_accounts(amt)
                if not splits:
                    # fallback: put the whole thing into first account (if exists)
                    if tier.accounts:
                        splits = [(tier.accounts[0].name, round(amt, 2))]
                for acc_name, acc_amt in splits:
                    moves.append((tier.name, acc_name, round(acc_amt, 2)))
                remaining -= amt
        if remaining > 0:
            # leftover after all targets -> Tier 4 preferred or weighted
            growth = next((t for t in self.sorted_by_priority() if "Tier 4" in t.name or "Growth" in t.purpose), None)
            if growth:
                splits = growth.allocate_into_accounts(remaining)
                if not splits and growth.accounts:
                    splits = [(growth.accounts[0].name, round(remaining, 2))]
                for acc_name, acc_amt in splits:
                    moves.append((growth.name, acc_name, round(acc_amt, 2)))
        return moves

    def rebalancing_moves(self) -> List[Tuple[str, float]]:
        under = [(t, t.gap) for t in self.sorted_by_priority() if t.gap > 0]
        over = [(t, t.total - t.target) for t in self.tiers if t.total > t.target]
        moves: List[Tuple[str, float]] = []
        if not under or not over:
            return moves
        i = j = 0
        while i < len(over) and j < len(under):
            from_tier, excess = over[i]
            to_tier, need = under[j]
            amt = round(min(excess, need), 2)
            if amt > 0:
                moves.append((f"{from_tier.name} ➜ {to_tier.name}", amt))
                excess -= amt
                need -= amt
            over[i] = (from_tier, excess)
            under[j] = (to_tier, need)
            if excess <= 0.005:
                i += 1
            if need <= 0.005:
                j += 1
        return moves

    def forecast(self, months: int) -> Dict[str, float]:
        return {t.name: sum(a.expected_growth(months) for a in t.accounts) for t in self.tiers}

# ----------------------------- Persistence ----------------------------- #

def load_plan(path: Path = CONFIG_FILE) -> Plan:
    if not path.exists():
        raise FileNotFoundError(f"Config not found at {path}. Run 'init' first.")
    with path.open() as f:
        data = json.load(f)
    tiers = []
    for t in data["tiers"]:
        accounts = []
        for a in t.get("accounts", []):
            accounts.append(Account(
                name=a["name"],
                balance=a.get("balance", 0.0),
                apy_pct=a.get("apy_pct", 0.0),
                notes=a.get("notes", ""),
                alloc_weight=a.get("alloc_weight", 1.0),
                account_target=a.get("account_target", None),
            ))
        tiers.append(Tier(
            name=t["name"],
            purpose=t["purpose"],
            target=t["target"],
            priority=t["priority"],
            accounts=accounts,
            preferred_account=t.get("preferred_account"),
        ))
    return Plan(tiers=tiers, last_updated=data.get("last_updated", date.today().isoformat()))

def save_plan(plan: Plan, path: Path = CONFIG_FILE) -> None:
    payload = {
        "tiers": [
            {
                "name": t.name,
                "purpose": t.purpose,
                "target": t.target,
                "priority": t.priority,
                "preferred_account": t.preferred_account,
                "accounts": [asdict(a) for a in t.accounts],
            }
            for t in plan.tiers
        ],
        "last_updated": date.today().isoformat(),
    }
    with path.open("w") as f:
        json.dump(payload, f, indent=2)

# ----------------------------- Defaults ----------------------------- #

def default_plan() -> Plan:
    return Plan(
        tiers=[
            Tier(
                name="Tier 1",
                purpose="Buffer & short‑term emergencies",
                target=30000,
                priority=1,
                accounts=[
                    Account("Checking", 0, 0.02, "Monthly expenses", alloc_weight=1.0),
                    Account("Savings (Discover)", 0, 4.11, "FDIC savings", alloc_weight=2.0, account_target=23000),
                ],
                preferred_account="Savings (Discover)",
            ),
            Tier(
                name="Tier 2",
                purpose="Emergency fund",
                target=30000,
                priority=2,
                accounts=[
                    Account("Savings/MM", 0, 3.75, "Liquid reserve", alloc_weight=1.0),
                    Account("USDC (Coinbase)", 0, 5.20, "Stablecoin yield", alloc_weight=2.0, account_target=20000),
                ],
                preferred_account="USDC (Coinbase)",
            ),
            Tier(
                name="Tier 3",
                purpose="Large capital expenditures",
                target=40000,
                priority=3,
                accounts=[
                    Account("Short‑Term Bonds (Schwab)", 0, 4.25, "Ladder/ETF", alloc_weight=2.0, account_target=30000),
                    Account("USDC (Coinbase)", 0, 4.50, "", alloc_weight=1.0, account_target=10000),
                ],
                preferred_account="Short‑Term Bonds (Schwab)",
            ),
            Tier(
                name="Tier 4",
                purpose="Long‑term debt reduction & income generation",
                target=100000,
                priority=4,
                accounts=[
                    Account("Bonds", 0, 4.25, "Income/low risk", alloc_weight=2.0),
                    Account("Dividend Stocks", 0, 3.10, "After‑tax income proxy", alloc_weight=1.0),
                    Account("REITs", 0, 4.50, "Higher yield", alloc_weight=1.0),
                    Account("Crypto", 0, 40.0, "High risk / high potential", alloc_weight=1.0),
                ],
                preferred_account="Bonds",
            ),
            Tier(
                name="Tier 5",
                purpose="Capital gains tax holding (1‑yr horizon)",
                target=25000,
                priority=5,
                accounts=[
                    Account("Short‑Term Bonds (Schwab)", 0, 4.25, "Hold until taxes due", alloc_weight=1.0),
                ],
                preferred_account="Short‑Term Bonds (Schwab)",
            ),
            Tier(
                name="Tier 6",
                purpose="Temporary holding (unallocated cash)",
                target=0,
                priority=6,
                accounts=[Account("Savings", 0, 3.75, "Parking until allocated", alloc_weight=1.0)],
                preferred_account="Savings",
            ),
        ]
    )

# ----------------------------- CLI ----------------------------- #

def build_parser():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd")
    sub.required = True

    p = sub.add_parser("init"); p.set_defaults(func=cmd_init); p.add_argument("--force", action="store_true")
    p = sub.add_parser("status"); p.set_defaults(func=cmd_status)

    p = sub.add_parser("allocate"); p.set_defaults(func=cmd_allocate); p.add_argument("--amount", type=float, required=True)
    p = sub.add_parser("allocate-detailed"); p.set_defaults(func=cmd_allocate_detailed); p.add_argument("--amount", type=float, required=True)

    p = sub.add_parser("rebalance"); p.set_defaults(func=cmd_rebalance)
    p = sub.add_parser("forecast"); p.set_defaults(func=cmd_forecast); p.add_argument("--months", type=int, default=12)

    p = sub.add_parser("set-balance"); p.set_defaults(func=cmd_set_balance)
    p.add_argument("--tier", required=True); p.add_argument("--account", required=True)
    p.add_argument("--balance", type=float, required=True)
    p.add_argument("--apy", type=float, default=None)
    p.add_argument("--notes", default="")

    p = sub.add_parser("set-target"); p.set_defaults(func=cmd_set_target)
    p.add_argument("--tier", required=True); p.add_argument("--target", type=float, required=True)

    p = sub.add_parser("set-preferred-account"); p.set_defaults(func=cmd_set_preferred)
    p.add_argument("--tier", required=True); p.add_argument("--account", required=False)

    p = sub.add_parser("set-account-weight"); p.set_defaults(func=cmd_set_weight)
    p.add_argument("--tier", required=True); p.add_argument("--account", required=True); p.add_argument("--weight", type=float, required=True)

    p = sub.add_parser("set-account-target"); p.set_defaults(func=cmd_set_account_target)
    p.add_argument("--tier", required=True); p.add_argument("--account", required=True); p.add_argument("--target", type=float, required=True)

    p = sub.add_parser("add-tier"); p.set_defaults(func=cmd_add_tier)
    p.add_argument("--name", required=True); p.add_argument("--purpose", required=True)
    p.add_argument("--target", type=float, required=True); p.add_argument("--priority", type=int, required=True)

    p = sub.add_parser("remove-tier"); p.set_defaults(func=cmd_remove_tier); p.add_argument("--name", required=True)
    return parser

# ----------------------------- Command Impl ----------------------------- #

def cmd_init(args):
    if CONFIG_FILE.exists() and not args.force:
        raise SystemExit(f"{CONFIG_FILE} already exists. Use --force to overwrite.")
    plan = default_plan()
    save_plan(plan)
    print(f"Initialized {CONFIG_FILE} with default tiers.")

def cmd_status(args):
    plan = load_plan()
    print(f"As of {plan.last_updated} — Total Reserves: ${plan.total_reserves:,.2f}\n")
    print(f"{'Tier':<8} {'Target':>12} {'Current':>14} {'Gap':>14}")
    print("-" * 52)
    for t in plan.sorted_by_priority():
        print(f"{t.name:<8} ${t.target:>11,.0f} ${t.total:>13,.2f} ${t.gap:>13,.2f}")
        if t.preferred_account:
            print(f"    Preferred: {t.preferred_account}")
        for a in t.accounts:
            apy = f" @ {a.apy_pct:.2f}%" if a.apy_pct else ""
            cap = f" cap={a.account_target:,.0f}" if a.account_target is not None else ""
            print(f"  - {a.name}: ${a.balance:,.2f}{apy} w={a.alloc_weight}{cap}")
    print()

def cmd_allocate(args):
    plan = load_plan()
    moves = plan.allocation_plan(args.amount)
    if not moves:
        print("No allocation needed — all targets met. Consider investing excess in Tier 4.")
        return
    print(f"Proposed allocation for ${args.amount:,.2f} (by priority, tier-level):")
    for name, amt in moves:
        print(f"  → {name}: ${amt:,.2f}")

def cmd_allocate_detailed(args):
    plan = load_plan()
    moves = plan.allocation_plan_detailed(args.amount)
    if not moves:
        print("No allocation needed — all targets met.")
        return
    print(f"Proposed allocation for ${args.amount:,.2f} (by priority, split by accounts):")
    for tier_name, acc_name, amt in moves:
        print(f"  → {tier_name} / {acc_name}: ${amt:,.2f}")

def cmd_rebalance(args):
    plan = load_plan()
    moves = plan.rebalancing_moves()
    if not moves:
        print("No rebalancing suggested — either no overfunded tiers or all underfunded are minor.")
        return
    print("Suggested rebalancing moves:")
    for route, amt in moves:
        print(f"  ↔ {route}: ${amt:,.2f}")

def cmd_forecast(args):
    plan = load_plan()
    months = args.months
    gains = plan.forecast(months)
    print(f"Projected growth over {months} months (compounded monthly):")
    total_gain = 0.0
    for tier_name, g in gains.items():
        print(f"  {tier_name}: ${g:,.2f}")
        total_gain += g
    print(f"  ——— Total: ${total_gain:,.2f}")

def cmd_set_balance(args):
    plan = load_plan()
    tier = plan.by_name(args.tier)
    tier.add_or_update_account(args.account, args.balance, apy_pct=args.apy, notes=args.notes or "")
    save_plan(plan)
    print(f"Updated {args.account} in {args.tier} to ${args.balance:,.2f}.")

def cmd_set_target(args):
    plan = load_plan()
    tier = plan.by_name(args.tier)
    tier.target = args.target
    save_plan(plan)
    print(f"Updated target for {args.tier} to ${args.target:,.0f}.")

def cmd_set_preferred(args):
    plan = load_plan()
    tier = plan.by_name(args.tier)
    tier.set_preferred(args.account if args.account else None)
    save_plan(plan)
    print(f"Preferred account for {args.tier} set to: {tier.preferred_account}")

def cmd_set_weight(args):
    plan = load_plan()
    tier = plan.by_name(args.tier)
    found = False
    for a in tier.accounts:
        if a.name == args.account:
            a.alloc_weight = args.weight
            found = True
            break
    if not found:
        tier.add_or_update_account(args.account, 0.0, alloc_weight=args.weight)
    save_plan(plan)
    print(f"Set weight for {args.account} in {args.tier} to {args.weight}.")

def cmd_set_account_target(args):
    plan = load_plan()
    tier = plan.by_name(args.tier)
    found = False
    for a in tier.accounts:
        if a.name == args.account:
            a.account_target = args.target
            found = True
            break
    if not found:
        tier.add_or_update_account(args.account, 0.0, account_target=args.target)
    save_plan(plan)
    print(f"Set account-level target for {args.account} in {args.tier} to ${args.target:,.0f}.")

def cmd_add_tier(args):
    plan = load_plan()
    if any(t.name == args.name for t in plan.tiers):
        raise SystemExit(f"Tier '{args.name}' already exists.")
    plan.tiers.append(Tier(name=args.name, purpose=args.purpose, target=args.target, priority=args.priority))
    save_plan(plan)
    print(f"Added {args.name}.")

def cmd_remove_tier(args):
    plan = load_plan()
    plan.tiers = [t for t in plan.tiers if t.name != args.name]
    save_plan(plan)
    print(f"Removed {args.name}.")

# ----------------------------- Entry ----------------------------- #

def main():
    parser = build_parser()
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(2)
    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
