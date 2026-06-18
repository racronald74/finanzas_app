import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repository = CategoryRepository();

  Future<int> createCategory(CategoryModel category) async {
    return await _repository.insertCategory(category);
  }

  Future<List<CategoryModel>> getCategories() async {
    return await _repository.getCategories();
  }

  Future<List<CategoryModel>> getCategoriesByType(String tipo) async {
    return await _repository.getCategoriesByType(tipo);
  }
}
