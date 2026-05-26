import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';

typedef WsHandler = void Function(dynamic data);

class SocketClient {
  SocketClient(this._config);

  final ApiConfig _config;
  io.Socket? _socket;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get status => _statusController.stream;
  bool _connected = false;
  bool get isConnected => _connected;

  void connect({Map<String, WsHandler> handlers = const {}}) {
    disconnect();
    final socket = io.io(
      _config.wsUrl,
      io.OptionBuilder()
          .setPath('/v1/ws')
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setAuth({'token': _config.token})
          .build(),
    );

    socket.onConnect((_) {
      _connected = true;
      _statusController.add(true);
    });
    socket.onDisconnect((_) {
      _connected = false;
      _statusController.add(false);
    });
    socket.onConnectError((err) {
      _connected = false;
      _statusController.add(false);
    });

    for (final entry in handlers.entries) {
      socket.on(entry.key, entry.value);
    }

    socket.connect();
    _socket = socket;
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    if (_connected) {
      _connected = false;
      _statusController.add(false);
    }
  }

  Future<void> close() async {
    disconnect();
    await _statusController.close();
  }
}
