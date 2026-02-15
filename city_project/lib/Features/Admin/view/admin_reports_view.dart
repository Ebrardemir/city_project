import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Home/model/report_model.dart';
import '../../Municipality/service/municipality_service.dart';

/// Admin Reports View - Tüm raporları yönetme ekranı
/// Admin kullanıcıları için tüm sistem raporlarını görüntüleme ve bulk actions
class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  final MunicipalityService _service = MunicipalityService();
  
  // Filters
  ReportStatus? _statusFilter;
  ReportCategory? _categoryFilter;
  
  // Selection for bulk actions
  final Set<String> _selectedReportIds = {};
  bool _isSelectionMode = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: _isSelectionMode
            ? Text('${_selectedReportIds.length} Rapor Seçildi')
            : const Text('📋 Tüm Raporlar'),
        actions: [
          if (_isSelectionMode) ...[
            // Bulk approve button
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _selectedReportIds.isEmpty ? null : _bulkApprove,
              tooltip: 'Seçilenleri Onayla',
            ),
            // Bulk fake button
            IconButton(
              icon: const Icon(Icons.report_problem),
              onPressed: _selectedReportIds.isEmpty ? null : _bulkMarkAsFake,
              tooltip: 'Seçilenleri Fake İşaretle',
            ),
            // Cancel selection
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelSelection,
              tooltip: 'İptal',
            ),
          ] else ...[
            // Filter button
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
              tooltip: 'Filtrele',
            ),
            // Selection mode toggle
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
              tooltip: 'Toplu İşlem',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          
          // Reports list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Hata: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Rapor bulunamadı',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
                final reports = docs.map((doc) {
                  try {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return ReportModel.fromJson(data);
                  } catch (e) {
                    print('⚠️ Rapor parse hatası (${doc.id}): $e');
                    return null;
                  }
                }).whereType<ReportModel>().toList();
                
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final isSelected = _selectedReportIds.contains(report.id);
                    
                    return _buildReportCard(report, isSelected);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build Firestore query based on filters
  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(100);
    
    // Apply status filter
    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter!.name);
    }
    
    // Apply category filter
    if (_categoryFilter != null) {
      query = query.where('category', isEqualTo: _categoryFilter!.name);
    }
    
    return query.snapshots();
  }
  
  /// Filter chips at the top
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Clear all filters
            if (_statusFilter != null || _categoryFilter != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: const Text('Filtreleri Temizle'),
                  avatar: const Icon(Icons.clear_all, size: 18),
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _categoryFilter = null;
                    });
                  },
                ),
              ),
            
            // Status chip
            FilterChip(
              label: Text(_statusFilter?.label ?? 'Tüm Durumlar'),
              selected: _statusFilter != null,
              onSelected: (_) => _showStatusFilterDialog(),
            ),
            
            const SizedBox(width: 8),
            
            // Category chip
            FilterChip(
              label: Text(_categoryFilter?.label ?? 'Tüm Kategoriler'),
              selected: _categoryFilter != null,
              onSelected: (_) => _showCategoryFilterDialog(),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Report card with selection support
  Widget _buildReportCard(ReportModel report, bool isSelected) {
    final statusColor = _getStatusColor(report.status);
    final categoryIcon = _getCategoryIcon(report.category);
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.purple, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(report.id);
          } else {
            context.pushNamed('report-detail', extra: report);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedReportIds.add(report.id);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(report.id),
                  ),
                ),
              
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: report.imageUrlBefore ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 32),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Report details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and status
                    Row(
                      children: [
                        Icon(categoryIcon, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          report.category.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            report.status.label,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: statusColor.withOpacity(0.2),
                          labelStyle: TextStyle(color: statusColor),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Location and support
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${report.district}, ${report.city}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${report.supportCount}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action button (only in non-selection mode)
              if (!_isSelectionMode)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'approve') {
                      _approveReport(report);
                    } else if (value == 'fake') {
                      _markAsFake(report);
                    }
                  },
                  itemBuilder: (context) => [
                    if (report.status == ReportStatus.pending)
                      const PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Onayla'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'fake',
                      child: Row(
                        children: [
                          Icon(Icons.report_problem, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Fake İşaretle'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Get color for status
  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.approved:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.fake:
        return Colors.red;
      case ReportStatus.flagged:
        return Colors.yellow;
    }
  }
  
  /// Get icon for category
  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.road:
        return Icons.construction;
      case ReportCategory.park:
        return Icons.park;
      case ReportCategory.water:
        return Icons.water_drop;
      case ReportCategory.garbage:
        return Icons.delete;
      case ReportCategory.lighting:
        return Icons.lightbulb;
      case ReportCategory.other:
        return Icons.more_horiz;
    }
  }
  
  /// Toggle selection
  void _toggleSelection(String reportId) {
    setState(() {
      if (_selectedReportIds.contains(reportId)) {
        _selectedReportIds.remove(reportId);
        // Exit selection mode if no items selected
        if (_selectedReportIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedReportIds.add(reportId);
      }
    });
  }
  
  /// Cancel selection mode
  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedReportIds.clear();
    });
  }
  
  /// Show filter sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtreler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Durum Filtresi'),
              subtitle: Text(_statusFilter?.label ?? 'Tümü'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showStatusFilterDialog();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Kategori Filtresi'),
              subtitle: Text(_categoryFilter?.label ?? 'Tümü'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showCategoryFilterDialog();
              },
            ),
            
            if (_statusFilter != null || _categoryFilter != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _categoryFilter = null;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Filtreleri Temizle'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Show status filter dialog
  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum Filtresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ReportStatus?>(
              title: const Text('Tümü'),
              value: null,
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() => _statusFilter = value);
                Navigator.pop(context);
              },
            ),
            ...ReportStatus.values.map((status) => RadioListTile<ReportStatus?>(
              title: Text(status.label),
              value: status,
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() => _statusFilter = value);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
  
  /// Show category filter dialog
  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Filtresi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ReportCategory?>(
                title: const Text('Tümü'),
                value: null,
                groupValue: _categoryFilter,
                onChanged: (value) {
                  setState(() => _categoryFilter = value);
                  Navigator.pop(context);
                },
              ),
              ...ReportCategory.values.map((category) => RadioListTile<ReportCategory?>(
                title: Text(category.label),
                value: category,
                groupValue: _categoryFilter,
                onChanged: (value) {
                  setState(() => _categoryFilter = value);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Approve single report
  Future<void> _approveReport(ReportModel report) async {
    try {
      await _service.approveReport(report.id, 'admin');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapor onaylandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Mark single report as fake
  Future<void> _markAsFake(ReportModel report) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Fake İşaretle'),
        content: const Text('Bu raporu fake olarak işaretlemek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Fake İşaretle'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _service.markAsFake(report.id, 'admin', reason: 'Admin tarafından fake işaretlendi');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapor fake olarak işaretlendi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Bulk approve selected reports
  Future<void> _bulkApprove() async {
    if (_selectedReportIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Onaylama'),
        content: Text('${_selectedReportIds.length} raporu onaylamak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    int successCount = 0;
    int errorCount = 0;
    
    for (final reportId in _selectedReportIds) {
      try {
        await _service.approveReport(reportId, 'admin');
        successCount++;
      } catch (e) {
        print('⚠️ Toplu onaylama hatası ($reportId): $e');
        errorCount++;
      }
    }
    
    _cancelSelection();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $successCount rapor onaylandı${errorCount > 0 ? ", $errorCount hata" : ""}'),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }
  
  /// Bulk mark as fake
  Future<void> _bulkMarkAsFake() async {
    if (_selectedReportIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Toplu Fake İşaretleme'),
        content: Text('${_selectedReportIds.length} raporu fake olarak işaretlemek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Fake İşaretle'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    int successCount = 0;
    int errorCount = 0;
    
    for (final reportId in _selectedReportIds) {
      try {
        await _service.markAsFake(reportId, 'admin', reason: 'Admin tarafından toplu fake işaretleme');
        successCount++;
      } catch (e) {
        print('⚠️ Toplu fake işaretleme hatası ($reportId): $e');
        errorCount++;
      }
    }
    
    _cancelSelection();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $successCount rapor fake işaretlendi${errorCount > 0 ? ", $errorCount hata" : ""}'),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.red,
        ),
      );
    }
  }
}
