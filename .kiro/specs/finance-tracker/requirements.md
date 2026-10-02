# Requirements Document

## Introduction

This document defines the requirements for the Finance Tracker — a beginner-friendly Android application built with Flutter and Dart. The app allows users to record income and expense transactions, view their current balance, browse transaction history, and see simple spending reports. All data is stored locally on the device using Hive. There is no authentication, no backend, and no network dependency.

---

## Glossary

- **App**: The Finance Tracker Flutter application.
- **Transaction**: A single financial record with an amount, description, type (income or expense), category, and date.
- **TransactionService**: The service layer responsible for all CRUD operations on the Hive database.
- **Hive**: The lightweight local NoSQL key-value store used for on-device persistence.
- **TransactionType**: An enumeration with exactly two values: `income` and `expense`.
- **Category**: An enumeration of eight predefined spending/income categories: `food`, `travel`, `shopping`, `bills`, `education`, `health`, `salary`, `other`.
- **HomeScreen**: The dashboard screen displaying the financial summary and recent transactions.
- **TransactionsScreen**: The full transaction list screen with delete support.
- **AddTransactionScreen**: The form screen for creating a new transaction.
- **ReportsScreen**: The screen displaying income/expense totals and a per-category bar chart.
- **EmptyStateWidget**: A widget displayed whenever a list or chart has no data to show.
- **SummaryCard**: A colored card widget showing a label, icon, and formatted monetary amount.
- **TransactionListItem**: A single row in a transaction list showing icon, category, description, date, and signed amount.
- **Balance**: The result of `getTotalIncome() - getTotalExpenses()` across all stored transactions.

---

## Requirements

### Requirement 1: Application Initialization

**User Story:** As a user, I want the app to start reliably with its local database ready, so that I can immediately record and view transactions without errors.

#### Acceptance Criteria

1. WHEN the app starts, THE App SHALL initialize Hive storage and register all type adapters (Transaction, TransactionType, Category) before rendering any screen.
2. WHEN the app starts, THE App SHALL open the `transactions` Hive box before launching the main navigation shell.
3. IF Hive initialization fails, THEN THE App SHALL display a full-screen error widget explaining the failure instead of the main navigation shell.
4. IF Hive initialization fails, THEN THE App SHALL log the error details to the console.

---

### Requirement 2: Transaction Data Model

**User Story:** As a developer, I want a well-defined transaction model with enforced validation rules, so that only valid data is ever persisted to the database.

#### Acceptance Criteria

1. THE Transaction SHALL have a unique identifier (`id`) generated using UUID v4, never supplied by the user.
2. THE Transaction SHALL have an `amount` field that is a positive number greater than 0.
3. THE Transaction SHALL have a `description` field that is non-empty and does not exceed 200 characters.
4. THE Transaction SHALL have a `type` field that is exactly one of the `TransactionType` enumeration values (`income` or `expense`).
5. THE Transaction SHALL have a `category` field that is exactly one of the eight `Category` enumeration values.
6. THE Transaction SHALL have a `date` field representing the user-selected transaction date.
7. THE Transaction SHALL have a `createdAt` field automatically set to the current date and time at the moment of creation.
8. THE TransactionService SHALL store Transaction objects using Hive type adapters generated from the `@HiveType` and `@HiveField` annotations.

---

### Requirement 3: Add Transaction

**User Story:** As a user, I want to record a new income or expense transaction with relevant details, so that I can keep an accurate log of my finances.

#### Acceptance Criteria

1. THE AddTransactionScreen SHALL present a form with fields for: transaction type (income/expense toggle), amount, description, category, and date.
2. THE AddTransactionScreen SHALL default the date field to today's date.
3. WHEN a user submits the form with a valid amount, description, category, and date, THE App SHALL call `TransactionService.addTransaction()` exactly once with the provided data.
4. WHEN a transaction is saved successfully, THE App SHALL display a success `SnackBar` and navigate back to the previous screen.
5. WHEN a user submits the form with an empty or missing amount, THE AddTransactionScreen SHALL display an inline validation error and SHALL NOT persist any transaction.
6. WHEN a user submits the form with an amount of 0 or a negative number, THE AddTransactionScreen SHALL display an inline validation error and SHALL NOT persist any transaction.
7. WHEN a user submits the form with an empty description, THE AddTransactionScreen SHALL display an inline validation error and SHALL NOT persist any transaction.
8. WHEN a user submits the form with a description exceeding 200 characters, THE AddTransactionScreen SHALL display an inline validation error and SHALL NOT persist any transaction.
9. WHEN a user submits the form without selecting a category, THE AddTransactionScreen SHALL display an inline validation error and SHALL NOT persist any transaction.

---

### Requirement 4: Transaction Persistence

**User Story:** As a user, I want my transactions to be saved permanently on my device, so that my financial data is available every time I open the app.

#### Acceptance Criteria

