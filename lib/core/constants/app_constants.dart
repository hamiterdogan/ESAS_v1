/// Application-wide string constants.
/// All hard-coded URLs, paths, and similar magic strings live here.
/// Import this file wherever you need a URL — do NOT duplicate the strings inline.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Network
  // ---------------------------------------------------------------------------

  /// Base URL for the ESAS REST API.
  static const String apiBaseUrl = 'https://esasapi.eyuboglu.k12.tr/api';

  /// Notification preference update endpoint.
  static const String bildirimTercihiGuncelleEndpoint =
      '/Notification/BildirimTercihiGuncelle';

  /// Base URL for the static file server (uploaded attachments).
  /// Append the module folder + file name, e.g. '${AppConstants.fileServerBaseUrl}IzinIstek/$fileName'.
  static const String fileServerBaseUrl =
      'https://esas.eyuboglu.k12.tr/TestDosyalar/';
}
