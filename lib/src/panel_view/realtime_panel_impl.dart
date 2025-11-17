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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'panel_view.dart';

/// A concrete, WebSocket-backed implementation of [RealtimePanelView]
/// intended for testing/demo. Consumers in production may provide a
/// different implementation.
class RealtimePanelViewImpl implements RealtimePanelView {
  WebSocket? _ws;
  final Map<String, List<void Function(Map<String, dynamic>)>> _listeners = {};
  Timer? _reconnectTimer;
  Uri? _uri;
  bool _closedByUser = false;

  @override
  bool get isConnected => _ws != null;

  @override
  Future<void> connect(String url) async {
    _closedByUser = false;
    _uri = Uri.parse(url);
    await _open();
  }

  Future<void> _open() async {
    if (_uri == null) throw StateError('No URI provided');
    _ws = await WebSocket.connect(_uri.toString());
    _ws!.listen(_onMessage, onDone: _onDone, onError: _onError, cancelOnError: true);
    _emitLocal('connected', {'url': _uri.toString()});
  }

  @override
  Future<void> disconnect() async {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
    _emitLocal('disconnected', {});
  }

  void _onMessage(dynamic raw) {
    try {
      final Map<String, dynamic> parsed = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = parsed['type'] as String? ?? '';
      final payload = (parsed['payload'] is Map) ? Map<String, dynamic>.from(parsed['payload']) : <String, dynamic>{'data': parsed['payload']};
      _dispatch(type, payload);
    } catch (e) {
      _dispatch('error', {'error': e.toString()});
    }
  }

  void _onDone() {
    _ws = null;
    _emitLocal('closed', {});
    if (!_closedByUser && _uri != null) {
      _reconnectTimer = Timer(const Duration(seconds: 2), () async {
        try {
          await connect(_uri!.toString());
        } catch (_) {}
      });
    }
  }

  void _onError(Object error) {
    _emitLocal('error', {'error': error.toString()});
    _ws = null;
  }

  void _dispatch(String type, Map<String, dynamic> payload) {
    final listeners = _listeners[type];
    if (listeners != null) {
      for (final l in List.from(listeners)) {
        try {
          l(payload);
        } catch (_) {}
      }
    }
  }

  void _emitLocal(String type, Map<String, dynamic> payload) => _dispatch(type, payload);

  @override
  void on(String event, void Function(Map<String, dynamic>) handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
  }

  @override
  void off(String event, void Function(Map<String, dynamic>) handler) {
    final list = _listeners[event];
    list?.remove(handler);
    if (list != null && list.isEmpty) _listeners.remove(event);
  }

  @override
  void send(String type, Map<String, dynamic> payload) {
    final msg = jsonEncode({'type': type, 'payload': payload});
    try {
      _ws?.add(msg);
    } catch (e) {
      _emitLocal('error', {'error': e.toString()});
    }
  }

  @override
  void sendStarted({required String url}) => send('started', {'url': url});

  @override
  void requestPodsList() => send('request_pods', {});

  @override
  void requestPodDetails(String name) => send('request_pod_details', {'name': name});

  @override
  void sendShowPod(String name) => send('show_pod', {'name': name});

  @override
  void sendCommand(String command, [Map<String, dynamic>? args]) => send('command', {'command': command, 'args': args ?? {}});
}
