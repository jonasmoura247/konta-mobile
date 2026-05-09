import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';

class PdfService {
  // Bank colors — uses dynamic bank registry
  static PdfColor _bankColor(String? bankId) {
    if (bankId == null) return PdfColors.grey600;
    final b = getBankById(bankId);
    if (b == null) return PdfColors.grey600;
    final c = b.color;
    return PdfColor(c.r, c.g, c.b);
  }

  static String _bankName(String? bankId) {
    if (bankId == null) return '—';
    return getBankById(bankId)?.name ?? bankId;
  }

  static String _groupName(String groupId) {
    switch (groupId) {
      case 'avista':
        return 'À Vista';
      case 'parcelamento':
        return 'Parcelamento';
      case 'assinatura':
        return 'Assinatura';
      default:
        return groupId;
    }
  }

  static Future<void> generateFamilyReport(DateTime month) async {
    final settings = DatabaseService.getSettings();
    final transactions = DatabaseService.getAllTransactions();
    final familyCount = settings.familyMode ? settings.familyCount : 1;
    final familyNames = settings.familyNames;

    // Gross occurrences: family-only, no division (familyCount=1)
    final grossOccurrences = FinanceCalculator.getOccurrencesForMonth(
      transactions,
      month,
      1,
      familyOnly: true,
    );

    final grossTotal = grossOccurrences.fold(0.0, (s, o) => s + o.amount);
    final perPerson = familyCount > 0 ? grossTotal / familyCount : grossTotal;

    // Gross by group
    final byGroup = <String, double>{};
    // Gross by category
    final byCategory = <String, double>{};
    for (final o in grossOccurrences) {
      byGroup[o.transaction.groupId] =
          (byGroup[o.transaction.groupId] ?? 0) + o.amount;
      byCategory[o.transaction.categoryId] =
          (byCategory[o.transaction.categoryId] ?? 0) + o.amount;
    }

    final monthName = DateFormat('MMMM', 'pt_BR').format(month);
    final monthYear = month.year.toString();
    final memberNames = List.generate(familyCount,
        (i) => i < familyNames.length ? familyNames[i] : 'Membro ${i + 1}');
    final membersLabel = memberNames.join(' / ');
    final monthStr = DateFormat("MMMM yyyy", 'pt_BR').format(month);
    final fmtTitle = monthName[0].toUpperCase() + monthName.substring(1);

    String fmt(double v) =>
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(v);

    final purple = PdfColor.fromHex('7C3AED');
    final purpleLight = PdfColor.fromHex('9F67E4');
    final greyBorder = PdfColors.grey300;
    final greyHeader = PdfColors.grey100;
    final styleHeader = pw.TextStyle(
        fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey600);
    final styleCell = const pw.TextStyle(fontSize: 9);
    final styleBold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);

    pw.Widget cell(String text,
            {pw.TextStyle? style,
            pw.Alignment align = pw.Alignment.centerLeft}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Align(
              alignment: align,
              child: pw.Text(text, style: style ?? styleCell)),
        );

    pw.Widget statCard(String label, String value, String sub) => pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 8),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: greyBorder),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(sub,
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ),
        );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // ── Header ──────────────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [purple, purpleLight],
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Relatório Família',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('$fmtTitle $monthYear · $membersLabel',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total do mês',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text(fmt(grossTotal),
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ]),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── 4 Stat cards ─────────────────────────────────────────────────
          pw.Row(children: [
            statCard('TOTAL FAMILIAR', fmt(grossTotal),
                '${grossOccurrences.length} lançamentos'),
            statCard('POR PESSOA', fmt(perPerson), '$familyCount pessoas'),
            statCard('MÊS', fmtTitle, monthYear),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: greyBorder),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MODO',
                        style: pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.grey600,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Família',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Somente itens marcados',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ),
          ]),
          pw.SizedBox(height: 20),

          // ── RESUMO POR PESSOA + RESUMO POR GRUPO (side by side) ──────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // POR PESSOA
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RESUMO POR PESSOA',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: greyBorder),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2),
                        1: const pw.FlexColumnWidth(2)
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: greyHeader),
                          children: [
                            cell('NOME', style: styleHeader),
                            cell('VALOR', style: styleHeader)
                          ],
                        ),
                        ...memberNames.map((name) => pw.TableRow(children: [
                              cell(name),
                              cell(fmt(perPerson), style: styleBold),
                            ])),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              // POR GRUPO
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RESUMO POR GRUPO',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: greyBorder),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2),
                        1: const pw.FlexColumnWidth(2)
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: greyHeader),
                          children: [
                            cell('GRUPO', style: styleHeader),
                            cell('TOTAL', style: styleHeader)
                          ],
                        ),
                        ...byGroup.entries.map((e) => pw.TableRow(children: [
                              cell(_groupName(e.key)),
                              cell(fmt(e.value), style: styleBold),
                            ])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── RESUMO POR CATEGORIA ──────────────────────────────────────────
          pw.Text('RESUMO POR CATEGORIA',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: greyBorder),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2)
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: greyHeader),
                children: [
                  cell('CATEGORIA', style: styleHeader),
                  cell('TOTAL', style: styleHeader)
                ],
              ),
              ...byCategory.entries.map((e) {
                final catName = getCategoryById(e.key).name;
                return pw.TableRow(children: [
                  cell(catName),
                  cell(fmt(e.value), style: styleBold),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── DETALHES DO MÊS ──────────────────────────────────────────────
          pw.Text('DETALHES DO MÊS',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: greyBorder),
            columnWidths: {
              0: const pw.FixedColumnWidth(52), // DATA
              1: const pw.FlexColumnWidth(3), // DESCRIÇÃO
              2: const pw.FlexColumnWidth(2), // GRUPO
              3: const pw.FlexColumnWidth(2), // CATEGORIA
              4: const pw.FlexColumnWidth(1.5), // BANCO
              5: const pw.FixedColumnWidth(28), // TIPO
              6: const pw.FlexColumnWidth(2), // TOTAL
              7: const pw.FlexColumnWidth(2), // FAMÍLIA
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: greyHeader),
                children: [
                  cell('DATA', style: styleHeader),
                  cell('DESCRIÇÃO', style: styleHeader),
                  cell('GRUPO', style: styleHeader),
                  cell('CATEGORIA', style: styleHeader),
                  cell('BANCO', style: styleHeader),
                  cell('TIPO', style: styleHeader),
                  cell('TOTAL', style: styleHeader),
                  cell('FAMÍLIA', style: styleHeader),
                ],
              ),
              ...grossOccurrences.map((o) {
                final t = o.transaction;
                final grossAmt = o.amount;
                final familyAmt =
                    familyCount > 1 ? grossAmt / familyCount : grossAmt;
                final tipoStr = o.installmentTotal > 1
                    ? '${o.installmentIndex}/${o.installmentTotal}'
                    : '1/1';
                final catName = getCategoryById(t.categoryId).name;
                final bColor = _bankColor(t.bankId);
                return pw.TableRow(children: [
                  cell(DateFormat('dd/MM/yyyy').format(t.startDate)),
                  cell(t.description),
                  cell(_groupName(t.groupId)),
                  cell(catName),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 5),
                    child: pw.Text(_bankName(t.bankId),
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: bColor,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                  cell(tipoStr),
                  cell(fmt(grossAmt), style: styleBold),
                  cell(fmt(familyAmt)),
                ]);
              }),
            ],
          ),
        ],
      ),
    );

    final safeMonth = monthStr.replaceAll(' ', '_');
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Relatorio_Familia_$safeMonth.pdf',
    );
  }
}
