import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_model.dart';

/// Servicio encargado de generar y mostrar reportes financieros en PDF.
class ReportPdfService {
  // Formato de fechas en español colombiano.
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Formato de valores monetarios colombianos.
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$ ',
    decimalDigits: 0,
  );

  /// Genera el documento PDF y abre la vista previa.
  static Future<void> exportReport(ReportModel report) async {
    // Crea un documento PDF.
    final pdf = pw.Document();

    // Agrega una página con la información financiera.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (context) => [
          // Encabezado del documento.
          pw.Text(
            'FinanzasApp',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Reporte financiero',
            style: const pw.TextStyle(fontSize: 17),
          ),
          pw.SizedBox(height: 8),

          // Período consultado.
          pw.Text(
            'Período: ${_dateFormat.format(report.fechaInicio)} - '
            '${_dateFormat.format(report.fechaFin)}',
          ),
          pw.SizedBox(height: 20),

          // Resumen financiero.
          _buildSectionTitle('Resumen financiero'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _buildSummaryRow('Total ingresos', report.totalIngresos),
              _buildSummaryRow('Total gastos', report.totalGastos),
              _buildSummaryRow('Saldo disponible', report.saldo),
            ],
          ),
          pw.SizedBox(height: 20),

          // Detalle de gastos por categoría.
          _buildSectionTitle('Gastos por categoría'),
          if (report.gastosPorCategoria.isEmpty)
            pw.Text('No hay gastos registrados en este período.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Categoría', 'Valor', 'Porcentaje'],
              data: report.gastosPorCategoria.map((category) {
                // Calcula el porcentaje de cada categoría.
                final percentage = report.totalGastos > 0
                    ? category.totalGastos / report.totalGastos * 100
                    : 0.0;

                return [
                  category.nombreCategoria,
                  _currencyFormat.format(category.totalGastos),
                  '${percentage.toStringAsFixed(1)}%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerHeight: 28,
              cellHeight: 25,
            ),

          pw.SizedBox(height: 25),

          // Fecha de generación del documento.
          pw.Divider(color: PdfColors.grey300),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Generado el ${_dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    // Abre la vista previa para imprimir o compartir el PDF.
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'reporte_financiero.pdf',
    );
  }

  /// Construye el título de cada sección.
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  /// Construye una fila del resumen financiero.
  static pw.TableRow _buildSummaryRow(String title, double amount) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(9), child: pw.Text(title)),
        pw.Padding(
          padding: const pw.EdgeInsets.all(9),
          child: pw.Text(
            _currencyFormat.format(amount),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
}
