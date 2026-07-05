import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Import dart:html only for web platform
import 'dart:html' as html;

class ExcelExportService {
  static Future<String?> _exportReport(String fileName, String sheetName, List<List<TextCellValue>> data) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[sheetName];

      // Add data
      for (final row in data) {
        sheet.appendRow(row);
      }

      // Auto-fit columns
      for (var i = 0; i < data.first.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[:\s]'), '-');
      final fullFileName = '$fileName\_$timestamp.xlsx';
      final bytes = excel.encode()!;

      // Web: Generate file in memory and trigger download
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fullFileName)
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);

      return fullFileName;
    } catch (e) {
      debugPrint('Error exporting report: $e');
      return null;
    }
  }

  static Future<String?> exportUsersReport() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = snapshot.docs;

      final data = <List<TextCellValue>>[
        // Headers
        [
          TextCellValue('User ID'),
          TextCellValue('Name'),
          TextCellValue('Email'),
          TextCellValue('Username'),
          TextCellValue('Role'),
          TextCellValue('Status'),
          TextCellValue('Approved'),
          TextCellValue('Employee ID'),
          TextCellValue('Phone'),
          TextCellValue('Created At')
        ],
        // Data rows
        for (final doc in users)
          [
            TextCellValue(doc.id),
            TextCellValue(doc.data()['name'] ?? ''),
            TextCellValue(doc.data()['email'] ?? ''),
            TextCellValue(doc.data()['username'] ?? ''),
            TextCellValue(doc.data()['role'] ?? ''),
            TextCellValue(doc.data()['status'] ?? ''),
            TextCellValue(doc.data()['approved'] == true ? 'Yes' : 'No'),
            TextCellValue(doc.data()['employeeId'] ?? ''),
            TextCellValue(doc.data()['phone'] ?? ''),
            TextCellValue((doc.data()['createdAt'] as Timestamp?)?.toDate().toString() ?? '')
          ],
      ];

      return _exportReport('Users_Report', 'Users Report', data);
    } catch (e) {
      debugPrint('Error exporting users report: $e');
      return null;
    }
  }

  static Future<String?> exportAssetsReport() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('assets').get();
      final assets = snapshot.docs;

      final data = <List<TextCellValue>>[
        // Headers
        [
          TextCellValue('Asset ID'),
          TextCellValue('Name'),
          TextCellValue('Code'),
          TextCellValue('Status'),
          TextCellValue('Quantity'),
          TextCellValue('Assigned To'),
          TextCellValue('Created At'),
          TextCellValue('Updated At')
        ],
        // Data rows
        for (final doc in assets)
          [
            TextCellValue(doc.id),
            TextCellValue(doc.data()['name'] ?? ''),
            TextCellValue(doc.data()['code'] ?? ''),
            TextCellValue(doc.data()['status'] ?? ''),
            TextCellValue(doc.data()['quantity']?.toString() ?? '0'),
            TextCellValue(doc.data()['assignedTo'] ?? ''),
            TextCellValue((doc.data()['createdAt'] as Timestamp?)?.toDate().toString() ?? ''),
            TextCellValue((doc.data()['updatedAt'] as Timestamp?)?.toDate().toString() ?? '')
          ],
      ];

      return _exportReport('Assets_Report', 'Assets Report', data);
    } catch (e) {
      debugPrint('Error exporting assets report: $e');
      return null;
    }
  }

  static Future<String?> exportAllocationsReport() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('allocations').get();
      final allocations = snapshot.docs;

      final data = <List<TextCellValue>>[
        // Headers
        [
          TextCellValue('Allocation ID'),
          TextCellValue('Asset ID'),
          TextCellValue('Asset Name'),
          TextCellValue('Asset Code'),
          TextCellValue('Asset Category'),
          TextCellValue('User ID'),
          TextCellValue('Status'),
          TextCellValue('Allocated At')
        ],
        // Data rows
        for (final doc in allocations)
          [
            TextCellValue(doc.id),
            TextCellValue(doc.data()['assetId'] ?? ''),
            TextCellValue(doc.data()['assetName'] ?? ''),
            TextCellValue(doc.data()['assetCode'] ?? ''),
            TextCellValue(doc.data()['assetCategory'] ?? ''),
            TextCellValue(doc.data()['userId'] ?? ''),
            TextCellValue(doc.data()['status'] ?? ''),
            TextCellValue((doc.data()['allocatedAt'] as Timestamp?)?.toDate().toString() ?? '')
          ],
      ];

      return _exportReport('Allocations_Report', 'Allocations Report', data);
    } catch (e) {
      debugPrint('Error exporting allocations report: $e');
      return null;
    }
  }

  static Future<String?> exportAssetRequestsReport() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('assetRequests').get();
      final requests = snapshot.docs;

      final data = <List<TextCellValue>>[
        // Headers
        [
          TextCellValue('Request ID'),
          TextCellValue('Asset ID'),
          TextCellValue('Asset Name'),
          TextCellValue('User ID'),
          TextCellValue('Request Type'),
          TextCellValue('Status'),
          TextCellValue('Remarks'),
          TextCellValue('Category'),
          TextCellValue('Created At')
        ],
        // Data rows
        for (final doc in requests)
          [
            TextCellValue(doc.id),
            TextCellValue(doc.data()['assetId'] ?? ''),
            TextCellValue(doc.data()['assetName'] ?? ''),
            TextCellValue(doc.data()['userId'] ?? ''),
            TextCellValue(doc.data()['requestType'] ?? doc.data()['type'] ?? ''),
            TextCellValue(doc.data()['status'] ?? ''),
            TextCellValue(doc.data()['remarks'] ?? ''),
            TextCellValue(doc.data()['category'] ?? ''),
            TextCellValue((doc.data()['createdAt'] as Timestamp?)?.toDate().toString() ?? '')
          ],
      ];

      return _exportReport('Asset_Requests_Report', 'Asset Requests Report', data);
    } catch (e) {
      debugPrint('Error exporting asset requests report: $e');
      return null;
    }
  }

  static Future<String?> exportMaintenanceReport() async {
    try {
      // Get maintenance requests
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('assetRequests')
          .where('requestType', whereIn: ['maintenance', 'maintenance request'])
          .get();

      // Get assets under maintenance
      final assetsSnapshot = await FirebaseFirestore.instance
          .collection('assets')
          .where('status', whereIn: ['under maintenance', 'maintenance', 'in progress', 'assigned'])
          .get();

      // Sheet 1: Maintenance Requests
      final requestsData = <List<TextCellValue>>[
        // Headers
        [
          TextCellValue('Request ID'),
          TextCellValue('Asset ID'),
          TextCellValue('Asset Name'),
          TextCellValue('User ID'),
          TextCellValue('Status'),
          TextCellValue('Remarks'),
          TextCellValue('Created At')
        ],
        // Data rows
        for (final doc in requestsSnapshot.docs)
          [
            TextCellValue(doc.id),
            TextCellValue(doc.data()['assetId'] ?? ''),
            TextCellValue(doc.data()['assetName'] ?? ''),
            TextCellValue(doc.data()['userId'] ?? ''),
            TextCellValue(doc.data()['status'] ?? ''),
            TextCellValue(doc.data()['remarks'] ?? ''),
            TextCellValue((doc.data()['createdAt'] as Timestamp?)?.toDate().toString() ?? '')
          ],
      ];

      final requestsResult = await _exportReport('Maintenance_Requests', 'Maintenance Requests', requestsData);

      // Sheet 2: Assets Under Maintenance
      final assetsData = <List<TextCellValue>>[
        // Headers
        [
          TextCellValue('Asset ID'),
          TextCellValue('Name'),
          TextCellValue('Code'),
          TextCellValue('Status'),
          TextCellValue('Quantity'),
          TextCellValue('Assigned To'),
          TextCellValue('Updated At')
        ],
        // Data rows
        for (final doc in assetsSnapshot.docs)
          [
            TextCellValue(doc.id),
            TextCellValue(doc.data()['name'] ?? ''),
            TextCellValue(doc.data()['code'] ?? ''),
            TextCellValue(doc.data()['status'] ?? ''),
            TextCellValue(doc.data()['quantity']?.toString() ?? '0'),
            TextCellValue(doc.data()['assignedTo'] ?? ''),
            TextCellValue((doc.data()['updatedAt'] as Timestamp?)?.toDate().toString() ?? '')
          ],
      ];

      final assetsResult = await _exportReport('Assets_Under_Maintenance', 'Assets Under Maintenance', assetsData);

      // Return the last exported file name
      return assetsResult ?? requestsResult;
    } catch (e) {
      debugPrint('Error exporting maintenance report: $e');
      return null;
    }
  }
}