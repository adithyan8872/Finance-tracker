# Tasks

## Task List

- [x] 1. Project Setup and Dependencies
  - [x] 1.1 Add required dependencies to pubspec.yaml (hive, hive_flutter, hive_generator, build_runner, uuid, fl_chart, intl, path_provider)
  - [x] 1.2 Configure analysis_options.yaml for strict linting
  - [x] 1.3 Run `flutter pub get` and verify all packages resolve

- [ ] 2. Data Models
  - [ ] 2.1 Create `lib/models/transaction.dart` with `Transaction` HiveObject, `TransactionType` enum, and `Category` enum including all HiveType/HiveField annotations
  - [ ] 2.2 Create `CategoryExtension` with `label`, `icon`, and `color` helpers on the `Category` enum
  - [ ] 2.3 Run `flutter pub run build_runner build` to generate `transaction.g.dart` Hive adapters
  - [ ] 2.4 Verify generated adapters compile without errors

- [ ] 3. TransactionService
  - [ ] 3.1 Create `lib/services/transaction_service.dart` with `ITransactionService` abstract class and `TransactionService` singleton implementation
  - [ ] 3.2 Implement `init()` — register adapters and open the `transactions` Hive box
  - [ ] 3.3 Implement `addTransaction(Transaction t)` — persist to Hive box
  - [ ] 3.4 Implement `getAllTransactions()` — return all items sorted by date descending
  - [ ] 3.5 Implement `deleteTransaction(String id)` — find key by id, delete if found, log warning if not found
  - [ ] 3.6 Implement `getTotalIncome()` — sum amounts of all income transactions
  - [ ] 3.7 Implement `getTotalExpenses()` — sum amounts of all expense transactions
  - [ ] 3.8 Implement `getBalance()` — return `getTotalIncome() - getTotalExpenses()`
  - [ ] 3.9 Implement `getExpensesByCategory()` — group and sum expense amounts by category
  - [ ] 3.10 Implement `getRecentTransactions({int limit = 5})` — return first `limit` items from sorted list

- [ ] 4. App Entry Point and Theme
  - [ ] 4.1 Update `lib/main.dart` to call `TransactionService.init()` before `runApp()`, wrapped in a try/catch that shows a full-screen error widget on failure
  - [ ] 4.2 Create `lib/app.dart` with `FinanceTrackerApp` MaterialApp using Material 3 theme

- [ ] 5. Reusable Widgets
  - [ ] 5.1 Create `lib/widgets/summary_card.dart` — colored card with label, icon, and formatted amount
  - [ ] 5.2 Create `lib/widgets/transaction_list_item.dart` — row with icon, category, description, date, and signed amount (green for income, red for expense)
  - [ ] 5.3 Create `lib/widgets/category_chip.dart` — selectable chip for the Add Transaction form
  - [ ] 5.4 Create `lib/widgets/empty_state_widget.dart` — centered icon and descriptive message

- [ ] 6. Main Scaffold and Navigation
  - [ ] 6.1 Create `lib/screens/main_scaffold.dart` with a `BottomNavigationBar` containing four tabs: Home, Transactions, Add Transaction, and Reports
  - [ ] 6.2 Implement tab switching using `IndexedStack` or `PageView` so each screen retains its state

- [ ] 7. Home Screen
  - [ ] 7.1 Create `lib/screens/home_screen.dart` as a `StatefulWidget`
  - [ ] 7.2 Load transactions from `TransactionService` in `initState` and on `didChangeDependencies` (to refresh on tab return)
  - [ ] 7.3 Display three `SummaryCard` widgets for balance, total income, and total expenses
  - [ ] 7.4 Display up to 5 recent `TransactionListItem` widgets
  - [ ] 7.5 Show `EmptyStateWidget` when no transactions exist

- [ ] 8. Transactions Screen
  - [ ] 8.1 Create `lib/screens/transactions_screen.dart` as a `StatefulWidget`
  - [ ] 8.2 Display all transactions sorted by date descending using `ListView.builder` with `TransactionListItem`
  - [ ] 8.3 Wrap each list item in a `Dismissible` widget for swipe-to-delete
  - [ ] 8.4 Show a confirmation `AlertDialog` before calling `TransactionService.deleteTransaction()`
  - [ ] 8.5 Refresh the list with `setState()` after a confirmed deletion
  - [ ] 8.6 Show `EmptyStateWidget` when the transaction list is empty

