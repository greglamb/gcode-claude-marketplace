# Forms — GAS TypeScript Reference

## Table of Contents

1. Core APIs
2. Creating and Modifying Forms
3. Processing Responses
4. Form Triggers
5. Linked Sheets
6. Common Pitfalls

## 1. Core APIs

Primary service: `FormApp`. Types under `GoogleAppsScript.Forms`.

```typescript
// Open existing form
const form = FormApp.openById("FORM_ID");

// Get active form (in bound scripts)
const activeForm = FormApp.getActiveForm();

// Create new form
const newForm = FormApp.create("Feedback Survey");
```

## 2. Creating and Modifying Forms

```typescript
const form = FormApp.create("Employee Survey");
form.setDescription("Monthly team satisfaction survey");
form.setConfirmationMessage("Thanks for your feedback!");
form.setAllowResponseEdits(false);
form.setLimitOneResponsePerUser(true);

// Add questions
const nameItem = form.addTextItem()
  .setTitle("Your Name")
  .setRequired(true);

const ratingItem = form.addScaleItem()
  .setTitle("How satisfied are you?")
  .setBounds(1, 5)
  .setLabels("Not at all", "Very satisfied");

const multiChoice = form.addMultipleChoiceItem()
  .setTitle("Department")
  .setChoiceValues(["Engineering", "Marketing", "Sales", "HR"])
  .setRequired(true);

const checkboxes = form.addCheckboxItem()
  .setTitle("Which tools do you use?")
  .setChoiceValues(["Slack", "Jira", "GitHub", "Confluence"]);

// Sections and page breaks
form.addPageBreakItem().setTitle("Section 2: Detailed Feedback");

const longAnswer = form.addParagraphTextItem()
  .setTitle("Any additional comments?");

// Get the form URL
const editUrl = form.getEditUrl();        // Editor URL
const publishedUrl = form.getPublishedUrl(); // Respondent URL
```

## 3. Processing Responses

```typescript
function processResponses(formId: string): void {
  const form = FormApp.openById(formId);
  const responses = form.getResponses();

  for (const response of responses) {
    const timestamp = response.getTimestamp();
    const email = response.getRespondentEmail(); // requires "collect emails" enabled
    const itemResponses = response.getItemResponses();

    for (const itemResponse of itemResponses) {
      const question = itemResponse.getItem().getTitle();
      const answer = itemResponse.getResponse(); // string | string[] | string[][]
      console.log(`${question}: ${answer}`);
    }
  }
}

// Get only new responses since last check
function getNewResponses(formId: string): GoogleAppsScript.Forms.FormResponse[] {
  const props = PropertiesService.getScriptProperties();
  const lastTimestamp = props.getProperty("lastFormCheck");
  const form = FormApp.openById(formId);

  let responses: GoogleAppsScript.Forms.FormResponse[];
  if (lastTimestamp) {
    responses = form.getResponses(new Date(lastTimestamp));
  } else {
    responses = form.getResponses();
  }

  props.setProperty("lastFormCheck", new Date().toISOString());
  return responses;
}
```

## 4. Form Triggers

Forms support an `onFormSubmit` trigger that fires when a response is submitted:

```typescript
// Install trigger programmatically
function createFormTrigger(): void {
  ScriptApp.newTrigger("onFormSubmit")
    .forForm("FORM_ID")
    .onFormSubmit()
    .create();
}

// Handler
function onFormSubmit(e: GoogleAppsScript.Forms.FormSubmitEvent): void {
  const response = e.response;
  const items = response.getItemResponses();

  // Process the submission
  for (const item of items) {
    console.log(`${item.getItem().getTitle()}: ${item.getResponse()}`);
  }
}

export { onFormSubmit, createFormTrigger };
```

**Note**: If the form is linked to a sheet, you can also use `onFormSubmit` from the spreadsheet side, which provides both the form response and the sheet row data.

## 5. Linked Sheets

Forms auto-populate a linked Google Sheet. You can access this relationship:

```typescript
const form = FormApp.openById("FORM_ID");

// Get the destination spreadsheet
const destinationId = form.getDestinationId();
if (destinationId) {
  const ss = SpreadsheetApp.openById(destinationId);
  // Process sheet data...
}

// Link a form to a new spreadsheet
form.setDestination(FormApp.DestinationType.SPREADSHEET, "SPREADSHEET_ID");
```

The sheet trigger approach is often simpler for data processing:

```typescript
// Spreadsheet-side onFormSubmit (different event type!)
function onFormSubmitFromSheet(
  e: GoogleAppsScript.Events.SheetsOnFormSubmit,
): void {
  const row = e.values;                    // Array of cell values
  const range = e.range;                   // The row range in the sheet
  const namedValues = e.namedValues;       // { "Question": ["Answer"], ... }

  console.log(`New submission in row ${range.getRow()}`);
}
```

## 6. Common Pitfalls

- **Response type varies by item type**: `getResponse()` returns `string` for text items, `string[]` for checkboxes, and `string[][]` for grid items. Always check the item type before processing.
- **Form vs Sheet trigger**: The `onFormSubmit` event object is completely different depending on whether the trigger is on the Form or on the linked Sheet. The Form trigger gives `FormResponse` objects; the Sheet trigger gives row values and named values.
- **No programmatic response deletion**: `FormApp` cannot delete individual responses. You can delete all responses with `form.deleteAllResponses()`, but not selectively.
- **File upload items**: File upload responses return Drive file IDs, not the actual files. Use `DriveApp.getFileById()` to access uploaded files.
- **Quiz mode**: Enabling quiz mode (`form.setIsQuiz(true)`) changes behavior — items can have point values and feedback, and the response object includes score data.
