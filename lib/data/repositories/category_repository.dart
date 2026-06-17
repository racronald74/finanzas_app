import '../database/database_helper.dart';
import '../models/category_model.dart';

class CategoryRepository {
  /// Insertar categoría
  Future<int> insertCategory(CategoryModel category) async {
    final db = await DatabaseHelper.instance.database;

    return await db.insert('categoria', category.toMap());
  }

  /// Obtener todas las categorías
  Future<List<CategoryModel>> getCategories() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query('categoria');

    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }
}
