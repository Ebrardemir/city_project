import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/municipality_viewmodel.dart';
import '../../Home/model/report_model.dart';
import 'resolve_report_view.dart';

/// Belediye Dashboard - Ana yönetim ekranı
/// Belediye yetkililerinin raporları görüntüleyip yönettiği ekran
class MunicipalityDashboardView extends StatefulWidget {
  const MunicipalityDashboardView({super.key});

  @override
  State<MunicipalityDashboardView> createState() => _MunicipalityDashboardViewState();
}

class _MunicipalityDashboardViewState extends State<MunicipalityDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MunicipalityViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏛️ Belediye Yönetim Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugDialog(context),
            tooltip: 'Debug: Belediye Değiştir',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filtrele',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MunicipalityViewModel>().refresh();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Consumer<MunicipalityViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Raporlar yükleniyor...'),
                ],
              ),
            );
          }
          
          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.init();
                    }, 
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Giriş Sayfasına Dön'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: Column(
              children: [
                // Belediye Bilgisi
                if (viewModel.currentUser != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.shade50,
                    child: Column(
                      children: [
                        Text(
                          '${viewModel.currentUser!.city ?? "-"} / ${viewModel.currentUser!.district ?? "Tümü"}',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900
                          ),
                        ),
                        if (viewModel.userDistricts.isNotEmpty)
                          Text(
                            'Sorumlu ilçeler: ${viewModel.userDistricts.join(", ")}',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                      ],
                    ),
                  ),

                // İstatistik Kartları
                _buildStatsSection(viewModel),
                
                // İlçe Seçimi (eğer birden fazla ilçe varsa)
                if (viewModel.userDistricts.length > 1)
                  _buildDistrictSelector(viewModel),
                
                // Rapor Listesi
                Expanded(
                  child: viewModel.filteredReports.isEmpty
                      ? _buildEmptyState()
                      : _buildReportList(viewModel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// İstatistik kartları bölümü
  Widget _buildStatsSection(MunicipalityViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Toplam',
              value: viewModel.stats['total']?.toString() ?? '0',
              color: Colors.blue,
              icon: Icons.description,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Bekleyen',
              value: viewModel.stats['pending']?.toString() ?? '0',
              color: Colors.orange,
              icon: Icons.pending,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Çözülen',
              value: viewModel.stats['resolved']?.toString() ?? '0',
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
  
  /// İlçe seçici
  Widget _buildDistrictSelector(MunicipalityViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: viewModel.selectedDistrictFilter,
        decoration: const InputDecoration(
          labelText: 'İlçe Seç',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tüm İlçeler')),
          ...viewModel.userDistricts.map((district) {
            return DropdownMenuItem(value: district, child: Text(district));
          }),
        ],
        onChanged: (value) {
          viewModel.setDistrictFilter(value);
        },
      ),
    );
  }
  
  /// Rapor listesi
  Widget _buildReportList(MunicipalityViewModel viewModel) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!viewModel.isLoadingMore && 
            viewModel.hasMoreReports && 
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          viewModel.loadMoreReports();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: viewModel.filteredReports.length + (viewModel.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == viewModel.filteredReports.length) {
             return const Center(
               child: Padding(
                 padding: EdgeInsets.all(16.0),
                 child: CircularProgressIndicator(),
               ),
             );
          }
          final report = viewModel.filteredReports[index];
          return _buildReportCard(context, report, viewModel);
        },
      ),
    );
  }
  
  /// Tek bir rapor kartı
  Widget _buildReportCard(
    BuildContext context,
    ReportModel report,
    MunicipalityViewModel viewModel,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // Theme handles elevation and shape
      child: InkWell(
        borderRadius: BorderRadius.circular(16), // Match theme radius
        onTap: () {
          // Rapor detayına git
          context.push('/report-detail', extra: report);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // İkon
              CircleAvatar(
                backgroundColor: _getStatusColor(report.status),
                radius: 24,
                child: Icon(
                  _getCategoryIcon(report.category),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.category.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${report.district}, ${report.city}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (report.neighborhood != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const SizedBox(width: 18), // Icon alignment indent
                          Expanded(
                            child: Text(
                              report.neighborhood!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          report.userFullName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${report.supportCount} destek',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Aksiyon butonları
              _buildActionButton(context, report, viewModel),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Aksiyon butonu (duruma göre)
  Widget _buildActionButton(
    BuildContext context,
    ReportModel report,
    MunicipalityViewModel viewModel,
  ) {
    switch (report.status) {
      case ReportStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context,
                  'Raporu Onayla',
                  'Bu raporu onaylamak istediğinize emin misiniz?',
                );
                if (confirmed) {
                  await viewModel.approveReport(report.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rapor onaylandı ✅')),
                    );
                  }
                }
              },
              tooltip: 'Onayla',
            ),
            IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context,
                  'Raporu Reddet / Sahte',
                  'Bu raporu sahte veya geçersiz olarak işaretlemek istiyor musunuz?',
                );
                if (confirmed) {
                  await viewModel.markReportAsFake(report.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rapor sahte olarak işaretlendi ❌')),
                    );
                  }
                }
              },
              tooltip: 'Reddet / Sahte',
            ),
            IconButton(
              icon: const Icon(Icons.build, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResolveReportView(report: report),
                  ),
                );
                if (result == true) {
                  viewModel.refresh();
                }
              },
              tooltip: 'Çöz',
            ),
          ],
        );
        
      case ReportStatus.approved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             IconButton(
              icon: const Icon(Icons.block, color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context,
                  'Raporu Reddet / Sahte',
                  'Bu raporu sahte veya geçersiz olarak işaretlemek istiyor musunuz?',
                );
                if (confirmed) {
                  await viewModel.markReportAsFake(report.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rapor sahte olarak işaretlendi ❌')),
                    );
                  }
                }
              },
              tooltip: 'Reddet / Sahte',
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResolveReportView(report: report),
                  ),
                );
                if (result == true) {
                  viewModel.refresh();
                }
              },
              icon: const Icon(Icons.build, size: 18),
              label: const Text('Çöz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        );
        
      case ReportStatus.resolved:
        return Chip(
          label: const Text('Çözüldü'),
          backgroundColor: Colors.green,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
          avatar: const Icon(Icons.check, color: Colors.white, size: 16),
        );
        
      case ReportStatus.fake:
        return Chip(
          label: const Text('Sahte'),
          backgroundColor: Colors.red,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
          avatar: const Icon(Icons.block, color: Colors.white, size: 16),
        );
        
      case ReportStatus.flagged:
        return Chip(
          label: const Text('İşaretlendi'),
          backgroundColor: Colors.yellow,
          labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
          avatar: const Icon(Icons.flag, color: Colors.black, size: 16),
        );
    }
  }
  
  /// Boş durum görseli
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz rapor yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seçili filtrelere uygun rapor bulunamadı',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Filtre bottom sheet'i
  void _showFilterSheet(BuildContext context) {
    final viewModel = context.read<MunicipalityViewModel>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtreler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Durum filtresi
              const Text('Durum:', style: TextStyle(fontWeight: FontWeight.w500)),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tümü'),
                    selected: viewModel.selectedStatusFilter == null,
                    onSelected: (_) {
                      viewModel.setStatusFilter(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...ReportStatus.values.map((status) {
                    return FilterChip(
                      label: Text(status.label),
                      selected: viewModel.selectedStatusFilter == status,
                      onSelected: (_) {
                        viewModel.setStatusFilter(status);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Kategori filtresi
              const Text('Kategori:', style: TextStyle(fontWeight: FontWeight.w500)),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tümü'),
                    selected: viewModel.selectedCategoryFilter == null,
                    onSelected: (_) {
                      viewModel.setCategoryFilter(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...ReportCategory.values.map((category) {
                    return FilterChip(
                      label: Text(category.label),
                      selected: viewModel.selectedCategoryFilter == category,
                      onSelected: (_) {
                        viewModel.setCategoryFilter(category);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Temizle butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    viewModel.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Filtreleri Temizle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Onay dialogu
  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
  
  /// Durum rengini al
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
  
  /// Kategori ikonunu al
  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.road:
        return Icons.foundation;
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

  void _showDebugDialog(BuildContext context) {
    // ViewModel'in kendisini saklayalım, context'i sürekli okumayalım
    final viewModel = context.read<MunicipalityViewModel>();
    
    // Şehirleri yüklemeyi başlat
    viewModel.loadDebugCities();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selectedCity = viewModel.currentUser?.city ?? "İstanbul";
        String? selectedDistrict = viewModel.currentUser?.district;
        List<String> currentDistricts = [];
        bool isLoadingDistricts = false;

        return StatefulBuilder(
          builder: (context, setState) {
            // Şehir seçili ama ilçeler henüz yüklenmediyse yükle
            if (selectedCity != null && currentDistricts.isEmpty && !isLoadingDistricts) {
               isLoadingDistricts = true;
               // Not: Dialog build esnasında setState çağırmamak için future kullanıyoruz
               Future.microtask(() async {
                 final list = await viewModel.getDebugDistricts(selectedCity!);
                 if (context.mounted) {
                   setState(() {
                     currentDistricts = list;
                     isLoadingDistricts = false;
                     // Eğer seçili ilçe yeni listede yoksa temizle
                     if (selectedDistrict != null && !currentDistricts.contains(selectedDistrict)) {
                       selectedDistrict = null;
                     }
                   });
                 }
               });
            }

            // Şehir Listesi (ViewModel'den alıyoruz, eğer boşsa manuel ekleyelim veya bekleyelim)
            final cities = viewModel.availableDebugCities.isNotEmpty 
                ? viewModel.availableDebugCities 
                : [selectedCity!];

            return AlertDialog(
              title: const Text('Debug: Belediye Değiştir'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Veritabanında kaydı bulunan şehir/ilçeler listelenir.', 
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // ŞEHİR SEÇİMİ
                    DropdownButtonFormField<String>(
                      value: cities.contains(selectedCity) ? selectedCity : null,
                      decoration: const InputDecoration(
                        labelText: 'Şehir',
                        border: OutlineInputBorder(),
                      ),
                      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedCity = val;
                            selectedDistrict = null;
                            currentDistricts = []; // Temizle ki yeniden yüklensin
                            isLoadingDistricts = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // İLÇE SEÇİMİ
                    if (isLoadingDistricts)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'İlçe (Opsiyonel)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü (İl Geneli)')),
                          ...currentDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedDistrict = val;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    viewModel.debugChangeMunicipality(
                      selectedCity ?? "",
                      selectedDistrict ?? "",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// İstatistik kartı widget'ı
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
