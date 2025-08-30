# UI Specification (iOS)

Navigation
- Tab bar with: Dashboard, Tiers, Accounts, Planner, More.
- More menu lists: Rebalance, History, Settings.

Dashboard
- Totals card: total reserves and per-tier totals.
- Funding progress: progress bars per tier with % toward target.
- Quick actions (future): Allocate, Rebalance.

Tiers
- List tiers by priority; show name, purpose, total, and gap.
- Add/Delete tier; navigate to Tier Detail.

Tier Detail
- Edit: Name, Purpose, Target ($), Priority, Preferred Account (menu).
- Accounts list: tap to edit; add new account (sheet editor).
- Account editor: Tier (picker), Name, Balance ($), APY %, Weight, Cap ($, optional), Notes, Preferred toggle.
- Consistent labeled fields with helpful placeholders; currency/percent formatting on focus change.

Planner
- Input new cash amount.
- Preview moves by tier and detailed by account.
- Apply allocation to update balances.

History
- Core Data-backed transaction list.
- Filters: Tier, Account, date range (30/90/365 days).
- Trend chart for selected account (Swift Charts).

Settings
- Privacy mode switch.
- Import/Export Plan JSON via Files.
- Export Accounts CSV and Transactions CSV.
- App info.

Accessibility & Mobile Considerations
- Larger tap targets, safe area padding.
- Dark mode support via system; text uses semantic colors.
- Right-to-left and localization planned.
