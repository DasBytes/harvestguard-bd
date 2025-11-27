import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:harvestguard_bd/widgets/batch_card.dart';

class BanglaAdvisoryCard extends StatelessWidget {
  final BatchModel batch;
  const BanglaAdvisoryCard({super.key, required this.batch});

  Color get _riskColor {
    if (batch.riskLevel.contains('উচ্চ')) return Colors.red;
    if (batch.riskLevel.contains('স্বল্প')) return Colors.green;
    return Colors.orange;
  }

  IconData get _riskIcon {
    if (batch.riskLevel.contains('উচ্চ')) return Icons.warning_amber;
    if (batch.riskLevel.contains('স্বল্প')) return Icons.check_circle_outline;
    return Icons.lightbulb_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _riskColor.withOpacity(0.1),
        border: Border.all(color: _riskColor, width: 2),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_riskIcon, color: _riskColor, size: 30.sp)
              .animate(
                target: batch.riskLevel.contains('উচ্চ') ? 1.0 : 0.0,
                onPlay: (controller) => controller.loop(reverse: true),
              )
              .shake(duration: 1000.ms, hz: 3)
              .scale(delay: 50.ms, duration: 500.ms),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A4: ETCL পূর্বাভাস',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _riskColor,
                  ),
                ),
                Text(
                  batch.riskLevel,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _riskColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'পরামর্শ: ${batch.advisory}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
