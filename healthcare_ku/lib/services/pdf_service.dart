import 'dart:typed_data';
import 'package:healthcare_ku/models/medical_record_model.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class PDFService {
  Future<Uint8List> generatePDF(MedicalRecord record) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a page to the document
    final PdfPage page = document.pages.add();

    // Get page client size
    final Size pageSize =
        Size(page.getClientSize().width, page.getClientSize().height);
    final PdfGraphics graphics = page.graphics;
    double yPosition = 0.0;
    const double margin = 40;

    // Function to add text
    void addText(
      String text, {
      double fontSize = 12,
      bool isBold = false,
      double? y,
    }) {
      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        fontSize,
        style: isBold ? PdfFontStyle.bold : PdfFontStyle.regular,
      );

      graphics.drawString(
        text,
        font,
        bounds: Rect.fromLTWH(
          margin,
          y ?? yPosition,
          pageSize.width - (margin * 2),
          50,
        ),
      );

      if (y == null) {
        yPosition += fontSize + 8;
      }
    }

    // Add title
    addText('Medical Record', fontSize: 24, isBold: true);
    yPosition += 20;

    // Add line separator
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      Offset(margin, yPosition),
      Offset(pageSize.width - margin, yPosition),
    );
    yPosition += 20;

    // Basic Information
    addText('Date: ${DateFormat('yyyy-MM-dd').format(record.dateCreated)}');
    addText('Patient ID: ${record.patientId}');
    addText('Doctor ID: ${record.doctorId}');
    yPosition += 10;

    // Clinical Information
    addText('Clinical Information', fontSize: 14, isBold: true);
    addText('Diagnosis: ${record.diagnosis}');
    addText('Symptoms: ${record.symptoms}');
    if (record.treatmentPlan.isNotEmpty) {
      addText('Treatment Plan: ${record.treatmentPlan}');
    }
    yPosition += 10;

    // Prescriptions
    if (record.prescriptions.isNotEmpty) {
      addText('Prescriptions', fontSize: 14, isBold: true);
      for (var prescription in record.prescriptions) {
        addText('• ${prescription.medication}');
        addText('  Dosage: ${prescription.dosage}');
        addText('  Frequency: ${prescription.frequency}');
        addText('  Duration: ${prescription.duration}');
        addText('  Instructions: ${prescription.instructions}');
        yPosition += 5;
      }
      yPosition += 10;
    }

    // Lab Results
    if (record.labResults.isNotEmpty) {
      addText('Laboratory Results', fontSize: 14, isBold: true);
      record.labResults.forEach((key, value) {
        addText('$key: $value');
      });
      yPosition += 10;
    }

    // Notes
    if (record.notes.isNotEmpty) {
      addText('Additional Notes', fontSize: 14, isBold: true);
      addText(record.notes);
    }

    // Save the document and dispose
    final List<int> bytes = await document.save();
    document.dispose();

    return Uint8List.fromList(bytes);
  }
}
