---
name: gas-typescript
description: >
  Best practices, design patterns, workflow, and SDLC for Google Apps Script projects using TypeScript,
  Rollup, and clasp. Use this skill whenever the user mentions Google Apps Script, GAS, clasp,
  Apps Script, script.google.com, or wants to automate Google Workspace (Gmail, Sheets, Calendar, Drive,
  Docs, Forms, Slides). Also trigger when the user references @types/google-apps-script, appsscript.json,
  .clasp.json, GAS triggers, UrlFetchApp, SpreadsheetApp, GmailApp, CalendarApp, DriveApp, or any
  Google Apps Script built-in service. Even if the user just says "I want to automate something in
  Google Sheets" or "write a Gmail script", use this skill — they likely need GAS with TypeScript.
---

# Google Apps Script + TypeScript Skill

Build professional, maintainable Google Apps Script projects using TypeScript, Rollup, and clasp.

## Core Principles

These principles guide every decision in a GAS+TS project:

1. **TypeScript-first**: All source code is TypeScript. JavaScript is only a build artifact.
2. **Local development**: Code lives in your editor and version control, not the script.google.com editor.
3. **SOLID design**: Apply Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion — especially important in GAS where the temptation is to write monolithic functions.
4. **Bundled output**: Rollup compiles TS into a single `Code.js` that clasp pushes. GAS has no module system at runtime — every `.gs` file shares a flat global scope.
5. **Avoid deprecated APIs**: Always prefer current GAS APIs. Check the reference files in `references/` for domain-specific guidance.

## Project Scaffolding

### Directory Structure

```
my-gas-project/
├── src/
│   ├── index.ts              # Entry point — exports to GAS global scope
│   ├── services/             # Business logic (one service per responsibility)
│   │   ├── gmail.service.ts
│   │   └── sheets.service.ts
│   ├── models/               # Interfaces and type definitions
│   │   └── types.ts
│   ├── utils/                # Shared helpers
│   │   └── logger.ts
│   └── config.ts             # Constants and configuration
├── test/
│   ├── services/
│   │   ├── gmail.service.test.ts
│   │   └── sheets.service.test.ts
│   └── setup.ts              # GAS global mocks
├── appsscript.json           # GAS manifest (committed to repo)
├── .clasp.json               # clasp project config (committed — scriptId is not secret)
├── .claspignore              # Controls what clasp pushes
├── rollup.config.mjs         # Rollup bundler config
├── tsconfig.json
├── package.json
└── .gitignore
```

### package.json

```json
{
  "name": "my-gas-project",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "rollup -c",
    "push": "npm run build && clasp push -f",
    "deploy": "npm run push && clasp create-deployment",
    "pull": "clasp pull",
    "login": "clasp login",
    "lint": "eslint src/",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "devDependencies": {
    "@types/google-apps-script": "latest",
    "rollup": "^4.0.0",
    "@rollup/plugin-typescript": "^12.0.0",
    "@rollup/plugin-node-resolve": "^16.0.0",
    "tslib": "^2.7.0",
    "typescript": "^5.5.0",
    "vitest": "^3.0.0",
    "eslint": "^9.0.0"
  }
}
```

### rollup.config.mjs

Rollup bundles all TS modules into a single `Code.js`. The `gas-entry` pattern exposes functions to GAS's global scope.

```js
import typescript from "@rollup/plugin-typescript";
import resolve from "@rollup/plugin-node-resolve";

export default {
  input: "src/index.ts",
  output: {
    file: "build/Code.js",
    format: "iife", // Wraps in IIFE — no module leakage
    name: "_GAS", // Internal namespace (GAS ignores this)
    banner: "/* Built with Rollup — do not edit directly */",
    // Expose top-level exports as GAS global functions:
    outro: `
      // Expose exports to GAS global scope
      Object.keys(exports).forEach(function(key) {
        this[key] = exports[key];
      });
    `,
  },
  plugins: [
    resolve(),
    typescript({
      tsconfig: "./tsconfig.json",
    }),
  ],
};
```

