# Slides — GAS TypeScript Reference

## Table of Contents

1. Core APIs
2. Creating and Opening Presentations
3. Slide Operations
4. Shapes and Text
5. Images and Tables
6. Layouts and Masters
7. Common Patterns
8. Common Pitfalls

## 1. Core APIs

Primary service: `SlidesApp`. Types under `GoogleAppsScript.Slides`.

For bound scripts (attached to a presentation), use `SlidesApp.getActivePresentation()`. For standalone scripts, open by ID.

## 2. Creating and Opening Presentations

```typescript
const pres = SlidesApp.create("My Presentation");
const presId = pres.getId();

const pres = SlidesApp.openById("PRESENTATION_ID");
const pres = SlidesApp.openByUrl("https://docs.google.com/presentation/d/PRES_ID/edit");

// Active presentation (bound scripts only)
const pres = SlidesApp.getActivePresentation();
```

## 3. Slide Operations

```typescript
// Get all slides
const slides = pres.getSlides();

// Add slides
const blankSlide = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
const titleSlide = pres.appendSlide(SlidesApp.PredefinedLayout.TITLE);
const titleBodySlide = pres.appendSlide(SlidesApp.PredefinedLayout.TITLE_AND_BODY);

// Insert at specific position (0-indexed)
const slide = pres.insertSlide(0, SlidesApp.PredefinedLayout.TITLE);

// Duplicate a slide
const duplicate = slides[0].duplicate();

// Delete a slide
slides[2].remove();

// Move slide to position
slides[0].move(3); // Move first slide to position 3

// Get slide by object ID
const slide = pres.getSlideById("SLIDE_OBJECT_ID");

// Slide properties
const objectId = slide.getObjectId();
const pageElements = slide.getPageElements();
const background = slide.getBackground();
```

## 4. Shapes and Text

```typescript
const slide = pres.getSlides()[0];

// Insert a text box
const shape = slide.insertShape(
  SlidesApp.ShapeType.TEXT_BOX,
  100, // left (points)
  100, // top (points)
  400, // width (points)
  50,  // height (points)
);

// Set text content
const textRange = shape.getText();
textRange.setText("Hello World");

// Text formatting
const style = textRange.getTextStyle();
style.setFontSize(24);
style.setFontFamily("Arial");
style.setBold(true);
style.setForegroundColor("#ffffff");

// Paragraph formatting
const paraStyle = textRange.getParagraphStyle();
paraStyle.setParagraphAlignment(SlidesApp.ParagraphAlignment.CENTER);

// Shape styling
shape.getFill().setSolidFill("#4285f4");
shape.getBorder().setWeight(2);
shape.getBorder().getLineFill().setSolidFill("#000000");

// Insert predefined shapes
const rect = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, 50, 200, 200, 100);
const ellipse = slide.insertShape(SlidesApp.ShapeType.ELLIPSE, 300, 200, 150, 150);
const arrow = slide.insertShape(SlidesApp.ShapeType.RIGHT_ARROW, 200, 350, 100, 50);

// Get existing placeholders (from layout)
const placeholders = slide.getPlaceholders();
for (const ph of placeholders) {
  const type = ph.asShape().getPlaceholderType();
  if (type === SlidesApp.PlaceholderType.TITLE) {
    ph.asShape().getText().setText("My Title");
  } else if (type === SlidesApp.PlaceholderType.BODY) {
    ph.asShape().getText().setText("Slide body content");
  }
}
```

## 5. Images and Tables

```typescript
// Insert image from URL
const image = slide.insertImage("https://example.com/logo.png");
image.setLeft(50);
image.setTop(50);
image.setWidth(200);
image.setHeight(100);

// Insert image from Drive
const blob = DriveApp.getFileById("FILE_ID").getBlob();
const driveImage = slide.insertImage(blob);

// Insert table
const table = slide.insertTable(3, 4); // 3 rows, 4 columns
table.getCell(0, 0).getText().setText("Header 1");
table.getCell(0, 1).getText().setText("Header 2");
table.getCell(1, 0).getText().setText("Data 1");

// Style table cells
const headerCell = table.getCell(0, 0);
headerCell.getFill().setSolidFill("#4285f4");
headerCell.getText().getTextStyle().setForegroundColor("#ffffff").setBold(true);

// Populate table from data array
function fillTable(
  table: GoogleAppsScript.Slides.Table,
  data: string[][],
): void {
  for (let row = 0; row < data.length; row++) {
    for (let col = 0; col < data[row].length; col++) {
      table.getCell(row, col).getText().setText(data[row][col]);
    }
  }
}
```

## 6. Layouts and Masters

```typescript
// Get available layouts
const layouts = pres.getLayouts();
for (const layout of layouts) {
  console.log(`Layout: ${layout.getLayoutName()}`);
}

// Get slide masters
const masters = pres.getMasters();

// Apply a layout by name
const targetLayout = layouts.find(l => l.getLayoutName() === "Title and Body");
if (targetLayout) {
  pres.appendSlide(targetLayout);
}
```

## 7. Common Patterns

### Generate Slides from Data

```typescript
interface SlideData {
  title: string;
  bullets: string[];
  imageUrl?: string;
}

function generateDeck(data: SlideData[]): void {
  const pres = SlidesApp.getActivePresentation();

  for (const item of data) {
    const slide = pres.appendSlide(SlidesApp.PredefinedLayout.TITLE_AND_BODY);
    const placeholders = slide.getPlaceholders();

    for (const ph of placeholders) {
      const shape = ph.asShape();
      const type = shape.getPlaceholderType();

      if (type === SlidesApp.PlaceholderType.TITLE) {
        shape.getText().setText(item.title);
      } else if (type === SlidesApp.PlaceholderType.BODY) {
        shape.getText().setText(item.bullets.join("\n"));
      }
    }

    if (item.imageUrl) {
      slide.insertImage(item.imageUrl, 400, 100, 250, 250);
    }
  }
}
```

### Generate from Spreadsheet Data

```typescript
function slidesFromSheet(sheetName: string): void {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const data = ss.getSheetByName(sheetName)?.getDataRange().getValues();
  if (!data || data.length < 2) return;

  const headers = data[0] as string[];
  const rows = data.slice(1);

  const slideData: SlideData[] = rows.map(row => ({
    title: String(row[0]),
    bullets: headers.slice(1).map((h, i) => `${h}: ${row[i + 1]}`),
  }));

  generateDeck(slideData);
}
```

## 8. Common Pitfalls

- **Points not pixels**: All positioning and sizing uses points (1 point = 1/72 inch). A standard slide is 720×405 points (10×5.625 inches).
- **Placeholder types**: Layout placeholders have specific types (TITLE, BODY, SUBTITLE). If you add text to the wrong placeholder, it may not render as expected.
- **Shape vs PageElement**: `getPageElements()` returns `PageElement` objects. You must call `.asShape()`, `.asImage()`, `.asTable()`, etc. before accessing type-specific methods. Check `getPageElementType()` first.
- **No animation API**: GAS cannot create or modify slide animations/transitions. These must be set manually in the Slides UI.
- **Batch considerations**: Each `insertShape`, `insertImage`, and `insertTable` call is a server round-trip. For generating many slides, this can be slow. Consider using the Advanced Slides Service (`Slides` API v1) for batch operations via `batchUpdate`.
- **Text range indexing**: `TextRange` operations are 0-indexed. `getRange(start, end)` where `end` is exclusive.
