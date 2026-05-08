import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Stockage {
  static const String _nomBase = 'tablette.db';
  static const int _versionSchema = 1;
  static const String tableAppairage = 'appairage';

  final Database _baseDeDonnees;

  Stockage._(this._baseDeDonnees);

  static Future<Stockage> ouvrir() async {
    final repertoire = await getApplicationDocumentsDirectory();
    final chemin = '${repertoire.path}/$_nomBase';
    final db = await openDatabase(
      chemin,
      version: _versionSchema,
      onCreate: _creerSchema,
    );
    return Stockage._(db);
  }

  static Future<Stockage> ouvrirEnMemoire(DatabaseFactory factory) async {
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: _versionSchema,
        onCreate: _creerSchema,
      ),
    );
    return Stockage._(db);
  }

  static Future<void> _creerSchema(Database db, int version) async {
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
}
