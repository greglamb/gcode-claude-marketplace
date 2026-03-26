# Docs — GAS TypeScript Reference

## Table of Contents

1. Core APIs
2. Creating and Opening Documents
3. Body Operations
4. Text Formatting
5. Tables
6. Images and Links
7. Find and Replace
8. Document Properties
9. Common Pitfalls

## 1. Core APIs

Primary service: `DocumentApp`. Types under `GoogleAppsScript.Document`.

For bound scripts (attached to a Doc), use `DocumentApp.getActiveDocument()`. For standalone scripts, open by ID.

## 2. Creating and Opening Documents

```typescript
// Create new
const doc = DocumentApp.create("My Document");
const docId = doc.getId();

// Open existing
const doc = DocumentApp.openById("DOCUMENT_ID");

// Open by URL
const doc = DocumentApp.openByUrl("https://docs.google.com/document/d/DOC_ID/edit");

// Active document (bound scripts only)
const doc = DocumentApp.getActiveDocument();
```

## 3. Body Operations

The document body is the main content container. All content is appended or inserted by index.

```typescript
const body = doc.getBody();

// Append content
body.appendParagraph("Regular paragraph text");
const heading = body.appendParagraph("Section Title");
heading.setHeading(DocumentApp.ParagraphHeading.HEADING1);

body.appendHorizontalRule();
body.appendPageBreak();

// Insert at specific position (0-indexed child position)
body.insertParagraph(0, "New first paragraph");

// Get all paragraphs
const paragraphs = body.getParagraphs();
for (const para of paragraphs) {
  console.log(`${para.getHeading()}: ${para.getText()}`);
}

// Clear all content
body.clear();
```

## 4. Text Formatting

```typescript
// Paragraph-level formatting
const para = body.appendParagraph("Formatted text");
para.setAlignment(DocumentApp.HorizontalAlignment.CENTER);
para.setIndentFirstLine(36);    // Points
para.setIndentStart(18);
para.setSpacingBefore(12);
para.setSpacingAfter(12);
para.setLineSpacing(1.5);

// Character-level formatting via editAsText
const text = body.editAsText();
text.setFontSize(12);
text.setFontFamily("Arial");
text.setBold(0, 5, true);              // Bold chars 0-5
text.setItalic(6, 10, true);
text.setForegroundColor(0, 5, "#ff0000");
text.setUnderline(0, 5, true);

// Style a specific paragraph's text
const paraText = para.editAsText();
paraText.setFontSize(0, paraText.getText().length - 1, 14);
```

## 5. Tables

```typescript
// Create table from 2D array
const table = body.appendTable([
  ["Name", "Role", "Email"],
  ["Alice", "Engineer", "alice@example.com"],
  ["Bob", "Designer", "bob@example.com"],
]);

// Style header row
const headerRow = table.getRow(0);
for (let i = 0; i < headerRow.getNumCells(); i++) {
  const cell = headerRow.getCell(i);
  cell.editAsText().setBold(true);
  cell.setBackgroundColor("#4285f4");
  cell.editAsText().setForegroundColor("#ffffff");
}

// Add rows dynamically
const newRow = table.appendTableRow();
newRow.appendTableCell("Charlie");
newRow.appendTableCell("PM");
newRow.appendTableCell("charlie@example.com");

// Set column widths (approximate — Docs doesn't have exact column width control)
table.setColumnWidth(0, 150);
table.setColumnWidth(1, 100);
table.setColumnWidth(2, 200);

// Get existing tables
const tables = body.getTables();
```

## 6. Images and Links

```typescript
// Insert image from Drive
const imageBlob = DriveApp.getFileById("FILE_ID").getBlob();
const image = body.appendImage(imageBlob);
image.setWidth(400);
image.setHeight(300);

// Insert image from URL
const response = UrlFetchApp.fetch("https://example.com/image.png");
body.appendImage(response.getBlob());

// Insert link
const para = body.appendParagraph("Click here for docs");
const text = para.editAsText();
text.setLinkUrl(0, 9, "https://docs.google.com");

// Insert link on specific text
const rangeBuilder = doc.newRange();
rangeBuilder.addElement(para);
```

## 7. Find and Replace

```typescript
// Simple find and replace
body.replaceText("{{NAME}}", "John Doe");
body.replaceText("{{DATE}}", new Date().toLocaleDateString());

// Regex-based find (uses RE2 syntax)
body.replaceText("\\b\\d{3}-\\d{4}\\b", "[REDACTED]");

// Find elements
const searchResult = body.findText("search term");
if (searchResult) {
  const element = searchResult.getElement();
  const start = searchResult.getStartOffset();
  const end = searchResult.getEndOffsetInclusive();
  element.asText().setBold(start, end, true);
}

// Iterate all matches
let result = body.findText("pattern");
while (result) {
  // process match
  result = body.findText("pattern", result);
}
```

## 8. Document Properties

```typescript
// Page setup
body.setMarginTop(72);     // 1 inch = 72 points
body.setMarginBottom(72);
body.setMarginLeft(72);
body.setMarginRight(72);

// Page size (letter = 612x792, A4 = 595x842)
body.setPageHeight(792);
body.setPageWidth(612);

// Document metadata
const title = doc.getName();
doc.setName("New Title");
const url = doc.getUrl();

// Save and close (important for standalone scripts)
doc.saveAndClose();
```

## 9. Common Pitfalls

- **saveAndClose()**: For standalone scripts that open docs by ID, always call `doc.saveAndClose()` when done. Without it, changes may not persist.
- **Body vs Header/Footer**: `doc.getBody()` only returns the main body. Use `doc.getHeader()` and `doc.getFooter()` for header/footer content. They may be `null` if not yet created — use `doc.addHeader()` / `doc.addFooter()`.
- **Element types**: The body is a tree of elements (Paragraph, Table, ListItem, etc.). Use `element.getType()` to check before casting with `asParagraph()`, `asTable()`, etc.
- **No undo**: Script changes to documents are immediate and can't be undone by the user. Consider making a copy first for destructive operations.
- **Template pattern**: The most common Docs pattern is "copy template, replace placeholders." Use `DriveApp.getFileById(templateId).makeCopy()` then `body.replaceText()` for each placeholder.
