import 'package:city_project/Features/ReportDetail/model/comment_model.dart';
import 'package:flutter/material.dart';
import '../service/comment_service.dart';

class ReportDetailViewModel extends ChangeNotifier {
  final CommentService _service;
  final String reportId;

  List<CommentModel> comments = [];
  bool isLoading = false;
  String? errorMessage;

  ReportDetailViewModel(this._service, this.reportId) {
    _loadComments();
  }

  Future<void> _loadComments() async {
    isLoading = true;
    notifyListeners();

    try {
      comments = await _service.getComments(reportId);
    } catch (e) {
      errorMessage = 'Yorumlar yüklenirken hata: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addComment(String message) async {
    if (message.trim().isEmpty) return false;

    try {
      final success = await _service.addComment(reportId, message);
      if (success) {
        // Yorumları tekrar yükle
        await _loadComments();
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = 'Yorum eklenirken hata: $e';
      notifyListeners();
      return false;
    }
  }
}
