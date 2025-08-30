# UI Specification (iOS)

Navigation
- Tab bar with: Dashboard, Tiers, Planner, History, Settings.

Dashboard
- Totals card: total reserves and per-tier totals.
- Funding progress: progress bars per tier with % toward target.
- Quick actions (future): Allocate, Rebalance.

Tiers
- List tiers by priority; show name, purpose, total, and gap.
- Add/Delete tier; navigate to Tier Detail.

Tier Detail
- Edit: name, purpose, target, priority, preferred account.
- Accounts list: tap to edit; add new account.
- Account editor: name, balance, APY, weight, optional cap, notes.

Planner
- Input new cash amount.
- Preview moves by tier and detailed by account.
- Apply allocation to update balances.

History
- List recent transactions (in-memory now; Core Data later).
- Filters and charts (future).

Settings
- Privacy mode switch.
- Import/Export Plan JSON via Files.
- App info.

Accessibility & Mobile Considerations
- Larger tap targets, safe area padding.
- Dark mode support via system; text uses semantic colors.
- Right-to-left and localization planned.

