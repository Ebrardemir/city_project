class CreateReportDraft {
  int? categoryId;
  String? categoryName;
  String description = '';

  double? lat;
  double? lng;

  // Foto backend gelince upload edilecek, şimdilik local path tutuyoruz
  String? localImagePath;

  bool get isValid =>
      categoryId != null &&
      description.trim().length >= 10 &&
      lat != null &&
      lng != null &&
      localImagePath != null;
}
