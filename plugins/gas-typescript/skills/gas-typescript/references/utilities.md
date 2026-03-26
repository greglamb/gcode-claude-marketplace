# Utilities — GAS TypeScript Reference

## Table of Contents

1. CacheService
2. Utilities (Encoding, Hashing, Dates, UUID)
3. HtmlService (Dialogs, Sidebars, Web Apps)
4. Session
5. OAuth Scopes Reference
6. Quotas and Limits

## 1. CacheService

Temporary key-value storage with configurable TTL (max 6 hours). Three scopes mirror PropertiesService.

```typescript
// Script cache — shared across all users
const scriptCache = CacheService.getScriptCache();

// User cache — per-user
const userCache = CacheService.getUserCache();

// Document cache — per-document (bound scripts only)
const docCache = CacheService.getDocumentCache();
```

### Basic Operations

```typescript
const cache = CacheService.getScriptCache();

// Put (duration in seconds, default 600, max 21600 = 6 hours)
cache.put("key", "value", 600);

// Get (returns null if expired or missing)
const value = cache.get("key");

// Remove
cache.remove("key");

// Batch operations — significantly faster for multiple keys
cache.putAll({
  key1: "value1",
  key2: "value2",
  key3: "value3",
}, 600);

const values = cache.getAll(["key1", "key2", "key3"]);
// Returns { key1: "value1", key2: "value2", key3: "value3" }

cache.removeAll(["key1", "key2", "key3"]);
```

### Cache vs Properties Decision Table

| Factor | CacheService | PropertiesService |
|--------|-------------|-------------------|
| Persistence | Temporary (max 6h) | Permanent |
| Speed | Faster | Slower |
| Max value size | 100 KB | 9 KB |
| Use for | API response caching, computed data, session state | Config, cursors, user preferences, API keys |
| Scope options | Script, User, Document | Script, User, Document |

### Typed Cache Wrapper

```typescript
export class TypedCache<T> {
  constructor(
    private readonly cache: GoogleAppsScript.Cache.Cache,
    private readonly ttlSeconds: number = 600,
  ) {}

  get(key: string): T | null {
    const raw = this.cache.get(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  }

  set(key: string, value: T): void {
    this.cache.put(key, JSON.stringify(value), this.ttlSeconds);
  }

  getOrFetch(key: string, fetcher: () => T): T {
    const cached = this.get(key);
    if (cached !== null) return cached;
    const fresh = fetcher();
    this.set(key, fresh);
    return fresh;
  }
}

// Usage
interface ApiResponse { items: string[]; total: number; }
const apiCache = new TypedCache<ApiResponse>(CacheService.getScriptCache(), 300);
const data = apiCache.getOrFetch("api:items", () => callExpensiveApi());
```

## 2. Utilities

The `Utilities` service provides encoding, hashing, date formatting, and more.

### Base64 Encoding

```typescript
const text = "Hello World";
const encoded = Utilities.base64Encode(text);                    // "SGVsbG8gV29ybGQ="
const decoded = Utilities.base64Decode(encoded);                 // Byte[]
const decodedStr = Utilities.base64Decode(encoded, Utilities.Charset.UTF_8); // Byte[]
const backToString = Utilities.newBlob(decoded).getDataAsString(); // "Hello World"

// Encode bytes (for binary data)
const bytes = [72, 101, 108, 108, 111];
const b64 = Utilities.base64Encode(bytes);

// Web-safe variant (uses - and _ instead of + and /)
const webSafe = Utilities.base64EncodeWebSafe(text);
```

### Hashing

```typescript
// SHA-256 (recommended for integrity checks)
const sha256 = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, "input");
const sha256Hex = sha256.map(b => (b < 0 ? b + 256 : b).toString(16).padStart(2, "0")).join("");

// MD5 (for checksums, not security)
const md5 = Utilities.computeDigest(Utilities.DigestAlgorithm.MD5, "input");

// HMAC signatures (for API auth)
const hmac = Utilities.computeHmacSha256Signature("message", "secret-key");
const hmacB64 = Utilities.base64Encode(hmac);
```

### UUID Generation

```typescript
const uuid = Utilities.getUuid(); // e.g., "550e8400-e29b-41d4-a716-446655440000"
```

### Date Formatting

```typescript
const now = new Date();

// Format with timezone
const formatted = Utilities.formatDate(now, "America/Los_Angeles", "yyyy-MM-dd HH:mm:ss");
// "2025-03-25 14:30:00"

// Common format patterns:
// "yyyy-MM-dd"            → "2025-03-25"
// "MM/dd/yyyy"            → "03/25/2025"
// "MMMM d, yyyy"          → "March 25, 2025"
// "EEE, MMM d"            → "Tue, Mar 25"
// "HH:mm:ss"              → "14:30:00"
// "h:mm a"                → "2:30 PM"
// "yyyy-MM-dd'T'HH:mm:ss" → ISO-like format
```

### URL Encoding and Other Utilities

```typescript
// URL encode
const encoded = encodeURIComponent("hello world & more");  // Use standard JS, not Utilities

// Sleep (milliseconds) — use between API calls to respect rate limits
Utilities.sleep(1000); // 1 second

// Zip/unzip
const blobs = [
  Utilities.newBlob("file1 content", "text/plain", "file1.txt"),
  Utilities.newBlob("file2 content", "text/plain", "file2.txt"),
];
const zip = Utilities.zip(blobs, "archive.zip");
const unzipped = Utilities.unzip(zip); // Blob[]

// Parse CSV
const csvString = "a,b,c\n1,2,3\n4,5,6";
const parsed = Utilities.parseCsv(csvString); // string[][]

// Create blob from string
const blob = Utilities.newBlob("content", "text/plain", "filename.txt");
```

