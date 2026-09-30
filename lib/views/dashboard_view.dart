import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';
import '../models/models.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _selectedStatusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final transfers = appState.transfers;
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    // Calculate statistics
    final total = transfers.length;
    final accepted = transfers.where((t) => t.status == 'تم الاستلام').length;
    final pending = transfers.where((t) => t.status == 'قيد الانتظار').length;
    final rejected = transfers.where((t) => t.status == 'مرفوضة').length;

    // Filter transfers based on active status card selection and search query
    final filteredTransfers = transfers.where((t) {
      final matchesStatus = _selectedStatusFilter == 'all' || t.status == _selectedStatusFilter;
      final matchesSearch = _searchQuery.isEmpty || t.project.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    // Determine section header title
    String tableTitle = Translations.get('latest_transactions', lang);
    if (_selectedStatusFilter == 'تم الاستلام') {
      tableTitle = lang == 'ar' ? 'آخر الاستلامات (تم الاستلام)' : 'Latest Transfers (Received)';
    } else if (_selectedStatusFilter == 'قيد الانتظار') {
      tableTitle = lang == 'ar' ? 'التسليمات قيد الانتظار' : 'Pending Transfers';
    } else if (_selectedStatusFilter == 'مرفوضة') {
      tableTitle = lang == 'ar' ? 'التسليمات المرفوضة' : 'Rejected Transfers';
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Statistics Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 4;
              if (constraints.maxWidth < 600) {
                crossAxisCount = 1;
              } else if (constraints.maxWidth < 1100) {
                crossAxisCount = 2;
              }

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isMobile ? 10 : 20,
                mainAxisSpacing: isMobile ? 10 : 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.7,
                children: [
                  _buildStatCard(
                    title: Translations.get('stat_total', lang),
                    value: '$total',
                    subText: Translations.get('this_month', lang),
                    icon: FontAwesomeIcons.cloudArrowUp,
                    accentColor: AppTheme.primary,
                    iconBgColor: AppTheme.primaryLight,
                    iconColor: AppTheme.primary,
                    isRTL: isRTL,
                    isSelected: _selectedStatusFilter == 'all',
                    onTap: () {
                      setState(() {
                        _selectedStatusFilter = 'all';
                      });
                    },
                  ),
                  _buildStatCard(
                    title: Translations.get('stat_accepted', lang),
                    value: '$accepted',
                    subText: Translations.get('this_month', lang),
                    icon: FontAwesomeIcons.squareCheck,
                    accentColor: AppTheme.success,
                    iconBgColor: AppTheme.successLight,
                    iconColor: AppTheme.successDark,
                    isRTL: isRTL,
                    isSelected: _selectedStatusFilter == 'تم الاستلام',
                    onTap: () {
                      setState(() {
                        _selectedStatusFilter = 'تم الاستلام';
                      });
                    },
                  ),
                  _buildStatCard(
                    title: Translations.get('stat_pending', lang),
                    value: '$pending',
                    subText: Translations.get('this_month', lang),
                    icon: FontAwesomeIcons.clock,
                    accentColor: AppTheme.warning,
                    iconBgColor: AppTheme.warningLight,
                    iconColor: AppTheme.warningDark,
                    isRTL: isRTL,
                    isSelected: _selectedStatusFilter == 'قيد الانتظار',
                    onTap: () {
                      setState(() {
                        _selectedStatusFilter = 'قيد الانتظار';
                      });
                    },
                  ),
                  _buildStatCard(
                    title: Translations.get('stat_rejected', lang),
                    value: '$rejected',
                    subText: Translations.get('this_month', lang),
                    icon: FontAwesomeIcons.ban,
                    accentColor: AppTheme.danger,
                    iconBgColor: AppTheme.dangerLight,
                    iconColor: AppTheme.dangerDark,
                    isRTL: isRTL,
                    isSelected: _selectedStatusFilter == 'مرفوضة',
                    onTap: () {
                      setState(() {
                        _selectedStatusFilter = 'مرفوضة';
                      });
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Table Section Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: AppTheme.shadow,
            ),
            padding: EdgeInsets.all(isMobile ? 14 : 24),
            child: Column(
              crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Section Header
                Row(
                  mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: isRTL
                      ? [
                          Text(
                            tableTitle,
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
                            tableTitle,
                            style: const TextStyle(
                              color: AppTheme.darkNeutral,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                ),
                const SizedBox(height: 24),

                // Project Search Filter
                Directionality(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.darkNeutral,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: lang == 'ar' ? 'ابحث باسم المشروع للفلترة...' : 'Search by project name to filter...',
                      hintStyle: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppTheme.lightNeutral,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 14,
                        color: AppTheme.lightNeutral,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                FontAwesomeIcons.circleXmark,
                                size: 14,
                                color: AppTheme.lightNeutral,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppTheme.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Table widget (horizontally scrollable if screen is thin)
                appState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTransfers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                Translations.get('no_transactions', lang),
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: AppTheme.lightNeutral,
                                ),
                              ),
                            ),
                          )
                        : _buildTransactionsTable(context, filteredTransfers, lang, isRTL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color accentColor,
    required Color iconBgColor,
    required Color iconColor,
    required bool isRTL,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isSelected ? accentColor : AppTheme.borderColor,
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : AppTheme.shadow,
          ),
          child: Stack(
            children: [
              // Vertical border accent (right for RTL, left for LTR)
              Positioned(
                top: 0,
                bottom: 0,
                right: isRTL ? 0 : null,
                left: isRTL ? null : 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(isRTL ? 16 : 0),
                      bottomRight: Radius.circular(isRTL ? 16 : 0),
                      topLeft: Radius.circular(isRTL ? 0 : 16),
                      bottomLeft: Radius.circular(isRTL ? 0 : 16),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 20,
                  vertical: isMobile ? 6 : 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: isRTL
                      ? [
                          // Icon on Left for RTL
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 24,
                                color: iconColor,
                              ),
                            ),
                          ),

                          // Text on Right for RTL
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppTheme.lightNeutral,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    color: AppTheme.darkNeutral,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subText,
                                  style: const TextStyle(
                                    color: AppTheme.lightNeutral,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      : [
                          // Text on Left for LTR
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppTheme.lightNeutral,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    color: AppTheme.darkNeutral,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subText,
                                  style: const TextStyle(
                                    color: AppTheme.lightNeutral,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Icon on Right for LTR
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 24,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTable(
    BuildContext context,
    List<TransferModel> transfers,
    String lang,
    bool isRTL,
  ) {
    final sortedList = [...transfers];
    sortedList.sort((a, b) {
      if (a.id == "t-1") return -1;
      if (b.id == "t-1") return 1;
      if (a.id == "t-2" && b.id != "t-1") return -1;
      if (b.id == "t-2" && a.id != "t-1") return 1;
      if (a.id == "t-3" && b.id != "t-1" && b.id != "t-2") return -1;
      if (b.id == "t-3" && a.id != "t-1" && a.id != "t-2") return 1;

      return b.id.compareTo(a.id);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.bg),
          dataRowMinHeight: 58,
          dataRowMaxHeight: 58,
          columnSpacing: 28,
          columns: [
            DataColumn(
              label: Text(
                Translations.get('table_date', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_project', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_jo', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_part', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_qty', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_from', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_to', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                Translations.get('table_status', lang),
                style: const TextStyle(
                  color: AppTheme.lightNeutral,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          rows: sortedList.map((transfer) {
            Color statusBg;
            Color statusText;
            String statusValue = transfer.status;
            if (transfer.status == 'تم الاستلام') {
              statusBg = AppTheme.successLight;
              statusText = AppTheme.successDark;
              statusValue = lang == 'ar' ? 'تم الاستلام' : 'Received';
            } else if (transfer.status == 'مرفوضة') {
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
                DataCell(Text(transfer.date)),
                DataCell(
                  Text(
                    transfer.project,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    transfer.jo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0891B2),
                    ),
                  ),
                ),
                DataCell(Text(transfer.part)),
                DataCell(
                  Text(
                    '${transfer.qty}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text('${transfer.senderName} (${transfer.fromDept})')),
                DataCell(
                  Text(
                    transfer.receiverName.isNotEmpty
                        ? '${transfer.receiverName} (${transfer.toDept})'
                        : (transfer.status == 'تم الاستلام' || transfer.status == 'مرفوضة'
                            ? transfer.toDept
                            : (lang == 'ar' ? 'قيد الانتظار (${transfer.toDept})' : 'Pending (${transfer.toDept})')),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      statusValue,
                      style: TextStyle(
                        color: statusText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
