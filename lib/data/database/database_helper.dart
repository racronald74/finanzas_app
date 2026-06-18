import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Helper para manejar la base de datos SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('finanzas_app_v5.db');
    return _database!;
  }

  /// Inicializar base de datos
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 5, onCreate: _createDB);
  }

  // Crear tablas y datos iniciales
  Future<void> _createDB(Database db, int version) async {
    //Tabla de usuarios
    await db.execute('''
      CREATE TABLE usuario (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        ingreso_fijo_mensual REAL DEFAULT 0,
        fecha_registro TEXT NOT NULL
      )
    ''');

    //Tabla de categorías
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

    //Tabla de ingresos
    await db.execute('''
  CREATE TABLE ingreso (
    id_ingreso INTEGER PRIMARY KEY AUTOINCREMENT,
    descripcion TEXT NOT NULL,
    monto REAL NOT NULL,
    fecha TEXT NOT NULL,
    tipo TEXT NOT NULL,
    id_categoria INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    FOREIGN KEY (id_categoria)
      REFERENCES categoria(id_categoria),
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

    await db.insert('categoria', {
      'nombre': 'Fondo de emergencia',
      'tipo': 'META',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Viaje',
      'tipo': 'META',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Vivienda',
      'tipo': 'META',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Vehículo',
      'tipo': 'META',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Educación',
      'tipo': 'META',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Tecnología',
      'tipo': 'META',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Otros',
      'tipo': 'META',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Servicios públicos',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Internet',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Telefonía móvil',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Arriendo',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Administración',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Tarjeta de crédito',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Crédito de vivienda',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Crédito de vehículo',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Suscripciones',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });

    await db.insert('categoria', {
      'nombre': 'Otros',
      'tipo': 'OBLIGACION',
      'es_sistema': 1,
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