## 3. HtmlService (Dialogs, Sidebars, Web Apps)

Create rich HTML-based UI for bound scripts or standalone web apps.

### Dialogs and Sidebars

```typescript
// Simple dialog from string
function showDialog(): void {
  const html = HtmlService.createHtmlOutput("<h1>Hello</h1><p>Custom dialog content</p>")
    .setWidth(400)
    .setHeight(300);
  SpreadsheetApp.getUi().showModalDialog(html, "My Dialog");
}

// Sidebar
function showSidebar(): void {
  const html = HtmlService.createHtmlOutput("<p>Sidebar content</p>")
    .setTitle("My Sidebar");
  SpreadsheetApp.getUi().showSidebar(html);
}

// From HTML file (preferred for complex UI)
// Create an HTML file in your project, reference it by name
function showRichDialog(): void {
  const html = HtmlService.createHtmlOutputFromFile("dialog")
    .setWidth(600)
    .setHeight(400);
  SpreadsheetApp.getUi().showModalDialog(html, "Rich Dialog");
}
```

### Client-Server Communication

In HTML files, use `google.script.run` to call server-side functions:

```html
<!-- dialog.html -->
<script>
  function onSubmit() {
    const value = document.getElementById("input").value;
    google.script.run
      .withSuccessHandler(result => { /* handle success */ })
      .withFailureHandler(error => { /* handle error */ })
      .serverFunction(value);
  }
</script>
```

### Web Apps

```typescript
// Serve HTML as a web app (requires deployment as web app)
function doGet(e: GoogleAppsScript.Events.DoGet): GoogleAppsScript.HTML.HtmlOutput {
  return HtmlService.createHtmlOutputFromFile("index")
    .setTitle("My Web App")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

// Handle POST requests
function doPost(e: GoogleAppsScript.Events.DoPost): GoogleAppsScript.Content.TextOutput {
  const data = JSON.parse(e.postData.contents);
  // Process data...
  return ContentService.createTextOutput(JSON.stringify({ status: "ok" }))
    .setMimeType(ContentService.MimeType.JSON);
}
```

## 4. Session

```typescript
// Current user info
const email = Session.getEffectiveUser().getEmail();
const activeUser = Session.getActiveUser().getEmail(); // May be empty for triggers

// Script timezone
const tz = Session.getScriptTimeZone();

// Temporary auth key (for HtmlService callbacks)
const key = ScriptApp.getOAuthToken();
```

**Note**: `getActiveUser()` returns empty string for time-driven triggers and when the script owner differs from the running user. Use `getEffectiveUser()` for reliable results.

## 5. OAuth Scopes Reference

Always declare the narrowest scopes needed in `appsscript.json`. GAS auto-detects scopes, but explicit declaration prevents over-permissioning.

### Spreadsheets
| Scope | Access Level |
|-------|-------------|
| `spreadsheets.currentonly` | Only the bound spreadsheet |
| `spreadsheets.readonly` | Read all spreadsheets |
| `spreadsheets` | Read/write all spreadsheets |

### Drive
| Scope | Access Level |
|-------|-------------|
| `drive.file` | Files created/opened by the script |
| `drive.readonly` | Read all Drive files |
| `drive` | Full Drive access |

### Gmail
| Scope | Access Level |
|-------|-------------|
| `gmail.readonly` | Read-only Gmail access |
| `gmail.send` | Send only (no read) |
| `gmail.modify` | Read + modify (labels, read status) |
| `gmail.compose` | Create drafts |

### Calendar
| Scope | Access Level |
|-------|-------------|
| `calendar.readonly` | Read-only calendar access |
| `calendar` | Full calendar access |
| `calendar.events` | Read/write events only |

### Documents
| Scope | Access Level |
|-------|-------------|
| `documents.readonly` | Read-only Docs access |
| `documents` | Full Docs access |
| `documents.currentonly` | Only the bound document |

### Other Common Scopes
| Scope | Purpose |
|-------|---------|
| `script.send_mail` | Send email via MailApp |
| `script.external_request` | UrlFetchApp HTTP calls |
| `forms.currentonly` | Only the bound form |
| `presentations` | Full Slides access |
| `presentations.readonly` | Read-only Slides |

All scopes are prefixed with `https://www.googleapis.com/auth/`. Example manifest:

```json
{
  "oauthScopes": [
    "https://www.googleapis.com/auth/spreadsheets.currentonly",
    "https://www.googleapis.com/auth/script.send_mail",
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/script.external_request"
  ]
}
```

## 6. Quotas and Limits

### Execution Limits

| Limit | Free Account | Google Workspace |
|-------|-------------|-----------------|
| Script runtime | 6 minutes | 30 minutes |
| Triggers total | 20 per user per script | 20 per user per script |
| Trigger runtime | 6 min per execution | 30 min per execution |
| Calendar events created | 5,000/day | 10,000/day |
| Contacts created | 1,000/day | 2,000/day |
| Documents created | 250/day | 1,500/day |
| Emails sent | 100/day | 1,500/day |
| Spreadsheets created | 250/day | 1,500/day |
| UrlFetchApp calls | 20,000/day | 100,000/day |

### Rate Limits (per user)

| Service | Read | Write |
|---------|------|-------|
| SpreadsheetApp | 300/100s | 60/100s |
| DriveApp | Varies by method | Add `Utilities.sleep(100)` in loops |

### Size Limits

| Resource | Limit |
|----------|-------|
| Cell content | 50,000 characters |
| Spreadsheet cells | 10,000,000 |
| Cache entry | 100 KB |
| Properties value | 9 KB |
| Properties total | 500 KB per store |
| Email attachment | 25 MB |
| UrlFetchApp response | 50 MB |
| Script project size | 50 MB |
