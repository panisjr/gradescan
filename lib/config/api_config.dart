class ApiConfig {
  // FormRead API
  static const String formReadApiKey = 'YOUR_FORMREAD_API_KEY';
  static const String formReadBaseUrl = 'https://api.formread.com/v1';

  // Google Cloud Vision (alternative)
  static const String googleVisionApiKey = 'YOUR_GOOGLE_API_KEY';

  // Azure Form Recognizer (alternative)
  static const String azureEndpoint = 'YOUR_AZURE_ENDPOINT';
  static const String azureApiKey = 'YOUR_AZURE_API_KEY';

  // Custom backend (if you have one)
  static const String customApiUrl = 'https://your-backend.com/api/scan';
  static const String customApiKey = 'YOUR_CUSTOM_API_KEY';

  // Active service selection
  static const OMRProvider activeProvider = OMRProvider.formRead;
}

enum OMRProvider {
  formRead,
  googleVision,
  azure,
  custom,
  offline, // Local processing without API
}
