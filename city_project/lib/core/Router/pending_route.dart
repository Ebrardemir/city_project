import 'package:flutter/foundation.dart';

/// PendingRoute: login sonrası yönlendirme için bildirim/deeplink hedefini tutar
class PendingTarget {
  final String route;
  final Map<String, dynamic>? params;
  final DateTime createdAt;

  PendingTarget({required this.route, this.params})
    : createdAt = DateTime.now();
}

class PendingRoute extends ChangeNotifier {
  PendingTarget? _target;
  PendingTarget? get target => _target;

  void set(PendingTarget target) {
    _target = target;
    notifyListeners();
  }

  PendingTarget? consumeIfValid(Duration ttl) {
    if (_target == null) return null;
    if (DateTime.now().difference(_target!.createdAt) > ttl) {
      _target = null;
      return null;
    }
    final result = _target;
    _target = null;
    notifyListeners();
    return result;
  }

  void clear() {
    _target = null;
    notifyListeners();
  }
}
