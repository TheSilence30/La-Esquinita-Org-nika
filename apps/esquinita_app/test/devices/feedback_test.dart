import 'package:esquinita_app/devices/feedback/scan_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Android: success and error go to the native feedback channel',
    () async {
      final calls = <(String, Object?)>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ScanFeedback.channel, (call) async {
            calls.add((call.method, call.arguments));
            return null;
          });
      addTearDown(() {
        ScanFeedback.sound = true;
        ScanFeedback.vibrate = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(ScanFeedback.channel, null);
      });
      await ScanFeedback.success();
      await ScanFeedback.error();
      expect(calls.map((c) => c.$1), ['success', 'error']);
      expect(calls.first.$2, {'sound': true, 'vibrate': true});

      ScanFeedback.sound = false; // the user's switch
      await ScanFeedback.success();
      expect(calls.last.$2, {'sound': false, 'vibrate': true});

      ScanFeedback.vibrate = false;
      await ScanFeedback.success();
      expect(calls, hasLength(3)); // both off: nothing is sent
    },
  );

  test(
    'without the native channel it stays silent instead of failing',
    () async {
      await ScanFeedback.success(); // no mock handler: MissingPluginException
    },
  );
}
