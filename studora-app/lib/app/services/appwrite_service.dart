import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';

import 'package:studora/app/services/logger_service.dart';

class AppwriteService extends GetxService {
  static const String _className = 'AppwriteService';
  static const String projectEndpoint = '';
  static const String projectId = '';

  final Client _client = Client()
    ..setEndpoint(
      projectEndpoint,
    ).setProject(projectId).setSelfSigned(status: true);

  late final Account _account = Account(_client);
  late final Databases _databases = Databases(_client);
  late final Storage _storage = Storage(_client);
  late final Realtime _realtime = Realtime(_client);
  late final Functions _functions = Functions(_client);

  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Storage get storage => _storage;
  Realtime get realtime => _realtime;
  Functions get functions => _functions;
  @override
  void onInit() {
    super.onInit();

    LoggerService.logInfo(
      _className,
      "onInit",
      'Initialized. Endpoint: ${_client.endPoint}, ProjectID: ${_client.config['project']}',
    );
  }

  RealtimeSubscription subscribe(
    List<String> channels,
    void Function(RealtimeMessage) callback,
  ) {
    final subscription = _realtime.subscribe(channels);
    subscription.stream.listen((response) {
      callback(response);
    });
    LoggerService.logInfo(
      _className,
      'subscribe',
      'Subscribed to channels: $channels',
    );
    return subscription;
  }
}
