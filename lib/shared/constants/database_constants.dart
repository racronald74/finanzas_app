/// Constantes relacionadas con la base de datos.
///
/// Centraliza el nombre y la versión de la base de datos
/// para evitar valores repetidos en el proyecto.
class DatabaseConstants {
  DatabaseConstants._();

  /// Nombre del archivo de la base de datos.
  static const String databaseName = 'finanzas_app.db';

  /// Versión actual de la base de datos.
  static const int databaseVersion = 6;
}
