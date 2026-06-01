import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Stockage {
  static const String _nomBase = 'tablette.db';
  static const int _versionSchema = 2;
  static const String tableAppairage = 'appairage';
  static const String tableContexteSession = 'contexte_session';

  final Database _baseDeDonnees;

  Stockage._(this._baseDeDonnees);

  static Future<Stockage> ouvrir() async {
    final repertoire = await getApplicationDocumentsDirectory();
    final chemin = '${repertoire.path}/$_nomBase';
    final db = await openDatabase(
      chemin,
      version: _versionSchema,
      onCreate: _creerSchema,
      onUpgrade: _migrerSchema,
    );
    return Stockage._(db);
  }

  static Future<Stockage> ouvrirEnMemoire(DatabaseFactory factory) async {
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: _versionSchema,
        onCreate: _creerSchema,
        onUpgrade: _migrerSchema,
      ),
    );
    return Stockage._(db);
  }

  static Future<void> _creerSchema(Database db, int version) async {
    await _creerTableAppairage(db);
    await _creerTableContexteSession(db);
  }

  static Future<void> _migrerSchema(
    Database db,
    int ancienneVersion,
    int nouvelleVersion,
  ) async {
    if (ancienneVersion < 2) {
      await _creerTableContexteSession(db);
    }
  }

  static Future<void> _creerTableAppairage(Database db) async {
    await db.execute('''
      CREATE TABLE $tableAppairage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pairing_id TEXT NOT NULL,
        pc_pub BLOB NOT NULL,
        tab_priv BLOB NOT NULL,
        tab_pub BLOB NOT NULL,
        date_appairage TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _creerTableContexteSession(Database db) async {
    await db.execute('''
      CREATE TABLE $tableContexteSession (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        patient_id TEXT NOT NULL,
        patient_initiales TEXT NOT NULL,
        niveau_demande INTEGER NOT NULL,
        est_demo INTEGER NOT NULL
      )
    ''');
  }

  Future<void> fermer() => _baseDeDonnees.close();

  Future<int> insererAppairage({
    required String pairingId,
    required List<int> pcPub,
    required List<int> tabPriv,
    required List<int> tabPub,
    required DateTime dateAppairage,
  }) {
    return _baseDeDonnees.insert(tableAppairage, <String, Object?>{
      'pairing_id': pairingId,
      'pc_pub': Uint8List.fromList(pcPub),
      'tab_priv': Uint8List.fromList(tabPriv),
      'tab_pub': Uint8List.fromList(tabPub),
      'date_appairage': dateAppairage.toUtc().toIso8601String(),
    });
  }

  Future<Map<String, Object?>?> lireAppairageActuel() async {
    final lignes = await _baseDeDonnees.query(
      tableAppairage,
      orderBy: 'date_appairage DESC, id DESC',
      limit: 1,
    );
    return lignes.isEmpty ? null : lignes.first;
  }

  Future<int> compterAppairages() async {
    final resultat = await _baseDeDonnees.rawQuery(
      'SELECT COUNT(*) AS total FROM $tableAppairage',
    );
    return Sqflite.firstIntValue(resultat) ?? 0;
  }

  Future<void> enregistrerContexteSession({
    required String patientId,
    required String patientInitiales,
    required int niveauDemande,
    required bool estDemo,
  }) async {
    await _baseDeDonnees.insert(
      tableContexteSession,
      <String, Object?>{
        'id': 1,
        'patient_id': patientId,
        'patient_initiales': patientInitiales,
        'niveau_demande': niveauDemande,
        'est_demo': estDemo ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> lireContexteSession() async {
    final lignes = await _baseDeDonnees.query(tableContexteSession, limit: 1);
    return lignes.isEmpty ? null : lignes.first;
  }

  Future<void> effacerContexteSession() async {
    await _baseDeDonnees.delete(tableContexteSession);
  }
}
