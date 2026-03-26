/**
 * Trigger Manager — Reusable trigger setup/teardown with duplicate prevention.
 *
 * Copy this file into your project's src/utils/ directory and adapt as needed.
 * All trigger handler functions must be exported from index.ts to be visible to GAS.
 *
 * Usage:
 *   import { TriggerManager } from "./utils/trigger-manager";
 *   const tm = new TriggerManager();
 *   tm.setupDaily("dailyReport", 9);
 *   tm.setupHourly("hourlySync", 1);
 *   tm.listAll();
 */

// ============================================================================
// Trigger Manager
// ============================================================================

interface TriggerInfo {
  id: string;
  handlerFunction: string;
  source: string;
  eventType: string;
}

export class TriggerManager {
  /**
   * Set up a daily trigger at a specific hour.
   * Removes existing triggers for the same function to prevent duplicates.
   */
  setupDaily(functionName: string, hour: number): void {
    this.deleteForFunction(functionName);
    ScriptApp.newTrigger(functionName)
      .timeBased()
      .atHour(hour)
      .everyDays(1)
      .create();
    console.log(`Daily trigger created: ${functionName} at ${hour}:00`);
  }

  /**
   * Set up an hourly trigger.
   */
  setupHourly(functionName: string, everyNHours: number = 1): void {
    this.deleteForFunction(functionName);
    ScriptApp.newTrigger(functionName)
      .timeBased()
      .everyHours(everyNHours)
      .create();
    console.log(`Hourly trigger created: ${functionName} every ${everyNHours}h`);
  }

  /**
   * Set up a weekly trigger on a specific day and hour.
   */
  setupWeekly(
    functionName: string,
    day: GoogleAppsScript.Script.WeekDay,
    hour: number,
  ): void {
    this.deleteForFunction(functionName);
    ScriptApp.newTrigger(functionName)
      .timeBased()
      .onWeekDay(day)
      .atHour(hour)
      .create();
    console.log(`Weekly trigger created: ${functionName} on ${day} at ${hour}:00`);
  }

  /**
   * Set up a minute-interval trigger.
   * Use sparingly — GAS limits total triggers per project to 20.
   */
  setupMinutely(functionName: string, everyNMinutes: 1 | 5 | 10 | 15 | 30): void {
    this.deleteForFunction(functionName);
    ScriptApp.newTrigger(functionName)
      .timeBased()
      .everyMinutes(everyNMinutes)
      .create();
    console.log(`Minute trigger created: ${functionName} every ${everyNMinutes}min`);
  }

  /**
   * Set up a spreadsheet onEdit trigger (installable — runs with full auth).
   * Only for bound scripts.
   */
  setupOnEdit(functionName: string): void {
    this.deleteForFunction(functionName);
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    ScriptApp.newTrigger(functionName)
      .forSpreadsheet(ss)
      .onEdit()
      .create();
    console.log(`onEdit trigger created: ${functionName}`);
  }

  /**
   * Set up a form submit trigger.
   * Can be attached to a Form or to the linked Spreadsheet.
   */
  setupOnFormSubmit(functionName: string, formId?: string): void {
    this.deleteForFunction(functionName);
    if (formId) {
      const form = FormApp.openById(formId);
      ScriptApp.newTrigger(functionName)
        .forForm(form)
        .onFormSubmit()
        .create();
    } else {
      const ss = SpreadsheetApp.getActiveSpreadsheet();
      ScriptApp.newTrigger(functionName)
        .forSpreadsheet(ss)
        .onFormSubmit()
        .create();
    }
    console.log(`onFormSubmit trigger created: ${functionName}`);
  }

  /**
   * Delete all triggers for a specific handler function.
   * Always call before creating a new trigger to prevent duplicates.
   */
  deleteForFunction(functionName: string): number {
    const triggers = ScriptApp.getProjectTriggers();
    let deleted = 0;
    for (const trigger of triggers) {
      if (trigger.getHandlerFunction() === functionName) {
        ScriptApp.deleteTrigger(trigger);
        deleted++;
      }
    }
    if (deleted > 0) {
      console.log(`Deleted ${deleted} existing trigger(s) for ${functionName}`);
    }
    return deleted;
  }

  /**
   * Delete ALL project triggers. Use with caution.
   */
  deleteAll(): number {
    const triggers = ScriptApp.getProjectTriggers();
    for (const trigger of triggers) {
      ScriptApp.deleteTrigger(trigger);
    }
    console.log(`Deleted ${triggers.length} trigger(s)`);
    return triggers.length;
  }

  /**
   * Check if a trigger already exists for a function.
   */
  exists(functionName: string): boolean {
    return ScriptApp.getProjectTriggers()
      .some(t => t.getHandlerFunction() === functionName);
  }

  /**
   * List all project triggers with details.
   */
  listAll(): TriggerInfo[] {
    const triggers = ScriptApp.getProjectTriggers();
    const info = triggers.map(t => ({
      id: t.getUniqueId(),
      handlerFunction: t.getHandlerFunction(),
      source: String(t.getTriggerSource()),
      eventType: String(t.getEventType()),
    }));

    console.log(`Total triggers: ${info.length}`);
    for (const t of info) {
      console.log(`  ${t.handlerFunction} — ${t.source} (${t.eventType})`);
    }
    return info;
  }
}

// ============================================================================
// Error-Wrapped Trigger Handler Pattern
// ============================================================================

/**
 * Wraps a trigger handler with error handling and optional email notification.
 * Use this to prevent silent trigger failures.
 *
 * Usage in index.ts:
 *   function dailyReport(): void { withTriggerErrorHandling("dailyReport", () => { ... }); }
 */
export function withTriggerErrorHandling(
  context: string,
  fn: () => void,
  notifyOnError: boolean = true,
): void {
  try {
    fn();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const stack = error instanceof Error ? error.stack ?? "" : "";
    console.error(`[${context}] Error: ${message}\n${stack}`);

    if (notifyOnError) {
      try {
        MailApp.sendEmail({
          to: Session.getEffectiveUser().getEmail(),
          subject: `[GAS Error] ${context}`,
          body: `Trigger "${context}" failed.\n\nError: ${message}\n\nStack:\n${stack}`,
        });
      } catch (emailError) {
        console.error(`Could not send error email: ${emailError}`);
      }
    }
  }
}

// ============================================================================
// Example: Initialize All Triggers
// ============================================================================

/**
 * Run once to set up all project triggers.
 * Export this from index.ts and run manually.
 */
export function initializeAllTriggers(): void {
  const tm = new TriggerManager();

  // Customize these for your project:
  // tm.setupDaily("dailyReport", 9);
  // tm.setupHourly("hourlySync", 1);
  // tm.setupWeekly("weeklySummary", ScriptApp.WeekDay.MONDAY, 10);
  // tm.setupOnEdit("onEditHandler");
  // tm.setupOnFormSubmit("onFormSubmitHandler");

  tm.listAll();
}
