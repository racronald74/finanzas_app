/// Modelo que representa una categoría del sistema.
///
/// Las categorías serán utilizadas por:
/// - Ingresos
/// - Gastos
/// - Metas
/// - Obligaciones
class CategoryModel {
  final int? idCategoria;
  final String nombre;
  final String tipo;
  final int esSistema;
  final int? idUsuario;

  CategoryModel({
    this.idCategoria,
    required this.nombre,
    required this.tipo,
    required this.esSistema,
    this.idUsuario,
  });

  /// Convierte el objeto a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      'tipo': tipo,
      'es_sistema': esSistema,
      'id_usuario': idUsuario,
    };
  }

  /// Convierte un Map de SQLite a objeto
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      idCategoria: map['id_categoria'],
      nombre: map['nombre'],
      tipo: map['tipo'],
      esSistema: map['es_sistema'],
      idUsuario: map['id_usuario'],
    );
  }
}
