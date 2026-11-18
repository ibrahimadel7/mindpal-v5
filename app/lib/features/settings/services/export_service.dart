import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mindpal_app/features/chat/domain/models.dart';
import 'package:mindpal_app/features/insights/domain/models.dart';

/// Service for exporting user data to PDF format.
class ExportService {
  /// Generate and share/save a PDF report.
  Future<void> exportToPdf({
    required BuildContext context,
    required List<Conversation> conversations,
    required Map<String, List<Message>> messagesByConversation,
    required List<EmotionStat> emotions,
    required List<HabitStat> habits,
    required InsightsSummary summary,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document(
      title: 'MindPal Journal Export',
      author: 'MindPal',
      creator: 'MindPal App',
    );

    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final now = DateTime.now();
    final reportDate = dateFormat.format(now);
    final dateRange = startDate != null && endDate != null
        ? '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'
        : 'All time';

    // Title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 100),
            pw.Text(
              'MindPal',
              style: pw.TextStyle(
                fontSize: 48,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.brown800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Personal Journal Export',
              style: pw.TextStyle(
                fontSize: 24,
                color: PdfColors.brown600,
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.brown200, thickness: 2),
            pw.SizedBox(height: 20),
            _buildInfoRow('Generated:', reportDate),
            _buildInfoRow('Date Range:', dateRange),
            _buildInfoRow('Total Conversations:', '${conversations.length}'),
            _buildInfoRow('Total Entries:', '${summary.entries}'),
            _buildInfoRow('Active Days:', '${summary.streak}'),
            pw.SizedBox(height: 40),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.brown50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Emotional Overview',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Dominant Mood: ${summary.dominantEmotion ?? summary.mood}',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.brown700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Insights summary page
    if (emotions.isNotEmpty || habits.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Insights Summary',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown800,
                ),
              ),
              pw.SizedBox(height: 20),
              if (emotions.isNotEmpty) ...[
                pw.Text(
                  'Emotion Frequency',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown700,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...emotions.take(10).map((e) => _buildStatBar(
                      e.label,
                      e.count,
                      emotions.map((x) => x.count).reduce((a, b) => a > b ? a : b),
                    )),
                pw.SizedBox(height: 24),
              ],
              if (habits.isNotEmpty) ...[
                pw.Text(
                  'Habit Mentions',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown700,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...habits.take(10).map((h) => _buildStatBar(
                      h.name,
                      h.count,
                      habits.map((x) => x.count).reduce((a, b) => a > b ? a : b),
                    )),
              ],
            ],
          ),
        ),
      );
    }

    // Conversation pages
    for (final conversation in conversations) {
      final messages = messagesByConversation[conversation.id] ?? [];
      if (messages.isEmpty) continue;

      final conversationDate = dateFormat.format(conversation.createdAt);
      final messageWidgets = <pw.Widget>[];

      for (final message in messages) {
        messageWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: message.isUser ? PdfColors.brown100 : PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      message.isUser ? 'You' : 'MindPal',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.brown700,
                      ),
                    ),
                    pw.Text(
                      timeFormat.format(message.createdAt),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  message.text,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    conversation.title ?? 'Reflection',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown800,
                    ),
                  ),
                  pw.Text(
                    conversationDate,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.brown600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.brown200),
              pw.SizedBox(height: 12),
            ],
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
          ),
          build: (context) => messageWidgets,
        ),
      );
    }

    // Share/print the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'mindpal_export_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.brown600,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBar(String label, int count, int maxCount) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.brown700,
                ),
              ),
              pw.Text(
                '$count',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Stack(
            children: [
              pw.Container(
                height: 8,
                decoration: pw.BoxDecoration(
                  color: PdfColors.brown100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Container(
                height: 8,
                width: 200 * percentage,
                decoration: pw.BoxDecoration(
                  color: PdfColors.brown400,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
