import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';
import '../models/models.dart';
import '../widgets/job_order_modal.dart';
import '../widgets/parts_summary_modal.dart';

class ProjectDetailsView extends StatelessWidget {
  const ProjectDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final projectId = appState.activeProjectId;
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    final project = appState.projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => ProjectModel(id: '', name: '', version: '', lastUpdate: '', jobOrders: []),
    );

    if (project.id.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: Text(Translations.get('project_not_found', lang))),
      );
    }

    // Calculate Job Order status counts
    final totalJOs = project.jobOrders.length;
    int completedCount = 0;
    int inProgressCount = 0;
    int notStartedCount = 0;

    for (var jo in project.jobOrders) {
      if (jo.delivered == jo.required) {
        completedCount++;
      } else if (jo.delivered > 0 && jo.delivered < jo.required) {
        inProgressCount++;
      } else {
        notStartedCount++;
      }
    }

    // Breadcrumb widgets
    final breadcrumbWidgets = [
      InkWell(
        onTap: () => appState.switchView('projects'),
        child: Text(
          Translations.get('projects', lang),
          style: const TextStyle(
            color: AppTheme.lightNeutral,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Icon(isRTL ? FontAwesomeIcons.chevronLeft : FontAwesomeIcons.chevronRight, size: 10, color: AppTheme.lightNeutral),
      const SizedBox(width: 8),
      Text(
        '${project.name} - ${project.version}',
        style: const TextStyle(
          color: AppTheme.darkNeutral,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;

    final summaryButton = Tooltip(
      message: lang == 'ar' ? 'تلخيص بالقطع' : 'Summary by Parts',
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => PartsSummaryModal(
              project: project,
              transfers: appState.transfers,
              lang: lang,
              isRTL: isRTL,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isRTL 
                ? [
                    Text(
                      lang == 'ar' ? 'تلخيص بالقطع' : 'Parts Summary',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(FontAwesomeIcons.cubes, size: 14, color: AppTheme.primary),
                  ]
                : [
                    const Icon(FontAwesomeIcons.cubes, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'ar' ? 'تلخيص بالقطع' : 'Parts Summary',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Breadcrumb Navigation (Dynamic RTL/LTR row placement)
          Row(
            mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: isRTL ? breadcrumbWidgets.reversed.toList() : breadcrumbWidgets,
          ),
          const SizedBox(height: 16),

          // Main Title
          Text(
            '${project.name} - ${project.version}',
            style: const TextStyle(
              color: AppTheme.darkNeutral,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            textAlign: isRTL ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 24),

          // Project Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 4;
              if (constraints.maxWidth < 600) {
                crossAxisCount = 2;
              }

              final statsList = [
                _buildMetaCard(
                  label: Translations.get('project_total_jos', lang),
                  value: '$totalJOs',
                  accentColor: AppTheme.primary,
                ),
                _buildMetaCard(
                  label: Translations.get('completed', lang),
                  value: '$completedCount',
                  accentColor: AppTheme.success,
                ),
                _buildMetaCard(
                  label: Translations.get('in_progress', lang),
                  value: '$inProgressCount',
                  accentColor: AppTheme.warning,
                ),
                _buildMetaCard(
                  label: Translations.get('not_started', lang),
                  value: '$notStartedCount',
                  accentColor: AppTheme.danger,
                ),
              ];

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: crossAxisCount == 2 ? 1.6 : 2.2,
                children: isRTL ? statsList : statsList,
              );
            },
          ),
          const SizedBox(height: 32),

          // Job Orders Table Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: AppTheme.shadow,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: isRTL
                      ? [
                          summaryButton,
                          const Spacer(),
                          Text(
                            Translations.get('table_jo', lang),
                            style: const TextStyle(
                              color: AppTheme.darkNeutral,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ]
                      : [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            Translations.get('table_jo', lang),
                            style: const TextStyle(
                              color: AppTheme.darkNeutral,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          summaryButton,
                        ],
                ),
                const SizedBox(height: 24),

                // Table widget
                _buildJobOrdersTable(context, appState, project, lang, isRTL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border(
          top: BorderSide(color: accentColor, width: 4),
          bottom: const BorderSide(color: AppTheme.borderColor),
          left: const BorderSide(color: AppTheme.borderColor),
          right: const BorderSide(color: AppTheme.borderColor),
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.darkNeutral,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.lightNeutral,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobOrdersTable(
    BuildContext context,
    AppState appState,
    ProjectModel project,
    String lang,
    bool isRTL,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.bg),
          dataRowMinHeight: 58,
          dataRowMaxHeight: 58,
          columnSpacing: 32,
          columns: [
            DataColumn(
              label: Text(
                Translations.get('table_jo', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_part', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_required', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_delivered', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_remaining', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_status', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_details', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
          rows: project.jobOrders.map((jo) {
            final remaining = jo.required - jo.delivered;

            String statusText = Translations.get('not_started', lang);
            Color statusBg = const Color(0xFFF1F5F9);
            Color statusTextColor = const Color(0xFF475569);

            if (jo.delivered == jo.required) {
              statusText = Translations.get('completed', lang);
              statusBg = AppTheme.successLight;
              statusTextColor = AppTheme.successDark;
            } else if (jo.delivered > 0 && jo.delivered < jo.required) {
              statusText = Translations.get('in_progress', lang);
              statusBg = AppTheme.warningLight;
              statusTextColor = AppTheme.warningDark;
            }

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    jo.jo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0891B2),
                    ),
                  ),
                ),
                DataCell(Text(jo.part)),
                DataCell(Text('${jo.required}')),
                DataCell(Text('${jo.delivered}')),
                DataCell(
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: remaining > 0 ? AppTheme.warningDark : AppTheme.successDark,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => JobOrderModal(
                          project: project,
                          joNumber: jo.jo,
                          transfers: appState.transfers,
                        ),
                      );
                    },
                    icon: const Icon(FontAwesomeIcons.eye, size: 14),
                    color: AppTheme.lightNeutral,
                    hoverColor: AppTheme.primaryLight,
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
