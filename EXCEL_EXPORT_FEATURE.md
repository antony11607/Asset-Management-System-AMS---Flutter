# Excel Export Feature

## Overview
The Admin Reports page now includes functionality to export various reports as Excel files (.xlsx).

## Implementation Details

### Service Layer
**File:** `lib/services/excel_export_service.dart`

The `ExcelExportService` class provides static methods for exporting different types of reports:

1. **exportUsersReport()** - Exports all users from the 'users' collection
2. **exportAssetsReport()** - Exports all assets from the 'assets' collection
3. **exportAllocationsReport()** - Exports all allocations from the 'allocations' collection
4. **exportAssetRequestsReport()** - Exports all asset requests from the 'assetRequests' collection
5. **exportMaintenanceReport()** - Exports maintenance requests and assets under maintenance (multi-sheet report)

### UI Integration
**File:** `lib/pages/admin_pages.dart`

The `AdminReportsPage` now includes download buttons for each report tile:
- Monthly Asset Allocation
- Registration Review
- Maintenance Summary
- Available Assets
- Total Asset Requests

Each report tile has a download icon button that triggers the corresponding export function.

### File Storage
- Files are saved with timestamps in the format: `ReportName_YYYY-MM-DD-HH-MM-SS.xlsx`
- On Android, files are saved to the Downloads folder (or app documents directory as fallback)
- On iOS and other platforms, files are saved to the app documents directory

### Permissions
- Android: Requires storage permission (requested automatically)
- iOS: No additional permissions required

## Usage

1. Navigate to Admin Dashboard → Reports tab
2. Click the download icon (↓) on any report tile
3. Wait for the export to complete
4. A success message will show the file path where the report was saved
5. Open the Excel file to view the report data

## Report Formats

### Users Report
- User ID, Name, Email, Username, Role, Status, Approved, Employee ID, Phone, Created At

### Assets Report
- Asset ID, Name, Code, Status, Quantity, Assigned To, Created At, Updated At

### Allocations Report
- Allocation ID, Asset ID, Asset Name, Asset Code, Asset Category, User ID, Status, Allocated At

### Asset Requests Report
- Request ID, Asset ID, Asset Name, User ID, Request Type, Status, Remarks, Category, Created At

### Maintenance Report (Multi-Sheet)
- Sheet 1: Maintenance Requests (Request ID, Asset ID, Asset Name, User ID, Status, Remarks, Created At)
- Sheet 2: Assets Under Maintenance (Asset ID, Name, Code, Status, Quantity, Assigned To, Updated At)

## Dependencies
- excel: ^4.0.3
- path_provider: ^2.1.4
- permission_handler: ^11.3.1

## Error Handling
- Storage permission denied: Shows error message
- Failed to get download directory: Shows error message
- Export errors: Caught and displayed in SnackBar
- File write errors: Caught and logged

## Notes
- All exports use TextCellValue for proper string handling in Excel
- Column widths are auto-set to 20 characters for better readability
- Timestamps in filenames ensure unique filenames for each export