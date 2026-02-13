class AppConfig {
  AppConfig._();

  //GÜNCELLENECEK !!

  // API adresiniz SSL sertifikası ile korunuyor ve 443 portunu kullanıyor.
  // Bu nedenle base URL'i bu şekilde güncelliyoruz.
  // NOT: Sonunda mutlaka '/' olmalı ki yol çözümlenirken '/api/' klasör olarak korunsun.
  static const String baseUrl = "http://30.10.24.11:5078/api/";

  //ios cihaz için
  //static const String baseUrl = "http://192.168.0.107:5078/api/";
  // static const String baseUrl = "http://10.189.75.130/api/";
  //static const String baseUrl = "http://192.168.0.107/api/";
  //static const baseUrl = 'http://192.168.0.107:5078/api';
}
//194.27.72.32%  192.168.0.107 192.168.0.107


  //static const String baseUrl = "http://10.0.2.2:5078/api/";
 //static const String baseUrl = "http://localhost:5078/api/";
