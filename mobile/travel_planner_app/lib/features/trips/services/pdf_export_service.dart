import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/trip_model.dart';

class PdfExportService {
  Future<void> generateAndShareTripPdf(Trip trip) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${trip.destination} Travel Itinerary',
                    style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.indigo800),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dates: ${trip.startDate} to ${trip.endDate}',
                    style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),
            
            if (trip.dayPlans.isEmpty)
              pw.Text('No itinerary has been generated yet.', style: pw.TextStyle(font: font))
            else
              ...trip.dayPlans.map((dayPlan) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 16),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.indigo50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            'Day ${dayPlan.dayNumber} - ${dayPlan.date}',
                            style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.indigo900),
                          ),
                          pw.Spacer(),
                          if (dayPlan.dailySummary != null && dayPlan.dailySummary!['weather_note'] != null)
                            pw.Text(
                              'Weather: ${dayPlan.dailySummary!['weather_note']}',
                              style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    if (dayPlan.dailySummary != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Text(
                          'Total Distance: ${dayPlan.dailySummary!['total_distance_km'] ?? 0} km  |  Total Time: ${dayPlan.dailySummary!['total_travel_time_minutes'] ?? 0} min',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
                        ),
                      ),

                    if (dayPlan.routeItems.isEmpty)
                      pw.Text('Free day! No places scheduled.', style: pw.TextStyle(font: font, color: PdfColors.grey))
                    else
                      ...dayPlan.routeItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '${index + 1}. ',
                                style: pw.TextStyle(font: boldFont, color: PdfColors.indigo400),
                              ),
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      item.placeName,
                                      style: pw.TextStyle(font: boldFont, fontSize: 12),
                                    ),
                                    pw.Text(
                                      '${item.category ?? "General"} • ${item.arrivalTime ?? "Time TBD"}',
                                      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    pw.Divider(color: PdfColors.grey300),
                  ],
                );
              }).toList(),

              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'Generated by AI Travel Itinerary Optimizer',
                  style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500),
                ),
              ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${trip.destination.replaceAll(' ', '_')}_Itinerary.pdf',
    );
  }
}