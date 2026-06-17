import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('finanzas_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        fecha_registro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categoria (
        id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        es_sistema INTEGER NOT NULL,
        id_usuario INTEGER,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
      )
    ''');

    await db.insert('categoria', {
      'nombre': 'Salario',
      'tipo': 'INGRESO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Negocio',
      'tipo': 'INGRESO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Freelance',
      'tipo': 'INGRESO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Otros',
      'tipo': 'INGRESO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Alimentación',
      'tipo': 'GASTO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Transporte',
      'tipo': 'GASTO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Salud',
      'tipo': 'GASTO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Educación',
      'tipo': 'GASTO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Vivienda',
      'tipo': 'GASTO',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Entretenimiento',
      'tipo': 'GASTO',
      'es_sistema': 1,
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
