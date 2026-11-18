import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(p.join(dir, 'mosque_chanda.db'), version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      await db.execute("CREATE TABLE members (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '', type TEXT NOT NULL, amount INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)");
      await db.execute("CREATE TABLE collections (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL, amount INTEGER NOT NULL, date TEXT NOT NULL, note TEXT NOT NULL DEFAULT '', FOREIGN KEY(member_id) REFERENCES members(id))");
      await db.execute('CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount INTEGER NOT NULL, type TEXT NOT NULL, date TEXT NOT NULL)');
    });
    return _db!;
  }
  Future<String?> getSetting(String key) async { final d=await database; final r=await d.query('settings',where:'key=?',whereArgs:[key],limit:1); return r.isEmpty?null:r.first['value'] as String; }
  Future<void> setSetting(String key,String value) async { final d=await database; await d.insert('settings',{'key':key,'value':value},conflictAlgorithm:ConflictAlgorithm.replace); }
  Future<void> addMember({required String name,required String phone,required String type,required int amount}) async { final d=await database; await d.insert('members',{'name':name,'phone':phone,'type':type,'amount':amount,'created_at':DateTime.now().toIso8601String()}); }
  Future<List<Map<String,Object?>>> getMembers() async { final d=await database; return d.query('members',orderBy:'name COLLATE NOCASE ASC'); }
  Future<List<Map<String,Object?>>> searchMembers(String q) async { final d=await database; if(q.trim().isEmpty)return getMembers(); return d.query('members',where:'name LIKE ? OR phone LIKE ?',whereArgs:['%$q%','%$q%'],orderBy:'name COLLATE NOCASE ASC'); }
  Future<void> addCollection({required int memberId,required int amount,required DateTime date,required String note}) async { final d=await database; await d.insert('collections',{'member_id':memberId,'amount':amount,'date':date.toIso8601String(),'note':note}); }
  Future<void> addTransaction({required String title,required int amount,required String type,required DateTime date}) async { final d=await database; await d.insert('transactions',{'title':title,'amount':amount,'type':type,'date':date.toIso8601String()}); }
  Future<List<Map<String,Object?>>> getTransactions() async { final d=await database; final r=await d.query('transactions',orderBy:'date DESC'); return r.map((x)=>{...x,'date':DateFormat('dd/MM/yyyy').format(DateTime.parse(x['date'] as String))}).toList(); }
  Future<Map<String,int>> getSummary() async { final d=await database; int sum(String sql) => 0; final m=Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM members'))??0; final c=Sqflite.firstIntValue(await d.rawQuery('SELECT COALESCE(SUM(amount),0) FROM collections'))??0; final i=Sqflite.firstIntValue(await d.rawQuery("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='INCOME'"))??0; final e=Sqflite.firstIntValue(await d.rawQuery("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='EXPENSE'"))??0; return {'members':m,'collections':c,'income':i,'expense':e}; }
}