- [ ] 9. Add Transaction Screen
  - [ ] 9.1 Create `lib/screens/add_transaction_screen.dart` as a `StatefulWidget`
  - [ ] 9.2 Implement income/expense type toggle using `ToggleButtons` or `SegmentedButton`
  - [ ] 9.3 Implement amount `TextFormField` with validator: required, must parse to a positive number
  - [ ] 9.4 Implement description `TextFormField` with validator: required, max 200 characters
  - [ ] 9.5 Implement category selector using `CategoryChip` widgets; validate that one is selected
  - [ ] 9.6 Implement date picker defaulting to today; validate that a date is selected
  - [ ] 9.7 Implement `_validateAndSave()` — validate form, build `Transaction` with a new UUID and `createdAt = DateTime.now()`, call `TransactionService.addTransaction()`, show success `SnackBar`, and pop screen

- [ ] 10. Reports Screen
  - [ ] 10.1 Create `lib/screens/reports_screen.dart` as a `StatefulWidget`
  - [ ] 10.2 Display total income and total expenses as summary tiles
  - [ ] 10.3 Retrieve `getExpensesByCategory()` and render a `BarChart` from `fl_chart` with one bar per category
  - [ ] 10.4 Show `EmptyStateWidget` when `getExpensesByCategory()` returns an empty map

- [ ] 11. Amount and Date Formatting
  - [x] 11.1 Create a formatting utility using `intl` that formats doubles to exactly 2 decimal places (e.g., `NumberFormat.currency`)
  - [-] 11.2 Apply the formatter consistently in `SummaryCard`, `TransactionListItem`, and `ReportsScreen`
  - [ ] 11.3 Format transaction dates using `intl.DateFormat` in `TransactionListItem`

- [ ] 12. Unit Tests for TransactionService
  - [ ] 12.1 Set up an in-memory Hive test environment in `test/` using `hive_test` or `hive` with a temp directory
  - [ ] 12.2 Write a test: `addTransaction` stores the record and increases list length by 1
  - [ ] 12.3 Write a test: `getAllTransactions` returns items sorted by date descending
  - [ ] 12.4 Write a test: `deleteTransaction` removes the correct record
  - [ ] 12.5 Write a test: `deleteTransaction` with a non-existent ID does not throw and does not change the list
  - [ ] 12.6 Write a test: `getTotalIncome`, `getTotalExpenses`, and `getBalance` compute correct values
  - [ ] 12.7 Write a test: `getExpensesByCategory` groups and sums correctly, excludes income

- [ ] 13. Property-Based Tests for TransactionService
  - [ ] 13.1 Write property test — **Property 1 (Balance Invariant)**: For any random set of income/expense transactions, `getBalance() == getTotalIncome() - getTotalExpenses()`
  - [ ] 13.2 Write property test — **Property 2 (Adding a Transaction Persists It)**: For any valid random transaction, after `addTransaction()`, `getAllTransactions()` contains it and count increases by 1
  - [ ] 13.3 Write property test — **Property 3 (Income Monotonicity)**: For any random income transaction, `getTotalIncome()` after addition >= before
  - [ ] 13.4 Write property test — **Property 4 (Expense Monotonicity)**: For any random expense transaction, `getTotalExpenses()` after addition >= before
  - [ ] 13.5 Write property test — **Property 5 (Delete Removes Target)**: For any stored transaction, after `deleteTransaction(id)`, no item with that ID exists in `getAllTransactions()`
  - [ ] 13.6 Write property test — **Property 6 (Delete No-Op for Missing IDs)**: For any UUID not in the store, `deleteTransaction()` does not throw and list is unchanged
  - [ ] 13.7 Write property test — **Property 7 (Category Breakdown Correctness)**: For any random transactions, breakdown values are positive, only expense categories present, sum equals `getTotalExpenses()` within 0.001
  - [ ] 13.8 Write property test — **Property 8 (Recent Transactions Bound)**: For any random `n` and transactions, `getRecentTransactions(limit: n).length <= n` and sorted by date descending

- [ ] 14. Widget Tests
  - [ ] 14.1 Write widget test: `HomeScreen` renders three `SummaryCard` widgets when transactions exist
  - [ ] 14.2 Write widget test: `HomeScreen` shows `EmptyStateWidget` when no transactions exist
  - [ ] 14.3 Write widget test: `AddTransactionScreen` shows inline validation errors on empty submit (Properties 9, 10)
  - [ ] 14.4 Write widget test: `TransactionListItem` displays income amounts in green and expense amounts in red (Property 11)
  - [ ] 14.5 Write widget test: `TransactionsScreen` removes the item from the list after swipe-to-dismiss and confirmation

- [ ] 15. Integration and Polish
  - [ ] 15.1 Verify the app builds without errors for Android (`flutter build apk --debug`)
  - [ ] 15.2 Test the full add-transaction flow on a device or emulator: fill form → save → verify appears on Home and Transactions screens
  - [ ] 15.3 Test the delete flow: swipe → confirm → verify item removed and totals updated
  - [ ] 15.4 Verify the Reports screen bar chart renders correctly with at least one expense transaction
  - [ ] 15.5 Verify empty states display correctly on first launch (no transactions)
