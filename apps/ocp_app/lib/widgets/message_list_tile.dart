import 'package:flutter/material.dart';
import 'package:ocp_core/ocp_core.dart';

/// Presentation-only message list item.
class MessageListTile extends StatelessWidget {
  const MessageListTile({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(message.body),
      subtitle: Text('${message.status.name} · ${message.senderId}'),
    );
  }
}
