import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apex_hires/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors', () {
    test('should have correct primary color', () {
      expect(AppColors.primary, const Color(0xFF0A66C2));
    });

    test('should have correct dark text color', () {
      expect(AppColors.darkText, const Color(0xFF0F172A));
    });

    test('should have correct background color', () {
      expect(AppColors.background, const Color(0xFFF8FAFC));
    });

    test('should have correct surface color', () {
      expect(AppColors.surface, const Color(0xFFFFFFFF));
    });

    test('should have correct pipeline status colors', () {
      expect(AppColors.applied, const Color(0xFF3B82F6));
      expect(AppColors.shortlisted, const Color(0xFF8B5CF6));
      expect(AppColors.interviewing, const Color(0xFFF59E0B));
      expect(AppColors.hired, const Color(0xFF10B981));
      expect(AppColors.rejected, const Color(0xFFEF4444));
    });

    test('getStatusColor should return correct color for each status', () {
      expect(AppColors.getStatusColor('applied'), AppColors.applied);
      expect(AppColors.getStatusColor('shortlisted'), AppColors.shortlisted);
      expect(AppColors.getStatusColor('interviewing'), AppColors.interviewing);
      expect(AppColors.getStatusColor('hired'), AppColors.hired);
      expect(AppColors.getStatusColor('rejected'), AppColors.rejected);
      expect(AppColors.getStatusColor('unknown'), AppColors.lightText);
    });

    test('getStatusLabel should return correct label for each status', () {
      expect(AppColors.getStatusLabel('applied'), 'Applied');
      expect(AppColors.getStatusLabel('shortlisted'), 'Shortlisted');
      expect(AppColors.getStatusLabel('interviewing'), 'Interviewing');
      expect(AppColors.getStatusLabel('hired'), 'Hired');
      expect(AppColors.getStatusLabel('rejected'), 'Rejected');
      expect(AppColors.getStatusLabel('custom'), 'custom');
    });

    test('should have correct accent color', () {
      expect(AppColors.accent, const Color(0xFF0EA5E9));
    });

    test('should have correct error color', () {
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('should have correct success color', () {
      expect(AppColors.success, const Color(0xFF10B981));
    });

    test('should have correct warning color', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });
  });
}
