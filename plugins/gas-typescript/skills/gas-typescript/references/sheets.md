# Sheets — GAS TypeScript Reference

## Table of Contents

1. Core APIs
2. Batch Operations (Critical for Performance)
3. Custom Functions
4. Named Ranges and Data Validation
5. Formatting and Conditional Rules
6. Common Pitfalls
7. Deprecated APIs to Avoid

## 1. Core APIs

Primary service: `SpreadsheetApp`. Types under `GoogleAppsScript.Spreadsheet`.

```typescript
const ss = SpreadsheetApp.getActiveSpreadsheet();
const sheet = ss.getSheetByName("Data");
if (!sheet) throw new Error("Sheet 'Data' not found");
```

For bound scripts (attached to a spreadsheet), `getActiveSpreadsheet()` works directly. For standalone scripts, open by ID:

```typescript
const ss = SpreadsheetApp.openById("SPREADSHEET_ID");
```

## 2. Batch Operations (Critical for Performance)

The single most important GAS Sheets optimization: **minimize calls to `getValues()` and `setValues()`**. Each call is a round-trip to Google's servers.

```typescript
// BAD: N round-trips
for (let i = 1; i <= 100; i++) {
  const val = sheet.getRange(i, 1).getValue(); // 100 server calls
  sheet.getRange(i, 2).setValue(val * 2);       // 100 more
}

// GOOD: 2 round-trips total
const data = sheet.getRange(1, 1, 100, 1).getValues(); // 1 call
const output = data.map(row => [row[0] * 2]);
sheet.getRange(1, 2, 100, 1).setValues(output);         // 1 call
```

**Flush sparingly**: `SpreadsheetApp.flush()` forces pending writes. Only use when you need intermediate results visible (e.g., progress indicators). Otherwise let GAS batch naturally.

### Reading Patterns

```typescript
// Get all data (auto-detects used range)
const allData = sheet.getDataRange().getValues();

// Get specific range
const range = sheet.getRange("A2:D100");
const values = range.getValues(); // string[][]

// Get with display values (formatted strings) vs raw values
const display = range.getDisplayValues();
const formulas = range.getFormulas();
```

### Writing Patterns

```typescript
// Write a 2D array
sheet.getRange(1, 1, data.length, data[0].length).setValues(data);

// Append rows (adds after last row with content)
sheet.appendRow(["Col1", "Col2", "Col3"]);

// Clear and rewrite (common pattern for "refresh" operations)
sheet.getDataRange().clearContent();
sheet.getRange(1, 1, newData.length, newData[0].length).setValues(newData);
```

## 3. Custom Functions

Custom functions run in cells like `=MYFUNC(A1:A10)`. They have severe restrictions:

- Cannot access other services (no `GmailApp`, `DriveApp`, etc.)
- Cannot modify the spreadsheet (read-only)
- 30-second execution limit (vs. 6 minutes for normal functions)
- Return value must be a primitive, 1D array, or 2D array

```typescript
/**
 * Calculates a discount price.
 * @param {number} price - Original price.
 * @param {number} discount - Discount percentage (0-100).
 * @returns {number} Discounted price.
 * @customfunction
 */
function DISCOUNTED_PRICE(price: number, discount: number): number {
  if (discount < 0 || discount > 100) {
    throw new Error("Discount must be 0-100");
  }
  return price * (1 - discount / 100);
}

export { DISCOUNTED_PRICE };
```

The `@customfunction` JSDoc tag enables autocomplete in the Sheets editor.

## 4. Named Ranges and Data Validation

```typescript
// Named ranges
const namedRange = ss.getRangeByName("ConfigRange");
if (namedRange) {
  const config = namedRange.getValues();
}

// Data validation — dropdown list
const rule = SpreadsheetApp.newDataValidation()
  .requireValueInList(["Active", "Inactive", "Pending"])
  .setAllowInvalid(false)
  .build();
sheet.getRange("B2:B100").setDataValidation(rule);
```

## 5. Formatting and Conditional Rules

```typescript
// Batch formatting
const headerRange = sheet.getRange(1, 1, 1, 5);
headerRange
  .setFontWeight("bold")
  .setBackground("#4285f4")
  .setFontColor("#ffffff")
  .setHorizontalAlignment("center");

// Conditional formatting
const conditionalRule = SpreadsheetApp.newConditionalFormatRule()
  .whenNumberGreaterThan(100)
  .setBackground("#d4edda")
  .setRanges([sheet.getRange("C2:C100")])
  .build();
const rules = sheet.getConditionalFormatRules();
rules.push(conditionalRule);
sheet.setConditionalFormatRules(rules);
```

## 6. Common Pitfalls

- **1-indexed ranges**: `getRange(row, col)` is 1-based, but `getValues()` returns a 0-based array. Off-by-one errors are extremely common.
- **Empty rows**: `getDataRange()` stops at the last row with content. Blank rows in the middle are included, but trailing blank rows are not.
- **Type coercion**: Sheets stores values as strings, numbers, dates, or booleans. `getValues()` returns the native type. A cell displaying "123" might be a string or number — check types.
- **Date timezone**: Dates from Sheets use the spreadsheet's timezone, not the script's. Use `Utilities.formatDate()` with an explicit timezone.

## 7. Deprecated APIs to Avoid

| Deprecated | Use Instead |
|-----------|-------------|
| `Sheet.getSheetValues()` | `Sheet.getRange().getValues()` |
| `Range.setFontSizes()` (singular array) | `Range.setFontSize()` for uniform or build font size arrays |

Prefer the Advanced Sheets Service (`Sheets` namespace) for bulk operations like batch updates, pivot table creation, and chart manipulation — the built-in `SpreadsheetApp` doesn't expose all Sheets API features.
