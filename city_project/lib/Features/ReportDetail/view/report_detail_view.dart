import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:city_project/Features/Home/model/report_model.dart';
import 'package:city_project/Features/MyReports/widgets/status_chip.dart';
import '../widgets/report_media_header.dart';
import '../widgets/report_timeline.dart';
import '../viewmodel/report_detail_viewmodel.dart';
import '../service/comment_service.dart';
import 'package:intl/intl.dart';

class ReportDetailView extends StatelessWidget {
  final ReportModel report;
  const ReportDetailView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportDetailViewModel(CommentService(), report.id),
      child: _ReportDetailContent(report: report),
    );
  }
}

class _ReportDetailContent extends StatefulWidget {
  final ReportModel report;

  const _ReportDetailContent({required this.report});

  @override
  State<_ReportDetailContent> createState() => _ReportDetailContentState();
}

class _ReportDetailContentState extends State<_ReportDetailContent> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAfter = (widget.report.imageUrlAfter ?? '').isNotEmpty;
    final isResolved = widget.report.status == ReportStatus.resolved;

    return Scaffold(
      appBar: AppBar(title: const Text('İhbar Detayı')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                // ✅ Görsel alan + üstüne durum etiketi
                Stack(
                  children: [
                    ReportMediaHeader(report: widget.report),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: StatusChip(status: widget.report.status),
                    ),
                    if (!isResolved)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Çözüm bekleniyor',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Başlık + kategori
                Text(
                  widget.report.category.label,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),

                // Açıklama kartı
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      widget.report.description,
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // AI Fake Detection skor (eğer var ise)
                if (widget.report.isFakeDetected == true)
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700], size: 22),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'AI Analiz Uyarısı',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Güvenilirlik: ${((widget.report.fakeConfidence ?? 0) * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sebep: ${widget.report.fakeReason?.label ?? 'Bilinmiyor'}',
                                  style: TextStyle(fontSize: 13, color: Colors.red[900]),
                                ),
                              ],
                            ),
                          ),
                          if (widget.report.aiDetectedLabels != null && widget.report.aiDetectedLabels!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 6,
                                children: widget.report.aiDetectedLabels!
                                    .take(5)
                                    .map(
                                      (label) => Chip(
                                        label: Text(label, style: const TextStyle(fontSize: 11)),
                                        backgroundColor: Colors.orange[100],
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                if (isResolved && hasAfter)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.compare, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Önce/Sonra karşılaştırması için sürgüyü kaydır.',
                              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!isResolved)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bu ihbar henüz çözülmedi. Belediye çözüm fotoğrafı yüklediğinde burada “Sonra” görseli de görünecek.',
                              style: TextStyle(color: cs.onSurfaceVariant, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Süreç (created/approved/resolved)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Süreç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        ReportTimeline(report: widget.report),
                        const SizedBox(height: 12),
                        Divider(color: cs.outlineVariant),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Destek: ${widget.report.supportCount}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Konum: ${widget.report.latitude.toStringAsFixed(5)}, ${widget.report.longitude.toStringAsFixed(5)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Yorumlar Başlığı
                const Text(
                  'Yorumlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Yorum Listesi
                Consumer<ReportDetailViewModel>(
                  builder: (context, vm, child) {
                    if (vm.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (vm.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                      );
                    }

                    if (vm.comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Henüz yorum yapılmamış. İlk yorumu sen yap!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vm.comments.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final comment = vm.comments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(
                              comment.userFullName.isNotEmpty ? comment.userFullName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            comment.userFullName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                comment.message,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd.MM.yyyy HH:mm').format(comment.createdAt),
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Yorum Ekleme Alanı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Yorum yap...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : () async {
                    final text = _commentController.text.trim();
                    if (text.isEmpty) return;

                    setState(() => _isSending = true);

                    final success = await context.read<ReportDetailViewModel>().addComment(text);

                    if (mounted) {
                      setState(() => _isSending = false);
                      if (success) {
                        _commentController.clear();
                        FocusScope.of(context).unfocus(); // Klavyeyi kapat
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yorum gönderilemedi.')),
                        );
                      }
                    }
                  },
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
