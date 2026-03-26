/**
 * Spreadsheet Automation Template
 *
 * A production-ready template for batch spreadsheet processing with:
 * - DRY_RUN mode for safe preview
 * - Batch read/write for performance
 * - Error handling with email notifications
 * - Execution logging with automatic log rotation
 * - Configurable via a single CONFIG object
 *
 * Copy this into your project's src/services/ directory and adapt.
 */

// ============================================================================
// Configuration
// ============================================================================

export interface AutomationConfig {
  /** Name of the sheet containing source data */
  sourceSheetName: string;
  /** Name of the sheet to write results to */
  outputSheetName: string;
  /** Name of the sheet for execution logs */
  logSheetName: string;
  /** 1-based row number where headers are */
  headerRow: number;
  /** 1-based row number where data starts */
  dataStartRow: number;
  /** Maximum rows to process per execution (safety limit) */
  maxRows: number;
  /** If true, logs actions but doesn't write results */
  dryRun: boolean;
  /** Send email summary on completion */
  sendEmail: boolean;
  /** Maximum log entries to keep before rotating */
  maxLogEntries: number;
}

export const DEFAULT_CONFIG: AutomationConfig = {
  sourceSheetName: "Data",
  outputSheetName: "Report",
  logSheetName: "Automation Log",
  headerRow: 1,
  dataStartRow: 2,
  maxRows: 10_000,
  dryRun: false,
  sendEmail: true,
  maxLogEntries: 1_000,
};

// ============================================================================
// Core Automation
// ============================================================================

export interface ProcessedRow {
  sourceRow: number;
  data: Record<string, unknown>;
  status: "processed" | "skipped" | "error";
  error?: string;
}

/**
 * Main automation entry point.
 * Call this from a trigger handler in index.ts.
 */
export function runAutomation(
  config: AutomationConfig = DEFAULT_CONFIG,
  processRow: (row: unknown[], headers: string[], rowIndex: number) => ProcessedRow,
): void {
  const startTime = Date.now();
  const mode = config.dryRun ? "DRY RUN" : "LIVE";
  console.log(`Starting automation [${mode}]...`);

  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();

    // Read source data in one batch call
    const sourceSheet = ss.getSheetByName(config.sourceSheetName);
    if (!sourceSheet) throw new Error(`Sheet "${config.sourceSheetName}" not found`);

    const lastRow = sourceSheet.getLastRow();
    const lastCol = sourceSheet.getLastColumn();
    if (lastRow < config.dataStartRow) {
      console.log("No data to process");
      return;
    }

    // Batch read — headers + all data in one call
    const allData = sourceSheet.getRange(
      config.headerRow, 1,
      Math.min(lastRow - config.headerRow + 1, config.maxRows + 1),
      lastCol,
    ).getValues();

    const headers = allData[0].map(String);
    const dataRows = allData.slice(config.dataStartRow - config.headerRow);

    // Filter out completely empty rows
    const nonEmptyRows = dataRows.filter(row => row.some(cell => cell !== ""));
    console.log(`Read ${nonEmptyRows.length} rows of data`);

    // Process each row
    const results: ProcessedRow[] = nonEmptyRows.map((row, idx) => {
      try {
        return processRow(row, headers, config.dataStartRow + idx);
      } catch (error) {
        return {
          sourceRow: config.dataStartRow + idx,
          data: {},
          status: "error" as const,
          error: error instanceof Error ? error.message : String(error),
        };
      }
    });

    const processed = results.filter(r => r.status === "processed");
    const skipped = results.filter(r => r.status === "skipped");
    const errors = results.filter(r => r.status === "error");

    // Write results
    if (!config.dryRun && processed.length > 0) {
      writeResults(ss, config, headers, processed);
    }

    // Log execution
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    logExecution(ss, config, {
      mode,
      totalRows: nonEmptyRows.length,
      processed: processed.length,
      skipped: skipped.length,
      errors: errors.length,
      elapsedSeconds: elapsed,
    });

    // Send notification
    if (config.sendEmail) {
      sendSummaryEmail(config, {
        mode,
        totalRows: nonEmptyRows.length,
        processed: processed.length,
        skipped: skipped.length,
        errors: errors.length,
        elapsedSeconds: elapsed,
        errorDetails: errors.slice(0, 5),
      });
    }

    console.log(
      `Automation complete [${mode}]: ${processed.length} processed, ` +
      `${skipped.length} skipped, ${errors.length} errors (${elapsed}s)`,
    );
  } catch (error) {
    handleFatalError(config, error);
  }
}

// ============================================================================
// Output
// ============================================================================

function writeResults(
  ss: GoogleAppsScript.Spreadsheet.Spreadsheet,
  config: AutomationConfig,
  headers: string[],
  results: ProcessedRow[],
): void {
  let outputSheet = ss.getSheetByName(config.outputSheetName);
  if (!outputSheet) {
    outputSheet = ss.insertSheet(config.outputSheetName);
  }

  // Clear and rewrite (atomic pattern)
  outputSheet.clear();

  // Write headers with formatting
  const outputHeaders = [...headers, "Status", "Processed At"];
  outputSheet.getRange(1, 1, 1, outputHeaders.length).setValues([outputHeaders]);
  outputSheet.getRange(1, 1, 1, outputHeaders.length)
    .setFontWeight("bold")
    .setBackground("#4285f4")
    .setFontColor("#ffffff");

  // Batch write all data rows
  const outputData = results.map(r => {
    const row = Object.values(r.data);
    return [...row, r.status, new Date().toISOString()];
  });

  if (outputData.length > 0) {
    outputSheet.getRange(2, 1, outputData.length, outputData[0].length)
      .setValues(outputData);
  }

  // Auto-resize
  for (let col = 1; col <= outputHeaders.length; col++) {
    outputSheet.autoResizeColumn(col);
  }

  console.log(`Wrote ${results.length} rows to "${config.outputSheetName}"`);
}

