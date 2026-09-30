import 'dart:convert';
import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

void main() {
  final file = File('assets/Projects DB.xlsm');
  if (!file.existsSync()) {
    print('Error: assets/Projects DB.xlsm does not exist!');
    return;
  }

  print('Loading Excel file...');
  final bytes = file.readAsBytesSync();
  final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
  final sheet = decoder.tables['Projects DB'];

  if (sheet == null) {
    print('Error: Sheet "Projects DB" not found in Excel!');
    return;
  }

  print('Parsing sheet rows...');
  final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

  int totalRows = 0;
  int skippedRows = 0;

  int count = 0;
  for (var row in sheet.rows) {
    count++;
    if (count <= 2) continue; // Skip header rows (Row 1 is index 0, Row 2 is index 1)

    if (row.length <= 6) {
      skippedRows++;
      continue;
    }

    final jo = row[1]?.toString().trim() ?? '';
    final qtyStr = row[4]?.toString().trim() ?? '0';
    final projectName = row[5]?.toString().trim() ?? '';
    final version = row[6]?.toString().trim() ?? '';

    if (projectName.isEmpty || version.isEmpty || jo.isEmpty) {
      skippedRows++;
      continue;
    }

    final rate = row[11]?.toString().trim() ?? '';
    final itemType = row[12]?.toString().trim() ?? '';
    final material = row[13]?.toString().trim() ?? '';
    final wires = row[16]?.toString().trim() ?? '';
    
    final a = row[8]?.toString().trim() ?? '';
    final b = row[9]?.toString().trim() ?? '';
    final c = row[10]?.toString().trim() ?? '';

    // Build size from columns
    String size = '';
    if (a.isNotEmpty && a != 'null') {
      if (b.isNotEmpty && b != 'null') {
        if (c.isNotEmpty && c != 'null') {
          size = 'A${a}B${b}C${c}';
        } else {
          size = 'A${a}B${b}';
        }
      } else {
        size = '$a mm';
      }
    }

    // Fallback: Parse size from Assembly Description (row[3]) if empty
    if (size.isEmpty) {
      final desc = row[3]?.toString() ?? '';
      final sizeRegex1 = RegExp(r'A\d+B\d+(?:C\d+)?');
      final sizeRegex2 = RegExp(r'\d+\s*mm');
      
      if (sizeRegex1.hasMatch(desc)) {
        size = sizeRegex1.firstMatch(desc)!.group(0)!;
      } else if (sizeRegex2.hasMatch(desc)) {
        size = sizeRegex2.firstMatch(desc)!.group(0)!;
      }
    }

    // Determine part item name
    String partName = itemType;
    if (partName.isEmpty || partName == 'null') {
      partName = row[18]?.toString().trim() ?? 'Unknown';
      // Clean up extra info from element desc if needed
      if (partName.contains('-')) {
        partName = partName.split('-').first;
      }
    }

    // Build specifications array: [Rate, Material, Wires]
    List<String> specs = [];
    final parsedRate = int.tryParse(rate) ?? double.tryParse(rate)?.round();
    if (parsedRate != null && parsedRate > 0) {
      specs.add('${parsedRate}A');
    } else if (rate.isNotEmpty && rate != 'null' && rate != '0') {
      specs.add(rate.contains('A') ? rate : '${rate}A');
    }

    if (material.isNotEmpty && material != 'null' && material != 'None') {
      specs.add(material);
    }

    final parsedWires = int.tryParse(wires);
    if (parsedWires != null && parsedWires > 0) {
      specs.add('${parsedWires}-Wire');
    }

    String specStr = specs.isNotEmpty ? ' (${specs.join(' - ')})' : '';
    String sizeStr = size.isNotEmpty ? ' $size' : '';
    final part = '$partName$sizeStr$specStr';

    final qty = double.tryParse(qtyStr)?.round() ?? int.tryParse(qtyStr) ?? 0;

    final joMap = {
      'jo': jo,
      'part': part,
      'required': qty,
      'delivered': 0,
    };

    grouped
        .putIfAbsent(projectName, () => {})
        .putIfAbsent(version, () => [])
        .add(joMap);

    totalRows++;
  }

  print('Grouping complete. Total valid JO rows: $totalRows. Skipped rows: $skippedRows');

  final List<Map<String, dynamic>> projectsJson = [];

  grouped.forEach((projectName, versions) {
    versions.forEach((version, jobOrders) {
      final idSafeProj = projectName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final idSafeVer = version.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final projectId = 'p-${idSafeProj}_$idSafeVer';

      projectsJson.add({
        'id': projectId,
        'name': projectName,
        'version': version,
        'lastUpdate': '04/08/2026',
        'jobOrders': jobOrders,
      });
    });
  });

  print('Writing to assets/projects.json...');
  final outputFile = File('assets/projects.json');
  outputFile.writeAsStringSync(json.encode(projectsJson));

  print('Success! Generated ${projectsJson.length} projects/versions containing $totalRows job orders.');
}
