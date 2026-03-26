# Calendar — GAS TypeScript Reference

## Table of Contents

1. Core APIs
2. Creating and Modifying Events
3. Recurring Events
4. Guest Management
5. Calendar Sync Patterns
6. Common Pitfalls

## 1. Core APIs

Primary service: `CalendarApp`. Types under `GoogleAppsScript.Calendar`.

```typescript
const defaultCal = CalendarApp.getDefaultCalendar();
const namedCal = CalendarApp.getCalendarById("calendar_id@group.calendar.google.com");
const ownedCals = CalendarApp.getAllOwnedCalendars();
```

For advanced features (free/busy queries, ACL management, watching for changes), enable the Advanced Calendar Service:

```json
{
  "dependencies": {
    "enabledAdvancedServices": [
      { "userSymbol": "Calendar", "serviceId": "calendar", "version": "v3" }
    ]
  }
}
```

## 2. Creating and Modifying Events

```typescript
// Simple event
const event = defaultCal.createEvent(
  "Team Standup",
  new Date("2025-03-25T09:00:00"),
  new Date("2025-03-25T09:30:00"),
  {
    description: "Daily sync",
    location: "Conference Room B",
    guests: "team@company.com",
    sendInvites: true,
  }
);

// All-day event
const allDay = defaultCal.createAllDayEvent(
  "Company Holiday",
  new Date("2025-12-25"),
);

// Modify existing
event.setTitle("Updated Standup");
event.setTime(
  new Date("2025-03-25T09:30:00"),
  new Date("2025-03-25T10:00:00"),
);
event.setColor(CalendarApp.EventColor.BANANA);
```

## 3. Recurring Events

```typescript
// Weekly recurring event
const recurrence = CalendarApp.newRecurrence()
  .addWeeklyRule()
  .onlyOnWeekdays([CalendarApp.Weekday.MONDAY, CalendarApp.Weekday.WEDNESDAY])
  .until(new Date("2025-12-31"));

const series = defaultCal.createEventSeries(
  "Recurring Sync",
  new Date("2025-04-01T14:00:00"),
  new Date("2025-04-01T14:30:00"),
  recurrence,
);
```

**Modifying one instance**: Use `event.getEventSeries()` to get the series, but modify individual occurrences via the event object returned from `getEvents()`.

## 4. Guest Management

```typescript
const event = defaultCal.getEventById("event_id");
if (event) {
  event.addGuest("new@example.com");
  event.removeGuest("old@example.com");

  const guests = event.getGuestList(true); // true = include owner
  for (const guest of guests) {
    const status = guest.getGuestStatus();
    // CalendarApp.GuestStatus: YES, NO, MAYBE, INVITED, OWNER
    console.log(`${guest.getEmail()}: ${status}`);
  }
}
```

## 5. Calendar Sync Patterns

Common pattern: sync calendar events to a spreadsheet or external system.

```typescript
function syncEventsToSheet(
  calendarId: string,
  sheetName: string,
  daysAhead: number,
): void {
  const cal = CalendarApp.getCalendarById(calendarId);
  if (!cal) throw new Error(`Calendar not found: ${calendarId}`);

  const now = new Date();
  const future = new Date(now.getTime() + daysAhead * 24 * 60 * 60 * 1000);
  const events = cal.getEvents(now, future);

  const rows = events.map(e => [
    e.getTitle(),
    e.getStartTime(),
    e.getEndTime(),
    e.getLocation(),
    e.getDescription(),
    e.getId(),
  ]);

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);
  if (!sheet) throw new Error(`Sheet not found: ${sheetName}`);

  // Clear and rewrite
  sheet.getDataRange().clearContent();
  sheet.appendRow(["Title", "Start", "End", "Location", "Description", "ID"]);
  if (rows.length > 0) {
    sheet.getRange(2, 1, rows.length, rows[0].length).setValues(rows);
  }
}
```

## 6. Common Pitfalls

- **Timezone handling**: `CalendarApp` uses the calendar's timezone, not the script's. Use `event.getStartTime().toISOString()` for unambiguous timestamps, or `Utilities.formatDate()` with an explicit timezone string.
- **getEvents() limits**: For calendars with many events, `getEvents()` over a large date range can be slow. Narrow the window and paginate with the Advanced Service if needed.
- **Event IDs**: GAS event IDs are not the same as Google Calendar API event IDs. If you need interop, use the Advanced Calendar Service which returns standard RFC-format IDs.
- **sendInvites default**: `createEvent` with guests does NOT send invites by default. Pass `sendInvites: true` explicitly.
