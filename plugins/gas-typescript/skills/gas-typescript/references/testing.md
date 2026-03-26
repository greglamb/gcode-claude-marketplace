# Testing — GAS TypeScript Reference

## Table of Contents

1. Test Setup with Vitest
2. Mocking GAS Globals
3. Writing Testable Services
4. What to Test vs. Skip

## 1. Test Setup with Vitest

### vitest.config.ts

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    setupFiles: ["./test/setup.ts"],
    globals: true,
  },
});
```

### test/setup.ts

Provide minimal GAS global stubs so type-checking passes. Real behavior comes from per-test mocks.

```typescript
import { vi } from "vitest";

globalThis.Logger = {
  log: vi.fn(),
  getLog: vi.fn().mockReturnValue(""),
  clear: vi.fn(),
} as unknown as GoogleAppsScript.Base.Logger;

globalThis.Utilities = {
  formatDate: vi.fn((date: Date, tz: string, fmt: string) => date.toISOString()),
  sleep: vi.fn(),
} as unknown as GoogleAppsScript.Utilities.Utilities;

// Add stubs for other GAS globals as needed:
// globalThis.PropertiesService = { ... }
// globalThis.SpreadsheetApp = { ... }
```

## 2. Mocking GAS Globals

GAS globals don't exist in Node.js. The core strategy is dependency injection: your services accept interfaces, not raw GAS globals. Tests provide mock implementations.

For services that must reference GAS globals directly (e.g., `PropertiesService` in a continuation pattern), stub them in `test/setup.ts` or per-test.

```typescript
import { vi, beforeEach } from "vitest";

// Per-test mock for PropertiesService
beforeEach(() => {
  const store: Record<string, string> = {};
  globalThis.PropertiesService = {
    getScriptProperties: () => ({
      getProperty: vi.fn((key: string) => store[key] ?? null),
      setProperty: vi.fn((key: string, value: string) => { store[key] = value; }),
      deleteProperty: vi.fn((key: string) => { delete store[key]; }),
    }),
  } as unknown as GoogleAppsScript.Properties.PropertiesService;
});
```

## 3. Writing Testable Services

Because services accept interfaces (not raw GAS globals), testing is straightforward:

```typescript
// test/services/gmail.service.test.ts
import { describe, it, expect, vi } from "vitest";
import { processUnread } from "../../src/services/gmail.service";
import type { IEmailService } from "../../src/models/types";

describe("processUnread", () => {
  it("marks all unread threads as read", () => {
    const mockThread = { markRead: vi.fn() };
    const mockService: IEmailService = {
      getUnreadThreads: vi.fn().mockReturnValue([mockThread, mockThread]),
      markAsRead: vi.fn(),
    };

    processUnread(mockService);

    expect(mockService.getUnreadThreads).toHaveBeenCalledWith("is:unread");
    expect(mockService.markAsRead).toHaveBeenCalledTimes(2);
  });

  it("handles empty inbox gracefully", () => {
    const mockService: IEmailService = {
      getUnreadThreads: vi.fn().mockReturnValue([]),
      markAsRead: vi.fn(),
    };

    processUnread(mockService);

    expect(mockService.markAsRead).not.toHaveBeenCalled();
  });
});
```

## 4. What to Test vs. Skip

**Test**: Business logic, data transformations, config parsing, rule engines, orchestration, error handling paths, continuation/cursor logic.

**Skip**: Direct GAS API calls (e.g., "does `GmailApp.search` work?"). Those are Google's responsibility. Your interfaces and mocks handle the boundary.

**Coverage target**: Aim for ≥75% unit test coverage on service files. `index.ts` (the GAS entry point with thin wrappers) typically doesn't need unit tests — it's integration-tested by running in GAS.