**Why IIFE + outro?** GAS executes all `.gs` files in a shared global scope. There's no `import`/`export` at runtime. The `outro` pattern takes every named export from `index.ts` and assigns it to `globalThis`, making it callable by GAS triggers, custom menus, and the Apps Script runtime.

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "declaration": false,
    "sourceMap": false,
    "outDir": "./build",
    "rootDir": "./src",
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "build", "test"]
}
```

Key: `target: ES2022` (GAS V8 supports modern JS), `module: ESNext` (Rollup needs ESM), `moduleResolution: bundler`, and no `lib: ["dom"]` (GAS isn't a browser).

### appsscript.json

```json
{
  "timeZone": "America/Los_Angeles",
  "dependencies": {},
  "exceptionLogging": "STACKDRIVER",
  "runtimeVersion": "V8"
}
```

Always set `runtimeVersion: "V8"`. The legacy Rhino runtime doesn't support modern JS.

### .clasp.json / .claspignore / .gitignore

**.clasp.json** — Point `rootDir` at `build/` so clasp only pushes compiled output:
```json
{ "scriptId": "YOUR_SCRIPT_ID", "rootDir": "build/" }
```

**.claspignore** — Only push `Code.js` and manifest:
```
**/**
!Code.js
!appsscript.json
```

**.gitignore** — Never commit `.clasprc.json` (contains OAuth tokens):
```
node_modules/
build/
.clasprc.json
```

## The index.ts Entry Point

`index.ts` bridges your modular TypeScript and GAS's flat global scope. Only functions exported here become available to GAS triggers and menus.

```typescript
// src/index.ts
import { processEmails } from "./services/gmail.service";
import { syncCalendar } from "./services/calendar.service";

// Simple triggers — GAS calls these by name
function onOpen(e: GoogleAppsScript.Events.SheetsOnOpen): void { /* build menu */ }
function onEdit(e: GoogleAppsScript.Events.SheetsOnEdit): void { /* handle edit */ }

// Installable trigger handlers
function dailyEmailDigest(): void { processEmails(); }
function menuRunSync(): void { syncCalendar(); }

// Export everything GAS needs to see — use this syntax, not `export function`
export { onOpen, onEdit, dailyEmailDigest, menuRunSync };
```

## SOLID Patterns for GAS

GAS projects tend to start as small scripts and grow into unmaintainable monoliths. Apply SOLID from the start:

- **Single Responsibility**: One service file per Google service domain (`gmail.service.ts`, `sheets.service.ts`). `index.ts` orchestrates — it doesn't contain business logic.
- **Dependency Inversion**: Wrap GAS globals behind interfaces (`IEmailService`, `ISheetService`) so business logic is testable without real GAS APIs.
- **Open/Closed**: Use config-driven rules (arrays of `{ query, action }` objects) so adding behavior means adding config, not changing service code.

The key pattern is dependency inversion — it enables everything else:

```typescript
// Define an interface for the GAS service boundary
export interface IEmailService {
  getUnreadThreads(query: string): GoogleAppsScript.Gmail.GmailThread[];
  markAsRead(thread: GoogleAppsScript.Gmail.GmailThread): void;
}

// Business logic depends on the interface, not GmailApp
export function processUnread(emailService: IEmailService): void {
  const threads = emailService.getUnreadThreads("is:unread");
  threads.forEach(t => emailService.markAsRead(t));
}

// Production implementation wraps the real GAS global
export class GmailEmailService implements IEmailService {
  getUnreadThreads(query: string) { return GmailApp.search(query); }
  markAsRead(thread: GoogleAppsScript.Gmail.GmailThread) { thread.markRead(); }
}
```

For more patterns (Open/Closed config-driven rules, factory patterns), see test case examples.

## clasp Workflow

### Initial Setup

```bash
npm install -g @google/clasp    # Install clasp globally
clasp login                      # Authenticate with Google
clasp create-script --type standalone --title "My Project" --rootDir build/
# Or clone an existing project:
clasp clone-script "SCRIPT_ID" --rootDir build/
```

### Daily Development Cycle

```bash
npm run build     # Compile TS → build/Code.js via Rollup
npm run push      # Build + push to script.google.com
clasp open-script # Open in browser to test
clasp tail-logs   # Stream Stackdriver logs
```

### Deployment

```bash
# Create a versioned deployment (immutable snapshot)
npm run deploy

# List deployments
clasp list-deployments

