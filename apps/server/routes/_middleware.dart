import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/admin/admin_service.dart';
import 'package:esquinita_server/app.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/devices/device_service.dart';
import 'package:esquinita_server/sync/pull_service.dart';
import 'package:esquinita_server/sync/push_service.dart';

Handler middleware(Handler handler) => handler
    .use(provider<AdminService>((_) => AdminService(appPool)))
    .use(provider<PushService>((_) => PushService(appPool)))
    .use(provider<PullService>((_) => PullService(appPool)))
    .use(provider<DeviceService>((_) => DeviceService(appPool)))
    .use(provider<AuthService>((_) => appAuth));
