import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/app_theme.dart';
import '../widgets/job_order_modal.dart';
import '../models/models.dart';

class PartGroupSummary {
  final String partName;
  final List<JobOrderModel> jobOrders;
  int required = 0;
  int delivered = 0;

  PartGroupSummary({required this.partName, required this.jobOrders}) {
    for (var jo in jobOrders) {
      required += jo.required;
      delivered += jo.delivered;
    }
  }

  int get remaining => required - delivered;
  double get progress => required > 0 ? (delivered / required) : 0.0;
}

class PartsSummaryModal extends StatefulWidget {
  final ProjectModel project;
  final List<TransferModel> transfers;
  final String lang;
  final bool isRTL;

  const PartsSummaryModal({
    super.key,
    required this.project,
    required this.transfers,
    required this.lang,
    required this.isRTL,
  });

  @override
  State<PartsSummaryModal> createState() => _PartsSummaryModalState();
}

class _PartsSummaryModalState extends State<PartsSummaryModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedParts = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PartGroupSummary> _getGroupedParts() {
    final Map<String, List<JobOrderModel>> grouped = {};
    for (var jo in widget.project.jobOrders) {
      grouped.putIfAbsent(jo.part, () => []).add(jo);
    }

    final List<PartGroupSummary> summaries = grouped.entries.map((e) {
      return PartGroupSummary(partName: e.key, jobOrders: e.value);
    }).toList();