// ============================================================================
// Logging
// ============================================================================

interface ExecutionLog {
  mode: string;
  totalRows: number;
  processed: number;
  skipped: number;
  errors: number;
  elapsedSeconds: string;
}

function logExecution(
  ss: GoogleAppsScript.Spreadsheet.Spreadsheet,
  config: AutomationConfig,
  log: ExecutionLog,
): void {
  let logSheet = ss.getSheetByName(config.logSheetName);
  if (!logSheet) {
    logSheet = ss.insertSheet(config.logSheetName);
    logSheet.appendRow(["Timestamp", "Mode", "Total", "Processed", "Skipped", "Errors", "Duration"]);
    logSheet.getRange(1, 1, 1, 7).setFontWeight("bold");
  }

  logSheet.appendRow([
    new Date(),
    log.mode,
    log.totalRows,
    log.processed,
    log.skipped,
    log.errors,
    `${log.elapsedSeconds}s`,
  ]);

  // Log rotation — keep only the most recent entries
  const lastRow = logSheet.getLastRow();
  if (lastRow > config.maxLogEntries + 1) { // +1 for header
    const rowsToDelete = lastRow - config.maxLogEntries - 1;
    logSheet.deleteRows(2, rowsToDelete);
    console.log(`Rotated log: deleted ${rowsToDelete} old entries`);
  }
}

// ============================================================================
// Notifications
// ============================================================================

interface SummaryData extends ExecutionLog {
  errorDetails: ProcessedRow[];
}

function sendSummaryEmail(config: AutomationConfig, summary: SummaryData): void {
  const errorSection = summary.errorDetails.length > 0
    ? `\n\nErrors (first ${summary.errorDetails.length}):\n` +
      summary.errorDetails.map(e => `  Row ${e.sourceRow}: ${e.error}`).join("\n")
    : "";

  const body = [
    `Spreadsheet Automation Summary`,
    `==============================`,
    ``,
    `Mode: ${summary.mode}`,
    `Timestamp: ${new Date().toISOString()}`,
    `Duration: ${summary.elapsedSeconds}s`,
    ``,
    `Total rows: ${summary.totalRows}`,
    `Processed:  ${summary.processed}`,
    `Skipped:    ${summary.skipped}`,
    `Errors:     ${summary.errors}`,
    errorSection,
  ].join("\n");

  try {
    MailApp.sendEmail({
      to: Session.getEffectiveUser().getEmail(),
      subject: `[Automation] ${summary.mode} — ${summary.processed} processed, ${summary.errors} errors`,
      body,
    });
  } catch (error) {
    console.error(`Could not send summary email: ${error}`);
  }
}

// ============================================================================
// Error Handling
// ============================================================================

function handleFatalError(config: AutomationConfig, error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  const stack = error instanceof Error ? error.stack ?? "" : "";

  console.error(`FATAL: ${message}\n${stack}`);

  // Try to log to sheet
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let logSheet = ss.getSheetByName(config.logSheetName);
    if (!logSheet) logSheet = ss.insertSheet(config.logSheetName);
    logSheet.appendRow([new Date(), "FATAL ERROR", 0, 0, 0, 1, message]);
  } catch (logError) {
    console.error(`Could not log error to sheet: ${logError}`);
  }

  // Try to send error email
  if (config.sendEmail) {
    try {
      MailApp.sendEmail({
        to: Session.getEffectiveUser().getEmail(),
        subject: `[Automation] FATAL ERROR`,
        body: `Fatal error in spreadsheet automation:\n\n${message}\n\nStack:\n${stack}`,
      });
    } catch (emailError) {
      console.error(`Could not send error email: ${emailError}`);
    }
  }

  throw error; // Re-throw so GAS logs it
}

// ============================================================================
// Example Usage
// ============================================================================

/**
 * Example: Process a "Sales Data" sheet.
 * Export this from index.ts and attach to a daily trigger.
 *
 * function dailySalesReport(): void {
 *   runAutomation(
 *     { ...DEFAULT_CONFIG, sourceSheetName: "Sales Data", outputSheetName: "Sales Report" },
 *     (row, headers, rowIndex) => {
 *       const revenue = Number(row[1]) || 0;
 *       const cost = Number(row[2]) || 0;
 *       if (revenue === 0) return { sourceRow: rowIndex, data: {}, status: "skipped" };
 *       return {
 *         sourceRow: rowIndex,
 *         data: { product: row[0], revenue, cost, margin: ((revenue - cost) / revenue * 100).toFixed(1) + "%" },
 *         status: "processed",
 *       };
 *     },
 *   );
 * }
 */
