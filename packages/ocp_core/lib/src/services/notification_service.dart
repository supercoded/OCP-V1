import 'package:logging/logging.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';
import 'package:ocp_core/src/models/message.dart';
import 'package:ocp_core/src/repositories/message_repository.dart';

/// In-app notification event.
class OcpNotification {
  const OcpNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
}

/// Dispatches in-app notifications.
class NotificationService {
  NotificationService({Logger? logger})
      : _logger = logger ?? ocpLogger('notification');

  final Logger _logger;
  final List<OcpNotification> _queue = [];

  List<OcpNotification> get pending => List.unmodifiable(_queue);

  void notify({required String id, required String title, required String body}) {
    _queue.add(
      OcpNotification(
        id: id,
        title: title,
        body: body,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    _logger.info('Notification queued: $title');
  }

  OcpNotification? popNext() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  void clear() => _queue.clear();
}
