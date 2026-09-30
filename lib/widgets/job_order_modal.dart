import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';
import '../providers/app_state.dart';

class JobOrderModal extends StatelessWidget {
  final ProjectModel project;
  final String joNumber;
  final List<TransferModel> transfers;

  const JobOrderModal({
    super.key,
    required this.project,
    required this.joNumber,
    required this.transfers,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    // Filter transfers matching this project & job order number
    final matchingTransfers = transfers.where(
      (t) => t.project == project.name && t.jo == joNumber,
    ).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      elevation: 24,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header (Dynamic LTR/RTL Row)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: isRTL
                    ? [
                        // Close Button (Left side for RTL)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                          color: AppTheme.lightNeutral,
                          hoverColor: AppTheme.primaryLight,
                        ),

                        // Title (Right side RTL)
                        Expanded(
                          child: Text(
                            '${Translations.get('modal_title', lang)} - $joNumber (${project.name})',
                            style: const TextStyle(
                              color: AppTheme.darkNeutral,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    : [
                        // Title (Left side LTR)
                        Expanded(
                          child: Text(
                            '${Translations.get('modal_title', lang)} - $joNumber (${project.name})',
                            style: const TextStyle(
                              color: AppTheme.darkNeutral,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Close Button (Right side for LTR)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                          color: AppTheme.lightNeutral,
                          hoverColor: AppTheme.primaryLight,
                        ),
                      ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 1),

            // Modal Body containing the Table
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    matchingTransfers.isEmpty
                        ? _buildEmptyState(lang)
                        : _buildHistoryTable(matchingTransfers, lang, isRTL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          Translations.get('modal_empty', lang),
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.lightNeutral,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHistoryTable(List<TransferModel> transfersList, String lang, bool isRTL) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.bg),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          columnSpacing: 24,
          columns: [
            DataColumn(
              label: Text(
                Translations.get('modal_header_date', lang),
                style: const TextStyle(color: AppTheme.lightNeutral, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('modal_header_part', lang),
                style: const TextStyle(color: AppTheme.lightNeutral, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('modal_header_qty', lang),
                style: const TextStyle(color: AppTheme.lightNeutral, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('modal_header_from', lang),
                style: const TextStyle(color: AppTheme.lightNeutral, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('modal_header_to', lang),
                style: const TextStyle(color: AppTheme.lightNeutral, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('modal_header_status', lang),
                style: const TextStyle(color: AppTheme.lightNeutral, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('modal_header_notes', lang),
                style: const TextStyle(color: AppTheme.lightNeutral, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
          rows: transfersList.map((t) {
            Color statusBg;
            Color statusText;
            String statusValue = t.status;
            if (t.status == 'تم الاستلام') {
              statusBg = AppTheme.successLight;
              statusText = AppTheme.successDark;
              statusValue = lang == 'ar' ? 'تم الاستلام' : 'Received';
            } else if (t.status == 'مرفوضة') {
              statusBg = AppTheme.dangerLight;
              statusText = AppTheme.dangerDark;
              statusValue = lang == 'ar' ? 'مرفوضة' : 'Rejected';
            } else {
              statusBg = AppTheme.warningLight;
              statusText = AppTheme.warningDark;
              statusValue = lang == 'ar' ? 'قيد الانتظار' : 'Pending';
            }

            return DataRow(
              cells: [
                DataCell(Text(t.date)),
                DataCell(Text(t.part)),
                DataCell(
                  Text(
                    '${t.qty}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text('${t.senderName} (${t.fromDept})')),
                DataCell(
                  Text(
                    t.receiverName.isNotEmpty
                        ? '${t.receiverName} (${t.toDept})'
                        : (t.status == 'تم الاستلام' || t.status == 'مرفوضة'
                            ? t.toDept
                            : (lang == 'ar' ? 'قيد الانتظار (${t.toDept})' : 'Pending (${t.toDept})')),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      statusValue,
                      style: TextStyle(
                        color: statusText,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: t.notes,
                    child: SizedBox(
                      width: 150,
                      child: Text(
                        t.notes,
                        style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
