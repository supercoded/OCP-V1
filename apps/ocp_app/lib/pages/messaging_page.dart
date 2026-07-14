import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/messaging_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/network_provider.dart';
import '../widgets/status_lamp.dart';
import '../widgets/analog_button.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final _draftController = TextEditingController();
  final _destNodeController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _draftController.dispose();
    _destNodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final messaging = context.watch<MessagingProvider>();
    final conn = context.watch<ConnectionProvider>();
    final network = context.watch<NetworkProvider>();

    final channelMessages = messaging.messagesForChannel(messaging.selectedChannel);

    // Auto-scroll when new messages arrive
    if (channelMessages.isNotEmpty) {
      _scrollToBottom();
    }

    return Row(
      children: [
        // Channel sidebar
        _buildChannelSidebar(context, messaging, conn),
        // Thread area
        Expanded(
          child: Column(
            children: [
              _buildHeader(context, messaging, conn),
              if (!conn.connected)
                _buildOfflineWarning(),
              if (messaging.sendError != null)
                _buildErrorBanner(messaging.sendError!),
              Expanded(
                child: _buildMessageList(context, channelMessages, messaging, network, conn),
              ),
              _buildInputArea(context, messaging, conn),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelSidebar(BuildContext context, MessagingProvider messaging, ConnectionProvider conn) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: OcpColors.ocpPanel,
        border: Border(right: BorderSide(color: OcpColors.ocpBorder)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: OcpColors.ocpBorder)),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              'CHANNELS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: OcpColors.ocpBright,
              ),
            ),
          ),
          // Channel list
          Expanded(
            child: ListView.builder(
              itemCount: MessagingProvider.channels.length,
              itemBuilder: (context, index) {
                final ch = MessagingProvider.channels[index];
                final isActive = messaging.selectedChannel == ch.id;
                final unread = messaging.unreadCount(ch.id);
                final lastMsg = messaging.lastMessageForChannel(ch.id);

                return GestureDetector(
                  onTap: () => messaging.selectChannel(ch.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? OcpColors.ocpPanel2 : Colors.transparent,
                      border: Border(
                        bottom: const BorderSide(color: OcpColors.ocpBorder, width: 0.5),
                        left: isActive
                            ? const BorderSide(color: OcpColors.ocpBright, width: 2)
                            : BorderSide.none,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ch.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? OcpColors.ocpBright : OcpColors.ocpText,
                              ),
                            ),
                            if (unread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: OcpColors.ocpBright,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: OcpColors.ocpBg,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (lastMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '${lastMsg.outgoing ? 'You: ' : ''}${lastMsg.text}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: OcpColors.ocpDim,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Destination node input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: OcpColors.ocpBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESTINATION NODE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: OcpColors.ocpDim,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _destNodeController,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                    color: OcpColors.ocpText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Broadcast (empty)',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: OcpColors.ocpDim.withAlpha(128),
                    ),
                    filled: true,
                    fillColor: OcpColors.ocpBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: OcpColors.ocpBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: OcpColors.ocpBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: OcpColors.ocpBright),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MessagingProvider messaging, ConnectionProvider conn) {
    final channelName = MessagingProvider.channels[messaging.selectedChannel].name;
    final threadMessages = messaging.messagesForChannel(messaging.selectedChannel);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: OcpColors.ocpPanel,
        border: Border(bottom: BorderSide(color: OcpColors.ocpBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            channelName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OcpColors.ocpBright,
            ),
          ),
          Row(
            children: [
              Text(
                '${threadMessages.length} messages',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  color: OcpColors.ocpDim,
                ),
              ),
              const SizedBox(width: 12),
              StatusLamp(connected: conn.connected),
              const SizedBox(width: 6),
              Text(
                conn.connected ? (conn.transportKind ?? 'connected') : 'offline',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  color: conn.connected ? OcpColors.ocpGreen : OcpColors.ocpRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: OcpColors.ocpRed.withAlpha(25),
      child: const Text(
        'No Meshtastic device connected — connect a node to send and receive messages.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: OcpColors.ocpRed),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: OcpColors.ocpRed.withAlpha(25),
      child: Text(
        error,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: OcpColors.ocpRed),
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    List<Message> messages,
    MessagingProvider messaging,
    NetworkProvider network,
    ConnectionProvider conn,
  ) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          conn.connected ? 'No messages yet. Send one below.' : 'Connect a Meshtastic device to start messaging.',
          style: const TextStyle(fontSize: 12, color: OcpColors.ocpDim),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        final isMe = m.outgoing || m.from == 'you' || m.from == '0';
        final senderName = isMe ? 'You' : network.resolveName(m.from);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.55,
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? OcpColors.ocpBright : OcpColors.ocpPanel2,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(8),
                        topRight: const Radius.circular(8),
                        bottomLeft: isMe ? const Radius.circular(8) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(8),
                      ),
                      border: isMe ? null : Border.all(color: OcpColors.ocpBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isMe ? OcpColors.ocpBg.withAlpha(179) : OcpColors.ocpBright,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: isMe ? OcpColors.ocpBg : OcpColors.ocpText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(m.timestamp),
                    style: const TextStyle(
                      fontSize: 9,
                      fontFamily: 'JetBrainsMono',
                      color: OcpColors.ocpDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, MessagingProvider messaging, ConnectionProvider conn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: OcpColors.ocpPanel,
        border: Border(top: BorderSide(color: OcpColors.ocpBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _draftController,
              enabled: conn.connected,
              onSubmitted: (_) => _handleSend(messaging, conn),
              style: const TextStyle(
                fontSize: 13,
                color: OcpColors.ocpText,
              ),
              decoration: InputDecoration(
                hintText: conn.connected ? 'Type message...' : 'No device connected',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: OcpColors.ocpDim.withAlpha(conn.connected ? 128 : 64),
                ),
                filled: true,
                fillColor: OcpColors.ocpBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: OcpColors.ocpBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: OcpColors.ocpBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: OcpColors.ocpBright),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: OcpColors.ocpBorder2.withAlpha(51)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnalogButton(
            onPressed: () => _handleSend(messaging, conn),
            child: const Text('Send', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _handleSend(MessagingProvider messaging, ConnectionProvider conn) {
    final text = _draftController.text.trim();
    if (text.isEmpty || !conn.connected) return;

    messaging.sendMessage(
      text: text,
      channel: messaging.selectedChannel,
      destinationNodeId: _destNodeController.text.trim().isNotEmpty
          ? _destNodeController.text.trim()
          : null,
    );
    _draftController.clear();
  }
}