import 'package:esquinita_app/devices/feedback/scan_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Android: success and error go to the native feedback channel',
    () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ScanFeedback.channel, (call) async {
            calls.add(call.method);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(ScanFeedback.channel, null),
      );
      await ScanFeedback.success();
      await ScanFeedback.error();
      expect(calls, ['success', 'error']);
    },
  );

  test(
    'without the native channel it stays silent instead of failing',
    () async {
      await ScanFeedback.success(); // no mock handler: MissingPluginException
    },
  );
}
