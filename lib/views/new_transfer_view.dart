import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';

class NewTransferView extends StatefulWidget {
  const NewTransferView({super.key});

  @override
  State<NewTransferView> createState() => _NewTransferViewState();
}

class _NewTransferViewState extends State<NewTransferView> {
  final _formKey = GlobalKey<FormState>();

  String _selectedVersion = 'Version 3';
  String _selectedProject = 'Busway Project';
  String _selectedPart = 'L Shape';
  List<String> _selectedJOs = [];
  final Map<String, TextEditingController> _joControllers = {};
  String _selectedDept = 'دهان';
  String _notes = '';
  XFile? _selectedImage;
  String? _imageBase64;

  @override
  void dispose() {
    for (var c in _joControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  final List<String> _depts = ['تشكيل', 'دهان', 'تجميع', 'قصدرة', 'جودة', 'لحام'];

  // Handle Pick Image
  Future<void> _pickImage(String lang) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
        });
        _showToast(Translations.get('image_success', lang), isError: false);
      }
    } catch (e) {
      _showToast(Translations.get('image_error', lang), isError: true);
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              message,
              style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(
              isError ? FontAwesomeIcons.circleXmark : FontAwesomeIcons.circleCheck,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  void _submitForm(String lang) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedJOs.isEmpty) {
        _showToast(
          lang == 'ar' ? 'يرجى تحديد أمر شغل واحد على الأقل' : 'Please select at least one Job Order',
          isError: true,
        );
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);
      final projects = appState.projects;

      // Find the project and job order to calculate remaining required qty
      final project = projects.firstWhere(
        (p) => p.name == _selectedProject && p.version == _selectedVersion,
        orElse: () => ProjectModel(id: '', name: '', version: '', lastUpdate: '', jobOrders: []),
      );
      
      final List<Map<String, dynamic>> transfersToSubmit = [];

      for (var jo in _selectedJOs) {
        final controller = _joControllers[jo];
        if (controller == null) continue;

        final qtyText = controller.text.trim();
        final qty = int.tryParse(qtyText) ?? 0;

        if (qty <= 0) {
          _showToast(
            lang == 'ar' 
                ? 'يرجى إدخال كمية صالحة لأمر الشغل $jo' 
                : 'Please enter a valid quantity for Job Order $jo',
            isError: true,
          );
          return;
        }

        final joModel = project.jobOrders.firstWhere(
          (j) => j.jo == jo,
          orElse: () => JobOrderModel(jo: '', part: '', required: 0, delivered: 0),
        );

        if (joModel.jo.isNotEmpty) {
          final remaining = joModel.required - joModel.delivered;
          if (remaining <= 0) {
            final msg = lang == 'ar'
                ? 'عذراً، أمر الشغل $jo تم تسليمه بالكامل بالفعل!'
                : 'Job Order $jo has already been fully delivered!';
            _showToast(msg, isError: true);
            return;
          }
          if (qty > remaining) {
            final msg = lang == 'ar'
                ? 'الكمية لأمر الشغل $jo أكبر من المتبقي المطلوب ($remaining قطعة)!'
                : 'Quantity for Job Order $jo exceeds remaining required ($remaining pcs)!';
            _showToast(msg, isError: true);
            return;
          }
        }

        transfersToSubmit.add({
          'jo': jo,
          'qty': qty,
        });
      }

      // Submit all validated transfers
      for (var transfer in transfersToSubmit) {
        final jo = transfer['jo'] as String;
        final qty = transfer['qty'] as int;

        await appState.addTransfer(
          version: _selectedVersion,
          project: _selectedProject,
          part: _selectedPart,
          jo: jo,
          toDept: _selectedDept,
          qty: qty,
          notes: _notes,
          imageUrl: _imageBase64,
        );
      }

      _showToast(Translations.get('form_success', lang), isError: false);

      // Navigate back to Dashboard
      appState.switchView('dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    final projects = appState.projects;

    // 1. Get unique project names
    final projectNames = projects.map((p) => p.name).toSet().toList();
    if (projectNames.isEmpty) {
      projectNames.add('Busway Project');
    }

    // Ensure _selectedProject is valid
    if (!projectNames.contains(_selectedProject)) {
      _selectedProject = projectNames.first;
    }

    // 2. Get unique versions for selected project name
    final versions = projects
        .where((p) => p.name == _selectedProject)
        .map((p) => p.version)
        .toSet()
        .toList();
    if (versions.isEmpty) {
      versions.add('Version 3');
    }

    // Ensure _selectedVersion is valid
    if (!versions.contains(_selectedVersion)) {
      _selectedVersion = versions.first;
    }

    // 3. Get job orders for selected project and version
    final selectedProjModel = projects.firstWhere(
      (p) => p.name == _selectedProject && p.version == _selectedVersion,
      orElse: () => ProjectModel(
        id: '',
        name: _selectedProject,
        version: _selectedVersion,
        lastUpdate: '',
        jobOrders: [],
      ),
    );

    // Get parts and JOs from this project model's job orders
    final parts = selectedProjModel.jobOrders.map((j) => j.part).toSet().toList();
    if (parts.isEmpty) {
      parts.add('L Shape');
    }

    // Ensure _selectedPart is valid
    if (!parts.contains(_selectedPart)) {
      _selectedPart = parts.first;
    }

    final joNumbers = selectedProjModel.jobOrders
        .where((j) => j.part == _selectedPart)
        .map((j) => j.jo)
        .toSet()
        .toList();
    if (joNumbers.isEmpty) {
      joNumbers.add('J-2504');
    }

    // Ensure _selectedJOs contains only valid JOs for this part
    _selectedJOs = _selectedJOs.where((jo) => joNumbers.contains(jo)).toList();
    if (_selectedJOs.isEmpty && joNumbers.isNotEmpty) {
      _selectedJOs = [joNumbers.first];
    }

    // Sync TextEditingControllers
    for (var jo in _selectedJOs) {
      if (!_joControllers.containsKey(jo)) {
        final joModel = selectedProjModel.jobOrders.firstWhere(
          (j) => j.jo == jo,
          orElse: () => JobOrderModel(jo: '', part: '', required: 0, delivered: 0),
        );
        final remaining = joModel.required - joModel.delivered;
        final initialQty = remaining > 0 ? remaining : 0;
        _joControllers[jo] = TextEditingController(text: '$initialQty');
      }
    }
    // Clean up unselected controllers
    final keysToRemove = _joControllers.keys.where((k) => !_selectedJOs.contains(k)).toList();
    for (var k in keysToRemove) {
      _joControllers[k]?.dispose();
      _joControllers.remove(k);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Breadcrumb (LTR/RTL dynamic row)
          Row(
            mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: isRTL 
                ? [
                    Text(
                      Translations.get('new_transfer', lang),
                      style: const TextStyle(color: AppTheme.darkNeutral, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(FontAwesomeIcons.chevronLeft, size: 10, color: AppTheme.lightNeutral),
                    const SizedBox(width: 4),
                    Text(
                      Translations.get('transfers', lang),
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ]
                : [
                    Text(
                      Translations.get('transfers', lang),
                      style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(FontAwesomeIcons.chevronRight, size: 10, color: AppTheme.lightNeutral),
                    const SizedBox(width: 4),
                    Text(
                      Translations.get('new_transfer', lang),
                      style: const TextStyle(color: AppTheme.darkNeutral, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
          ),
          const SizedBox(height: 12),

          // Main form card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: AppTheme.shadow,
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get('new_transfer', lang),
                    style: const TextStyle(
                      color: AppTheme.darkNeutral,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;

                      return Column(
                        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // Row 1: Version & Project
                          _buildGridRow(
                            isWide: isWide,
                            child1: _buildDropdown(
                              label: Translations.get('label_version', lang),
                              value: _selectedVersion,
                              items: versions,
                              onChanged: (val) {
                                setState(() {
                                  _selectedVersion = val!;
                                  // Update part and JO based on new version
                                  final pModel = projects.firstWhere(
                                    (p) => p.name == _selectedProject && p.version == _selectedVersion,
                                    orElse: () => ProjectModel(id: '', name: '', version: '', lastUpdate: '', jobOrders: []),
                                  );
                                  final pParts = pModel.jobOrders.map((j) => j.part).toSet().toList();
                                  _selectedPart = pParts.isNotEmpty ? pParts.first : 'L Shape';
                                  
                                  final pJOs = pModel.jobOrders.where((j) => j.part == _selectedPart).map((j) => j.jo).toSet().toList();
                                  _selectedJOs = pJOs.isNotEmpty ? [pJOs.first] : [];
                                });
                              },
                              isRTL: isRTL,
                            ),
                            child2: _buildDropdown(
                              label: Translations.get('label_project', lang),
                              value: _selectedProject,
                              items: projectNames,
                              onChanged: (val) {
                                setState(() {
                                  _selectedProject = val!;
                                  // Update version list and pick first
                                  final projectVersions = projects
                                      .where((p) => p.name == _selectedProject)
                                      .map((p) => p.version)
                                      .toSet()
                                      .toList();
                                  _selectedVersion = projectVersions.isNotEmpty ? projectVersions.first : 'Version 1';
                                  
                                  // Update part and JO based on new version/project
                                  final pModel = projects.firstWhere(
                                    (p) => p.name == _selectedProject && p.version == _selectedVersion,
                                    orElse: () => ProjectModel(id: '', name: '', version: '', lastUpdate: '', jobOrders: []),
                                  );
                                  final pParts = pModel.jobOrders.map((j) => j.part).toSet().toList();
                                  _selectedPart = pParts.isNotEmpty ? pParts.first : 'L Shape';
                                  
                                  final pJOs = pModel.jobOrders.where((j) => j.part == _selectedPart).map((j) => j.jo).toSet().toList();
                                  _selectedJOs = pJOs.isNotEmpty ? [pJOs.first] : [];
                                });
                              },
                              isRTL: isRTL,
                            ),
                            isRTL: isRTL,
                          ),
                          const SizedBox(height: 20),

                          // Row 2: Part Name & Receiving Department
                          _buildGridRow(
                            isWide: isWide,
                            child1: _buildDropdown(
                              label: Translations.get('label_part', lang),
                              value: _selectedPart,
                              items: parts,
                              onChanged: (val) {
                                setState(() {
                                  _selectedPart = val!;
                                  // Update JO based on new part
                                  final pModel = projects.firstWhere(
                                    (p) => p.name == _selectedProject && p.version == _selectedVersion,
                                    orElse: () => ProjectModel(id: '', name: '', version: '', lastUpdate: '', jobOrders: []),
                                  );
                                  final pJOs = pModel.jobOrders.where((j) => j.part == _selectedPart).map((j) => j.jo).toSet().toList();
                                  _selectedJOs = pJOs.isNotEmpty ? [pJOs.first] : [];
                                });
                              },
                              isRTL: isRTL,
                            ),
                            child2: _buildDropdown(
                              label: Translations.get('label_to_dept', lang),
                              value: _selectedDept,
                              items: _depts,
                              onChanged: (val) => setState(() => _selectedDept = val!),
                              isRTL: isRTL,
                            ),
                            isRTL: isRTL,
                          ),
                          const SizedBox(height: 24),

                          // Row 3: JO Selection (Chips, full width)
                          _buildJOMultiSelect(
                            label: isRTL ? 'أرقام أوامر الشغل (أختر واحدة أو أكثر) *' : 'Job Orders (Select one or more) *',
                            availableJOs: joNumbers,
                            selectedJOs: _selectedJOs,
                            onSelectionChanged: (jo, selected) {
                              setState(() {
                                if (selected) {
                                  if (!_selectedJOs.contains(jo)) {
                                    _selectedJOs.add(jo);
                                  }
                                } else {
                                  // Keep at least one selected JO
                                  if (_selectedJOs.length > 1) {
                                    _selectedJOs.remove(jo);
                                  }
                                }
                              });
                            },
                            isRTL: isRTL,
                          ),
                          const SizedBox(height: 24),

                          // Row 4: JO Quantities dynamic list
                          _buildJOsQuantitiesSection(lang, isRTL, selectedProjModel.jobOrders),
                          const SizedBox(height: 24),

                          // Row 5: Notes (Full width)
                          _buildNotesInput(lang, isRTL),
                          const SizedBox(height: 20),

                          // Row 6: Image Attachment (Full width)
                          _buildImageAttachment(lang, isRTL),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _submitForm(lang),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          Translations.get('btn_send', lang),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridRow({required bool isWide, required Widget child1, required Widget child2, required bool isRTL}) {
    if (isWide) {
      // Swap columns if RTL to keep layout consistency
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isRTL
            ? [
                Expanded(child: child2),
                const SizedBox(width: 24),
                Expanded(child: child1),
              ]
            : [
                Expanded(child: child1),
                const SizedBox(width: 24),
                Expanded(child: child2),
              ],
      );
    } else {
      return Column(
        children: [
          child2,
          const SizedBox(height: 20),
          child1,
        ],
      );
    }
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isRTL,
  }) {
    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkNeutral,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 8),

        // Select Input (DropdownButtonFormField)
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
          icon: const Icon(FontAwesomeIcons.chevronDown, size: 14, color: AppTheme.lightNeutral),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            fillColor: AppTheme.cardBg,
            filled: true,
          ),
          items: items.map((item) {
            // Translate display for departments if language is English
            String displayText = item;
            if (!isRTL) {
              if (item == 'تشكيل') displayText = 'Forming / Sheet Metal';
              if (item == 'دهان') displayText = 'Painting';
              if (item == 'تجميع') displayText = 'Assembly';
              if (item == 'قصدرة') displayText = 'Tinning';
              if (item == 'جودة') displayText = 'Quality Control';
              if (item == 'لحام') displayText = 'Welding';
            }
            return DropdownMenuItem<String>(
              value: item,
              child: Align(
                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  displayText,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildJOMultiSelect({
    required String label,
    required List<String> availableJOs,
    required List<String> selectedJOs,
    required Function(String, bool) onSelectionChanged,
    required bool isRTL,
  }) {
    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkNeutral,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isRTL ? WrapAlignment.end : WrapAlignment.start,
          children: availableJOs.map((jo) {
            final isSelected = selectedJOs.contains(jo);
            return FilterChip(
              label: Text(
                jo,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkNeutral,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primary,
              checkmarkColor: Colors.white,
              backgroundColor: AppTheme.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.borderColor,
                  width: 1.5,
                ),
              ),
              onSelected: (selected) {
                onSelectionChanged(jo, selected);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildJOsQuantitiesSection(String lang, bool isRTL, List<JobOrderModel> allJobOrders) {
    if (_selectedJOs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          isRTL ? '⚠️ يرجى تحديد أمر شغل (جوابية) واحد على الأقل' : '⚠️ Please select at least one Job Order',
          style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13),
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
        ),
      );
    }

    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          isRTL ? 'الكميات المطلوبة لكل أمر شغل *' : 'Quantities for each Job Order *',
          style: const TextStyle(
            color: AppTheme.darkNeutral,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedJOs.length,
          itemBuilder: (context, index) {
            final jo = _selectedJOs[index];
            final joModel = allJobOrders.firstWhere(
              (j) => j.jo == jo,
              orElse: () => JobOrderModel(jo: '', part: '', required: 0, delivered: 0),
            );
            final remaining = joModel.required - joModel.delivered;
            final controller = _joControllers[jo];

            if (controller == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 450;
                  
                  final infoText = Expanded(
                    child: Column(
                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isRTL ? 'أمر شغل' : 'JO'}: $jo',
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRTL 
                              ? 'المطلوب: ${joModel.required} | المسلم: ${joModel.delivered} | المتبقي: $remaining'
                              : 'Req: ${joModel.required} | Del: ${joModel.delivered} | Rem: $remaining',
                          style: const TextStyle(
                            color: AppTheme.lightNeutral,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );

                  final qtyField = SizedBox(
                    width: isMobile ? double.infinity : 120,
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixText: 'pcs',
                        suffixStyle: const TextStyle(color: AppTheme.lightNeutral, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return isRTL ? 'مطلوب' : 'Required';
                        }
                        final q = int.tryParse(val);
                        if (q == null || q <= 0) {
                          return isRTL ? 'غير صالح' : 'Invalid';
                        }
                        if (q > remaining) {
                          return isRTL ? 'تعدى الباقي' : 'Exceeds rem.';
                        }
                        return null;
                      },
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [infoText]),
                        const SizedBox(height: 12),
                        qtyField,
                      ],
                    );
                  } else {
                    return Row(
                      children: isRTL 
                          ? [qtyField, const SizedBox(width: 16), infoText] 
                          : [infoText, const SizedBox(width: 16), qtyField],
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesInput(String lang, bool isRTL) {
    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          Translations.get('label_notes', lang),
          style: const TextStyle(
            color: AppTheme.darkNeutral,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),

        // Textarea field
        TextFormField(
          maxLines: 4,
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            hintText: Translations.get('placeholder_notes', lang),
            hintStyle: const TextStyle(color: AppTheme.lightNeutral, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
          onSaved: (val) {
            _notes = val ?? '';
          },
        ),
      ],
    );
  }

  Widget _buildImageAttachment(String lang, bool isRTL) {
    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          Translations.get('label_image', lang),
          style: const TextStyle(
            color: AppTheme.darkNeutral,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),

        // Tappable file upload zone
        InkWell(
          onTap: () => _pickImage(lang),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              border: Border.all(color: AppTheme.borderColor, width: 2, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Column(
              children: [
                if (_selectedImage == null) ...[
                  const Icon(FontAwesomeIcons.cloudArrowUp, color: AppTheme.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    Translations.get('placeholder_image', lang),
                    style: const TextStyle(
                      color: AppTheme.lightNeutral,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedImage!.name,
                        style: const TextStyle(
                          color: AppTheme.successDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(FontAwesomeIcons.circleCheck, color: AppTheme.success, size: 16),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
