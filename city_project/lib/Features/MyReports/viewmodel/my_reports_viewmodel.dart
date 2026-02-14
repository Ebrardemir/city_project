import 'package:flutter/foundation.dart';
import '../model/report_model.dart';
import '../service/my_reports_service.dart';

class MyReportsViewModel extends ChangeNotifier {
  final MyReportsService _service;
  MyReportsViewModel(this._service);

  bool loading = false;
  List<ReportModel> _all = [];
  List<ReportModel> visible = [];

  ReportStatus? selectedStatus; // null => tümü

  Future<void> load() async {
    loading = true;
    notifyListeners();

    _all = await _service.fetchMyReports();
    _applyFilter();

    loading = false;
    notifyListeners();
  }

  void setFilter(ReportStatus? status) {
    selectedStatus = status;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (selectedStatus == null) {
      visible = List.of(_all);
    } else {
      visible = _all.where((e) => e.status == selectedStatus).toList();
    }
  }
}