# Redeploy an existing deployment ID
clasp create-deployment --deploymentId "AKfycbx..."
```

### Key clasp 3.x Changes

- clasp no longer transpiles TypeScript — you must use a bundler (Rollup).
- Several commands were renamed (e.g., `open` → `open-script`, `deploy` → `create-deployment`).
- Use `--user` flag for multi-account support.

## Testing Strategy

GAS globals (`SpreadsheetApp`, `GmailApp`, etc.) don't exist in Node.js. The strategy is dependency injection + mocking with Vitest.

Because services accept interfaces (not raw GAS globals), you provide mock implementations in tests. A `test/setup.ts` file stubs common globals (`Logger`, `Utilities`, `PropertiesService`), and each test creates specific mocks for the service interfaces.

**Test**: Business logic, data transformations, config parsing, rule engines, orchestration.
**Skip**: Direct GAS API calls — those are Google's responsibility. Your interfaces handle the boundary.

For detailed test setup, mock patterns, and examples, read `references/testing.md`.

## GAS-Specific Patterns

### Execution Time Limits

GAS has a 6-minute execution limit (30 minutes for Workspace accounts). For long-running operations, use a continuation pattern:

```typescript
function processBatch(): void {
  const startTime = Date.now();
  const MAX_RUNTIME_MS = 5 * 60 * 1000; // 5 min safety margin

  const props = PropertiesService.getScriptProperties();
  let cursor = parseInt(props.getProperty("cursor") ?? "0", 10);
  const data = getDataToProcess();

  while (cursor < data.length) {
    if (Date.now() - startTime > MAX_RUNTIME_MS) {
      props.setProperty("cursor", cursor.toString());
      // Re-trigger via time-based trigger
      ScriptApp.newTrigger("processBatch")
        .timeBased()
        .after(1000)
        .create();
      return;
    }
    processItem(data[cursor]);
    cursor++;
  }

  // Done — clean up
  props.deleteProperty("cursor");
}
```

### Properties Service for State

Use `PropertiesService` instead of global variables for persistent state:

- `ScriptProperties` — shared across all users of the script
- `UserProperties` — per-user storage
- `DocumentProperties` — bound to the host document

All values are strings. Serialize with `JSON.stringify` / `JSON.parse`.

### CacheService for Temporary Data

Use `CacheService` for expensive-to-compute values that don't need persistence. TTL is configurable up to 6 hours (default 600 seconds).

```typescript
function getExpensiveData(key: string): unknown {
  const cache = CacheService.getScriptCache();
  const cached = cache.get(key);
  if (cached) return JSON.parse(cached);

  const data = performExpensiveOperation();
  cache.put(key, JSON.stringify(data), 600); // 10 minutes
  return data;
}
```

**Cache vs Properties**: Cache is fast but temporary (max 6 hours). Properties are persistent but slower. Use cache for session data and API response caching; use Properties for configuration and cursor state.

Three cache scopes mirror Properties: `getScriptCache()`, `getUserCache()`, `getDocumentCache()`.

### Quotas and Rate Limits

| Resource | Limit |
|----------|-------|
| Execution time | 6 min (30 min Workspace) |
| Spreadsheet reads | 300 per 100 seconds |
| Spreadsheet writes | 60 per 100 seconds |
| Email sends (free) | 100/day |
| Email sends (Workspace) | 1,500/day |
| UrlFetchApp calls | 20,000/day |
| Cache entry max size | 100 KB |
| Properties max value size | 9 KB |
| Triggers per project | 20 |

Design for these limits: batch Sheets operations, add `Utilities.sleep()` between bulk Drive/Gmail calls, and use CacheService to reduce repeated reads.

### MailApp vs GmailApp for Sending

Use `MailApp.sendEmail()` for sending — it requires the narrower `script.send_mail` scope. `GmailApp.sendEmail()` works but requires full Gmail access. Reserve `GmailApp` for reading, searching, and label management.

### Error Handling & Logging

```typescript
export function withErrorHandling<T>(
  fn: () => T,
  context: string,
): T | undefined {
  try {
    return fn();
  } catch (error) {
    console.error(`[${context}] ${error instanceof Error ? error.message : String(error)}`);
    // console.error logs to Stackdriver (GAS V8 runtime)
    return undefined;
  }
}
```

Use `console.log` / `console.error` — these go to Cloud Logging (Stackdriver) in the V8 runtime. `Logger.log` is legacy and only visible in the script editor.

### UrlFetchApp for External APIs

```typescript
function callExternalApi(endpoint: string, apiKey: string): unknown {
  const options: GoogleAppsScript.URL_Fetch.URLFetchRequestOptions = {
    method: "get",
    headers: { Authorization: `Bearer ${apiKey}` },
    muteHttpExceptions: true, // Don't throw on non-2xx
  };

  const response = UrlFetchApp.fetch(endpoint, options);
  const code = response.getResponseCode();

  if (code !== 200) {
    throw new Error(`API returned ${code}: ${response.getContentText()}`);
  }

  return JSON.parse(response.getContentText());
}
```

Always set `muteHttpExceptions: true` so you can handle errors yourself instead of getting opaque exceptions.

### Retry with Exponential Backoff

External APIs fail transiently. Wrap `UrlFetchApp` calls with retry:

```typescript
function fetchWithRetry(url: string, options: GoogleAppsScript.URL_Fetch.URLFetchRequestOptions, maxRetries = 3): unknown {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const response = UrlFetchApp.fetch(url, { ...options, muteHttpExceptions: true });
      const code = response.getResponseCode();
      if (code >= 200 && code < 300) return JSON.parse(response.getContentText());
      if (code >= 400 && code < 500) throw new Error(`Client error ${code}`);
    } catch (error) {
      if (attempt === maxRetries) throw error;
    }
    Utilities.sleep(Math.pow(2, attempt) * 1000); // 1s, 2s, 4s
  }
  throw new Error("Unreachable");
}
```

### UI Patterns: Menus, Dialogs, and Sidebars

For bound scripts (attached to a Sheet/Doc), add custom menus in `onOpen`:

```typescript
function onOpen(): void {
  SpreadsheetApp.getUi()
    .createMenu("My Tools")
    .addItem("Run Sync", "menuRunSync")
    .addSeparator()
    .addSubMenu(SpreadsheetApp.getUi().createMenu("Settings").addItem("Configure", "menuConfigure"))
    .addToUi();
}
```

Use `SpreadsheetApp.getUi().prompt()` for simple input, `SpreadsheetApp.getUi().alert()` for messages, and `HtmlService.createHtmlOutputFromFile()` for rich dialogs/sidebars. See `references/utilities.md` for details.

### OAuth Scope Management

Minimize scopes in `appsscript.json` to reduce the permission prompt and improve security:

```json
{
  "oauthScopes": [
    "https://www.googleapis.com/auth/spreadsheets.currentonly",
    "https://www.googleapis.com/auth/script.send_mail",
    "https://www.googleapis.com/auth/drive.file"
  ]
}
```

Prefer narrow scopes: `spreadsheets.currentonly` over `spreadsheets`, `drive.file` over `drive`. See `references/utilities.md` for the complete scope reference.

## Google TypeScript Style Highlights

Follow the Google TypeScript Style Guide with these GAS-relevant points:

- **Named exports only** — no `export default`. This avoids ambiguity and helps tree-shaking.
- **`const` and `let`** — never `var`.
- **Use `readonly`** for properties that don't change after initialization.
- **Interfaces over type aliases** for object shapes — they're more extensible.
- **No namespaces** — use ES modules (Rollup handles the bundling).
- **Parameter properties** in constructors — `constructor(private readonly service: IEmailService)`.

## Domain References

For domain-specific GAS patterns (API usage, common pitfalls, deprecated methods), read the appropriate reference file:

- **Gmail**: `references/gmail.md` — GmailApp, MailApp, labels, threads, drafts, sending
- **Sheets**: `references/sheets.md` — SpreadsheetApp, ranges, batch operations, custom functions
- **Calendar**: `references/calendar.md` — CalendarApp, events, recurring events, guests
- **Drive**: `references/drive.md` — DriveApp, file operations, permissions, Advanced Drive Service
- **Docs**: `references/docs.md` — DocumentApp, body operations, tables, images, formatting
- **Forms**: `references/forms.md` — FormApp, responses, linked sheets
- **Slides**: `references/slides.md` — SlidesApp, presentations, shapes, layouts
- **Utilities**: `references/utilities.md` — CacheService, Utilities (encoding/hashing/UUID), OAuth scopes, HtmlService UI, quotas
- **Testing**: `references/testing.md` — Vitest setup, mocking GAS globals, test examples

Read the relevant reference before writing domain-specific code.

## Asset Templates

The `assets/` directory contains TypeScript templates for common patterns. Copy and adapt them into your project:

- **`assets/trigger-manager.ts`** — Reusable trigger setup/teardown with duplicate prevention
- **`assets/spreadsheet-automation.ts`** — Batch spreadsheet processing with DRY_RUN mode, error emails, and log rotation
