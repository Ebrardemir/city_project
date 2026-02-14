import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/locator.dart';
import '../../../core/services/location_service.dart';
import '../viewmodel/create_report_viewmodel.dart';
import '../widgets/location_picker_card.dart';
import '../widgets/photo_picker_card.dart';

class CreateReportView extends StatelessWidget {
  const CreateReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateReportViewModel(locator<LocationService>()),
      child: const _CreateReportBody(),
    );
  }
}

class _CreateReportBody extends StatelessWidget {
  const _CreateReportBody();

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eksik bilgi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateReportViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('İhbar Oluştur')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          PhotoPickerCard(
            imagePath: vm.draft.localImagePath,
            onPicked: vm.setImagePath,
          ),
          const SizedBox(height: 10),

          // Kategori
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: vm.draft.categoryId,
                    items: vm.categories
                        .map((c) => DropdownMenuItem(
                              value: c.$1,
                              child: Text(c.$2),
                            ))
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      final name =
                          vm.categories.firstWhere((e) => e.$1 == id).$2;
                      vm.setCategory(id, name);
                    },
                    decoration: const InputDecoration(hintText: 'Kategori seç'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Açıklama
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Açıklama',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    minLines: 1,
                    maxLines: 5,
                    onChanged: vm.setDescription,
                    decoration: const InputDecoration(
                      hintText: 'Sorunu kısaca anlatın (en az 10 karakter)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Konum
          LocationPickerCard(
            loading: vm.loadingLocation,
            lat: vm.draft.lat,
            lng: vm.draft.lng,
            onGetCurrent: vm.getCurrentLocation,
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.submitting
                  ? null
                  : () async {
                      final err = vm.firstValidationError();
                      if (err != null) {
                        await _showErrorDialog(context, err);
                        return;
                      }

                      final ok = await vm.submit();
                      if (!context.mounted) return;

                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Başarılı. İhbar gönderildi'),
                          ),
                        );
                        context.pop();
                      } else {
                        await _showErrorDialog(
                          context,
                          'Bir hata oluştu. Tekrar deneyin.',
                        );
                      }
                    },
              child: vm.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gönder'),
            ),
          ),
        ],
      ),
    );
  }
}
