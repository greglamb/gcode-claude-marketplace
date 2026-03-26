# Gmail — GAS TypeScript Reference

## Table of Contents

1. Core APIs
2. MailApp vs GmailApp for Sending
3. Thread vs Message Model
4. Label Management
5. Search Queries
6. Drafts and Sending
7. Common Pitfalls
8. Deprecated APIs to Avoid

## 1. Core APIs

The primary service is `GmailApp`. For advanced features (batch modify, history sync), enable the Advanced Gmail Service (`Gmail` namespace) via `appsscript.json`:

```json
{
  "dependencies": {
    "enabledAdvancedServices": [
      { "userSymbol": "Gmail", "serviceId": "gmail", "version": "v1" }
    ]
  }
}
```

Type: `GoogleAppsScript.Gmail.GmailApp` for built-in, `GoogleAppsScript.Gmail` for the advanced service.

## 2. MailApp vs GmailApp for Sending

**Use `MailApp` for sending email.** It requires only the `script.send_mail` scope — much narrower than `GmailApp`'s full Gmail access. Reserve `GmailApp` for reading, searching, and label management.

```typescript
// PREFERRED — narrow scope
MailApp.sendEmail({
  to: "recipient@example.com",
  subject: "Report Ready",
  body: "Plain text body",
  htmlBody: "<h1>Report Ready</h1><p>See attached.</p>",
  attachments: [pdfBlob],
  name: "Automation Bot",
  replyTo: "noreply@example.com",
});

// Check remaining daily quota
const remaining = MailApp.getRemainingDailyQuota();
console.log(`Emails remaining today: ${remaining}`);
```

`GmailApp.sendEmail()` works identically but triggers the broader `gmail.modify` scope prompt, which users may reject. Only use it when you also need Gmail read/search functionality in the same script.

## 2. Thread vs Message Model

GAS models Gmail as **threads** containing **messages**. Most operations work at the thread level.

```typescript
// Get threads, then iterate messages
const threads = GmailApp.search("is:unread", 0, 50);
for (const thread of threads) {
  const messages = thread.getMessages();
  for (const msg of messages) {
    const subject = msg.getSubject();
    const from = msg.getFrom();
    const body = msg.getPlainBody(); // prefer over getBody() for processing
  }
}
```

**Batch read optimization**: `GmailApp.getMessagesForThreads(threads)` fetches all messages for multiple threads in one call, significantly reducing execution time.

```typescript
const threads = GmailApp.search("label:process-me", 0, 100);
const allMessages = GmailApp.getMessagesForThreads(threads);
// allMessages[i] corresponds to threads[i]
```

## 3. Label Management

```typescript
// Get or create a label
function getOrCreateLabel(name: string): GoogleAppsScript.Gmail.GmailLabel {
  let label = GmailApp.getUserLabelByName(name);
  if (!label) {
    label = GmailApp.createLabel(name);
  }
  return label;
}

// Apply label to threads
const label = getOrCreateLabel("Processed");
const threads = GmailApp.search("from:noreply@example.com");
for (const thread of threads) {
  label.addToThread(thread);
}
```

**Nested labels**: Use `/` separator — `GmailApp.createLabel("Parent/Child")`.

## 4. Search Queries

GmailApp.search uses the same query syntax as the Gmail search bar:

| Query | Purpose |
|-------|---------|
| `is:unread` | Unread messages |
| `from:user@example.com` | From specific sender |
| `newer_than:1d` | Within last day |
| `has:attachment filename:pdf` | PDFs attached |
| `label:my-label -label:processed` | Has label, not processed |
| `in:inbox category:primary` | Primary inbox only |

Always paginate with the `start` and `max` parameters:
```typescript
GmailApp.search("is:unread", 0, 100); // start=0, max=100
```

Maximum `max` is 500. For larger sets, loop with incrementing `start`.

## 5. Drafts and Sending

```typescript
// Send email
GmailApp.sendEmail(
  "recipient@example.com",
  "Subject line",
  "Plain text body",
  {
    htmlBody: "<h1>HTML body</h1>",
    attachments: [blob],
    name: "Sender Display Name",
    replyTo: "reply@example.com",
    cc: "cc@example.com",
  }
);

// Create draft
GmailApp.createDraft(
  "recipient@example.com",
  "Draft Subject",
  "Draft body",
  { htmlBody: "<p>HTML draft</p>" }
);
```

**Daily send limits**: Free accounts: 100/day. Google Workspace: 1,500/day. Plan for this.

## 6. Common Pitfalls

- **Quota exhaustion**: `GmailApp.search` counts against read quota. Cache results; don't call in loops.
- **Thread mutation during iteration**: Modifying threads (moving, labeling) while iterating can cause skips. Collect thread IDs first, then mutate.
- **getBody() vs getPlainBody()**: `getBody()` returns HTML. For text processing, use `getPlainBody()`.
- **Attachments**: `message.getAttachments()` can be slow for large attachments. Use `{includeAttachments: false}` in advanced service if you only need metadata.

## 7. Deprecated APIs to Avoid

| Deprecated | Use Instead |
|-----------|-------------|
| `GmailApp.getStarredThreads()` | `GmailApp.search("is:starred")` |
| `GmailApp.getInboxThreads()` | `GmailApp.search("in:inbox")` |
| `GmailApp.getPriorityInboxThreads()` | `GmailApp.search("is:important")` |

These legacy methods have pagination issues and may not return consistent results. Always prefer `search()` with appropriate queries.