1. WHEN `TransactionService.addTransaction()` is called with a valid Transaction, THE TransactionService SHALL persist the transaction to the Hive `transactions` box.
2. WHEN `TransactionService.addTransaction()` is called, THE TransactionService SHALL result in `getAllTransactions()` returning a list with exactly one more item than before.
3. WHEN `TransactionService.addTransaction()` is called with an income transaction, THE TransactionService SHALL result in `getTotalIncome()` increasing by the transaction's amount.
4. WHEN `TransactionService.addTransaction()` is called with an expense transaction, THE TransactionService SHALL result in `getTotalExpenses()` increasing by the transaction's amount.
5. THE App SHALL store all data locally on the device and SHALL NOT make any network requests to persist or retrieve transaction data.

---

### Requirement 5: Delete Transaction

**User Story:** As a user, I want to delete a transaction I recorded by mistake, so that my financial records stay accurate.

#### Acceptance Criteria

1. WHEN a user swipes a transaction row to dismiss it on the TransactionsScreen, THE App SHALL show a confirmation dialog before deleting.
2. WHEN a user confirms deletion, THE TransactionService SHALL remove the transaction with the specified ID from the Hive box.
3. WHEN a transaction is deleted, THE TransactionsScreen SHALL refresh and no longer display the deleted transaction.
4. WHEN `TransactionService.deleteTransaction()` is called with an ID that does not exist in the box, THE TransactionService SHALL complete without throwing an exception and SHALL leave the transaction list unchanged.
5. WHEN a user cancels the deletion confirmation dialog, THE App SHALL dismiss the dialog and leave the transaction list unchanged.

---

### Requirement 6: Financial Summary (Home Screen)

**User Story:** As a user, I want to see my current balance, total income, and total expenses at a glance, so that I have an immediate overview of my financial state.

#### Acceptance Criteria

1. THE HomeScreen SHALL display a `SummaryCard` showing the current balance computed as `getTotalIncome() - getTotalExpenses()`.
2. THE HomeScreen SHALL display a `SummaryCard` showing the total income.
3. THE HomeScreen SHALL display a `SummaryCard` showing the total expenses.
4. THE HomeScreen SHALL display the 5 most recent transactions using `TransactionListItem` widgets, sorted by date descending.
5. WHEN the HomeScreen displays more than 5 transactions are stored, THE HomeScreen SHALL show at most 5 `TransactionListItem` widgets in the recent transactions list.
6. WHEN no transactions have been recorded, THE HomeScreen SHALL display an `EmptyStateWidget` in place of the recent transactions list.
7. WHEN the user navigates back to the HomeScreen from another tab, THE HomeScreen SHALL refresh and display up-to-date summary data.

---

### Requirement 7: Transaction List (Transactions Screen)

**User Story:** As a user, I want to browse my complete transaction history sorted by date, so that I can review all past financial activity.

#### Acceptance Criteria

1. THE TransactionsScreen SHALL display all stored transactions using `TransactionListItem` widgets, sorted by date descending (newest first).
2. THE TransactionsScreen SHALL visually distinguish income transactions by displaying the amount in green.
3. THE TransactionsScreen SHALL visually distinguish expense transactions by displaying the amount in red.
4. WHEN no transactions have been recorded, THE TransactionsScreen SHALL display an `EmptyStateWidget`.
5. WHEN the transaction list is long, THE TransactionsScreen SHALL use `ListView.builder` for lazy rendering to avoid loading all widgets at once.

---

### Requirement 8: Reports Screen

**User Story:** As a user, I want to see a visual breakdown of my spending by category, so that I can understand where my money is going.

#### Acceptance Criteria

1. THE ReportsScreen SHALL display total income and total expenses as summary tiles.
2. THE ReportsScreen SHALL display a bar chart showing expense amounts grouped by category.
3. WHEN expense transactions exist, THE ReportsScreen bar chart SHALL display one bar per category that has at least one expense transaction.
4. WHEN no expense transactions exist, THE ReportsScreen SHALL display an `EmptyStateWidget` in place of the bar chart.
5. THE ReportsScreen category breakdown values SHALL equal the sum of expense amounts for each respective category.

---

### Requirement 9: Financial Calculations

**User Story:** As a user, I want the app to compute accurate financial totals and balances, so that I can trust the numbers shown.

#### Acceptance Criteria

1. THE TransactionService.getBalance() SHALL return the value of `getTotalIncome() - getTotalExpenses()` at all times.
2. THE TransactionService.getBalance() SHALL return `0.0` when no transactions are stored.
3. THE TransactionService.getBalance() SHALL return a finite `double` value (not NaN, not Infinity) for any valid set of transactions.
4. THE TransactionService.getExpensesByCategory() SHALL return a map containing only categories that have at least one expense transaction.
5. THE TransactionService.getExpensesByCategory() SHALL return a map where every value is greater than 0.
6. THE TransactionService.getExpensesByCategory() SHALL return an empty map when no expense transactions are stored.
7. THE TransactionService.getExpensesByCategory() SHALL return a map where the sum of all values equals `getTotalExpenses()` within a floating-point tolerance of 0.001.
8. THE TransactionService.getRecentTransactions() SHALL return a list sorted by date descending.
9. WHEN `getRecentTransactions(limit: n)` is called, THE TransactionService SHALL return a list containing at most `n` items.
10. THE TransactionService.getAllTransactions() SHALL return all stored transactions sorted by date descending.

