import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern: ensures only one instance of DatabaseHelper exists
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter to access the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('people.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Reel (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        user TEXT, 
        profilePic TEXT, 
        score REAL, 
        date TEXT, 
        status TEXT, 
        reason TEXT, 
        transcript TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Source (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reelID INTEGER,
        url TEXT,
        FOREIGN KEY (reelID) REFERENCES Reel (id) ON DELETE CASCADE
      )
    ''');
  }

  // CREATE: Add a Reel and its Sources
  Future<void> addReelWithSources(Map<String, dynamic> reelData, List<String> urls) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      int reelId = await txn.insert('Reel', reelData);
      for (String url in urls) {
        await txn.insert('Source', {'reelID': reelId, 'url': url});
      }
    });
  }

  // READ: Fetch all Reels with their Sources list
  Future<List<Map<String, dynamic>>> fetchAllReels() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> reelMaps = await db.query('Reel');

    List<Map<String, dynamic>> result = [];
    for (var reel in reelMaps) {
      Map<String, dynamic> reelWithSources = Map.of(reel);
      final sourceMaps = await db.query('Source', where: 'reelID = ?', whereArgs: [reel['id']]);
      reelWithSources['sources'] = sourceMaps.map((s) => s['url'] as String).toList();
      result.add(reelWithSources);
    }
    return result;
  }

  // READ: Fetch one Reel by username
  Future<Map<String, dynamic>?> fetchReelByUser(String username) async {
    final db = await instance.database;
    final maps = await db.query('Reel', where: 'user = ?', whereArgs: [username], limit: 1);
    
    if (maps.isEmpty) return null;
    
    Map<String, dynamic> reel = Map.of(maps.first);
    final sourceMaps = await db.query('Source', where: 'reelID = ?', whereArgs: [reel['id']]);
    reel['sources'] = sourceMaps.map((s) => s['url'] as String).toList();
    return reel;
  }

  // DELETE: Remove a Reel (Sources delete automatically via Cascade)
  Future<int> deleteReel(int id) async {
    final db = await instance.database;
    return await db.delete('Reel', where: 'id = ?', whereArgs: [id]);
  }
}
