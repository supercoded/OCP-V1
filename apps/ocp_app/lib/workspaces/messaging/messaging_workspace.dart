import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/widgets/message_list_tile.dart';

/// Messaging workspace — direct/group messages and offline queue.
class MessagingWorkspace extends StatefulWidget {
  const MessagingWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  State<MessagingWorkspace> createState() => _MessagingWorkspaceState();
}

class _MessagingWorkspaceState extends State<MessagingWorkspace> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    await widget.coordinator.core.messagingService.sendMessage(
      messageId: DateTime.now().microsecondsSinceEpoch.toString(),
      conversationId: 'default',
      workspaceId: 'default',
      senderId: 'local',
      body: body,
    );
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: widget.coordinator.core.messagingService
                  .conversationHistory('default'),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      MessageListTile(message: messages[index]),
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
                    hintText: 'Message (offline queue)',
                  ),
                ),
              ),
              IconButton(onPressed: _send, icon: const Icon(Icons.send)),
            ],
          ),
        ],
      ),
    );
  }
}
