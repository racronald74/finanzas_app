import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../shared/constants/database_constants.dart';

/// Clase encargada de administrar la conexión con SQLite.
///
/// Implementa el patrón Singleton para mantener
/// una única instancia de la base de datos durante
/// toda la ejecución de la aplicación.
class DatabaseHelper {
  // Instancia única utilizada por la aplicación y las pruebas.
  static DatabaseHelper instance = DatabaseHelper._init();

  /// Referencia a la base de datos.
  static Database? _database;

  /// Constructor privado utilizado por el Singleton.
  DatabaseHelper._init();

  /// Constructor utilizado para configurar pruebas.
  ///
  /// Sustituye temporalmente la instancia principal por una
  /// que utiliza la base de datos proporcionada.
  DatabaseHelper.forTesting(Database database) {
    _database = database;

    // Permite que los servicios y repositorios utilicen esta instancia.
    instance = this;
  }

  /// Inicializa el esquema y las categorías en la base temporal.
  Future<void> initializeForTesting() async {
    // Obtiene la conexión temporal de SQLite.
    final db = await database;

    // Crea todas las tablas de la aplicación.
    await _createSchema(db);

    // Inserta las categorías predeterminadas.
    await _seedSystemCategories(db);
  }

  /// Obtiene la instancia de la base de datos.
  ///
  /// Si aún no existe, la crea automáticamente.
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB(DatabaseConstants.databaseName);

