import 'package:integration_test/integration_test_driver.dart';

// Runs integration_test/ on a device and saves what the test reports in
// build/integration_response_data.json.
Future<void> main() => integrationDriver();