---

### Requirement 10: Amount Formatting

**User Story:** As a user, I want monetary amounts to be displayed consistently with 2 decimal places, so that the financial figures are clear and professional.

#### Acceptance Criteria

1. WHEN displaying any transaction amount or computed total, THE App SHALL format the value to exactly 2 decimal places.
2. THE App SHALL use the `intl` package for all currency and date formatting.

---

### Requirement 11: Navigation

**User Story:** As a user, I want to move between screens easily using a persistent navigation bar, so that I can access any part of the app at any time.

#### Acceptance Criteria

1. THE App SHALL display a persistent Bottom Navigation Bar with four tabs: Home, Transactions, Add Transaction, and Reports.
2. WHEN a user taps a Bottom Navigation Bar tab, THE App SHALL navigate to the corresponding screen without losing data on other tabs.
3. WHEN the user submits a valid transaction on the AddTransactionScreen, THE App SHALL return the user to the previous screen in the navigation stack.

---

### Requirement 12: Empty States

**User Story:** As a user, I want informative empty-state messages when there is no data to display, so that I understand the app is working correctly and know what action to take next.

#### Acceptance Criteria

1. WHEN the transaction list is empty on the HomeScreen, THE App SHALL display an `EmptyStateWidget` with a contextual message.
2. WHEN the transaction list is empty on the TransactionsScreen, THE App SHALL display an `EmptyStateWidget` with a contextual message.
3. WHEN there are no expense transactions on the ReportsScreen, THE App SHALL display an `EmptyStateWidget` with a contextual message.
4. THE EmptyStateWidget SHALL include a centered illustration or icon and a descriptive message explaining how to add data.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Balance Invariant

*For any* set of income and expense transactions stored in TransactionService, `getBalance()` shall always equal `getTotalIncome() - getTotalExpenses()`.

**Validates: Requirements 9.1, 9.2, 9.3**

---

### Property 2: Adding a Transaction Persists It

*For any* valid Transaction object, after calling `addTransaction()`, `getAllTransactions()` shall contain exactly one item with the same ID, and the total count shall increase by exactly one.

**Validates: Requirements 4.1, 4.2**

---

### Property 3: Income Monotonicity

*For any* income transaction added to TransactionService, `getTotalIncome()` after the addition shall be greater than or equal to `getTotalIncome()` before the addition.

**Validates: Requirements 4.3**

---

### Property 4: Expense Monotonicity

*For any* expense transaction added to TransactionService, `getTotalExpenses()` after the addition shall be greater than or equal to `getTotalExpenses()` before the addition.

**Validates: Requirements 4.4**

---

### Property 5: Delete Removes Exactly the Target Transaction

*For any* collection of stored transactions and any transaction ID within that collection, after calling `deleteTransaction(id)`, `getAllTransactions()` shall not contain any transaction with that ID.

**Validates: Requirements 5.2, 5.3**

---

### Property 6: Delete is a No-Op for Non-Existent IDs

*For any* ID that does not correspond to a stored transaction, calling `deleteTransaction(id)` shall not throw an exception and shall leave `getAllTransactions()` unchanged.

**Validates: Requirements 5.4**

---

### Property 7: Category Breakdown Correctness

*For any* set of transactions, `getExpensesByCategory()` shall return a map where every value is positive, only expense categories are present, and the sum of all values equals `getTotalExpenses()` within a tolerance of 0.001.

**Validates: Requirements 8.5, 9.4, 9.5, 9.6, 9.7**

---

### Property 8: Recent Transactions Bound

*For any* positive integer `n` and any collection of stored transactions, `getRecentTransactions(limit: n)` shall return a list of at most `n` items sorted by date descending.

**Validates: Requirements 9.8, 9.9**

---

### Property 9: Form Validation Rejects Invalid Amounts

*For any* amount value that is zero or negative (including all strings that parse to ≤ 0), the AddTransactionScreen form validation shall reject the submission and the transaction count in TransactionService shall remain unchanged.

**Validates: Requirements 3.5, 3.6, 2.2**

---

### Property 10: Form Validation Rejects Invalid Descriptions

*For any* description string that is empty or whose trimmed length exceeds 200 characters, the AddTransactionScreen form validation shall reject the submission and the transaction count in TransactionService shall remain unchanged.

**Validates: Requirements 3.7, 3.8, 2.3**

---

### Property 11: Transaction List Color Coding

*For any* Transaction object rendered as a `TransactionListItem`, the displayed amount color shall be green if the type is `income` and red if the type is `expense`.

**Validates: Requirements 7.2, 7.3**
