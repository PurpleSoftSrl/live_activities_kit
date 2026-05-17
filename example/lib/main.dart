import 'dart:async';

import 'package:flutter/material.dart';
import 'package:live_activities_kit/live_activities.dart';
import 'package:live_activities_kit/live_activities_platform_interface.dart';

void main() => runApp(const LiveActivitiesApp());

class LiveActivitiesApp extends StatelessWidget {
  const LiveActivitiesApp({super.key});
  @override Widget build(BuildContext c) => const MaterialApp(home: LiveActivitiesDemo());
}

class LiveActivitiesDemo extends StatefulWidget {
  const LiveActivitiesDemo({super.key});
  @override State<LiveActivitiesDemo> createState() => _LiveActivitiesDemoState();
}

class _LiveActivitiesDemoState extends State<LiveActivitiesDemo> {
  bool _supported = false; String _status = ''; String _activeId = ''; StreamSubscription<void>? _timerSub;

  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final ok = await LiveActivity.isSupported;
    setState(() { _supported = ok; _status = ok ? '✅ Supported' : '❌ Not supported'; });
    LiveActivity.onAction.listen((action) {
      setState(() => _status = '🔔 Action tapped: $action');
      if (action == 'cancel') LiveActivity.end(_activeId);
    });
  }

  Future<void> _start() async {
    final id = 'order-${DateTime.now().millisecond}';
    final ok = await LiveActivity.start(
      id: id,
      data: const LiveActivityData(title: 'Preparing order', subtitle: 'Estimated 5 min', progress: 0.2),
    );
    setState(() { _activeId = ok != null ? id : ''; _status = ok != null ? '✅ Started' : '❌ Failed'; });
  }

  Future<void> _startTimer() async {
    final id = 'eta-${DateTime.now().millisecond}';
    await LiveActivity.timer(id: id, title: 'Delivery arriving', subtitle: 'On the way', duration: const Duration(seconds: 30));
    setState(() { _activeId = id; _status = '⏱ Timer started'; });
  }

  Future<void> _startWithActions() async {
    final id = 'act-${DateTime.now().millisecond}';
    await LiveActivity.startWithActions(
      id: id,
      data: const LiveActivityData(title: 'Confirm order?', progress: 0.5),
      actions: {'confirm': '✅ Confirm', 'cancel': '❌ Cancel'},
    );
    setState(() { _activeId = id; _status = '📋 With actions'; });
  }

  Future<void> _update() async {
    if (_activeId.isEmpty) return;
    final ok = await LiveActivity.update(id: _activeId, data: const LiveActivityData(title: 'Ready!', progress: 1.0));
    setState(() => _status = ok ? '✅ Updated' : '❌ Failed');
  }

  Future<void> _end() async {
    if (_activeId.isEmpty) return;
    _timerSub?.cancel();
    await LiveActivity.end(_activeId);
    setState(() { _activeId = ''; _status = '✅ Ended'; });
  }

  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Live Activities')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(_status, textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleMedium),
      const SizedBox(height: 20),
      if (_supported && _activeId.isEmpty) ...[_btn('Basic: Start', _start), const SizedBox(height: 10)],
      if (_activeId.isEmpty) ...[_btn('⏱ Timer (30s countdown)', _startTimer), const SizedBox(height: 10)],
      if (_activeId.isEmpty) ...[_btn('📋 With action buttons', _startWithActions), const SizedBox(height: 10)],
      if (_activeId.isNotEmpty) ...[_btn('Update', _update), const SizedBox(height: 10), _btn('End', _end)],
      const SizedBox(height: 30), OutlinedButton(onPressed: _check, child: const Text('Re-check support')),
    ]),
  );

  Widget _btn(String label, VoidCallback fn) => ElevatedButton(onPressed: fn, child: Text(label));
}

