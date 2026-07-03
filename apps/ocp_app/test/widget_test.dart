import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocp_app/widgets/message_list_tile.dart';
import 'package:ocp_core/ocp_core.dart';

void main() {
  testWidgets('message list tile renders body', (tester) async {
    final message = Message(
      messageId: '1',
      conversationId: 'c',
      workspaceId: 'w',
      senderId: 's',
      body: 'hello',
      status: MessageStatus.pending,
      createdAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MessageListTile(message: message))),
    );
    expect(find.text('hello'), findsOneWidget);
  });
}
