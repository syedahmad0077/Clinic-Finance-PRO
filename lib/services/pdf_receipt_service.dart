import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/patient_receipt_model.dart';
import 'package:clinic_finance_pro/models/clinic_token_model.dart';

class PdfReceiptService {
  /// Generate A4 PDF containing Single 1/4th Quadrant Receipt (Top-Left 1/4th used, remaining 3/4th 100% Blank for Paper Reuse)
  static Future<Uint8List> generate4upA4LabReceiptPdf(
      PatientReceiptModel receipt) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // TOP HALF: Top-Left 1/4th contains Single Receipt, Top-Right is Blank
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Expanded(
                      child: _buildQuadrantReceipt(receipt, copyTitle: ''),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.SizedBox(), // Top-Right 1/4th Blank
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              // BOTTOM HALF: Bottom 2/4ths completely BLANK for full paper reuse
              pw.Expanded(
                child: pw.SizedBox(),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Single compact quadrant receipt widget (A6 quadrant size)
  static pw.Widget _buildQuadrantReceipt(PatientReceiptModel receipt,
      {String copyTitle = ''}) {
    final formattedDate =
        DateFormat('dd-MMM-yyyy hh:mm a').format(receipt.createdAt);
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Clinic Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'SYED SADIQ LAB$copyTitle',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal900,
                  ),
                ),
                pw.Text(
                  'Muhallah Doake, G.T. Road, Muridke | Ph: +92 300 4915255',
                  style: pw.TextStyle(fontSize: 6.5, color: PdfColors.teal900, fontWeight: pw.FontWeight.bold),
                ),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 2),
                  height: 0.5,
                  color: PdfColors.teal800,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 2),

          // Patient & Date Info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Pt. Name: ${receipt.patientName}',
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Date: $formattedDate',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Text(
                'Age/Gender: ${receipt.age} Yrs / ${receipt.gender}',
                style: const pw.TextStyle(fontSize: 6.5),
              ),
              pw.Spacer(),
              pw.Text(
                'Contact: ${receipt.contact.isNotEmpty ? receipt.contact : "N/A"}',
                style: const pw.TextStyle(fontSize: 6.5),
              ),
            ],
          ),
          pw.SizedBox(height: 4),

          // Tests Table Header
          pw.Container(
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TEST DESCRIPTION',
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                pw.Text('PRICE (PKR)',
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),

          // Tests List
          pw.Expanded(
            child: pw.ListView.builder(
              itemCount: receipt.tests.length,
              itemBuilder: (context, index) {
                final test = receipt.tests[index];
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${index + 1}. ${test.name}',
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                      pw.Text(
                        currencyFormat.format(test.price),
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),

          // Financial Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Fee: PKR ${currencyFormat.format(receipt.totalFee)}',
                      style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text('Amount Paid: PKR ${currencyFormat.format(receipt.amountPaid)}',
                      style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Dues / Balance: PKR ${currencyFormat.format(receipt.remainingBalance)}',
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                      color: receipt.remainingBalance > 0
                          ? PdfColors.red800
                          : PdfColors.green800,
                    ),
                  ),
                ],
              ),
              // Signature Box
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: 70,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.black)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Sign: ${receipt.user?.name ?? "Muzaffar (Lab)"}',
                        style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Print or Direct Preview Lab Receipt PDF
  static Future<void> print4upA4LabReceipt(PatientReceiptModel receipt) async {
    final pdfBytes = await generate4upA4LabReceiptPdf(receipt);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Lab_Receipt_${receipt.patientName}.pdf',
    );
  }

  /// Generate Compact Clinic Token Slip PDF (Matching Hospital Parachi Format)
  static Future<Uint8List> generateClinicTokenPdf(ClinicTokenModel token) async {
    final pdf = pw.Document();
    final formattedDate =
        DateFormat('dd-MMM-yy hh:mm a').format(token.createdAt);
    final receptionistName = token.user?.name ?? 'Reception';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Top Title
              pw.Text(
                'Token No: ${token.tokenNumber}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),

              // Clinic Header Pill Container (Matching Official Report Header)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1.2),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SYED SADIQ POLY CLINIC',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Muhallah Doake, G.T. Road, Muridke (Syed Sadiq Ali Shah Road)',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'Ph: +92 300 4915255',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Barcode & QR Code Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: token.tokenCode,
                    height: 22,
                    width: 120,
                    drawText: false,
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: '${token.tokenCode} | SYED SADIQ POLY CLINIC | ${token.patientName} | Token #${token.tokenNumber}',
                    height: 38,
                    width: 38,
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Patient Information Block
              pw.Text(
                token.patientName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                '${token.age > 0 ? "${token.age} Years" : "Adult"} / ${token.gender}',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                textAlign: pw.TextAlign.center,
              ),
              if (token.contact.isNotEmpty && token.contact.toLowerCase() != 'null')
                pw.Text(
                  'Mobile: ${token.contact}',
                  style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                  textAlign: pw.TextAlign.center,
                ),
              pw.Text(
                'Syed Sadiq Clinic',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                formattedDate,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1.2, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Doctor Header line: e.g. Dr. Kashif Bashir (1)
              pw.Text(
                '${token.doctorName} (${token.tokenNumber})',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),

              // GIANT BOLD CENTER TOKEN NUMBER: e.g. 1
              pw.Text(
                '${token.tokenNumber}',
                style: pw.TextStyle(
                  fontSize: 48,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),

              // Doctor Details
              pw.Text(
                '${token.doctorName} (${token.tokenNumber})',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                token.doctorSpecialization,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '(Clinic Patient)',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                token.patientType,
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),

              // Amount Paid
              pw.Text(
                'Amount Paid = ${token.consultationFee.toInt()} /-',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1.2, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Bottom Barcode & Footer
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: token.tokenCode,
                height: 22,
                width: 140,
                drawText: false,
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    formattedDate,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '( $receptionistName Reception )',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print Clinic Token Slip
  static Future<void> printClinicToken(ClinicTokenModel token) async {
    final pdfBytes = await generateClinicTokenPdf(token);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Token_Slip_${token.tokenNumber}.pdf',
    );
  }
}