    // Filter by search query if present
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      return summaries.where((s) => s.partName.toLowerCase().contains(query)).toList();
    }

    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    final groupedParts = _getGroupedParts();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      backgroundColor: AppTheme.bg,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            _buildHeader(context),

            // Search Bar
            _buildSearchBar(),

            // Parts List
            Expanded(
              child: groupedParts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: groupedParts.length,
                      itemBuilder: (context, index) {
                        return _buildPartCard(groupedParts[index], isMobile);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: widget.isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: widget.isRTL
            ? [
                IconButton(
                  icon: const Icon(FontAwesomeIcons.xmark, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppTheme.lightNeutral,
                ),
                const Spacer(),
                Text(
                  widget.lang == 'ar' ? 'تلخيص كميات القطع' : 'Part Quantities Summary',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNeutral,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(FontAwesomeIcons.cubes, color: AppTheme.primary, size: 20),
              ]
            : [
                const Icon(FontAwesomeIcons.cubes, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.lang == 'ar' ? 'تلخيص كميات القطع' : 'Part Quantities Summary',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNeutral,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.xmark, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppTheme.lightNeutral,
                ),
              ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      color: Colors.white,
      child: Directionality(
        textDirection: widget.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: widget.lang == 'ar' ? 'ابحث باسم القطعة...' : 'Search by part name...',
            hintStyle: const TextStyle(color: AppTheme.lightNeutral, fontSize: 13),
            prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 14, color: AppTheme.lightNeutral),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(FontAwesomeIcons.circleXmark, size: 14, color: AppTheme.lightNeutral),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FontAwesomeIcons.circleExclamation, size: 48, color: AppTheme.lightNeutral),
            const SizedBox(height: 16),
            Text(
              widget.lang == 'ar' ? 'لا توجد نتائج بحث مطابقة!' : 'No matching results found!',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.lightNeutral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartCard(PartGroupSummary s, bool isMobile) {
    final isExpanded = _expandedParts.contains(s.partName);
    
    // Determine overall status colors
    Color statusColor = AppTheme.lightNeutral;
    Color statusBg = const Color(0xFFF1F5F9);
    String statusText = widget.lang == 'ar' ? 'لم تبدأ' : 'Not Started';

    if (s.delivered == s.required) {
      statusColor = AppTheme.successDark;
      statusBg = AppTheme.successLight;
      statusText = widget.lang == 'ar' ? 'مكتملة' : 'Completed';
    } else if (s.delivered > 0) {
      statusColor = AppTheme.warningDark;
      statusBg = AppTheme.warningLight;
      statusText = widget.lang == 'ar' ? 'قيد التنفيذ' : 'In Progress';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Part Header Tap Area
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedParts.remove(s.partName);
                } else {
                  _expandedParts.add(s.partName);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.isRTL
                        ? [
                            _buildProgressColumn(s, statusBg, statusColor, statusText, isMobile),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPartName(s.partName, true)),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                              size: 14,
                              color: AppTheme.lightNeutral,
                            ),
                          ]
                        : [
                            Icon(
                              isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                              size: 14,
                              color: AppTheme.lightNeutral,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPartName(s.partName, false)),
                            const SizedBox(width: 16),
                            _buildProgressColumn(s, statusBg, statusColor, statusText, isMobile),
                          ],
                  ),
                  const SizedBox(height: 12),
                  // Sleek Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: s.progress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: s.delivered == s.required ? AppTheme.success : AppTheme.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Job Orders List
          if (isExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderColor),
            Container(
              color: AppTheme.bg.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildJOsSubTable(s, isMobile),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartName(String name, bool alignRight) {
    return Text(
      name,
      style: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkNeutral,
      ),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );
  }

  Widget _buildProgressColumn(
    PartGroupSummary s,
    Color statusBg,
    Color statusColor,
    String statusText,
    bool isMobile,
  ) {
    final remainingText = widget.lang == 'ar'
        ? 'متبقي: ${s.remaining}'
        : 'Rem: ${s.remaining}';
        
    return Column(
      crossAxisAlignment: widget.isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${s.delivered} / ${s.required}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 12 : 14,
                color: AppTheme.darkNeutral,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 8 : 10,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          remainingText,
          style: TextStyle(
            color: s.remaining > 0 ? AppTheme.warningDark : AppTheme.successDark,
            fontSize: isMobile ? 9 : 11,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildJOsSubTable(PartGroupSummary s, bool isMobile) {
    return Directionality(
      textDirection: widget.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
            child: Text(
              widget.lang == 'ar' ? 'الجوابيات المرتبطة بهذه القطعة:' : 'Job Orders for this part:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightNeutral,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          Table(
            columnWidths: isMobile
                ? const {
                    0: FlexColumnWidth(2.2), // JO ID
                    1: FlexColumnWidth(1.1), // Required
                    2: FlexColumnWidth(1.1), // Delivered
                    3: FlexColumnWidth(1.1), // Remaining
                    4: FlexColumnWidth(2.5), // Status (needs slightly more space for text scaling)
                    5: FlexColumnWidth(1.0), // Eye button
                  }
                : const {
                    0: FlexColumnWidth(2.5), // JO ID
                    1: FlexColumnWidth(1.2), // Required
                    2: FlexColumnWidth(1.2), // Delivered
                    3: FlexColumnWidth(1.2), // Remaining
                    4: FlexColumnWidth(2.2), // Status
                    5: FlexColumnWidth(1.0), // Eye button
                  },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1.5)),
                ),
                children: [
                  _buildSubTableHeaderCell(widget.lang == 'ar' ? 'الجوابية' : 'Job Order', isMobile),
                  _buildSubTableHeaderCell(widget.lang == 'ar' ? 'مطلوب' : 'Req', isMobile),
                  _buildSubTableHeaderCell(widget.lang == 'ar' ? 'مسلم' : 'Del', isMobile),
                  _buildSubTableHeaderCell(widget.lang == 'ar' ? 'باقي' : 'Rem', isMobile),
                  _buildSubTableHeaderCell(widget.lang == 'ar' ? 'الحالة' : 'Status', isMobile),
                  _buildSubTableHeaderCell('', isMobile),
                ],
              ),
              // Data Rows
              ...s.jobOrders.map((jo) {
                final rem = jo.required - jo.delivered;
                
                Color joStatusColor = AppTheme.lightNeutral;
                Color joStatusBg = const Color(0xFFF1F5F9);
                String joStatusText = widget.lang == 'ar' ? 'لم تبدأ' : 'Not Started';

                if (jo.delivered == jo.required) {
                  joStatusColor = AppTheme.successDark;
                  joStatusBg = AppTheme.successLight;
                  joStatusText = widget.lang == 'ar' ? 'مكتملة' : 'Completed';
                } else if (jo.delivered > 0) {
                  joStatusColor = AppTheme.warningDark;
                  joStatusBg = AppTheme.warningLight;
                  joStatusText = widget.lang == 'ar' ? 'قيد التنفيذ' : 'In Progress';
                }

                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: widget.isRTL ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          jo.jo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0891B2),
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text('${jo.required}', style: TextStyle(fontSize: isMobile ? 11 : 12)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text('${jo.delivered}', style: TextStyle(fontSize: isMobile ? 11 : 12)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '$rem',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: rem > 0 ? AppTheme.warningDark : AppTheme.successDark,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Align(
                        alignment: widget.isRTL ? Alignment.centerRight : Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: joStatusBg,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              joStatusText,
                              style: TextStyle(
                                color: joStatusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 8 : 9,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(FontAwesomeIcons.eye, size: isMobile ? 10 : 12),
                      color: AppTheme.lightNeutral,
                      hoverColor: AppTheme.primaryLight,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => JobOrderModal(
                            project: widget.project,
                            joNumber: jo.jo,
                            transfers: widget.transfers,
                          ),
                        );
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubTableHeaderCell(String text, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.lightNeutral,
          fontSize: isMobile ? 10 : 11,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}
