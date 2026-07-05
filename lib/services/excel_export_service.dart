import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

// Conditional imports for platform-specific implementations
// Mobile/Desktop implementation (uses dart:io)
import 'excel_export_service_mobile.dart' if (dart.library.html) 'excel_export_service_web.dart';

// Re-export the platform-specific implementation
export 'excel_export_service_mobile.dart' if (dart.library.html) 'excel_export_service_web.dart';
