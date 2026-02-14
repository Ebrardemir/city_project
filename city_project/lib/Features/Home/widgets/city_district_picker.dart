import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CityDistrictPicker extends StatefulWidget {
  final Function(LatLng location, String city, String district) onLocationSelected;

  const CityDistrictPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<CityDistrictPicker> createState() => _CityDistrictPickerState();
}

class _CityDistrictPickerState extends State<CityDistrictPicker> {
  String? selectedCity;
  String? selectedDistrict;

  // Türkiye'nin büyük şehirleri ve merkez koordinatları
  final Map<String, Map<String, LatLng>> turkeyLocations = {
    'İstanbul': {
      'Kadıköy': LatLng(40.9833, 29.0333),
      'Beşiktaş': LatLng(41.0422, 29.0096),
      'Şişli': LatLng(41.0602, 28.9887),
      'Üsküdar': LatLng(41.0226, 29.0156),
      'Beyoğlu': LatLng(41.0423, 28.9779),
      'Fatih': LatLng(41.0185, 28.9497),
      'Bakırköy': LatLng(40.9799, 28.8738),
    },
    'Ankara': {
      'Çankaya': LatLng(39.9185, 32.8597),
      'Keçiören': LatLng(39.9889, 32.8632),
      'Yenimahalle': LatLng(39.9861, 32.7953),
      'Mamak': LatLng(39.9205, 32.9142),
      'Etimesgut': LatLng(39.9474, 32.6688),
      'Sincan': LatLng(39.9960, 32.5795),
    },
    'İzmir': {
      'Konak': LatLng(38.4189, 27.1287),
      'Karşıyaka': LatLng(38.4599, 27.1120),
      'Bornova': LatLng(38.4698, 27.2143),
      'Buca': LatLng(38.3981, 27.1765),
      'Bayraklı': LatLng(38.4619, 27.1612),
      'Çiğli': LatLng(38.4963, 27.0518),
    },
    'Bursa': {
      'Osmangazi': LatLng(40.1885, 29.0610),
      'Yıldırım': LatLng(40.1905, 29.1058),
      'Nilüfer': LatLng(40.2043, 28.9894),
      'Gemlik': LatLng(40.4310, 29.1564),
    },
    'Antalya': {
      'Muratpaşa': LatLng(36.8889, 30.7125),
      'Kepez': LatLng(36.9225, 30.7239),
      'Konyaaltı': LatLng(36.8836, 30.6279),
      'Alanya': LatLng(36.5437, 31.9982),
    },
    'Adana': {
      'Seyhan': LatLng(37.0017, 35.3289),
      'Çukurova': LatLng(37.0167, 35.2833),
      'Sarıçam': LatLng(37.0000, 35.3833),
      'Yüreğir': LatLng(36.9667, 35.3833),
    },
    'Gaziantep': {
      'Şahinbey': LatLng(37.0662, 37.3833),
      'Şehitkamil': LatLng(37.0594, 37.3408),
    },
    'Konya': {
      'Selçuklu': LatLng(37.8667, 32.4833),
      'Meram': LatLng(37.8667, 32.4667),
      'Karatay': LatLng(37.8833, 32.5000),
    },
  };

  @override
  Widget build(BuildContext context) {
    final cities = turkeyLocations.keys.toList()..sort();
    
    List<String> districts = [];
    if (selectedCity != null && turkeyLocations[selectedCity] != null) {
      districts = turkeyLocations[selectedCity]!.keys.toList()..sort();
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konum Seçin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'İl ve ilçenizi seçin',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // İl Seçimi
            const Text(
              'İl',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  hint: const Text('İl seçin'),
                  value: selectedCity,
                  borderRadius: BorderRadius.circular(12),
                  items: cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                      selectedDistrict = null; // İl değişince ilçeyi sıfırla
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // İlçe Seçimi
            const Text(
              'İlçe',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedCity == null 
                      ? Colors.grey.shade200 
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  hint: Text(
                    selectedCity == null ? 'Önce il seçin' : 'İlçe seçin',
                    style: TextStyle(
                      color: selectedCity == null 
                          ? Colors.grey.shade400 
                          : Colors.black54,
                    ),
                  ),
                  value: selectedDistrict,
                  borderRadius: BorderRadius.circular(12),
                  items: districts.map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: selectedCity == null ? null : (value) {
                    setState(() {
                      selectedDistrict = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: selectedCity != null && selectedDistrict != null
                        ? () {
                            final location = turkeyLocations[selectedCity]![selectedDistrict]!;
                            widget.onLocationSelected(
                              location,
                              selectedCity!,
                              selectedDistrict!,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Konumu Onayla',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
