import 'package:flutter_test/flutter_test.dart';
import 'package:guitarr_app/tools/icon_generator.dart';

void main() {
  group('Icon Generator Tests', () {
    testWidgets('should generate app icon successfully', (WidgetTester tester) async {
      // Generate the base icon
      final iconData = await IconGenerator.generateAppIcon();
      
      // Verify icon was generated
      expect(iconData, isNotNull);
      expect(iconData.length, greaterThan(0));
      
      print('Generated icon with ${iconData.length} bytes');
    });

    testWidgets('should generate iOS icons in all required sizes', (WidgetTester tester) async {
      // Generate iOS icons
      final iosIcons = await IconGenerator.generateIOSIcons();
      
      // Verify all required sizes are generated
      expect(iosIcons, isNotNull);
      expect(iosIcons.length, equals(15)); // 15 different iOS icon sizes
      
      // Check some specific sizes exist
      expect(iosIcons['Icon-1024.png'], isNotNull);
      expect(iosIcons['Icon-60@3x.png'], isNotNull);
      expect(iosIcons['Icon-40@2x.png'], isNotNull);
      
      print('Generated ${iosIcons.length} iOS icon variants');
    });

    testWidgets('should generate Android icons in all required sizes', (WidgetTester tester) async {
      // Generate Android icons
      final androidIcons = await IconGenerator.generateAndroidIcons();
      
      // Verify all required sizes are generated
      expect(androidIcons, isNotNull);
      expect(androidIcons.length, equals(6)); // 6 different Android icon sizes
      
      // Check some specific sizes exist
      expect(androidIcons['ic_launcher.png'], isNotNull);
      expect(androidIcons['mipmap-xxxhdpi/ic_launcher.png'], isNotNull);
      expect(androidIcons['mipmap-mdpi/ic_launcher.png'], isNotNull);
      
      print('Generated ${androidIcons.length} Android icon variants');
    });
  });
}