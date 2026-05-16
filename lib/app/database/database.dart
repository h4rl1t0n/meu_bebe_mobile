import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  DB._();
  static final DB instance = DB._();
  static Database? _database;
  static Future<Database>? _databaseFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_databaseFuture != null) return _databaseFuture!;
    _databaseFuture = _initDatabase('meu_bebe.db');
    _database = await _databaseFuture;
    return _database!;
  }

  Future<Database> _initDatabase(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migrações futuras serão adicionadas aqui conforme o schema evolui.
    // Exemplo:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE pregnant ADD COLUMN new_column TEXT');
    // }
  }

  Future<void> _createDB(Database db, int version) async {
    await _createPregnantTable(db);
    await _createUserTable(db);
    await _createAppointmentTable(db);
    await _createExamTable(db);
    await _createMedicationTable(db);
    await _createVaccineTable(db);
    await _createCurrentPregnancyTable(db);
    await _createPreviousPregnancyTable(db);
    await _createExpectationTable(db);
    await _createBirthTable(db);
    await _createBirthMomentTable(db);
    await _createObservationsTable(db);
    await _createPainReliefTable(db);
  }

  Future<void> _createPregnantTable(Database db) async {
    await db.execute('''
      CREATE TABLE pregnant (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        birth_date TEXT,
        cpf TEXT,
        social_name TEXT,
        national_health_card TEXT,
        prenatal_place TEXT,
        professional_name TEXT,
        prenatal_place_contact TEXT
      )
    ''');
  }

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT
      )
    ''');
  }

  Future<void> _createAppointmentTable(Database db) async {
    await db.execute('''
      CREATE TABLE appointment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        appointment_date TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createExamTable(Database db) async {
    await db.execute('''
      CREATE TABLE exam (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        exam_date TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createMedicationTable(Database db) async {
    await db.execute('''
      CREATE TABLE medication (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        medication_time TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createVaccineTable(Database db) async {
    await db.execute('''
      CREATE TABLE vaccine (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        used INTEGER NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createCurrentPregnancyTable(Database db) async {
    await db.execute('''
      CREATE TABLE current_pregnancy (
        id INTEGER PRIMARY KEY,
        last_menstrual_period TEXT,
        first_ultrasound TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createPreviousPregnancyTable(Database db) async {
    await db.execute('''
      CREATE TABLE previous_pregnancy (
        id INTEGER PRIMARY KEY,
        pregnancy_number INTEGER,
        given_birth_number INTEGER,
        abortions_number INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createExpectationTable(Database db) async {
    await db.execute('''
      CREATE TABLE expectation (
        id INTEGER PRIMARY KEY,
        companion INTEGER NOT NULL DEFAULT 1,
        shave_intimate_hair INTEGER NOT NULL DEFAULT 1,
        bowel_wash_or_suppository INTEGER NOT NULL DEFAULT 1,
        low_light_environment INTEGER NOT NULL DEFAULT 1,
        listen_to_music INTEGER NOT NULL DEFAULT 1,
        drink_liquids INTEGER NOT NULL DEFAULT 1,
        record_photos_or_videos INTEGER NOT NULL DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createBirthTable(Database db) async {
    await db.execute('''
      CREATE TABLE birth (
        id INTEGER PRIMARY KEY,
        who_cut INTEGER NOT NULL,
        collect_stem_cells INTEGER NOT NULL DEFAULT 0,
        skin_baby_contact INTEGER NOT NULL,
        breastfeed_first_hour INTEGER NOT NULL,
        breastfeed_restrictions INTEGER NOT NULL DEFAULT 0,
        first_bath INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createBirthMomentTable(Database db) async {
    await db.execute('''
      CREATE TABLE birth_moment (
        id INTEGER PRIMARY KEY,
        birth_way INTEGER NOT NULL,
        anesthesia INTEGER NOT NULL,
        vaginal_cut INTEGER NOT NULL,
        preferred_position INTEGER,
        other_position TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createObservationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE observations (
        id INTEGER PRIMARY KEY,
        observations TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createPainReliefTable(Database db) async {
    await db.execute('''
      CREATE TABLE pain_relief (
        id INTEGER PRIMARY KEY,
        pain_relief INTEGER NOT NULL,
        massage INTEGER NOT NULL DEFAULT 0,
        ball_exercises INTEGER NOT NULL DEFAULT 0,
        breath_relax_exercises INTEGER NOT NULL DEFAULT 0,
        shower_bath INTEGER NOT NULL DEFAULT 0,
        bathtub_bath INTEGER NOT NULL DEFAULT 0,
        acupuncture INTEGER NOT NULL DEFAULT 0,
        acupressure INTEGER NOT NULL DEFAULT 0,
        other_method INTEGER NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }
}
