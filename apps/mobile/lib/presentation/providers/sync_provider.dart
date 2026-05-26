import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/socket_client.dart';
import 'settings_provider.dart';
import 'emails_provider.dart';

final socketProvider = Provider<SocketClient>((ref) {
  final client = SocketClient(ref.watch(apiConfigProvider));
  ref.onDispose(client.close);
  return client;
});

final syncConnectionProvider = StateProvider<bool>((ref) => false);

final syncBootstrapProvider = Provider<void>((ref) {
  final socket = ref.watch(socketProvider);

  void invalidateEmails(dynamic _) {
    ref.invalidate(inboxProvider);
    ref.invalidate(sentProvider);
  }

  socket.connect(handlers: {
    'email.sent': invalidateEmails,
    'email.received': invalidateEmails,
    'email.delivered': invalidateEmails,
    'email.bounced': invalidateEmails,
    'email.opened': invalidateEmails,
    'email.clicked': invalidateEmails,
    'email.failed': invalidateEmails,
  });

  final sub = socket.status.listen((connected) {
    ref.read(syncConnectionProvider.notifier).state = connected;
  });
  ref.onDispose(sub.cancel);
});
