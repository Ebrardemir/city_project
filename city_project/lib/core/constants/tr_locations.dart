class TrLocations {
  static const List<String> cities = [
  
    "Ankara",
    "Antalya",
    "Bursa", 
    "İstanbul",
    "İzmir",
  ];

  // Şimdilik örnek: 5 ilçe listesiyle başlatıyoruz.
  // Hepsini istersen sonra tamamlarız (mesajda çok uzuyor).
  static const Map<String, List<String>> districtsByCity = {
    "İstanbul": [
      "Adalar","Avcılar","Bağcılar","Bahçelievler","Bakırköy",
      "Başakşehir","Bayrampaşa","Beşiktaş","Beykoz","Beylikdüzü",
      "Beyoğlu","Büyükçekmece","Çekmeköy","Esenler","Esenyurt",
      "Eyüpsultan","Fatih","Gaziosmanpaşa","Güngören","Kadıköy",
      "Kağıthane","Kartal","Küçükçekmece","Maltepe","Pendik",
      "Sancaktepe","Sarıyer","Silivri","Sultanbeyli","Sultangazi",
      "Şile","Şişli","Tuzla","Ümraniye","Üsküdar","Zeytinburnu"
    ],
    "Ankara": [
      "Altındağ","Çankaya","Etimesgut","Keçiören","Mamak",
      "Sincan","Yenimahalle","Gölbaşı","Pursaklar","Polatlı"
    ],
    "İzmir": [
      "Bornova","Buca","Karşıyaka","Konak","Bayraklı",
      "Çiğli","Gaziemir","Karabağlar","Menemen","Torbalı"
    ],
    "Bursa": [
      "Nilüfer","Osmangazi","Yıldırım","İnegöl","Gemlik",
      "Mudanya","Karacabey","Mustafakemalpaşa"
    ],
    "Antalya": [
      "Kepez","Konyaaltı","Muratpaşa","Alanya","Manavgat",
      "Serik","Kemer","Kaş"
    ],
  };

  static List<String> districtsOf(String? city) {
    if (city == null) return const [];
    return districtsByCity[city] ?? const [];
  }
}
