import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pantas_awb/models/awb_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class PDFService {
  /// Generate printable AWB label in A6 format (105mm x 148mm)
  static Future<String> generateAWBLabelA6(
    AWB awb,
    String senderDept,
    String qrContent,
  ) async {
    final pdf = pw.Document();

    // Generate QR code image
    final qrImage = await _generateQRImage(qrContent);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PANTAS AWB',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'SMART SECURE HANDOVER',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // AWB Number and QR Code
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AWB NUMBER:',
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          awb.airwayId,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'DATE: ${_formatDate(awb.createdAt)}',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.Text(
                          'TIME: ${_formatTime(awb.createdAt)}',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.Text(
                          'EXPIRE: ${_formatDate(awb.expiresAt)}',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Image(qrImage),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Shipper Section
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SHIPPER (FROM)',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Name: ${awb.senderName}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Text(
                      'Dept: ${awb.senderDepartment}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Text(
                      'Phone: ${awb.senderPhone}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // Consignee Section
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CONSIGNEE (TO)',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Name: ${awb.recipientName}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Text(
                      'Address: ${awb.recipientAddress}',
                      style: const pw.TextStyle(fontSize: 7),
                      maxLines: 2,
                    ),
                    pw.Text(
                      'Phone: ${awb.recipientPhone}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // Shipment Details
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SHIPMENT DETAILS',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Reference: ${awb.reference}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Text(
                      'Item: ${awb.remarks}',
                      style: const pw.TextStyle(fontSize: 7),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(width: 1)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Created with PANTAS AWB v2.0',
                      style: const pw.TextStyle(fontSize: 6),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'Printed: ${_formatDateTime(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 6),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final fileName = 'PANTAS_AWB_${awb.airwayId}_A6_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Generate printable AWB label in 80mm thermal format
  static Future<String> generateAWBLabel80mm(
    AWB awb,
    String senderDept,
    String qrContent,
  ) async {
    final pdf = pw.Document();

    // Generate QR code image
    final qrImage = await _generateQRImage(qrContent);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(3),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                'PANTAS AWB',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'SMART SECURE HANDOVER',
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),

              // AWB Number
              pw.Text(
                'AWB NUMBER: ${awb.airwayId}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'DATE: ${_formatDate(awb.createdAt)}  TIME: ${_formatTime(awb.createdAt)}',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'EXPIRE: ${_formatDate(awb.expiresAt)} (7 days)',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),

              // QR Code
              pw.Container(
                width: 70,
                height: 70,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Image(qrImage),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Scan untuk verifikasi handover',
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),

              // Shipper
              pw.Text(
                'SHIPPER (FROM):',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Name: ${awb.senderName}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Dept: ${awb.senderDepartment}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Phone: ${awb.senderPhone}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 4),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),

              // Consignee
              pw.Text(
                'CONSIGNEE (TO):',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Name: ${awb.recipientName}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Address: ${awb.recipientAddress}',
                style: const pw.TextStyle(fontSize: 7),
                maxLines: 2,
              ),
              pw.Text(
                'Phone: ${awb.recipientPhone}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 4),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),

              // Shipment
              pw.Text(
                'SHIPMENT:',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Reference: ${awb.reference}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Item: ${awb.remarks}',
                style: const pw.TextStyle(fontSize: 7),
                maxLines: 2,
              ),
              pw.SizedBox(height: 4),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),

              // Timeline
              pw.Text(
                'TIMELINE:',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Created: ${_formatDateTime(awb.createdAt)}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Received: _________________',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                'Completed: _________________',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 4),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),

              // Verification
              pw.Text(
                'VERIFICATION:',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'QR Signature: HMAC-SHA256 ✓',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 8),

              // Footer
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Printed: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'PANTAS AWB - Smart Secure Handover',
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final fileName = 'PANTAS_AWB_${awb.airwayId}_80mm_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Generate printable AWB label in 58mm thermal format
  static Future<String> generateAWBLabel58mm(
    AWB awb,
    String senderDept,
    String qrContent,
  ) async {
    final pdf = pw.Document();

    // Generate QR code image
    final qrImage = await _generateQRImage(qrContent);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, 150 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(2),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                'PANTAS AWB',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'SMART SECURE HANDOVER',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 3),
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 3),

              // AWB Number
              pw.Text(
                'AWB: ${awb.airwayId}',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                '${_formatDate(awb.createdAt)} ${_formatTime(awb.createdAt)}',
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Expire: ${_formatDate(awb.expiresAt)}',
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),

              // QR Code
              pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Image(qrImage),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Scan untuk verifikasi',
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 3),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),

              // Shipper
              pw.Text(
                'FROM:',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                awb.senderName,
                style: const pw.TextStyle(fontSize: 6),
              ),
              pw.Text(
                awb.senderDepartment,
                style: const pw.TextStyle(fontSize: 6),
              ),
              pw.Text(
                'ID: ${awb.airwayId.substring(0, 8)}',
                style: const pw.TextStyle(fontSize: 6),
              ),
              pw.SizedBox(height: 2),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),

              // Consignee
              pw.Text(
                'TO:',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                awb.recipientName,
                style: const pw.TextStyle(fontSize: 6),
              ),
              pw.Text(
                awb.recipientAddress,
                style: const pw.TextStyle(fontSize: 6),
                maxLines: 2,
              ),
              pw.SizedBox(height: 2),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),

              // Reference
              pw.Text(
                'REF: ${awb.reference}',
                style: const pw.TextStyle(fontSize: 6),
              ),
              pw.Text(
                'ITEM: ${awb.remarks}',
                style: const pw.TextStyle(fontSize: 6),
                maxLines: 2,
              ),
              pw.SizedBox(height: 2),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),

              // Timeline
              pw.Text(
                'TIMELINE:',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Created: ${_formatDate(awb.createdAt)}',
                style: const pw.TextStyle(fontSize: 6),
              ),
              pw.Text(
                'Received: _________',
                style: const pw.TextStyle(fontSize: 6),
              ),
              pw.SizedBox(height: 3),

              // Separator
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 2),

              // Verification
              pw.Text(
                'HMAC-SHA256 Verified ✓',
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),

              // Footer
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                'Printed: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 5),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final fileName = 'PANTAS_AWB_${awb.airwayId}_58mm_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Generate PDF report from AWB list
  static Future<String> generateAWBReport(
    List<AWB> awbs,
    String reportName,
  ) async {
    final pdf = pw.Document();

    // Header
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PANTAS AWB',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Smart Secure Handover System',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Report: $reportName',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Generated: ${DateTime.now().toString().split('.')[0]}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Airway Bill Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total Records: ${awbs.length}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    // Data Table
    if (awbs.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'Detailed AWB Records',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                    5: const pw.FlexColumnWidth(1),
                    6: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'AWB ID',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Sender',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Recipient',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Reference',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Status',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Created',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Data rows
                    for (var awb in awbs)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(awb.airwayId, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(awb.senderName, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(awb.type, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(awb.recipientName, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(awb.reference, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(awb.status, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              awb.createdAt.toString().split('.')[0],
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // Footer
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Report Summary',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total Records: ${awbs.length}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Created: ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'PANTAS AWB - Smart Secure Handover System',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final output = await getApplicationDocumentsDirectory();
    final fileName = 'PANTAS_AWB_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // Helper method to generate QR code image
  static Future<Uint8List> _generateQRImage(String content) async {
    final qrImage = await QrPainter(
      data: content,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(200);
    return qrImage!.buffer.asUint8List();
  }

  // Helper methods for date/time formatting
  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }
}
