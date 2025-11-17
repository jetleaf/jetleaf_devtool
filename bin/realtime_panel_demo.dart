// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:io';
import 'dart:convert';

import 'package:jetleaf_devtool/src/panel_view/realtime_panel_impl.dart';

/// Demo that starts a local websocket server and shows how RealtimePanelViewImpl
/// interacts. Run with `dart run bin/realtime_panel_demo.dart` from the package
/// root.

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  print('Demo WebSocket server listening on ws://127.0.0.1:${server.port}');

  server.listen((HttpRequest req) async {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = await WebSocketTransformer.upgrade(req);
      print('Client connected');
      socket.listen((data) {
        print('Received from client: $data');
        try {
          final parsed = jsonDecode(data as String) as Map<String, dynamic>;
          final type = parsed['type'] as String? ?? '';
          final payload = parsed['payload'] ?? {};

          if (type == 'request_pods') {
            final reply = jsonEncode({
              'type': 'pods',
              'payload': {
                'items': ['user_service', 'api_gateway', 'cache_manager']
              }
            });
            socket.add(reply);
          }

          if (type == 'request_pod_details') {
            final name = (payload is Map && payload['name'] is String) ? payload['name'] as String : 'unknown';
            final reply = jsonEncode({
              'type': 'podDetails',
              'payload': {
                'name': name,
                'cpu': 12,
                'memory': 256,
                'uptime': 99.9
              }
            });
            socket.add(reply);
          }
        } catch (e) {
          print('Error handling message: $e');
        }
      }, onDone: () => print('client disconnected'));
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  });

  // Create a client implementation and connect to the server for demo
  final client = RealtimePanelViewImpl();
  final wsUrl = 'ws://127.0.0.1:${server.port}';
  client.on('connected', (p) => print('[client] connected: $p'));
  client.on('pods', (p) => print('[client] pods: ${p['items']}'));
  client.on('podDetails', (p) => print('[client] pod details: $p'));

  await client.connect(wsUrl);
  print('Client connected to $wsUrl');

  // Request pods from the server and then request details for one
  client.requestPodsList();
  await Future.delayed(Duration(seconds: 1));
  client.requestPodDetails('user_service');

  // Keep demo running for a short while
  await Future.delayed(Duration(seconds: 3));
  await client.disconnect();
  await server.close(force: true);
  print('Demo complete');
}
