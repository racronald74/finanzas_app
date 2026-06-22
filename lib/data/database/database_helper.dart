import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const int _dbVersion = 6;

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('finanzas_app_v5.db');
    return _database!;
  }

  /// Inicializa la base de datos, creando las tablas necesarias y aplicando migraciones si es necesario.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedSystemCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createSchema(db);
        await _migrateExistingColumns(db);
        await _seedSystemCategories(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuario (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        idioma TEXT DEFAULT 'es',
        tema TEXT DEFAULT 'claro',
        tamano_texto TEXT DEFAULT 'normal',
        alto_contraste INTEGER DEFAULT 0,
        ingreso_fijo_mensual REAL DEFAULT 0,
        fecha_registro TEXT NOT NULL,
        ultimo_acceso TEXT,
        notificaciones_activas INTEGER DEFAULT 1
      )
    ''');

    /// Crea la tabla de categorías
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categoria (
        id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        es_sistema INTEGER NOT NULL DEFAULT 0,
        id_usuario INTEGER,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE
      )
    ''');
    // Crea la tabla de ingresos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ingreso (
        id_ingreso INTEGER PRIMARY KEY AUTOINCREMENT,
        monto REAL NOT NULL CHECK (monto > 0),
        fecha TEXT NOT NULL,
        fuente TEXT,
        descripcion TEXT,
        origen TEXT DEFAULT 'Manual',
        tipo TEXT DEFAULT 'ADICIONAL',
        id_categoria INTEGER,
        id_usuario INTEGER NOT NULL,
        fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_categoria)
          REFERENCES categoria(id_categoria)
          ON DELETE SET NULL,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE
      )
    ''');
    // Crea la tabla de gastos
    await db.execute('''
  CREATE TABLE IF NOT EXISTS gasto (
    id_gasto INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    monto REAL NOT NULL CHECK (monto > 0),
    fecha TEXT NOT NULL,
    descripcion TEXT,
    origen TEXT NOT NULL DEFAULT 'MANUAL',
    id_usuario INTEGER NOT NULL,
    id_categoria INTEGER NOT NULL,
    id_pago INTEGER,
    fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario)
      REFERENCES usuario(id_usuario)
      ON DELETE CASCADE,

    FOREIGN KEY (id_categoria)
      REFERENCES categoria(id_categoria),

    FOREIGN KEY (id_pago)
      REFERENCES pago(id_pago)
      ON DELETE SET NULL
  )
