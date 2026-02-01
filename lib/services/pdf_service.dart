import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/visitor.dart';

class PdfService {
  Future<File> generateMonthlyReport(
    List<Visitor> visitors,
    Map<String, dynamic> stats,
    String monthName,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          _buildHeader(monthName),
          pw.SizedBox(height: 20),
          _buildKpiSection(stats),
          pw.SizedBox(height: 20),
          pw.Text(
            'Liste des nouveaux visiteurs',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildVisitorsTable(visitors),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    return _saveDocument(name: 'rapport_$monthName.pdf', pdf: pdf);
  }

  pw.Widget _buildHeader(String monthName) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ZOE CHURCH',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text('Rapport Mensuel - $monthName'),
            ],
          ),
          pw.PdfLogo(),
        ],
      ),
    );
  }

  pw.Widget _buildKpiSection(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildKpiItem('Total Visiteurs', '${stats['visitorsTopMonth'] ?? 0}'),
          _buildKpiItem('Taux Rétention', '${stats['retentionRate'] ?? 0}%'),
          _buildKpiItem('Demandes Prière', '${stats['prayerRequests'] ?? 0}'),
        ],
      ),
    );
  }

  pw.Widget _buildKpiItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildVisitorsTable(List<Visitor> visitors) {
    if (visitors.isEmpty) {
      return pw.Text('Aucun nouveau visiteur ce mois-ci.');
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Nom', 'Téléphone', 'Quartier', 'Date', 'Source'],
      data: visitors.map((v) {
        return [
          v.nomComplet,
          v.telephone,
          v.quartier,
          DateFormat('dd/MM/yyyy').format(v.dateEnregistrement),
          v.commentConnu,
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Généré automatiquement par Zoe Church App le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
      ),
    );
  }

  Future<File> _saveDocument({required String name, required pw.Document pdf}) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> openFile(File file) async {
    await OpenFile.open(file.path);
  }
  
  Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Voici le rapport mensuel.',
      subject: subject,
    );
  }
}
