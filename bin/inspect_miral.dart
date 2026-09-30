import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

void main() {
  final file = File('assets/Projects DB.xlsm');
  final bytes = file.readAsBytesSync();
  final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
  final sheet = decoder.tables['Projects DB']!;

  int count = 0;
  for (var row in sheet.rows) {
    count++;
    if (count <= 2) continue; // skip headers
    if (row.length > 5 && row[5] != null) {
      final proj = row[5].toString().trim();
      if (proj == 'MIral Project') {
        print('Row $count (MIral Project):');
        for (int col = 0; col < row.length; col++) {
          print('  Col $col: ${row[col]}');
        }
        print('---------------------------');
        break; // Just one is enough
      }
    }
  }
}