    return _database!;
  }

  /// Inicializa la base de datos.
  ///
  /// Crea las tablas necesarias y aplica las migraciones
  /// cuando cambia la versión del esquema.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
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

    // Crea el historial del ingreso fijo mensual.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ingreso_fijo_historico (
        id_ingreso_fijo INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL,
        monto REAL NOT NULL CHECK (monto >= 0),
        fecha_inicio TEXT NOT NULL,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE
      )
    ''');

    // Crea la tabla de categorías.
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

    // Crea la tabla de ingresos.
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

    // Crea la tabla de gastos.
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

    // Crea la tabla de metas.
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

    // Crea la tabla de aportes a metas.
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

    // Crea la tabla de deudas.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deuda (
        id_deuda INTEGER PRIMARY KEY AUTOINCREMENT,
        acreedor TEXT NOT NULL,
        monto_total REAL NOT NULL CHECK (monto_total > 0),
        saldo_pendiente REAL NOT NULL CHECK (saldo_pendiente >= 0),
        saldo_capital REAL NOT NULL DEFAULT 0 CHECK (saldo_capital >= 0),

        -- Capital existente al inicio del período mensual actual.
        capital_inicio_periodo REAL NOT NULL DEFAULT 0
          CHECK (capital_inicio_periodo >= 0),

        intereses_pendientes REAL NOT NULL DEFAULT 0
          CHECK (intereses_pendientes >= 0),
        fecha_ultimo_calculo_intereses TEXT,
        tasa_interes_ea REAL NOT NULL DEFAULT 0
          CHECK (tasa_interes_ea >= 0),
        tasa_interes REAL DEFAULT 0,
        cuota_mensual REAL,
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

    // Crea la tabla de pagos de deudas.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pago (
        id_pago INTEGER PRIMARY KEY AUTOINCREMENT,
        monto REAL NOT NULL CHECK (monto > 0),
        abono_capital REAL NOT NULL DEFAULT 0 CHECK (abono_capital >= 0),
        intereses_pagados REAL NOT NULL DEFAULT 0
          CHECK (intereses_pagados >= 0),
        tipo_pago TEXT NOT NULL DEFAULT 'ORDINARIO',
        opcion_abono TEXT,
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

    // Crea la tabla de obligaciones recurrentes.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS obligacion (
        id_obligacion INTEGER PRIMARY KEY AUTOINCREMENT,
        id_grupo_recurrencia INTEGER,
        recurrencia_activa INTEGER DEFAULT 1,
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
        id_categoria INTEGER,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE,
        FOREIGN KEY (id_gasto_generado)
          REFERENCES gasto(id_gasto)
          ON DELETE SET NULL,
        FOREIGN KEY (id_categoria)
          REFERENCES categoria(id_categoria)
          ON DELETE RESTRICT
      )
    ''');

    // Crea la tabla de presupuestos.
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

    // Crea la tabla de notificaciones.
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

    // Crea índices para mejorar el rendimiento de las consultas.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ingreso_usuario ON ingreso(id_usuario)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_gasto_usuario ON gasto(id_usuario)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categoria_tipo ON categoria(tipo)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ingreso_fijo_usuario '
      'ON ingreso_fijo_historico(id_usuario)',
    );
  }

  /// Aplica migraciones para agregar nuevas columnas
  /// a tablas existentes sin perder datos.
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

    await _addColumnIfMissing(db, 'obligacion', 'id_categoria', 'INTEGER');

    // Agrega el identificador para agrupar obligaciones recurrentes.
    await _addColumnIfMissing(
      db,
      'obligacion',
      'id_grupo_recurrencia',
      'INTEGER',
    );

    // Indica si una obligación recurrente continúa activa.
    await _addColumnIfMissing(
      db,
      'obligacion',
      'recurrencia_activa',
      'INTEGER DEFAULT 1',
    );

    await db.execute('''
      UPDATE obligacion
      SET id_categoria = (
        SELECT id_categoria
        FROM categoria
        WHERE categoria.nombre = obligacion.categoria
          AND categoria.tipo = 'GASTO'
          AND categoria.id_usuario IS NULL
        LIMIT 1
      )
      WHERE id_categoria IS NULL
        AND categoria IS NOT NULL
    ''');

    // Crea el historial del ingreso fijo para bases existentes.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ingreso_fijo_historico (
        id_ingreso_fijo INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL,
        monto REAL NOT NULL CHECK (monto >= 0),
        fecha_inicio TEXT NOT NULL,
        FOREIGN KEY (id_usuario)
          REFERENCES usuario(id_usuario)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ingreso_fijo_usuario '
      'ON ingreso_fijo_historico(id_usuario)',
    );

    // Agrega los campos financieros de las deudas.
    await _addColumnIfMissing(
      db,
      'deuda',
      'saldo_capital',
      'REAL NOT NULL DEFAULT 0',
    );

    await _addColumnIfMissing(
      db,
      'deuda',
      'tasa_interes_ea',
      'REAL NOT NULL DEFAULT 0',
    );

    await _addColumnIfMissing(db, 'deuda', 'cuota_mensual', 'REAL');

    // Inicializa el capital pendiente con el saldo anterior.
    await db.execute('''
      UPDATE deuda
      SET saldo_capital = saldo_pendiente
      WHERE saldo_capital = 0
        AND saldo_pendiente > 0
    ''');

    // Agrega los campos financieros de los pagos.
    await _addColumnIfMissing(
      db,
      'pago',
      'abono_capital',
      'REAL NOT NULL DEFAULT 0',
    );

    await _addColumnIfMissing(
      db,
      'pago',
      'intereses_pagados',
      'REAL NOT NULL DEFAULT 0',
    );

    await _addColumnIfMissing(
      db,
      'pago',
      'tipo_pago',
      "TEXT NOT NULL DEFAULT 'ORDINARIO'",
    );

    await _addColumnIfMissing(db, 'pago', 'opcion_abono', 'TEXT');

    // Agrega los intereses pendientes a las deudas existentes.
    await _addColumnIfMissing(
      db,
      'deuda',
      'intereses_pendientes',
      'REAL NOT NULL DEFAULT 0',
    );

    // Agrega la fecha del último cálculo de intereses.
    await _addColumnIfMissing(
      db,
      'deuda',
      'fecha_ultimo_calculo_intereses',
      'TEXT',
    );

    // Agrega el capital de referencia del período mensual actual.
    await _addColumnIfMissing(
      db,
      'deuda',
      'capital_inicio_periodo',
      'REAL NOT NULL DEFAULT 0',
    );

    // Inicializa el capital de referencia de las deudas existentes.
    // Solo modifica registros que aún no tienen ese valor.
    await db.execute('''
      UPDATE deuda
      SET capital_inicio_periodo = saldo_capital
      WHERE capital_inicio_periodo = 0
        AND saldo_capital > 0
    ''');
  }

  /// Verifica si una columna existe en una tabla y la agrega si falta.
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

  /// Inserta categorías predeterminadas si todavía no existen.
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
      ('Servicios publicos', 'GASTO'),
      ('Internet', 'GASTO'),
      ('Telefonia movil', 'GASTO'),
      ('Arriendo', 'GASTO'),
      ('Administracion', 'GASTO'),
      ('Tarjeta de credito', 'GASTO'),
      ('Credito de vivienda', 'GASTO'),
      ('Credito de vehiculo', 'GASTO'),
      ('Suscripciones', 'GASTO'),
      ('Pago de deuda', 'GASTO'),
      ('Otros', 'GASTO'),
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

    // Verifica e inserta cada categoría predeterminada.
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

  /// Cierra la conexión con la base de datos.
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Ejecuta varias operaciones dentro de una transacción SQLite.
  ///
  /// Si alguna operación falla, SQLite revierte todos los cambios.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final Database db = await database;

    return await db.transaction(action);
  }
}
