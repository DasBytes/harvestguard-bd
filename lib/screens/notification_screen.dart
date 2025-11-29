import 'package:flutter/material.dart';
import 'package:harvestguard_bd/services/notification_service.dart';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  
  // Variable to control the custom alert message inside the dialog
  String? _localAlertMessage;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    _notificationService.startMonitoring();
    
    // Listen for real-time notifications
    _notificationService.notificationStream.listen((notifications) {
      _checkForCriticalNotifications(notifications);
    });
  }

  // Logic to show alert INSIDE the dialog (replaces SnackBar)
  void _checkForCriticalNotifications(List<NotificationModel> notifications) {
    if (!mounted) return;

    final newCriticalCount = notifications.where((n) => 
      !n.isRead && n.priority == NotificationPriority.critical
    ).length;

    if (newCriticalCount > 0) {
      _showLocalAlert("⚠️ $newCriticalCountটি নতুন জরুরি বিজ্ঞপ্তি এসেছে!", isError: true);
    }
  }

  // Shows a temporary message at the bottom of the dialog
  void _showLocalAlert(String message, {bool isError = false}) {
    setState(() {
      _localAlertMessage = message;
    });

    _alertTimer?.cancel();
    _alertTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _localAlertMessage = null;
        });
      }
    });
  }

  Future<void> _checkNotificationsManually() async {
    setState(() {
      _isLoading = true;
    });

    // Manually trigger the check
    await _notificationService.checkAndGenerateNotifications();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // Show confirmation that refresh worked
      _showLocalAlert("তথ্য হালনাগাদ করা হয়েছে");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Returns a Dialog widget to create the Alert Popup effect
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8, // 80% Screen Height
          color: Colors.grey.shade50,
          child: Stack(
            children: [
              Column(
                children: [
                  // ================= Header Section =================
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.green.shade700,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "বিজ্ঞপ্তি",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Refresh Button
                            IconButton(
                              icon: _isLoading 
                                ? SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : Icon(Icons.refresh, color: Colors.white),
                              onPressed: _isLoading ? null : _checkNotificationsManually,
                              tooltip: 'রিফ্রেশ করুন',
                            ),
                            // Close Button
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'বন্ধ করুন',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ================= Body Section (List) =================
                  Expanded(
                    child: StreamBuilder<List<NotificationModel>>(
                      stream: _notificationService.notificationStream,
                      builder: (context, snapshot) {
                        final notifications = _notificationService.allNotifications;

                        if (notifications.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 60), // Extra bottom padding for alert
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(notifications[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ================= Custom Local Alert (Toast) =================
              // This ensures the alert is visible ON TOP of the dialog content
              if (_localAlertMessage != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _localAlertMessage!,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            "কোন বিজ্ঞপ্তি নেই",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _checkNotificationsManually,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text("রিফ্রেশ করুন"),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade300 : notification.getPriorityColor().withOpacity(0.5),
        ),
        boxShadow: [
          if (!notification.isRead)
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _notificationService.markAsRead(notification.id);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.getPriorityColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(notification.icon, color: notification.getPriorityColor(), size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(notification.message, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.actionRequired,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                        ),
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
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

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'এখনই';
    if (difference.inMinutes < 60) return '${difference.inMinutes} মি আগে';
    if (difference.inHours < 24) return '${difference.inHours} ঘন্টা আগে';
    return '${difference.inDays} দিন আগে';
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _notificationService.stopMonitoring();
    super.dispose();
  }
}