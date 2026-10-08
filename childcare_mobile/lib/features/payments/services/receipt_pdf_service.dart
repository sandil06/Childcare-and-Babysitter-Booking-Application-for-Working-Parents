import 'dart:io';

class ReceiptPdfService {
  static final ReceiptPdfService _instance = ReceiptPdfService._internal();
  factory ReceiptPdfService() => _instance;
  ReceiptPdfService._internal();

  /// Generates a compliant PDF-1.4 file and writes it to device storage.
  /// Returns the absolute path of the generated PDF file.
  Future<String> downloadReceiptPdf({
    required String receiptNo,
    required String transactionId,
    required String bookingId,
    required String parentName,
    required String babysitterName,
    required String date,
    required String timeRange,
    required String duration,
    required String hourlyRate,
    required String subtotal,
    required String serviceFee,
    required String totalAmount,
    required String paymentStatus,
    required String provider,
  }) async {
    final pdfContent = _buildPdfDocument(
      receiptNo: receiptNo,
      transactionId: transactionId,
      bookingId: bookingId,
      parentName: parentName,
      babysitterName: babysitterName,
      date: date,
      timeRange: timeRange,
      duration: duration,
      hourlyRate: hourlyRate,
      subtotal: subtotal,
      serviceFee: serviceFee,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus,
      provider: provider,
    );

    final dir = await _resolveStorageDirectory();
    final cleanReceiptId = receiptNo.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = 'LittleHands_Receipt_$cleanReceiptId.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(pdfContent, flush: true);
    return file.path;
  }

  Future<Directory> _resolveStorageDirectory() async {
    // 1. Android external Downloads folder
    if (Platform.isAndroid) {
      try {
        final d1 = Directory('/storage/emulated/0/Download');
        if (await d1.exists()) return d1;
        final d2 = Directory('/sdcard/Download');
        if (await d2.exists()) return d2;
      } catch (_) {}
    }

    // 2. Desktop user Downloads folder
    try {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        final d = Directory('$home/Downloads');
        if (await d.exists()) return d;
      }
    } catch (_) {}

    // 3. System temp directory fallback
    return Directory.systemTemp;
  }

  String _buildPdfDocument({
    required String receiptNo,
    required String transactionId,
    required String bookingId,
    required String parentName,
    required String babysitterName,
    required String date,
    required String timeRange,
    required String duration,
    required String hourlyRate,
    required String subtotal,
    required String serviceFee,
    required String totalAmount,
    required String paymentStatus,
    required String provider,
  }) {
    final buffer = StringBuffer();
    // Begin text stream
    buffer.writeln('BT');

    // Header: LittleHands Childcare
    buffer.writeln('/F2 22 Tf');
    buffer.writeln('50 780 Td');
    buffer.writeln('(LittleHands Childcare) Tj');
    buffer.writeln('/F1 10 Tf');
    buffer.writeln('0 -18 Td');
    buffer.writeln('(Official Payment Receipt & Escrow Guarantee) Tj');

    // Teal Divider Line
    buffer.writeln('ET');
    buffer.writeln('0.0 0.36 0.38 rg'); // LittleHands teal (#005B60)
    buffer.writeln('50 748 495 2.5 re f');
    buffer.writeln('0 0 0 rg'); // Reset to black
    buffer.writeln('BT');

    // Status Banner
    buffer.writeln('/F2 13 Tf');
    buffer.writeln('50 716 Td');
    buffer.writeln('(PAYMENT STATUS: ${paymentStatus.toUpperCase()}) Tj');

    // Metadata lines
    buffer.writeln('/F1 10 Tf');
    buffer.writeln('0 -22 Td');
    buffer.writeln('(Receipt Number: $receiptNo) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Transaction ID: $transactionId) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Booking Reference: $bookingId) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Payment Provider: $provider) Tj');
    buffer.writeln('0 -24 Td');

    // Section 1: Caregiver & Schedule Details
    buffer.writeln('/F2 12 Tf');
    buffer.writeln('(Booking Details) Tj');
    buffer.writeln('/F1 10 Tf');
    buffer.writeln('0 -18 Td');
    buffer.writeln('(Parent: $parentName) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Babysitter: $babysitterName) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Care Date: $date) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Time Window: $timeRange) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Duration: $duration) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Hourly Rate: $hourlyRate) Tj');
    buffer.writeln('0 -24 Td');

    // Section 2: Financial Breakdown
    buffer.writeln('/F2 12 Tf');
    buffer.writeln('(Financial Breakdown) Tj');
    buffer.writeln('/F1 10 Tf');
    buffer.writeln('0 -18 Td');
    buffer.writeln('(Subtotal: $subtotal) Tj');
    buffer.writeln('0 -16 Td');
    buffer.writeln('(Platform Service Fee: $serviceFee) Tj');
    buffer.writeln('0 -22 Td');

    // Total Amount Highlight
    buffer.writeln('/F2 16 Tf');
    buffer.writeln('(Total Amount Paid: $totalAmount) Tj');
    buffer.writeln('0 -26 Td');

    // Trust Guarantee & Footer
    buffer.writeln('/F1 9 Tf');
    buffer.writeln('(Verified by LittleHands Escrow Protection.) Tj');
    buffer.writeln('0 -14 Td');
    buffer.writeln('(Funds are held in escrow until care session completion.) Tj');
    buffer.writeln('0 -14 Td');
    buffer.writeln('(Issued on: ${DateTime.now().toUtc().toIso8601String().split('T').first}) Tj');
    buffer.writeln('ET');

    final streamContent = buffer.toString();
    final streamLength = streamContent.length;

    final objects = <String>[];
    objects.add('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    objects.add('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
    objects.add('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>\nendobj\n');
    objects.add('4 0 obj\n<< /Length $streamLength >>\nstream\n$streamContent\nendstream\nendobj\n');
    objects.add('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');
    objects.add('6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n');

    final pdf = StringBuffer();
    pdf.writeln('%PDF-1.4');
    final offsets = <int>[];
    int currentOffset = pdf.toString().length;

    for (final obj in objects) {
      offsets.add(currentOffset);
      pdf.write(obj);
      currentOffset += obj.length;
    }

    final startXref = currentOffset;
    pdf.writeln('xref');
    pdf.writeln('0 ${objects.length + 1}');
    pdf.writeln('0000000000 65535 f ');
    for (final offset in offsets) {
      pdf.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    pdf.writeln('trailer');
    pdf.writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>');
    pdf.writeln('startxref');
    pdf.writeln('$startXref');
    pdf.writeln('%%EOF');

    return pdf.toString();
  }
}