''');
    // Crea la tabla de metas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        id_meta INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto_objetivo REAL NOT NULL CHECK (monto_objetivo > 0),
        monto_acumulado REAL NOT NULL DEFAULT 0 CHECK (monto_acumulado >= 0),
        fecha_limite TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'Activa',
        id_usuario INTEGER NOT NULL,
        fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        prioridad TEXT,
        recordatorio INTEGER DEFAULT 0,
        categoria TEXT,
        fecha_cumplimiento TEXT,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE
      )
    ''');
    // Crea la tabla de aportes a metas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS aporte (
        id_aporte INTEGER PRIMARY KEY AUTOINCREMENT,
        monto REAL NOT NULL CHECK (monto > 0),
        fecha TEXT NOT NULL,
        origen TEXT NOT NULL DEFAULT 'Manual',
        id_meta INTEGER NOT NULL,
        fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_meta)
          REFERENCES meta(id_meta)
          ON DELETE CASCADE
      )
    ''');
    // Crea la tabla de deudas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deuda (
        id_deuda INTEGER PRIMARY KEY AUTOINCREMENT,
        acreedor TEXT NOT NULL,
        monto_total REAL NOT NULL CHECK (monto_total > 0),
        saldo_pendiente REAL NOT NULL CHECK (saldo_pendiente >= 0),
        tasa_interes REAL DEFAULT 0,
        plazo INTEGER,
        fecha_inicio TEXT NOT NULL,
        recordatorio INTEGER DEFAULT 0,
        estado TEXT NOT NULL DEFAULT 'Activa',
        id_usuario INTEGER NOT NULL,
        fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE
      )
    ''');
    // Crea la tabla de pagos de deudas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pago (
        id_pago INTEGER PRIMARY KEY AUTOINCREMENT,
        monto REAL NOT NULL CHECK (monto > 0),
        fecha TEXT NOT NULL,
        metodo_pago TEXT,
        descripcion TEXT,
        id_deuda INTEGER NOT NULL,
        fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_deuda)
          REFERENCES deuda(id_deuda)
          ON DELETE CASCADE
      )
    ''');
    // Crea la tabla de obligaciones recurrentes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS obligacion (
        id_obligacion INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL CHECK (monto > 0),
        fecha_vencimiento TEXT NOT NULL,
        recordatorio INTEGER DEFAULT 0,
        estado TEXT NOT NULL DEFAULT 'Pendiente',
        es_recurrente INTEGER DEFAULT 0,
        dia_vencimiento INTEGER,
        id_usuario INTEGER NOT NULL,
        id_gasto_generado INTEGER,
        fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        frecuencia TEXT,
        categoria TEXT,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE,
        FOREIGN KEY (id_gasto_generado)
          REFERENCES gasto(id_gasto)
          ON DELETE SET NULL
      )
    ''');
    // Crea la tabla de presupuestos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS presupuesto (
        id_presupuesto INTEGER PRIMARY KEY AUTOINCREMENT,
        monto_limite REAL NOT NULL CHECK (monto_limite >= 0),
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        id_usuario INTEGER NOT NULL,
        id_categoria INTEGER NOT NULL,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE,
        FOREIGN KEY (id_categoria)
          REFERENCES categoria(id_categoria)
          ON DELETE CASCADE
      )
    ''');
    // Crea la tabla de notificaciones
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notificacion (
        id_notificacion INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        mensaje TEXT NOT NULL,
        fecha TEXT NOT NULL,
        leida INTEGER NOT NULL DEFAULT 0,
        id_usuario INTEGER NOT NULL,
        fecha_lectura TEXT,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE
      )
    ''');

    /// Crea índices para mejorar el rendimiento de las consultas.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ingreso_usuario ON ingreso(id_usuario)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_gasto_usuario ON gasto(id_usuario)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categoria_tipo ON categoria(tipo)',
    );
  }

  /// Aplica migraciones para agregar nuevas columnas a tablas existentes sin perder datos.
  Future<void> _migrateExistingColumns(Database db) async {
    await _addColumnIfMissing(db, 'usuario', 'idioma', "TEXT DEFAULT 'es'");
    await _addColumnIfMissing(db, 'usuario', 'tema', "TEXT DEFAULT 'claro'");
    await _addColumnIfMissing(
      db,
      'usuario',
      'tamano_texto',
      "TEXT DEFAULT 'normal'",
    );
    await _addColumnIfMissing(
      db,
      'usuario',
      'alto_contraste',
      'INTEGER DEFAULT 0',
    );
    await _addColumnIfMissing(db, 'usuario', 'ultimo_acceso', 'TEXT');
    await _addColumnIfMissing(
      db,
      'usuario',
      'notificaciones_activas',
      'INTEGER DEFAULT 1',
    );

    await _addColumnIfMissing(db, 'ingreso', 'fuente', 'TEXT');
    await _addColumnIfMissing(db, 'ingreso', 'origen', "TEXT DEFAULT 'Manual'");
    await _addColumnIfMissing(db, 'ingreso', 'fecha_registro', 'TEXT');
    await db.execute(
      "UPDATE ingreso SET fecha_registro = COALESCE(fecha_registro, datetime('now'))",
    );
  }

  /// Verifica si una columna existe en una tabla y la agrega si falta, utilizando ALTER TABLE.
  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);

    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  /// Inserta categorías predeterminadas para cada tipo (INGRESO, GASTO, META, OBLIGACION) si no existen, marcándolas como de sistema.
  Future<void> _seedSystemCategories(Database db) async {
    const categories = [
      ('Salario', 'INGRESO'),
      ('Negocio', 'INGRESO'),
      ('Freelance', 'INGRESO'),
      ('Otros', 'INGRESO'),
      ('Alimentacion', 'GASTO'),
      ('Transporte', 'GASTO'),
      ('Salud', 'GASTO'),
      ('Educacion', 'GASTO'),
      ('Vivienda', 'GASTO'),
      ('Entretenimiento', 'GASTO'),
      ('Fondo de emergencia', 'META'),
      ('Viaje', 'META'),
      ('Vivienda', 'META'),
      ('Vehiculo', 'META'),
      ('Educacion', 'META'),
      ('Tecnologia', 'META'),
      ('Otros', 'META'),
      ('Servicios publicos', 'OBLIGACION'),
      ('Internet', 'OBLIGACION'),
      ('Telefonia movil', 'OBLIGACION'),
      ('Arriendo', 'OBLIGACION'),
      ('Administracion', 'OBLIGACION'),
      ('Tarjeta de credito', 'OBLIGACION'),
      ('Credito de vivienda', 'OBLIGACION'),
      ('Credito de vehiculo', 'OBLIGACION'),
      ('Suscripciones', 'OBLIGACION'),
      ('Otros', 'OBLIGACION'),
    ];

    /// Para cada categoría predeterminada, verifica si ya existe una categoría con el mismo nombre y tipo sin un usuario asociado. Si no existe, la inserta como categoría de sistema.
    for (final category in categories) {
      final exists = await db.query(
        'categoria',
        where: 'nombre = ? AND tipo = ? AND id_usuario IS NULL',
        whereArgs: [category.$1, category.$2],
        limit: 1,
      );

      if (exists.isEmpty) {
        await db.insert('categoria', {
          'nombre': category.$1,
          'tipo': category.$2,
          'es_sistema': 1,
        });
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
