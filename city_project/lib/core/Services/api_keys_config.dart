/// API Keys Configuration
/// 
/// IMPORTANT: Do not commit API keys to version control!
/// Store these in environment variables or secure configuration files.

class ApiKeysConfig {
  // Google Cloud Vision API Key
  // Set via environment variable: GOOGLE_CLOUD_VISION_API_KEY
  // Or via Firebase Remote Config for production
  static String? googleCloudVisionApiKey = _getApiKey('GOOGLE_CLOUD_VISION_API_KEY');

  static String? _getApiKey(String keyName) {
    // Bu method development sırasında env variable'ları okuyabilir
    // Hackathon süresi kısıtlı olduğu için şimdilik null
    return null;
  }

  /// API Key'i initialize et (App startup'ında)
  static Future<void> initializeApiKeys() async {
    // TODO: Firebase Remote Config'den API key'leri oku
    // await FirebaseRemoteConfig.instance.fetchAndActivate();
    // googleCloudVisionApiKey = FirebaseRemoteConfig.instance.getString('google_cloud_vision_api_key');
  }
}
