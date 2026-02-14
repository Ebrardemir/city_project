import 'package:flutter/foundation.dart';
import '../../MyReports/model/report_model.dart';
import '../service/nearby_reports_service.dart';

enum NearbyViewMode { list, map }

class NearbyReportsViewModel extends ChangeNotifier {
  final NearbyReportsService _service;
  NearbyReportsViewModel(this._service);

  bool loading = false;
  List<ReportModel> _all = [];
  List<ReportModel> visible = [];

  NearbyViewMode mode = NearbyViewMode.list;

  ReportStatus? statusFilter; // null => tümü
  int? categoryFilter; // null => tümü (categoryId)

  Future<void> load() async {
    loading = true;
    notifyListeners();
    _all = await _service.fetchNearby();
    _apply();
    loading = false;
    notifyListeners();
  }

  void setMode(NearbyViewMode m) {
    mode = m;
    notifyListeners();
  }

  void setStatusFilter(ReportStatus? s) {
    statusFilter = s;
    _apply();
    notifyListeners();
  }

  void setCategoryFilter(int? id) {
    categoryFilter = id;
    _apply();
    notifyListeners();
  }

  void _apply() {
    var list = _all;

    if (statusFilter != null) {
      list = list.where((e) => e.status == statusFilter).toList();
    }
    if (categoryFilter != null) {
      list = list.where((e) => e.categoryId == categoryFilter).toList();
    }

    visible = list;
  }
}
