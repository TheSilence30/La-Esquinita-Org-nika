import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/app.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/sync/push_service.dart';

Handler middleware(Handler handler) => handler
    .use(provider<PushService>((_) => PushService(appPool)))
    .use(provider<AuthService>((_) => appAuth));
