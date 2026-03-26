# Drive — GAS TypeScript Reference

## Table of Contents

1. Core APIs
2. File Operations
3. Folder Navigation
4. Permissions and Sharing
5. Advanced Drive Service
6. Common Pitfalls

## 1. Core APIs

Primary service: `DriveApp`. Types under `GoogleAppsScript.Drive`.

```typescript
const rootFolder = DriveApp.getRootFolder();
const file = DriveApp.getFileById("FILE_ID");
const folder = DriveApp.getFolderById("FOLDER_ID");
```

For bulk operations, metadata queries, or features not in `DriveApp`, enable the Advanced Drive Service:

```json
{
  "dependencies": {
    "enabledAdvancedServices": [
      { "userSymbol": "Drive", "serviceId": "drive", "version": "v3" }
    ]
  }
}
```

## 2. File Operations

### Creating Files

```typescript
// Create from string content
const textFile = DriveApp.createFile("notes.txt", "Hello world", MimeType.PLAIN_TEXT);

// Create from blob
const blob = Utilities.newBlob("CSV,Data\n1,2", MimeType.CSV, "data.csv");
const csvFile = DriveApp.createFile(blob);

// Create in specific folder
const folder = DriveApp.getFolderById("FOLDER_ID");
const fileInFolder = folder.createFile("report.txt", "Content", MimeType.PLAIN_TEXT);
```

### Reading Files

```typescript
const file = DriveApp.getFileById("FILE_ID");
const content = file.getBlob().getDataAsString(); // Text content
const bytes = file.getBlob().getBytes();           // Binary content
const mimeType = file.getMimeType();
```

### Converting Between Formats

```typescript
// Export Google Doc as PDF
const doc = DriveApp.getFileById("DOC_ID");
const pdfBlob = doc.getAs(MimeType.PDF);
DriveApp.createFile(pdfBlob).setName("exported.pdf");

// Export Sheets as CSV
const sheet = DriveApp.getFileById("SHEET_ID");
const csvBlob = sheet.getAs(MimeType.CSV);
```

## 3. Folder Navigation

```typescript
// Search for files
const files = DriveApp.searchFiles('title contains "report" and mimeType = "application/pdf"');
while (files.hasNext()) {
  const file = files.next();
  console.log(`${file.getName()} — ${file.getUrl()}`);
}

// Iterate folder contents
function listFolder(folder: GoogleAppsScript.Drive.Folder, depth: number = 0): void {
  const prefix = "  ".repeat(depth);
  const files = folder.getFiles();
  while (files.hasNext()) {
    console.log(`${prefix}📄 ${files.next().getName()}`);
  }
  const subfolders = folder.getFolders();
  while (subfolders.hasNext()) {
    const sub = subfolders.next();
    console.log(`${prefix}📁 ${sub.getName()}`);
    listFolder(sub, depth + 1);
  }
}
```

### Search Query Syntax

DriveApp.searchFiles uses the Drive API v2 query syntax:

| Query | Purpose |
|-------|---------|
| `title = 'exact name'` | Exact filename match |
| `title contains 'partial'` | Partial filename match |
| `mimeType = 'application/pdf'` | Filter by MIME type |
| `modifiedDate > '2025-01-01'` | Modified after date |
| `'FOLDER_ID' in parents` | Files in a specific folder |
| `trashed = false` | Exclude trashed files |

Combine with `and` / `or`. Note: this is Drive API v2 syntax, not v3.

## 4. Permissions and Sharing

```typescript
const file = DriveApp.getFileById("FILE_ID");

// Share with specific user
file.addEditor("user@example.com");
file.addViewer("viewer@example.com");

// Share with anyone (link sharing)
file.setSharing(
  DriveApp.Access.ANYONE_WITH_LINK,
  DriveApp.Permission.VIEW,
);

// Remove access
file.removeEditor("user@example.com");

// Check current access
const editors = file.getEditors();
const viewers = file.getViewers();
```

## 5. Advanced Drive Service

Use for features not available in `DriveApp`:

```typescript
// Move a file to a folder (Drive API v3)
function moveFile(fileId: string, targetFolderId: string): void {
  const file = Drive.Files!.get(fileId, { fields: "parents" });
  const previousParents = file.parents?.join(",") ?? "";
  Drive.Files!.update({}, fileId, undefined, {
    addParents: targetFolderId,
    removeParents: previousParents,
    fields: "id, parents",
  });
}

// List files with pagination
function listAllFiles(): GoogleAppsScript.Drive.Schema.File[] {
  const allFiles: GoogleAppsScript.Drive.Schema.File[] = [];
  let pageToken: string | undefined;

  do {
    const response = Drive.Files!.list({
      pageSize: 100,
      pageToken: pageToken,
      fields: "nextPageToken, files(id, name, mimeType)",
    });
    if (response.files) {
      allFiles.push(...response.files);
    }
    pageToken = response.nextPageToken ?? undefined;
  } while (pageToken);

  return allFiles;
}
```

## 6. Common Pitfalls

- **Iterator pattern**: `DriveApp.getFiles()` returns a `FileIterator`, not an array. Use `while (iter.hasNext())` — don't try to spread or `Array.from()` it.
- **Quota limits**: Creating many files rapidly can hit Drive API quotas. Add `Utilities.sleep(100)` between bulk operations.
- **Shared Drives**: `DriveApp` has limited support for Shared Drives. Use the Advanced Drive Service with `supportsAllDrives: true` for Shared Drive operations.
- **File in multiple folders**: Drive v3 doesn't truly support files in multiple folders (shortcuts are different). Avoid relying on `addToFolder` patterns.
- **Search syntax version**: `DriveApp.searchFiles()` uses Drive API v2 query syntax even if you have the v3 Advanced Service enabled. The query field names differ (`title` in v2 vs `name` in v3).
