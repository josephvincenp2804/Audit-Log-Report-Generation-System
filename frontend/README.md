# Audit Log Report Generation System - Flutter Frontend

An enterprise Material 3 Flutter application for audit trail monitoring, transaction auditing, report generation, and database simulation.

## Features

- **Audit Dashboard**:
  - Live KPI cards: Total activities, INSERTs, UPDATEs, DELETEs.
  - 14-day chronological audit activity distribution chart.
  - Recent audit activities table with direct link to details.
  - Natural-language compliance summary.
- **Audit Log Trail**:
  - Real-time search by username substring.
  - Multi-criteria filtering by action type (INSERT, UPDATE, DELETE) and table name (`employees`, `departments`, `users`).
  - Date range filtering (Start & End dates with quick presets: Today, Last 7 Days, Last 14 Days).
  - Server-side sorting (Timestamp, Audit ID) and pagination.
  - Deep-dive record inspection modal with formatted JSON before/after state diff.
- **Report Generation Screen**:
  - Filter criteria: Date ranges, operation types, usernames.
  - Live summary statistics banner (Total, INSERT, UPDATE, DELETE counts).
  - One-click compliant PDF export with dynamic headers, alternating rows, and `Page X of Y` numbering.
  - Direct CSV download.
- **Database Simulation Console**:
  - Live database transactions (INSERT, UPDATE, DELETE) against SQLite with atomic audit trail generation.
  - Material 3 confirmation dialogs for DELETE operations.
  - Configurable system user attribution.

## Getting Started

1. Get dependencies:
   ```bash
   flutter pub get
   ```

2. Run on Chrome Web:
   ```bash
   flutter run -d chrome
   ```

3. Run on Windows Desktop:
   ```bash
   flutter run -d windows
   ```

4. Run tests:
   ```bash
   flutter test
   ```
