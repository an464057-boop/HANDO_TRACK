import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';
import '../models/models.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final filteredNotifications = appState.getFilteredNotifications();
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips (with horizontal scrolling to prevent mobile overflows)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: isRTL
                  ? [
                      _buildFilterChip(context, appState, label: Translations.get('filter_technical', lang), filterId: 'technical', lang: lang),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, appState, label: Translations.get('filter_pending', lang), filterId: 'pending', lang: lang),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, appState, label: Translations.get('filter_accepted', lang), filterId: 'accepted', lang: lang),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, appState, label: Translations.get('filter_all', lang), filterId: 'all', lang: lang),
                    ]
                  : [
                      _buildFilterChip(context, appState, label: Translations.get('filter_all', lang), filterId: 'all', lang: lang),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, appState, label: Translations.get('filter_accepted', lang), filterId: 'accepted', lang: lang),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, appState, label: Translations.get('filter_pending', lang), filterId: 'pending', lang: lang),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, appState, label: Translations.get('filter_technical', lang), filterId: 'technical', lang: lang),
                    ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications List
          appState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredNotifications.isEmpty
                  ? _buildEmptyState(lang)
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = filteredNotifications[index];
                        return _buildNotificationCard(context, appState, notif, lang, isRTL);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    AppState appState, {
    required String label,
    required String filterId,
    required String lang,
  }) {
    final isActive = appState.notifFilter == filterId;

    return InkWell(
      onTap: () {
        appState.setNotifFilter(filterId);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.cardBg,
          border: Border.all(color: isActive ? AppTheme.primary : AppTheme.borderColor),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.lightNeutral,
            fontWeight: FontWeight.w700,
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.bellSlash,
            size: 48,
            color: AppTheme.borderColor,
          ),
          const SizedBox(height: 16),
          Text(
            Translations.get('no_notifications', lang),
            style: const TextStyle(
              color: AppTheme.darkNeutral,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Translations.get('sub_no_notifications', lang),
            style: const TextStyle(
              color: AppTheme.lightNeutral,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppState appState,
    NotificationModel notif,
    String lang,
    bool isRTL,
  ) {
    // Translate mock relative times if in English mode
    String timeText = notif.time;
    if (lang == 'en') {
      if (notif.time == 'الآن') timeText = 'Just now';
      if (notif.time == 'منذ 10 دقائق') timeText = '10 minutes ago';
      if (notif.time == 'منذ 45 دقيقة') timeText = '45 minutes ago';
      if (notif.time == 'منذ ساعتين') timeText = '2 hours ago';
    }

    return GestureDetector(
      onTap: () => _showNotificationDetails(context, appState, notif, lang, isRTL),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.shadowSm,
        ),
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            // Align content row elements depending on RTL/LTR
            final cardContent = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isRTL
                  ? [
                      // RTL layout: info details on left, actions on the left side
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Content on left
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${notif.sender} (${notif.senderDept}) ${Translations.get('notif_title', lang)}',
                                    style: const TextStyle(
                                      color: AppTheme.darkNeutral,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),

                                  // Metadata items (RTL spacing)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildMetadataItem(Translations.get('table_qty', lang), '${notif.qty}', isRTL),
                                      const SizedBox(height: 4),
                                      _buildMetadataItem(Translations.get('table_jo', lang), notif.jo, isRTL),
                                      const SizedBox(height: 4),
                                      _buildMetadataItem(Translations.get('table_part', lang), notif.part, isRTL),
                                      const SizedBox(height: 4),
                                      _buildMetadataItem(Translations.get('table_project', lang), notif.project, isRTL),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      color: AppTheme.lightNeutral,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Icon wrapper on right
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.solidBell,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 24),
                        _buildActions(context, appState, notif, lang),
                      ],
                    ]
                  : [
                      // LTR layout: info details on right, actions on the right side
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon wrapper on left
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.solidBell,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Content on right
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${notif.sender} (${notif.senderDept}) ${Translations.get('notif_title', lang)}',
                                    style: const TextStyle(
                                      color: AppTheme.darkNeutral,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  const SizedBox(height: 8),

                                  // Metadata items (LTR spacing)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildMetadataItem(Translations.get('table_project', lang), notif.project, isRTL),
                                      const SizedBox(height: 4),
                                      _buildMetadataItem(Translations.get('table_part', lang), notif.part, isRTL),
                                      const SizedBox(height: 4),
                                      _buildMetadataItem(Translations.get('table_jo', lang), notif.jo, isRTL),
                                      const SizedBox(height: 4),
                                      _buildMetadataItem(Translations.get('table_qty', lang), '${notif.qty}', isRTL),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      color: AppTheme.lightNeutral,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 24),
                        _buildActions(context, appState, notif, lang),
                      ],
                    ],
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cardContent,
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 8),
                  _buildActions(context, appState, notif, lang),
                ],
              );
            } else {
              return cardContent;
            }
          },
        ),
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value, bool isRTL) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: AppTheme.lightNeutral,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppTheme.darkNeutral,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
      textAlign: isRTL ? TextAlign.right : TextAlign.left,
    );
  }

  Widget _buildActions(BuildContext context, AppState appState, NotificationModel notif, String lang) {
    if (notif.status == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.successLight,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          Translations.get('stat_accepted', lang),
          style: const TextStyle(
            color: AppTheme.successDark,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    } else if (notif.status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.dangerLight,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          Translations.get('stat_rejected', lang),
          style: const TextStyle(
            color: AppTheme.dangerDark,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    } else {
      // Pending actions
      final isTargetDept = appState.currentUser?.department == notif.toDept;

      if (!isTargetDept) {
        final isRTL = lang == 'ar';
        // Show pending badge instead of action buttons for other departments
        return Align(
          alignment: isRTL ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // warningLight background
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: Text(
              lang == 'ar' ? 'انتظار استلام (${notif.toDept})' : 'Pending (${notif.toDept})',
              style: const TextStyle(
                color: AppTheme.warningDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Reject button
          ElevatedButton(
            onPressed: () {
              appState.rejectNotification(notif.id);
              _showToast(context, Translations.get('reject_success', lang), isSuccess: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerLight,
              foregroundColor: AppTheme.dangerDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                side: const BorderSide(color: AppTheme.danger),
              ),
            ),
            child: Text(
              Translations.get('notif_reject', lang),
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Accept button
          ElevatedButton(
            onPressed: () {
              appState.acceptNotification(notif.id);
              _showToast(context, Translations.get('accept_success', lang), isSuccess: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
            ),
            child: Text(
              Translations.get('notif_accept', lang),
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }
  }

  void _showToast(BuildContext context, String message, {required bool isSuccess}) {
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
              isSuccess ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    AppState appState,
    NotificationModel notif,
    String lang,
    bool isRTL,
  ) {
    // Look up the corresponding transfer details locally
    TransferModel? transfer;
    try {
      transfer = appState.transfers.firstWhere((t) => t.id == notif.transferId);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) {
        UserModel? senderUser;
        bool isSenderLoading = true;
        UserModel? receiverUser;
        bool isReceiverLoading = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Trigger asynchronous sender fetch if not already done
            if (isSenderLoading) {
              FirebaseFirestore.instance
                  .collection('users')
                  .where('name', isEqualTo: notif.sender)
                  .limit(1)
                  .get()
                  .then((userSnap) {
                if (userSnap.docs.isNotEmpty) {
                  senderUser = UserModel.fromMap(userSnap.docs.first.data());
                }
                if (context.mounted) {
                  setModalState(() {
                    isSenderLoading = false;
                  });
                }
              }).catchError((_) {
                if (context.mounted) {
                  setModalState(() {
                    isSenderLoading = false;
                  });
                }
              });
            }

            // Trigger asynchronous receiver fetch if transfer is processed
            final hasReceiver = transfer != null && transfer.receiverName.isNotEmpty;
            if (hasReceiver && isReceiverLoading) {
              FirebaseFirestore.instance
                  .collection('users')
                  .where('name', isEqualTo: transfer.receiverName)
                  .limit(1)
                  .get()
                  .then((userSnap) {
                if (userSnap.docs.isNotEmpty) {
                  receiverUser = UserModel.fromMap(userSnap.docs.first.data());
                }
                if (context.mounted) {
                  setModalState(() {
                    isReceiverLoading = false;
                  });
                }
              }).catchError((_) {
                if (context.mounted) {
                  setModalState(() {
                    isReceiverLoading = false;
                  });
                }
              });
            }

            final labelStyle = const TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.lightNeutral,
              fontSize: 13,
            );
            final valueStyle = const TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.darkNeutral,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            );

            // Reusable row for details table
            Widget detailRow(String label, String value) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: isRTL
                      ? [
                          Expanded(
                            child: Text(
                              value,
                              style: valueStyle,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ':$label',
                            style: labelStyle,
                          ),
                        ]
                      : [
                          Text(
                            '$label: ',
                            style: labelStyle,
                          ),
                          Expanded(
                            child: Text(
                              value,
                              style: valueStyle,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: AppTheme.shadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkNeutral,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.radiusLg - 1),
                          topRight: Radius.circular(AppTheme.radiusLg - 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: isRTL
                            ? [
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.xmark, size: 18, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                Text(
                                  lang == 'ar' ? 'تفاصيل طلب التسليم' : 'Delivery Request Details',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ]
                            : [
                                Text(
                                  lang == 'ar' ? 'تفاصيل طلب التسليم' : 'Delivery Request Details',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.xmark, size: 18, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                      ),
                    ),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // 1. Sender Info Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.bg,
                                borderRadius: BorderRadius.circular(AppTheme.radius),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: isRTL
                                    ? [
                                        // Sender Details (Right aligned in RTL)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                notif.sender,
                                                style: const TextStyle(
                                                  color: AppTheme.darkNeutral,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    isSenderLoading 
                                                        ? (lang == 'ar' ? 'جاري التحميل...' : 'Loading...')
                                                        : (senderUser?.id ?? 'EMP-001'),
                                                    style: const TextStyle(
                                                      color: AppTheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    lang == 'ar' ? ' | كود الموظف: ' : ' | Emp Code: ',
                                                    style: const TextStyle(
                                                      color: AppTheme.lightNeutral,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    notif.senderDept,
                                                    style: const TextStyle(
                                                      color: AppTheme.darkNeutral,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    lang == 'ar' ? 'القسم: ' : 'Dept: ',
                                                    style: const TextStyle(
                                                      color: AppTheme.lightNeutral,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Avatar Icon
                                        const CircleAvatar(
                                          backgroundColor: AppTheme.primaryLight,
                                          radius: 20,
                                          child: Icon(FontAwesomeIcons.solidUser, size: 16, color: AppTheme.primary),
                                        ),
                                      ]
                                    : [
                                        // Avatar Icon
                                        const CircleAvatar(
                                          backgroundColor: AppTheme.primaryLight,
                                          radius: 20,
                                          child: Icon(FontAwesomeIcons.solidUser, size: 16, color: AppTheme.primary),
                                        ),
                                        const SizedBox(width: 12),
                                        // Sender Details (Left aligned in LTR)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                notif.sender,
                                                style: const TextStyle(
                                                  color: AppTheme.darkNeutral,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    lang == 'ar' ? 'Dept: ' : 'Dept: ',
                                                    style: const TextStyle(
                                                      color: AppTheme.lightNeutral,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    notif.senderDept,
                                                    style: const TextStyle(
                                                      color: AppTheme.darkNeutral,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    lang == 'ar' ? ' | Emp Code: ' : ' | Emp Code: ',
                                                    style: const TextStyle(
                                                      color: AppTheme.lightNeutral,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    isSenderLoading 
                                                        ? (lang == 'ar' ? 'Loading...' : 'Loading...')
                                                        : (senderUser?.id ?? 'EMP-001'),
                                                    style: const TextStyle(
                                                      color: AppTheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                              ),
                            ),

                            if (hasReceiver) ...[
                              const SizedBox(height: 12),
                              Text(
                                lang == 'ar' ? 'بيانات المستلم' : 'Receiver Details',
                                style: const TextStyle(
                                  color: AppTheme.darkNeutral,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: notif.status == 'accepted' 
                                      ? AppTheme.successLight.withOpacity(0.4) 
                                      : AppTheme.dangerLight.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                  border: Border.all(
                                    color: notif.status == 'accepted' 
                                        ? AppTheme.success.withOpacity(0.5) 
                                        : AppTheme.danger.withOpacity(0.5)
                                  ),
                                ),
                                child: Row(
                                  children: isRTL
                                      ? [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  transfer.receiverName,
                                                  style: const TextStyle(
                                                    color: AppTheme.darkNeutral,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      isReceiverLoading 
                                                          ? (lang == 'ar' ? 'جاري التحميل...' : 'Loading...')
                                                          : (receiverUser?.id ?? 'EMP-002'),
                                                      style: TextStyle(
                                                        color: notif.status == 'accepted' 
                                                            ? AppTheme.successDark 
                                                            : AppTheme.dangerDark,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      lang == 'ar' ? ' | كود الموظف: ' : ' | Emp Code: ',
                                                      style: const TextStyle(
                                                        color: AppTheme.lightNeutral,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      receiverUser?.department ?? (notif.toDept),
                                                      style: const TextStyle(
                                                        color: AppTheme.darkNeutral,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      lang == 'ar' ? 'القسم: ' : 'Dept: ',
                                                      style: const TextStyle(
                                                        color: AppTheme.lightNeutral,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          CircleAvatar(
                                            backgroundColor: notif.status == 'accepted' 
                                                ? AppTheme.successLight 
                                                : AppTheme.dangerLight,
                                            radius: 20,
                                            child: Icon(
                                              notif.status == 'accepted' 
                                                  ? FontAwesomeIcons.solidCircleCheck 
                                                  : FontAwesomeIcons.solidCircleXmark,
                                              size: 16,
                                              color: notif.status == 'accepted' 
                                                  ? AppTheme.success
                                                  : AppTheme.danger,
                                            ),
                                          ),
                                        ]
                                      : [
                                          CircleAvatar(
                                            backgroundColor: notif.status == 'accepted' 
                                                ? AppTheme.successLight 
                                                : AppTheme.dangerLight,
                                            radius: 20,
                                            child: Icon(
                                              notif.status == 'accepted' 
                                                  ? FontAwesomeIcons.solidCircleCheck 
                                                  : FontAwesomeIcons.solidCircleXmark,
                                              size: 16,
                                              color: notif.status == 'accepted' 
                                                  ? AppTheme.success
                                                  : AppTheme.danger,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  transfer.receiverName,
                                                  style: const TextStyle(
                                                    color: AppTheme.darkNeutral,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      lang == 'ar' ? 'Dept: ' : 'Dept: ',
                                                      style: const TextStyle(
                                                        color: AppTheme.lightNeutral,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      receiverUser?.department ?? (notif.toDept),
                                                      style: const TextStyle(
                                                        color: AppTheme.darkNeutral,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      lang == 'ar' ? ' | Emp Code: ' : ' | Emp Code: ',
                                                      style: const TextStyle(
                                                        color: AppTheme.lightNeutral,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      isReceiverLoading 
                                                          ? (lang == 'ar' ? 'Loading...' : 'Loading...')
                                                          : (receiverUser?.id ?? 'EMP-002'),
                                                      style: TextStyle(
                                                        color: notif.status == 'accepted' 
                                                            ? AppTheme.successDark 
                                                            : AppTheme.dangerDark,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // 2. Transfer Details Section
                            Text(
                              lang == 'ar' ? 'تفاصيل الطلب' : 'Request Details',
                              style: const TextStyle(
                                color: AppTheme.darkNeutral,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: AppTheme.borderColor),
                            detailRow(Translations.get('table_project', lang), notif.project),
                            detailRow(Translations.get('table_version', lang), notif.version),
                            detailRow(Translations.get('table_part', lang), notif.part),
                            detailRow(Translations.get('table_jo', lang), notif.jo),
                            detailRow(Translations.get('table_qty', lang), '${notif.qty} pcs'),
                            detailRow(Translations.get('label_to_dept', lang), notif.toDept),
                            detailRow(lang == 'ar' ? 'تاريخ الإرسال' : 'Sent Date', transfer?.date ?? notif.time),
                            const SizedBox(height: 16),

                            // 3. Notes Section
                            Text(
                              lang == 'ar' ? 'الملاحظات' : 'Notes',
                              style: const TextStyle(
                                color: AppTheme.darkNeutral,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.bg,
                                borderRadius: BorderRadius.circular(AppTheme.radius),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Text(
                                transfer?.notes ?? (lang == 'ar' ? 'لا توجد ملاحظات.' : 'No notes.'),
                                style: const TextStyle(
                                  color: AppTheme.lightNeutral,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                textAlign: isRTL ? TextAlign.right : TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. Image Attachment Section (If present)
                            if (transfer != null && transfer.imageUrl != null && transfer.imageUrl!.isNotEmpty) ...[
                              Text(
                                lang == 'ar' ? 'الصورة المرفقة' : 'Image Attachment',
                                style: const TextStyle(
                                  color: AppTheme.darkNeutral,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radius),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(AppTheme.radius),
                                  ),
                                  child: Image.memory(
                                    base64Decode(
                                      transfer.imageUrl!.contains(',')
                                          ? transfer.imageUrl!.substring(transfer.imageUrl!.indexOf(',') + 1)
                                          : transfer.imageUrl!
                                    ),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Center(
                                          child: Text(
                                            lang == 'ar' ? 'تعذر عرض الصورة' : 'Could not display image',
                                            style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Divider before actions
                    const Divider(color: AppTheme.borderColor, height: 1),

                    // Bottom Action Bar (Accept / Reject)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (notif.status == 'pending' && appState.currentUser?.department == notif.toDept) ...[
                            // Reject Button
                            ElevatedButton(
                              onPressed: () {
                                appState.rejectNotification(notif.id);
                                Navigator.pop(context);
                                _showToast(context, Translations.get('reject_success', lang), isSuccess: false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.dangerLight,
                                foregroundColor: AppTheme.dangerDark,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                  side: const BorderSide(color: AppTheme.danger),
                                ),
                              ),
                              child: Text(
                                Translations.get('notif_reject', lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Accept Button
                            ElevatedButton(
                              onPressed: () {
                                appState.acceptNotification(notif.id);
                                Navigator.pop(context);
                                _showToast(context, Translations.get('accept_success', lang), isSuccess: true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                ),
                              ),
                              child: Text(
                                Translations.get('notif_accept', lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ] else ...[
                            // Dismiss / OK Button if already processed or user is from another department
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.bg,
                                foregroundColor: AppTheme.darkNeutral,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                  side: const BorderSide(color: AppTheme.borderColor),
                                ),
                              ),
                              child: Text(
                                lang == 'ar' ? 'إغلاق' : 'Close',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
