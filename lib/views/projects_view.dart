import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';
import '../models/models.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedVersion = 'all';
  String? _selectedProjectName;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final projects = appState.projects;
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    final projectVersions = projects.map((p) => p.version).toSet().toList();
    projectVersions.sort((a, b) {
      final aNum = int.tryParse(a.replaceAll(RegExp(r'\D+'), ''));
      final bNum = int.tryParse(b.replaceAll(RegExp(r'\D+'), ''));
      if (aNum != null && bNum != null) {
        return bNum.compareTo(aNum); // Descending order
      }
      return b.compareTo(a);
    });

    if (_selectedVersion != 'all' && !projectVersions.contains(_selectedVersion)) {
      _selectedVersion = 'all';
    }

    // If a project name is selected, show its versions list view instead of the main project group list
    if (_selectedProjectName != null) {
      return _buildVersionsListView(context, appState, _selectedProjectName!, lang, isRTL);
    }

    // Apply filters and group projects by name
    final query = _searchController.text.trim().toLowerCase();
    final groupedProjects = <String, List<ProjectModel>>{};
    for (var p in projects) {
      if (query.isNotEmpty &&
          !p.name.toLowerCase().contains(query) &&
          !p.version.toLowerCase().contains(query)) {
        continue;
      }
      if (_selectedVersion != 'all' && p.version != _selectedVersion) {
        continue;
      }
      groupedProjects.putIfAbsent(p.name, () => []).add(p);
    }

    final uniqueProjectNames = groupedProjects.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Search Bar Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: AppTheme.shadowSm,
            ),
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                final searchFields = [
                  // Version Filter
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: Column(
                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '(Version)',
                          style: TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedVersion,
                          isExpanded: true,
                          alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                          onChanged: (val) {
                            setState(() {
                              _selectedVersion = val!;
                            });
                          },
                          icon: const Icon(FontAwesomeIcons.chevronDown, size: 14, color: AppTheme.lightNeutral),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                              borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Align(
                                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  Translations.get('all_versions', lang),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            ...projectVersions.map((v) => DropdownMenuItem(
                              value: v,
                              child: Align(
                                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  v,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 16 : 0),

                  // Project Name Search
                  Expanded(
                    flex: isMobile ? 0 : 2,
                    child: Column(
                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.get('filter_project_name', lang),
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: Translations.get('filter_project_name_placeholder', lang),
                            hintStyle: const TextStyle(color: AppTheme.lightNeutral, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                              borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: isRTL
                                ? searchFields.reversed.map((w) => w is Expanded ? w.child : w).toList()
                                : searchFields.map((w) => w is Expanded ? w.child : w).toList(),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: isRTL ? searchFields.reversed.toList() : searchFields,
                          ),
                    const SizedBox(height: 20),

                    // Search trigger button
                    Row(
                      mainAxisAlignment: isRTL ? MainAxisAlignment.start : MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild to apply filter
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                            ),
                          ),
                          child: Text(
                            Translations.get('btn_search', lang),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Grid of Project Groups
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 3;
              if (constraints.maxWidth < 600) {
                crossAxisCount = 1;
              } else if (constraints.maxWidth < 1000) {
                crossAxisCount = 2;
              }

              if (uniqueProjectNames.isEmpty) {
                return _buildEmptyState(lang);
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.2,
                ),
                itemCount: uniqueProjectNames.length,
                itemBuilder: (context, index) {
                  final name = uniqueProjectNames[index];
                  final versions = groupedProjects[name]!;
                  return _buildProjectGroupCard(context, name, versions, lang, isRTL);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.shadow,
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.folderOpen,
            size: 48,
            color: AppTheme.borderColor,
          ),
          const SizedBox(height: 16),
          Text(
            Translations.get('no_projects_found', lang),
            style: const TextStyle(
              color: AppTheme.darkNeutral,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Translations.get('sub_no_projects', lang),
            style: const TextStyle(
              color: AppTheme.lightNeutral,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    AppState appState,
    ProjectModel project,
    String lang,
    bool isRTL,
  ) {
    Color badgeColor;
    Color badgeText;
    // Cycle colors based on version string to support any dynamic version string cleanly
    final vHash = project.version.hashCode.abs();
    final colorIndex = vHash % 3;
    if (colorIndex == 0) {
      badgeColor = AppTheme.primaryLight;
      badgeText = AppTheme.primary;
    } else if (colorIndex == 1) {
      badgeColor = AppTheme.successLight;
      badgeText = AppTheme.successDark;
    } else {
      badgeColor = AppTheme.warningLight;
      badgeText = AppTheme.warningDark;
    }

    final detailButton = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          isRTL ? FontAwesomeIcons.chevronLeft : FontAwesomeIcons.chevronRight,
          size: 14,
          color: AppTheme.lightNeutral,
        ),
      ),
    );

    final detailsInfo = Expanded(
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            project.name,
            style: const TextStyle(
              color: AppTheme.darkNeutral,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              project.version,
              style: TextStyle(
                color: badgeText,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sub metadata Row
          Row(
            mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: isRTL
                ? [
                    Text(
                      project.lastUpdate,
                      style: const TextStyle(color: AppTheme.darkNeutral, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    Text(
                      ' :${Translations.get('project_last_update', lang)}',
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${project.jobOrders.length}',
                      style: const TextStyle(color: AppTheme.darkNeutral, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    Text(
                      ' :${Translations.get('project_total_jos', lang)}',
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 11),
                    ),
                  ]
                : [
                    Text(
                      '${Translations.get('project_total_jos', lang)}: ',
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 11),
                    ),
                    Text(
                      '${project.jobOrders.length}',
                      style: const TextStyle(color: AppTheme.darkNeutral, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${Translations.get('project_last_update', lang)}: ',
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 11),
                    ),
                    Text(
                      project.lastUpdate,
                      style: const TextStyle(color: AppTheme.darkNeutral, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ],
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () {
        appState.setActiveProject(project.id);
        appState.switchView('project-details');
      },
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.shadowSm,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: isRTL
              ? [detailButton, const SizedBox(width: 16), detailsInfo]
              : [detailsInfo, const SizedBox(width: 16), detailButton],
        ),
      ),
    );
  }

  Widget _buildProjectGroupCard(
    BuildContext context,
    String projectName,
    List<ProjectModel> versionsList,
    String lang,
    bool isRTL,
  ) {
    // Sort versions to find the latest update
    versionsList.sort((a, b) {
      final aNum = int.tryParse(a.version.replaceAll(RegExp(r'\D+'), ''));
      final bNum = int.tryParse(b.version.replaceAll(RegExp(r'\D+'), ''));
      if (aNum != null && bNum != null) {
        return bNum.compareTo(aNum);
      }
      return b.version.compareTo(a.version);
    });
    final latestModel = versionsList.first;
    final versionCount = versionsList.length;

    final detailButton = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          isRTL ? FontAwesomeIcons.chevronLeft : FontAwesomeIcons.chevronRight,
          size: 14,
          color: AppTheme.lightNeutral,
        ),
      ),
    );

    final detailsInfo = Expanded(
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            projectName,
            style: const TextStyle(
              color: AppTheme.darkNeutral,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Versions Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              lang == 'ar' ? '$versionCount إصدارات' : '$versionCount Versions',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Metadata: latest update
          Row(
            mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: isRTL
                ? [
                    Text(
                      latestModel.lastUpdate,
                      style: const TextStyle(color: AppTheme.darkNeutral, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    Text(
                      ' :${Translations.get('project_last_update', lang)}',
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 11),
                    ),
                  ]
                : [
                    Text(
                      '${Translations.get('project_last_update', lang)}: ',
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 11),
                    ),
                    Text(
                      latestModel.lastUpdate,
                      style: const TextStyle(color: AppTheme.darkNeutral, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ],
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () {
        setState(() {
          _selectedProjectName = projectName;
        });
      },
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.shadowSm,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: isRTL
              ? [detailButton, const SizedBox(width: 16), detailsInfo]
              : [detailsInfo, const SizedBox(width: 16), detailButton],
        ),
      ),
    );
  }

  Widget _buildVersionsListView(
    BuildContext context,
    AppState appState,
    String projectName,
    String lang,
    bool isRTL,
  ) {
    final versionsList = appState.projects.where((p) => p.name == projectName).toList();
    versionsList.sort((a, b) {
      final aNum = int.tryParse(a.version.replaceAll(RegExp(r'\D+'), ''));
      final bNum = int.tryParse(b.version.replaceAll(RegExp(r'\D+'), ''));
      if (aNum != null && bNum != null) {
        return bNum.compareTo(aNum);
      }
      return b.version.compareTo(a.version);
    });

    final backButton = TextButton.icon(
      onPressed: () {
        setState(() {
          _selectedProjectName = null;
        });
      },
      icon: Icon(isRTL ? FontAwesomeIcons.chevronRight : FontAwesomeIcons.chevronLeft, size: 14),
      label: Text(
        lang == 'ar' ? 'العودة للمشاريع' : 'Back to Projects',
        style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: isRTL
                ? [
                    Expanded(
                      child: Text(
                        '$projectName - ${lang == 'ar' ? 'الإصدارات المتاحة' : 'Available Versions'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNeutral),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    backButton,
                  ]
                : [
                    backButton,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$projectName - ${lang == 'ar' ? 'الإصدارات المتاحة' : 'Available Versions'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNeutral),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 24),

          // Versions Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 3;
              if (constraints.maxWidth < 600) {
                crossAxisCount = 1;
              } else if (constraints.maxWidth < 1000) {
                crossAxisCount = 2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.2,
                ),
                itemCount: versionsList.length,
                itemBuilder: (context, index) {
                  final project = versionsList[index];
                  return _buildProjectCard(context, appState, project, lang, isRTL);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
