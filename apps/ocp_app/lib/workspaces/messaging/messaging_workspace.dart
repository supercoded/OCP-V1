import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/widgets/message_list_tile.dart';
import 'package:ocp_core/ocp_core.dart';

/// Messaging workspace — send/receive text over the mock ODP session.
class MessagingWorkspace extends StatefulWidget {
  const MessagingWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  State<MessagingWorkspace> createState() => _MessagingWorkspaceState();
}

class _MessagingWorkspaceState extends State<MessagingWorkspace> {
  final _controller = TextEditingController();
  late Stream<Message> _updates;

  @override
  void initState() {
    super.initState();
    _updates = widget.coordinator.core.messagingService.messageUpdates;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    await widget.coordinator.deviceSession.sendText(body);
    _controller.clear();
    if (mounted) setState(() {});
  }

  Future<void> _simulateInbound() async {
    await widget.coordinator.mockDeviceLoop.emitText('mesh ping');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = widget.coordinator.core.sessionService.state;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Session: ${sessionState.name} · '
            '${widget.coordinator.core.sessionService.activeDeviceId ?? 'none'}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<Message>(
              stream: _updates,
              builder: (context, _) {
                return FutureBuilder<List<Message>>(
                  future: widget.coordinator.core.messagingService
                      .conversationHistory(OcpAppCoordinator.defaultConversationId),
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Send a message — the mock device echoes it back over ODP.',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          MessageListTile(message: messages[index]),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              IconButton(
                onPressed: _simulateInbound,
                icon: const Icon(Icons.download),
                tooltip: 'Simulate inbound mesh message',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
