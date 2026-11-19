import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:public_file_saver/public_file_saver.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MosqueChandaApp());
}

class BHelper {
  static const bn = {'0':'০','1':'১','2':'২','3':'৩','4':'৪','5':'৫','6':'৬','7':'৭','8':'৮','9':'৯'};
  static const mNames = ['','জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন','জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];
  static String toBn(dynamic n) => n == null ? '০' : n.toString().split('').map((c) => bn[c] ?? c).join('');
  static String taka(int p) => '৳ ${toBn(p ~/ 100)}';
  static const _numberWords = <String>['শূন্য','এক','দুই','তিন','চার','পাঁচ','ছয়','সাত','আট','নয়','দশ','এগারো','বারো','তেরো','চৌদ্দ','পনেরো','ষোলো','সতেরো','আঠারো','উনিশ','বিশ','একুশ','বাইশ','তেইশ','চব্বিশ','পঁচিশ','ছাব্বিশ','সাতাশ','আটাশ','ঊনত্রিশ','ত্রিশ','একত্রিশ','বত্রিশ','তেত্রিশ','চৌত্রিশ','পঁয়ত্রিশ','ছত্রিশ','সাঁইত্রিশ','আটত্রিশ','ঊনচল্লিশ','চল্লিশ','একচল্লিশ','বিয়াল্লিশ','তেতাল্লিশ','চুয়াল্লিশ','পঁয়তাল্লিশ','ছেচল্লিশ','সাতচল্লিশ','আটচল্লিশ','ঊনপঞ্চাশ','পঞ্চাশ','একান্ন','বাহান্ন','তিপ্পান্ন','চুয়ান্ন','পঞ্চান্ন','ছাপ্পান্ন','সাতান্ন','আটান্ন','ঊনষাট','ষাট','একষট্টি','বাষট্টি','তেষট্টি','চৌষট্টি','পঁয়ষট্টি','ছেষট্টি','সাতষট্টি','আটষট্টি','ঊনসত্তর','সত্তর','একাত্তর','বাহাত্তর','তিয়াত্তর','চুয়াত্তর','পঁচাত্তর','ছিয়াত্তর','সাতাত্তর','আটাত্তর','ঊনআশি','আশি','একাশি','বিরাশি','তিরাশি','চুরাশি','পঁচাশি','ছিয়াশি','সাতাশি','আটাশি','ঊননব্বই','নব্বই','একানব্বই','বিরানব্বই','তিরানব্বই','চুরানব্বই','পঁচানব্বই','ছিয়ানব্বই','সাতানব্বই','আটানব্বই','নিরানব্বই'];
  static String _underThousand(int n) {
    if (n < 100) return _numberWords[n];
    final h = n ~/ 100, r = n % 100;
    return '${_numberWords[h]}শত${r == 0 ? '' : ' ${_numberWords[r]}'}';
  }
  static String numberWords(int n) {
    if (n <= 0) return 'শূন্য';
    final parts = <String>[];
    void add(int unit, String label) {
      final q = n ~/ unit;
      if (q > 0) { parts.add('${_underThousand(q)} $label'); n %= unit; }
    }
    add(10000000, 'কোটি');
    add(100000, 'লাখ');
    add(1000, 'হাজার');
    if (n > 0) parts.add(_underThousand(n));
    return parts.join(' ');
  }
  static String amountInWords(int paisa) => '${numberWords(paisa ~/ 100)} টাকা মাত্র';

}

class MosqueChandaApp extends StatelessWidget {
  const MosqueChandaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'মসজিদ চাঁদা হিসাব',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF087F70),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F7F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF086B60),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          side: const BorderSide(color: Color(0xFFB7D5CE)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE8E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE8E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF087F70), width: 1.6),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF087F70),
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF087F70),
        unselectedItemColor: Color(0xFF81918C),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5EEEA),
        thickness: 1,
        space: 1,
      ),
    ),
    home: const MainScreen(),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _tab = 0;
  Database? _db;
  bool _loading = true, _locked = false;
  bool _isSearchOpen = false;
  bool _isInitialized = false; // অটো ব্যাকআপ কন্ট্রোলার
  bool _backupInProgress = false;
  Timer? _autoBackupTimer;
  Timer? _periodicAutoBackupTimer;
  GoogleSignInAccount? _googleDriveAccount;
  Future<void>? _googleDriveInit;
  Timer? _googleDriveTimer;
  bool _driveBackupInProgress = false;
  String _pin = '', _search = '', _mFilter = 'MONTHLY', _cFilter = 'ALL';
  String _mosqueName = 'আপনার মসজিদের নাম';
  final _pinCtrl = TextEditingController(), _sCtrl = TextEditingController();
  int _cYear = DateTime.now().year, _cMonth = DateTime.now().month;
  int _opCash = 0, _opBank = 0, _cash = 0, _bank = 0, _mChanda = 0, _mInc = 0, _mExp = 0;
  
  List<Map<String, dynamic>> _members = [], _cashList = [], _cashChandaRows = [];

  final List<String> _defaultInCats = ['জুমার সাপ্তাহিক কালেকশন','মসজিদে মেস/ম্যাচ ভাড়া','মেসের বিদ্যুৎ বিল আদায়','এককালীন দান / অনুদান','মাদ্রাসায় দান','মাদ্রাসার ছাত্রদের বেতন আদায়','মাসিক চাঁদা','রমজান ইফতার ও তারাবিহ ফান্ড','কোরবানির চামড়া বিক্রির অর্থ','ফিতরা ও সদকা','মসজিদ উন্নয়ন বিশেষ অনুদান','অন্যান্য আয়'];
  final List<String> _defaultOutCats = ['ইমাম সাহেবের বেতন','মুয়াজ্জিন সাহেবের বেতন','খাদেমের বেতন','বিদ্যুৎ বিল','পানির বিল','মসজিদ সংস্কার ও মেরামত','রমজান ইফতার ও তারাবিহ খরচ','পরিচ্ছন্নতা সামগ্রী','অন্যান্য ব্যয়'];

  List<String> _inCats = [];
  List<String> _outCats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inCats = List.from(_defaultInCats);
    _outCats = List.from(_defaultOutCats);
    _googleDriveInit = _initializeGoogleDrive();
    _init();
  }

  Future<void> _init() async {
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'mosque_chanda_master_v1.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE members (id INTEGER PRIMARY KEY AUTOINCREMENT, book_sl INTEGER, name TEXT, phone TEXT, address TEXT DEFAULT "", monthly_rate INTEGER, member_type TEXT DEFAULT "MONTHLY", status TEXT DEFAULT "ACTIVE", skip_until TEXT DEFAULT "")');
        await db.execute('CREATE TABLE collections (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER, year INTEGER, month INTEGER, amount INTEGER, receipt_no TEXT, date TEXT, type TEXT, note TEXT, cashbook_id INTEGER)');
        await db.execute('CREATE TABLE cashbook (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, category TEXT, amount INTEGER, payment_method TEXT, voucher_no TEXT, date TEXT, note TEXT)');
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
        await db.insert('settings', {'key': 'opening_cash', 'value': '0'});
        await db.insert('settings', {'key': 'opening_bank', 'value': '0'});
        await db.insert('settings', {'key': 'app_pin', 'value': ''});
      },
      onOpen: (db) async {
        // পুরোনো ডাটাবেজে address কলাম না থাকলে নিরাপদে যোগ করা হবে।
        final memberColumns = await db.rawQuery('PRAGMA table_info(members)');
        if (!memberColumns.any((c) => c['name'] == 'address')) {
          await db.execute("ALTER TABLE members ADD COLUMN address TEXT DEFAULT ''");
        }
        if (!memberColumns.any((c) => c['name'] == 'skip_until')) {
          await db.execute("ALTER TABLE members ADD COLUMN skip_until TEXT DEFAULT ''");
        }
        if (!memberColumns.any((c) => c['name'] == 'skip_visit_period')) {
          await db.execute("ALTER TABLE members ADD COLUMN skip_visit_period TEXT DEFAULT ''");
        }
        // প্রতিটি চাঁদার মাসিক রেকর্ডকে তার মূল ক্যাশবুক এন্ট্রির সঙ্গে যুক্ত রাখি।
        final collectionColumns = await db.rawQuery('PRAGMA table_info(collections)');
        if (!collectionColumns.any((c) => c['name'] == 'cashbook_id')) {
          await db.execute('ALTER TABLE collections ADD COLUMN cashbook_id INTEGER');
        }
        // পুরোনো রেকর্ডে একক মিল পাওয়া গেলে নিরাপদে ক্যাশবুক লিংক পুনর্গঠন।
        final legacyCollections = await db.rawQuery("SELECT c.id, c.receipt_no, c.date, m.name FROM collections c LEFT JOIN members m ON m.id=c.member_id WHERE c.cashbook_id IS NULL AND COALESCE(c.receipt_no,'')!=''");
        for (final item in legacyCollections) {
          final memberName = (item['name'] ?? '').toString();
          if (memberName.isEmpty) continue;
          final matches = await db.query('cashbook', where: 'voucher_no=? AND date=? AND category=? AND note LIKE ?', whereArgs: [item['receipt_no'], item['date'], 'মাসিক চাঁদা', '$memberName — %']);
          if (matches.length == 1) {
            await db.update('collections', {'cashbook_id': matches.first['id']}, where: 'id=?', whereArgs: [item['id']]);
          }
        }
        // বাৎসরিক ধার্যকে পূর্ণ টাকায় স্থিতিশীল রাখতে ভাগের ভগ্নাংশ সমন্বয়।
        final yearlyMembers = await db.query('members', where: 'member_type=?', whereArgs: ['YEARLY']);
        for (final member in yearlyMembers) {
          final oldRate = member['monthly_rate'] as int? ?? 0;
          final annualTaka = (oldRate * 12 + 50) ~/ 100;
          final correctedRate = (annualTaka * 100 + 11) ~/ 12;
          if (oldRate != correctedRate) {
            await db.update('members', {'monthly_rate': correctedRate}, where: 'id=?', whereArgs: [member['id']]);
          }
        }
        await db.execute('CREATE TABLE IF NOT EXISTS custom_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, name TEXT UNIQUE)');
        await db.execute('CREATE TABLE IF NOT EXISTS cashbook_items (id INTEGER PRIMARY KEY AUTOINCREMENT, cashbook_id INTEGER, title TEXT, amount INTEGER, date TEXT)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_collections_member_period ON collections(member_id, year, month)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_collections_cashbook_id ON collections(cashbook_id)');
      },
    );

    final mosqueRows = await _db!.query('settings', where: 'key=?', whereArgs: ['mosque_name'], limit: 1);
    if (mosqueRows.isNotEmpty && (mosqueRows.first['value'] ?? '').toString().trim().isNotEmpty) {
      _mosqueName = mosqueRows.first['value'].toString();
    } else {
      await _db!.insert('settings', {'key': 'mosque_name', 'value': _mosqueName}, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final pRes = await _db!.query('settings', where: 'key="app_pin"');
    if (pRes.isNotEmpty && pRes.first['value'].toString().trim().isNotEmpty) {
      _pin = pRes.first['value'].toString().trim();
      _locked = true;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    if (_db == null || !mounted) return;
    setState(() => _loading = true);

    final cIn = await _db!.query('custom_categories', where: 'type="INCOME"');
    final cOut = await _db!.query('custom_categories', where: 'type="EXPENSE"');
    _inCats = List.from(_defaultInCats)..addAll(cIn.map((e) => e['name'].toString()));
    _outCats = List.from(_defaultOutCats)..addAll(cOut.map((e) => e['name'].toString()));

    final oc = await _db!.query('settings', where: 'key="opening_cash"');
    _opCash = oc.isNotEmpty ? (int.tryParse(oc.first['value'].toString()) ?? 0) : 0;
    final ob = await _db!.query('settings', where: 'key="opening_bank"');
    _opBank = ob.isNotEmpty ? (int.tryParse(ob.first['value'].toString()) ?? 0) : 0;

    // ১ নভেম্বর ২০২৬ থেকে নতুন নগদ/ব্যাংক হিসাব গণনা হবে।
    // এর আগের সব এন্ট্রি শুধু পুরোনো রেকর্ড; শুরুর তহবিলের সঙ্গে যোগ হবে না।
    const accountingStartDate = '2026-11-01';
    final cashIn = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='INCOME' AND payment_method='CASH' AND date>=?",
      [accountingStartDate],
    )).first['s'] as int;
    // নভেম্বর থেকে ক্যাশবুকে লিংক না থাকা আদায় নগদ হিসেবে একবার যোগ হবে।
    final unlinkedCashCollections = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM collections WHERE cashbook_id IS NULL AND date>=?",
      [accountingStartDate],
    )).first['s'] as int;
    final cashOut = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='EXPENSE' AND payment_method='CASH' AND date>=?",
      [accountingStartDate],
    )).first['s'] as int;
    final tB = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='TRANSFER' AND payment_method='CASH_TO_BANK' AND date>=?",
      [accountingStartDate],
    )).first['s'] as int;
    final tC = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='TRANSFER' AND payment_method='BANK_TO_CASH' AND date>=?",
      [accountingStartDate],
    )).first['s'] as int;
    _cash = _opCash + cashIn + unlinkedCashCollections - cashOut - tB + tC;

    final bIn = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='INCOME' AND payment_method='BANK' AND date>=?",
      [accountingStartDate],
    )).first['s'] as int;
    final bOut = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='EXPENSE' AND payment_method='BANK' AND date>=?",
      [accountingStartDate],
    )).first['s'] as int;
    _bank = _opBank + bIn - bOut + tB - tC;

    final mp = '$_cYear-${_cMonth.toString().padLeft(2, '0')}';
    // "এই মাসে যাব না" অবস্থা শুধু নির্বাচিত মাসের জন্য; মাস বদলালে নিজে থেকেই সক্রিয় হবে।
    await _db!.update(
      'members',
      {'status': 'ACTIVE', 'skip_visit_period': ''},
      where: "status=? AND COALESCE(skip_visit_period, '') != ?",
      whereArgs: ['NO_VISIT', mp],
    );
    _mChanda = (await _db!.rawQuery("SELECT COALESCE(SUM(amount),0) as s FROM collections WHERE substr(date,1,7)=?", [mp])).first['s'] as int;
    final monthCashbookIncome = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='INCOME' AND substr(date,1,7)=?", [mp]
    )).first['s'] as int;
    final monthUnlinkedCollections = (await _db!.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as s FROM collections WHERE cashbook_id IS NULL AND substr(date,1,7)=?", [mp]
    )).first['s'] as int;
    _mInc = monthCashbookIncome + monthUnlinkedCollections;
    _mExp = (await _db!.rawQuery("SELECT COALESCE(SUM(amount),0) as s FROM cashbook WHERE type='EXPENSE' AND substr(date,1,7)=?", [mp])).first['s'] as int;
    _cashList = await _db!.rawQuery("SELECT * FROM cashbook WHERE substr(date,1,7)=? ORDER BY date DESC, id DESC", [mp]);
    // ক্যাশবুকে আলাদা রিসিভ না থাকলেও নির্বাচিত মাসের সব সদস্যের চাঁদা গ্রুপে দেখাই।
    _cashChandaRows = await _db!.rawQuery("""
      SELECT c.member_id, m.name AS member_name, c.receipt_no, c.date,
             MAX(c.cashbook_id) AS cashbook_id,
             SUM(c.amount) AS amount,
             MIN(c.year * 12 + c.month) AS first_period,
             MAX(c.year * 12 + c.month) AS last_period,
             COUNT(*) AS period_count
      FROM collections c
      LEFT JOIN members m ON m.id = c.member_id
      WHERE substr(c.date, 1, 7) = ?
      GROUP BY c.member_id, c.receipt_no, c.date
      ORDER BY c.date DESC, m.book_sl ASC, c.id DESC
    """, [mp]);

    final rawM = await _db!.query('members', orderBy: 'book_sl ASC, id ASC');
    // সদস্যপ্রতি আলাদা query না করে দুইটি aggregate query-তে সর্বশেষ জমা ও নির্বাচিত মাসের জমা আনি।
    final lastPaidRows = await _db!.rawQuery(
      'SELECT member_id, MAX(year * 12 + month) AS last_period FROM collections GROUP BY member_id',
    );
    final lastPaidByMember = <int, int>{
      for (final row in lastPaidRows)
        (row['member_id'] as num).toInt(): (row['last_period'] as num).toInt(),
    };
    final currentPaidRows = await _db!.rawQuery(
      'SELECT member_id, COUNT(*) AS total FROM collections WHERE substr(date,1,7)=? GROUP BY member_id',
      [mp],
    );
    final currentPaidByMember = <int, int>{
      for (final row in currentPaidRows)
        (row['member_id'] as num).toInt(): (row['total'] as num).toInt(),
    };

    List<Map<String, dynamic>> res = [];
    for (var m in rawM) {
      final memberId = (m['id'] as num).toInt();
      final lastPeriod = lastPaidByMember[memberId];
      String lpText = 'কোন জমা নেই';
      bool covered = false;
      if (lastPeriod != null) {
        final ly = (lastPeriod - 1) ~/ 12;
        final lm = ((lastPeriod - 1) % 12) + 1;
        lpText = '${BHelper.mNames[lm]} ${BHelper.toBn(ly)} পর্যন্ত পরিশোধিত';
        covered = (ly * 12 + lm) >= (_cYear * 12 + _cMonth);
      }
      final thisMonthPaidCount = currentPaidByMember[memberId] ?? 0;
      res.add({
        ...m,
        'lp_text': lpText,
        'covered': covered,
        'paid_this_month': thisMonthPaidCount > 0,
        'skip_until': (m['skip_until'] ?? '').toString(),
      });
    }
    _members = res;
    if (!mounted) return;
    setState(() => _loading = false);

    // ডাটা পরিবর্তনের পর ব্যাকআপ পেন্ডিং রাখি; ব্যাকগ্রাউন্ড থেকে ফিরলে আবার চেষ্টা হবে।
    await _db!.insert('settings', {'key': 'telegram_backup_pending_at', 'value': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
    // প্রথম চালু হওয়ার পরও একবার অটো ব্যাকআপের চেষ্টা হবে।
    _isInitialized = true;
    _scheduleAutoBackup();
    _scheduleGoogleDriveBackup();

    // অ্যাপ খোলা থাকলে প্রতি ২৪ ঘণ্টায় অন্তত একবার ব্যাকআপের চেষ্টা।
    _periodicAutoBackupTimer ??= Timer.periodic(const Duration(hours: 24), (_) {
      if (mounted) {
        _sendBackupToTelegram(showToast: false, isAuto: true);
        _scheduleGoogleDriveBackup();
      }
    });
  }

  Future<String> _readSetting(String key, {String fallback = ''}) async {
    final rows = await _db!.query('settings', where: 'key=?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? fallback : (rows.first['value']?.toString() ?? fallback);
  }

  void _scheduleAutoBackup({Duration delay = const Duration(seconds: 8)}) {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer(delay, () {
      if (mounted) _sendBackupToTelegram(showToast: false, isAuto: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _checkAutoBackupOnResume();
    }
  }

  Future<void> _checkAutoBackupOnResume() async {
    if (_db == null) return;
    final pending = await _readSetting('telegram_backup_pending_at');
    final last = await _readSetting('telegram_last_auto_backup');
    final lastTime = DateTime.tryParse(last);
    final due = pending.isNotEmpty || lastTime == null ||
        DateTime.now().difference(lastTime) >= const Duration(hours: 24);
    if (due) {
      _scheduleAutoBackup(delay: const Duration(seconds: 3));
    }
    _scheduleGoogleDriveBackup(delay: const Duration(seconds: 6));
  }

  Future<void> _configureTelegram() async {
    if (_db == null) return;
    final tokenC = TextEditingController(
      text: await _readSetting('telegram_bot_token'),
    );
    final chatC = TextEditingController(
      text: await _readSetting('telegram_chat_id'),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Telegram ব্যাকআপ সেটআপ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BotFather থেকে পাওয়া নতুন Bot Token এবং Telegram Chat ID দিন। Token গোপন রাখুন।',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenC,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Telegram Bot Token',
                  hintText: '123456:ABC-...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: chatC,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Telegram Chat ID',
                  hintText: 'Telegram Chat ID লিখুন',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tokenC.text.trim().isEmpty || chatC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bot Token এবং Chat ID দুটোই দিতে হবে।')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await _db!.insert(
        'settings',
        {'key': 'telegram_bot_token', 'value': tokenC.text.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _db!.insert(
        'settings',
        {'key': 'telegram_chat_id', 'value': chatC.text.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telegram সেটআপ সংরক্ষণ হয়েছে। এখন সংযোগ পরীক্ষা করে ব্যাকআপ পাঠাচ্ছি।')),
        );
      }
      await _sendBackupToTelegram(showToast: true);
    }
    tokenC.dispose();
    chatC.dispose();
  }

  // Telegram-এ সম্পূর্ণ SQLite ডেটার JSON ব্যাকআপ পাঠায়।
  Future<void> _sendBackupToTelegram({bool showToast = true, bool isAuto = false}) async {
    if (_db == null) return;
    if (_backupInProgress) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('একটি ব্যাকআপ ইতিমধ্যে পাঠানো হচ্ছে। একটু অপেক্ষা করুন।')),
        );
      } else if (isAuto) {
        // ম্যানুয়াল ব্যাকআপ চলার সময় অটো ব্যাকআপ বাদ না দিয়ে পরে আবার চেষ্টা করবে।
        _scheduleAutoBackup(delay: const Duration(seconds: 20));
      }
      return;
    }

    HttpClient? client;
    _backupInProgress = true;
    try {
      final token = await _readSetting('telegram_bot_token');
      final chatId = await _readSetting('telegram_chat_id');

      if (token.trim().isEmpty || token.trim() == 'YOUR_NEW_TELEGRAM_BOT_TOKEN') {
        if (showToast && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('আগে “Telegram সেটআপ” থেকে Bot Token ও Chat ID সংরক্ষণ করুন।')),
          );
        }
        return;
      }

      final safeSettings = await _db!.query(
        'settings',
        where: 'key NOT IN (?, ?, ?, ?)',
        whereArgs: ['telegram_bot_token', 'telegram_chat_id', 'telegram_last_auto_backup', 'telegram_backup_pending_at'],
      );
      final bData = {
        'app': 'mosque_chanda_master_v1',
        'saved_at': DateTime.now().toIso8601String(),
        'members': await _db!.query('members'),
        'collections': await _db!.query('collections'),
        'cashbook': await _db!.query('cashbook'),
        'cashbook_items': await _db!.query('cashbook_items'),
        'custom_categories': await _db!.query('custom_categories'),
        'settings': safeSettings,
      };
      final jsonBytes = utf8.encode(jsonEncode(bData));
      final boundary = '----MosqueChandaTelegram${DateTime.now().microsecondsSinceEpoch}';
      final bytes = BytesBuilder();

      void addField(String name, String value) {
        bytes.add(utf8.encode('--$boundary\r\n'));
        bytes.add(utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
        bytes.add(utf8.encode('$value\r\n'));
      }

      void addFile(String name, String filename, List<int> fileBytes) {
        bytes.add(utf8.encode('--$boundary\r\n'));
        bytes.add(utf8.encode('Content-Disposition: form-data; name="$name"; filename="$filename"\r\n'));
        bytes.add(utf8.encode('Content-Type: application/json; charset=utf-8\r\n\r\n'));
        bytes.add(fileBytes);
        bytes.add(utf8.encode('\r\n'));
      }

      addField('chat_id', chatId.trim());
      addField(
        'caption',
        '🕌 $_mosqueName - ডেটাবেজ ব্যাকআপ\n'
        'তারিখ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
      addFile(
        'document',
        'mosque_chanda_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        jsonBytes,
      );
      bytes.add(utf8.encode('--$boundary--\r\n'));

      client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
      final uri = Uri.parse('https://api.telegram.org/bot${token.trim()}/sendDocument');
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 30));
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      final payload = bytes.toBytes();
      request.contentLength = payload.length;
      request.add(payload);

      final response = await request.close().timeout(const Duration(seconds: 60));
      final responseText = await utf8.decoder.bind(response).join();
      Map<String, dynamic> result = {};
      try {
        result = Map<String, dynamic>.from(jsonDecode(responseText));
      } catch (_) {}

      if (response.statusCode != 200 || result['ok'] != true) {
        final description = result['description']?.toString() ?? 'HTTP ${response.statusCode}';
        throw Exception(description);
      }

      await _db!.insert(
        'settings',
        {'key': 'telegram_last_auto_backup', 'value': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _db!.delete('settings', where: 'key=?', whereArgs: ['telegram_backup_pending_at']);
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('আলহামদুলিল্লাহ! Telegram-এ ব্যাকআপ সফলভাবে পাঠানো হয়েছে।')),
        );
      }
    } catch (e) {
      if (showToast && mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Telegram ব্যাকআপ ব্যর্থ: $message')),
        );
      } else if (isAuto && mounted) {
        // নেটওয়ার্ক সাময়িকভাবে না থাকলে ৫ মিনিট পর আবার চেষ্টা।
        _scheduleAutoBackup(delay: const Duration(minutes: 5));
      }
    } finally {
      client?.close(force: true);
      _backupInProgress = false;
    }
  }

  static const String _driveClientId = '';
  static const List<String> _driveScopes = ['https://www.googleapis.com/auth/drive.file'];

  Future<void> _initializeGoogleDrive() async {
    try {
      await GoogleSignIn.instance.initialize(serverClientId: _driveClientId.isEmpty ? null : _driveClientId);
      final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (attempt != null) _googleDriveAccount = await attempt;
    } catch (_) {
      // Google Drive setup failure must never stop the local database or Telegram backup.
    }
  }

  void _scheduleGoogleDriveBackup({Duration delay = const Duration(seconds: 12)}) {
    _googleDriveTimer?.cancel();
    _googleDriveTimer = Timer(delay, () async {
      if (!mounted || _db == null) return;
      final enabled = await _readSetting('google_drive_backup_enabled');
      if (enabled != '1') return;
      await _sendBackupToGoogleDrive(showToast: false, allowPrompt: false);
    });
  }

  Future<void> _sendBackupToGoogleDrive({bool showToast = true, bool allowPrompt = true}) async {
    if (_db == null || _driveBackupInProgress) return;
    _driveBackupInProgress = true;
    HttpClient? client;
    try {
      await (_googleDriveInit ??= _initializeGoogleDrive());
      GoogleSignInAccount? account = _googleDriveAccount;
      if (account == null && allowPrompt) {
        account = await GoogleSignIn.instance.authenticate();
        _googleDriveAccount = account;
      } else if (account == null) {
        final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
        if (attempt != null) {
          account = await attempt;
          _googleDriveAccount = account;
        }
      }
      if (account == null) {
        if (showToast && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('আগে Google Drive-এর জন্য Google অ্যাকাউন্ট সংযুক্ত করুন।')),
          );
        }
        return;
      }

      var authorization = await account.authorizationClient.authorizationForScopes(_driveScopes);
      if (authorization == null && allowPrompt) {
        authorization = await account.authorizationClient.authorizeScopes(_driveScopes);
      }
      if (authorization == null) {
        if (showToast && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Drive-এর অনুমতি আবার দিতে হবে। ব্যাকআপ বাটনে চাপ দিন।')),
          );
        }
        return;
      }

      final safeSettings = await _db!.query(
        'settings',
        where: 'key NOT IN (?, ?, ?, ?, ?, ?)',
        whereArgs: ['telegram_bot_token', 'telegram_chat_id', 'telegram_last_auto_backup',
          'telegram_backup_pending_at', 'google_drive_backup_enabled', 'google_drive_last_backup'],
      );
      final backupData = {
        'app': 'mosque_chanda_master_v1',
        'saved_at': DateTime.now().toIso8601String(),
        'members': await _db!.query('members'),
        'collections': await _db!.query('collections'),
        'cashbook': await _db!.query('cashbook'),
        'cashbook_items': await _db!.query('cashbook_items'),
        'custom_categories': await _db!.query('custom_categories'),
        'settings': safeSettings,
      };
      final jsonBytes = utf8.encode(jsonEncode(backupData));
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'mosque_chanda_backup_$stamp.json';
      final boundary = '----MosqueChandaDrive${DateTime.now().microsecondsSinceEpoch}';
      final body = BytesBuilder();
      body.add(utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'));
      body.add(utf8.encode(jsonEncode({'name': filename, 'mimeType': 'application/json'})));
      body.add(utf8.encode('\r\n--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'));
      body.add(jsonBytes);
      body.add(utf8.encode('\r\n--$boundary--\r\n'));

      client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
      final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name');
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 30));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${authorization.accessToken}');
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/related; boundary=$boundary');
      final payload = body.toBytes();
      request.contentLength = payload.length;
      request.add(payload);
      final response = await request.close().timeout(const Duration(seconds: 60));
      final responseText = await utf8.decoder.bind(response).join();
      Map<String, dynamic> result = {};
      try { result = Map<String, dynamic>.from(jsonDecode(responseText)); } catch (_) {}
      if (response.statusCode < 200 || response.statusCode >= 300 || result['id'] == null) {
        final message = result['error'] is Map
            ? (result['error']['message']?.toString() ?? 'HTTP ${response.statusCode}')
            : 'HTTP ${response.statusCode}';
        throw Exception(message);
      }

      await _db!.insert('settings', {'key': 'google_drive_backup_enabled', 'value': '1'},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _db!.insert('settings', {'key': 'google_drive_last_backup', 'value': DateTime.now().toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace);
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive-এ ব্যাকআপ সফলভাবে সংরক্ষিত হয়েছে।')),
        );
      }
    } catch (e) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Drive ব্যাকআপ ব্যর্থ: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      client?.close(force: true);
      _driveBackupInProgress = false;
    }
  }

  Future<bool> _restoreFromJsonString(String str) async {
    try {
      final decoded = jsonDecode(str.trim());
      if (decoded is! Map) throw const FormatException('JSON ফাইলের গঠন সঠিক নয়।');
      final m = Map<String, dynamic>.from(decoded);
      if (m['app'] != 'mosque_chanda_master_v1') {
        throw const FormatException('ব্যাকআপ ফাইলের ভার্সন মেলেনি।');
      }

      // আগে সব টেবিলের তথ্য যাচাই করা হয়; ভুল JSON হলে বর্তমান ডাটা ছোঁয়া হবে না।
      List<Map<String, dynamic>> readRows(String key) {
        final value = m[key];
        if (value == null) return <Map<String, dynamic>>[];
        if (value is! List) throw FormatException('$key অংশটি সঠিক নয়।');
        return value.map((item) {
          if (item is! Map) throw FormatException('$key অংশে ভুল রেকর্ড আছে।');
          return Map<String, dynamic>.from(item);
        }).toList();
      }

      final members = readRows('members');
      final collections = readRows('collections');
      final cashbook = readRows('cashbook');
      final settings = readRows('settings');
      final cashbookItems = readRows('cashbook_items');
      final customCategories = readRows('custom_categories');
      for (final requiredKey in ['members', 'collections', 'cashbook', 'settings']) {
        if (!m.containsKey(requiredKey) || m[requiredKey] is! List) {
          throw FormatException('ব্যাকআপে $requiredKey অংশ নেই বা সঠিক নয়। বর্তমান ডাটা নিরাপদ রাখা হয়েছে।');
        }
      }
      final memberIds = members.map((r) => r['id']).where((id) => id != null).toSet();
      for (final row in collections) {
        if (row['member_id'] == null || !memberIds.contains(row['member_id'])) {
          throw const FormatException('ব্যাকআপে এমন জমার রেকর্ড আছে যার সদস্য পাওয়া যায়নি। বর্তমান ডাটা অপরিবর্তিত রাখা হয়েছে।');
        }
      }

      // একক transaction: মাঝপথে কোনো সমস্যা হলে আগের ডাটা স্বয়ংক্রিয়ভাবে ফিরে থাকবে।
      await _db!.transaction((txn) async {
        await txn.execute('CREATE TABLE IF NOT EXISTS members (id INTEGER PRIMARY KEY AUTOINCREMENT, book_sl INTEGER, name TEXT, phone TEXT, address TEXT DEFAULT "", monthly_rate INTEGER, member_type TEXT DEFAULT "MONTHLY", status TEXT DEFAULT "ACTIVE", skip_until TEXT DEFAULT "", skip_visit_period TEXT DEFAULT "")');
        await txn.execute('CREATE TABLE IF NOT EXISTS collections (id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER, year INTEGER, month INTEGER, amount INTEGER, receipt_no TEXT, date TEXT, type TEXT, note TEXT, cashbook_id INTEGER)');
        final restoreMemberColumns = await txn.rawQuery('PRAGMA table_info(members)');
        if (!restoreMemberColumns.any((c) => c['name'] == 'skip_visit_period')) await txn.execute("ALTER TABLE members ADD COLUMN skip_visit_period TEXT DEFAULT ''");
        final restoreCollectionColumns = await txn.rawQuery('PRAGMA table_info(collections)');
        if (!restoreCollectionColumns.any((c) => c['name'] == 'cashbook_id')) await txn.execute('ALTER TABLE collections ADD COLUMN cashbook_id INTEGER');
        await txn.execute('CREATE INDEX IF NOT EXISTS idx_collections_member_period ON collections(member_id, year, month)');
        await txn.execute('CREATE INDEX IF NOT EXISTS idx_collections_cashbook_id ON collections(cashbook_id)');
        await txn.execute('CREATE TABLE IF NOT EXISTS cashbook (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, category TEXT, amount INTEGER, payment_method TEXT, voucher_no TEXT, date TEXT, note TEXT)');
        await txn.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
        await txn.execute('CREATE TABLE IF NOT EXISTS custom_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, name TEXT UNIQUE)');
        await txn.execute('CREATE TABLE IF NOT EXISTS cashbook_items (id INTEGER PRIMARY KEY AUTOINCREMENT, cashbook_id INTEGER, title TEXT, amount INTEGER, date TEXT)');

        await txn.delete('members');
        await txn.delete('collections');
        await txn.delete('cashbook');
        await txn.delete('settings',
          where: 'key NOT IN (?, ?)',
          whereArgs: ['telegram_bot_token', 'telegram_chat_id']);
        await txn.delete('custom_categories');
        await txn.delete('cashbook_items');

        const mCols = {'id', 'book_sl', 'name', 'phone', 'address', 'monthly_rate', 'member_type', 'status', 'skip_until', 'skip_visit_period'};
        for (final r in members) {
          final row = Map<String, dynamic>.from(r)..removeWhere((k, v) => !mCols.contains(k));
          await txn.insert('members', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        const cCols = {'id', 'member_id', 'year', 'month', 'amount', 'receipt_no', 'date', 'type', 'note', 'cashbook_id'};
        for (final r in collections) {
          final row = Map<String, dynamic>.from(r)..removeWhere((k, v) => !cCols.contains(k));
          await txn.insert('collections', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        const cbCols = {'id', 'type', 'category', 'amount', 'payment_method', 'voucher_no', 'date', 'note'};
        for (final r in cashbook) {
          final row = Map<String, dynamic>.from(r)..removeWhere((k, v) => !cbCols.contains(k));
          await txn.insert('cashbook', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        const sCols = {'key', 'value'};
        for (final r in settings) {
          final row = Map<String, dynamic>.from(r)..removeWhere((k, v) =>
            !sCols.contains(k) || k == 'telegram_bot_token' || k == 'telegram_chat_id');
          if (row.isNotEmpty) {
            await txn.insert('settings', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        for (final r in cashbookItems) {
          await txn.insert('cashbook_items', r, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final r in customCategories) {
          await txn.insert('custom_categories', r, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('আলহামদুলিল্লাহ! সকল ডাটা সফলভাবে রিস্টোর হয়েছে!')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('রিস্টোর করতে সমস্যা: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _pickJsonBackupAndRestore() async {
    try {
      final result = await const MethodChannel('mosque_chanda/file_picker')
          .invokeMapMethod<String, dynamic>('pickJsonBackup');
      if (result == null) return;

      final fileName = result['name'] as String? ?? 'backup.json';
      final rawBytes = result['bytes'];
      final Uint8List? bytes = rawBytes is Uint8List
          ? rawBytes
          : rawBytes is List
              ? Uint8List.fromList(rawBytes.cast<int>())
              : null;

      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('ফাইলটি পড়া যাচ্ছে না।');
      }
      final jsonText = utf8.decode(bytes, allowMalformed: false);
      final preview = jsonDecode(jsonText);
      if (preview is! Map || preview['app'] != 'mosque_chanda_master_v1') {
        throw const FormatException('এটি এই অ্যাপের সঠিক JSON ব্যাকআপ নয়।');
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('JSON ব্যাকআপ রিস্টোর করবেন?'),
          content: Text('$fileName ফাইল থেকে তথ্য ফিরিয়ে আনা হবে। এতে এই ফোনের বর্তমান হিসাব ব্যাকআপের তথ্য দিয়ে প্রতিস্থাপিত হবে।'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('রিস্টোর করুন')),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await _restoreFromJsonString(jsonText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON ফাইল পড়তে সমস্যা: $e')),
        );
      }
    }
  }

  List<int> _buildPdfFromRgb(int width, int height, Uint8List rgbBytes) {
    final compressed = zlib.encode(rgbBytes);
    final buffer = BytesBuilder();
    final offsets = <int>[];

    void writeString(String s) { buffer.add(utf8.encode(s)); }

    writeString('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n');

    offsets.add(buffer.length);
    writeString('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    offsets.add(buffer.length);
    writeString('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    const double pageW = 595.0;
    const double pageH = 842.0;
    const double margin = 28.0;
    const double maxW = pageW - (margin * 2);
    const double maxH = pageH - (margin * 2);

    double scaleW = maxW / width;
    double scaleH = maxH / height;
    double scale = scaleW < scaleH ? scaleW : scaleH;

    double drawW = width * scale;
    double drawH = height * scale;
    double posX = margin + (maxW - drawW) / 2;
    double posY = margin + (maxH - drawH) / 2;

    offsets.add(buffer.length);
    writeString('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageW.toInt()} ${pageH.toInt()}] /Resources << /XObject << /Im1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n');

    offsets.add(buffer.length);
    writeString('4 0 obj\n<< /Type /XObject /Subtype /Image /Width $width /Height $height /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode /Length ${compressed.length} >>\nstream\n');
    buffer.add(compressed);
    writeString('\nendstream\nendobj\n');

    final content = 'q ${drawW.toStringAsFixed(2)} 0 0 ${drawH.toStringAsFixed(2)} ${posX.toStringAsFixed(2)} ${posY.toStringAsFixed(2)} cm /Im1 Do Q';
    final contentBytes = utf8.encode(content);
    offsets.add(buffer.length);
    writeString('5 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n$content\nendstream\nendobj\n');

    final startXref = buffer.length;
    writeString('xref\n0 6\n');
    writeString('0000000000 65535 f \n');
    for (var offset in offsets) {
      writeString('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }

    writeString('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF');
    return buffer.toBytes();
  }

  List<int> _buildMultiPagePdfFromRgb(int width, int height, Uint8List rgbBytes) {
    const double pageW = 595.0;
    const double pageH = 842.0;
    const double margin = 24.0;
    const double maxW = pageW - (margin * 2);
    const double maxH = pageH - (margin * 2);
    final sliceHeight = ((width * maxH) / maxW).floor().clamp(1, height).toInt();
    final pageCount = (height + sliceHeight - 1) ~/ sliceHeight;
    final objectCount = 2 + (pageCount * 3);
    final buffer = BytesBuilder();
    final offsets = List<int>.filled(objectCount + 1, 0);

    void writeString(String value) => buffer.add(utf8.encode(value));
    void writeObject(int number, String body) {
      offsets[number] = buffer.length;
      writeString('$number 0 obj\n$body\nendobj\n');
    }

    writeString('%PDF-1.4\n%\xFF\xFF\xFF\xFF\n');
    writeObject(1, '<< /Type /Catalog /Pages 2 0 R >>');
    final kids = List.generate(pageCount, (i) => '${3 + (i * 3)} 0 R').join(' ');
    writeObject(2, '<< /Type /Pages /Kids [$kids] /Count $pageCount >>');

    for (var page = 0; page < pageCount; page++) {
      final top = page * sliceHeight;
      final pagePixelHeight = (height - top).clamp(1, sliceHeight).toInt();
      final pageRgb = Uint8List(width * pagePixelHeight * 3);
      final sourceStart = top * width * 3;
      pageRgb.setRange(0, pageRgb.length, rgbBytes, sourceStart);
      final compressed = zlib.encode(pageRgb);
      final pageObject = 3 + (page * 3);
      final imageObject = pageObject + 1;
      final contentObject = pageObject + 2;
      final drawH = pagePixelHeight * (maxW / width);

      writeObject(
        pageObject,
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageW.toInt()} ${pageH.toInt()}] /Resources << /XObject << /Im1 $imageObject 0 R >> >> /Contents $contentObject 0 R >>',
      );

      offsets[imageObject] = buffer.length;
      writeString('$imageObject 0 obj\n<< /Type /XObject /Subtype /Image /Width $width /Height $pagePixelHeight /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode /Length ${compressed.length} >>\nstream\n');
      buffer.add(compressed);
      writeString('\nendstream\nendobj\n');

      final content = 'q ${maxW.toStringAsFixed(2)} 0 0 ${drawH.toStringAsFixed(2)} ${margin.toStringAsFixed(2)} ${margin.toStringAsFixed(2)} cm /Im1 Do Q';
      final contentBytes = utf8.encode(content);
      offsets[contentObject] = buffer.length;
      writeString('$contentObject 0 obj\n<< /Length ${contentBytes.length} >>\nstream\n$content\nendstream\nendobj\n');
    }

    final startXref = buffer.length;
    writeString('xref\n0 ${objectCount + 1}\n');
    writeString('0000000000 65535 f \n');
    for (var i = 1; i <= objectCount; i++) {
      writeString('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
    }
    writeString('trailer\n<< /Size ${objectCount + 1} /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF');
    return buffer.toBytes();
  }

  Future<void> _exportBoundaryToMultiPagePdf(GlobalKey key, String fileName, BuildContext ctx, String successMsg) async {
    ui.Image? image;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary || !renderObject.attached) {
        throw Exception('PDF-এর কনটেন্ট প্রস্তুত হয়নি। আবার চেষ্টা করুন।');
      }

      image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('PDF ছবি তৈরি করা যায়নি।');

      final width = image.width;
      final height = image.height;
      final rgba = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final rgbBytes = Uint8List(width * height * 3);
      var sourceIndex = 0;
      var targetIndex = 0;
      for (var i = 0; i < width * height; i++) {
        rgbBytes[targetIndex++] = rgba[sourceIndex++];
        rgbBytes[targetIndex++] = rgba[sourceIndex++];
        rgbBytes[targetIndex++] = rgba[sourceIndex++];
        sourceIndex++;
      }

      final pdfBytes = Uint8List.fromList(_buildMultiPagePdfFromRgb(width, height, rgbBytes));
      final saved = await PublicFileSaver().save(
        bytes: pdfBytes,
        fileName: '$fileName.pdf',
        mimeType: 'application/pdf',
        subDir: 'MosqueChanda',
      );

      if (!mounted) return;
      if (saved != null && saved.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successMsg Download/MosqueChanda ফোল্ডারে পাওয়া যাবে।')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF সেভ হয়নি। আবার চেষ্টা করুন।')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF তৈরি বা সেভ করতে সমস্যা: $e')),
        );
      }
    } finally {
      image?.dispose();
    }
  }

  Future<void> _exportBoundaryToPdf(GlobalKey key, String fileName, BuildContext ctx, String successMsg) async {
    ui.Image? image;
    try {
      // Dialog-এর RepaintBoundary পুরোপুরি paint হওয়া পর্যন্ত অপেক্ষা করি।
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary || !renderObject.attached) {
        throw Exception('PDF-এর কনটেন্ট প্রস্তুত হয়নি। আবার চেষ্টা করুন।');
      }

      image = await renderObject.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('PDF ছবি তৈরি করা যায়নি।');

      final width = image.width;
      final height = image.height;
      final rgba = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final rgbBytes = Uint8List(width * height * 3);
      var sourceIndex = 0;
      var targetIndex = 0;
      for (var i = 0; i < width * height; i++) {
        rgbBytes[targetIndex++] = rgba[sourceIndex++];
        rgbBytes[targetIndex++] = rgba[sourceIndex++];
        rgbBytes[targetIndex++] = rgba[sourceIndex++];
        sourceIndex++; // Alpha বাদ
      }

      final pdfBytes = Uint8List.fromList(_buildPdfFromRgb(width, height, rgbBytes));
      final saved = await PublicFileSaver().save(
        bytes: pdfBytes,
        fileName: '$fileName.pdf',
        mimeType: 'application/pdf',
        subDir: 'MosqueChanda',
      );

      if (!mounted) return;
      if (saved != null && saved.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successMsg Download/MosqueChanda ফোল্ডারে পাওয়া যাবে।')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF সেভ হয়নি। আবার চেষ্টা করুন।')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF তৈরি বা সেভ করতে সমস্যা: $e')),
        );
      }
    } finally {
      image?.dispose();
    }
  }

void _addMember({Map<String, dynamic>? member}) {
    final slC = TextEditingController(text: member?['book_sl']?.toString() ?? '');
    final nC = TextEditingController(text: member?['name'] ?? '');
    final pC = TextEditingController(text: member?['phone'] ?? '');
    final addressC = TextEditingController(text: member?['address'] ?? '');
    String type = member?['member_type'] ?? 'MONTHLY', st = member?['status'] ?? 'ACTIVE';
    final rC = TextEditingController(text: member != null ? (type == 'YEARLY' ? ((member['monthly_rate'] * 12 + 50) ~/ 100) : (member['monthly_rate'] ~/ 100)).toString() : '200');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: Text(member == null ? 'নতুন সদস্য' : 'তথ্য পরিবর্তন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: slC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ক্রমিক নম্বর (বাধ্যতামূলক)')),
                TextField(controller: nC, decoration: const InputDecoration(labelText: 'নাম (বাধ্যতামূলক)')),
                TextField(controller: pC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'মোবাইল নম্বর')),
                TextField(controller: addressC, maxLines: 2, decoration: const InputDecoration(labelText: 'ঠিকানা (শুধু বিস্তারিত পেজে দেখাবে)')),
                DropdownButtonFormField<String>(
                  value: type, decoration: const InputDecoration(labelText: 'ধরন'),
                  items: const [DropdownMenuItem(value: 'MONTHLY', child: Text('মাসিক')), DropdownMenuItem(value: 'YEARLY', child: Text('বাৎসরিক'))],
                  onChanged: (v) => setD(() { type = v!; if (member == null) rC.text = type == 'YEARLY' ? '2400' : '200'; }),
                ),
                if (member != null) DropdownButtonFormField<String>(
                  value: st, decoration: const InputDecoration(labelText: 'অবস্থা'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('সক্রিয়')),
                    DropdownMenuItem(value: 'RELOCATED', child: Text('স্থানান্তরিত')),
                    DropdownMenuItem(value: 'DECEASED', child: Text('মরহুম')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('ফাঁকা/বন্ধ')),
                    DropdownMenuItem(value: 'NO_VISIT', child: Text('এই মাসে যাব না')),
                  ],
                  onChanged: (v) => setD(() => st = v!),
                ),
                TextField(controller: rC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: type == 'YEARLY' ? 'বাৎসরিক চাঁদা (টাকা)' : 'মাসিক চাঁদা (টাকা)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                if (nC.text.trim().isEmpty) return;
                int bSl = int.tryParse(slC.text) ?? (_members.length + 1);
                int mR = type == 'YEARLY' ? (((int.tryParse(rC.text) ?? 2400) * 100 + 11) ~/ 12) : ((int.tryParse(rC.text) ?? 200) * 100);
                if (member == null) {
                  await _db!.insert('members', {'book_sl': bSl, 'name': nC.text.trim(), 'phone': pC.text.trim(), 'address': addressC.text.trim(), 'monthly_rate': mR, 'member_type': type, 'status': st, 'skip_visit_period': st == 'NO_VISIT' ? '${_cYear}-${_cMonth.toString().padLeft(2, '0')}' : ''});
                } else {
                  await _db!.update('members', {'book_sl': bSl, 'name': nC.text.trim(), 'phone': pC.text.trim(), 'address': addressC.text.trim(), 'monthly_rate': mR, 'member_type': type, 'status': st, 'skip_visit_period': st == 'NO_VISIT' ? '${_cYear}-${_cMonth.toString().padLeft(2, '0')}' : ''}, where: 'id=?', whereArgs: [member['id']]);
                }
                Navigator.pop(ctx);
                _refresh();
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _collectFee(Map<String, dynamic> member, bool isRange, {int? targetMonth, int? targetYear}) {
    int sM = targetMonth ?? _cMonth, sY = targetYear ?? _cYear, eM = targetMonth ?? _cMonth, eY = targetYear ?? _cYear;
    int rate = member['monthly_rate'] as int;
    final rC = TextEditingController(), aC = TextEditingController(text: (rate ~/ 100).toString()), nC = TextEditingController();
    String method = 'CASH';
    DateTime selectedDate = DateTime.now();
    int count() => (!isRange) ? 1 : ((eY * 12 + eM) >= (sY * 12 + sM) ? (eY * 12 + eM) - (sY * 12 + sM) + 1 : 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) {
          int cnt = count();
          void chg() { int c = count(); if (c > 0) { final isYearly = member['member_type'] == 'YEARLY'; final amountTaka = isYearly ? ((rate * c + 50) ~/ 100) : ((rate * c) ~/ 100); aC.text = amountTaka.toString(); } setD(() {}); }
          return AlertDialog(
            title: Text('${member['name']} — চাঁদা জমা'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setD(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.teal.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 18, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                'টাকা জমার তারিখ: ${BHelper.toBn(selectedDate.day)}/${BHelper.toBn(selectedDate.month)}/${BHelper.toBn(selectedDate.year)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ],
                          ),
                          const Icon(Icons.edit_calendar, size: 18, color: Colors.teal),
                        ],
                      ),
                    ),
                  ),

                  Row(children: [
                    Expanded(child: DropdownButtonFormField<int>(value: sM, decoration: InputDecoration(labelText: isRange ? 'শুরুর মাস' : 'মাস'), items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(BHelper.mNames[m]))).toList(), onChanged: (v) { sM = v!; chg(); })),
                    const SizedBox(width: 6),
                    Expanded(child: DropdownButtonFormField<int>(value: sY, decoration: InputDecoration(labelText: isRange ? 'শুরুর সাল' : 'সাল'), items: List.generate(7, (i) => _cYear - 2 + i).map((y) => DropdownMenuItem(value: y, child: Text(BHelper.toBn(y)))).toList(), onChanged: (v) { sY = v!; chg(); })),
                  ]),
                  if (isRange) ...[
                    Row(children: [
                      Expanded(child: DropdownButtonFormField<int>(value: eM, decoration: const InputDecoration(labelText: 'শেষ মাস'), items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(BHelper.mNames[m]))).toList(), onChanged: (v) { eM = v!; chg(); })),
                      const SizedBox(width: 6),
                      Expanded(child: DropdownButtonFormField<int>(value: eY, decoration: const InputDecoration(labelText: 'শেষ সাল'), items: List.generate(7, (i) => _cYear - 2 + i).map((y) => DropdownMenuItem(value: y, child: Text(BHelper.toBn(y)))).toList(), onChanged: (v) { eY = v!; chg(); })),
                    ]),
                    Text(cnt > 0 ? 'মেয়াদ: ${BHelper.toBn(cnt)} মাস' : 'ভুল তারিখ!', style: TextStyle(fontWeight: FontWeight.bold, color: cnt > 0 ? Colors.teal : Colors.red)),
                  ],
                  DropdownButtonFormField<String>(
                    value: method, decoration: const InputDecoration(labelText: 'মাধ্যম'),
                    items: const [DropdownMenuItem(value: 'CASH', child: Text('নগদ ক্যাশ')), DropdownMenuItem(value: 'BANK', child: Text('ব্যাংক একাউন্ট'))],
                    onChanged: (v) => setD(() => method = v!),
                  ),
                  TextField(controller: rC, decoration: const InputDecoration(labelText: 'কাগজের রসিদ নং (যেমন: ১০৫৪)')),
                  TextField(controller: aC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'টাকার পরিমাণ')),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: 'মন্তব্য (ঐচ্ছিক)')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white),
                onPressed: () async {
                  if (cnt <= 0) return;
                  int tk = int.tryParse(aC.text) ?? 0;
                  if (tk <= 0) return;
                  String rNo = rC.text.trim().isEmpty ? 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}' : rC.text.trim();
                  int sTot = sY * 12 + (sM - 1), eTot = (!isRange) ? sTot : eY * 12 + (eM - 1);

                  // যে মাসের সম্পূর্ণ ধার্য আগে থেকেই জমা হয়েছে, সেখানে দ্বিতীয়বার জমা আটকাই।
                  final alreadyPaidPeriods = <String>[];
                  final partialPaidPeriods = <String>[];
                  for (int period = sTot; period <= eTot; period++) {
                    final year = period ~/ 12;
                    final month = (period % 12) + 1;
                    final paidRows = await _db!.rawQuery(
                      'SELECT COALESCE(SUM(amount),0) AS total FROM collections WHERE member_id=? AND year=? AND month=?',
                      [member['id'], year, month],
                    );
                    final paidAmount = (paidRows.first['total'] as num?)?.toInt() ?? 0;
                    final monthLabel = '${BHelper.mNames[month]} ${BHelper.toBn(year)}';
                    final requiredAmount = member['member_type'] == 'YEARLY' ? rate - 1 : rate;
                    if (paidAmount >= requiredAmount) {
                      alreadyPaidPeriods.add(monthLabel);
                    } else if (paidAmount > 0) {
                      partialPaidPeriods.add(monthLabel);
                    }
                  }
                  if (alreadyPaidPeriods.isNotEmpty) {
                    await showDialog<void>(
                      context: context,
                      builder: (warningCtx) => AlertDialog(
                        title: const Text('এই মাসের চাঁদা আগেই সম্পূর্ণ জমা হয়েছে'),
                        content: Text('${alreadyPaidPeriods.join('، ')} — এই মাসগুলোর ধার্য সম্পূর্ণ পরিশোধিত। ভুল করে দ্বিতীয়বার জমা এড়াতে এই এন্ট্রি বন্ধ রাখা হয়েছে। প্রয়োজন হলে সদস্যের জমার বিবরণ থেকে আগের এন্ট্রি সংশোধন করুন।'),
                        actions: [TextButton(onPressed: () => Navigator.pop(warningCtx), child: const Text('ঠিক আছে'))],
                      ),
                    );
                    return;
                  }
                  if (partialPaidPeriods.isNotEmpty) {
                    final proceed = await showDialog<bool>(
                      context: context,
                      builder: (warningCtx) => AlertDialog(
                        title: const Text('আগে আংশিক জমা আছে'),
                        content: Text('${partialPaidPeriods.join('، ')} মাসে আগে কিছু টাকা জমা হয়েছে। নতুন টাকাটি অতিরিক্ত/বাকি জমা হিসেবে যোগ করবেন?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(warningCtx, false), child: const Text('না')),
                          ElevatedButton(onPressed: () => Navigator.pop(warningCtx, true), child: const Text('হ্যাঁ, জমা দিন')),
                        ],
                      ),
                    );
                    if (proceed != true) return;
                  }

                  // মোট জমার প্রতিটি পয়সা মাসগুলোর মধ্যে ভাগ হবে; ভাগশেষও যোগ হবে,
                  // যাতে ৪০০ টাকা কখনো ৩৯৯ টাকা হিসেবে হিসাব না হয়।
                  final totalPaisa = tk * 100;
                  final share = totalPaisa ~/ cnt;
                  final remainder = totalPaisa % cnt;
                  
                  final entryDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0).toIso8601String();
                  String pTx = !isRange ? '${BHelper.mNames[sM]} $sY' : '${BHelper.mNames[sM]} $sY হতে ${BHelper.mNames[eM]} $eY ($cnt মাস)';
                  await _db!.transaction((txn) async {
                    final cashbookId = await txn.insert('cashbook', {
                      'type': 'INCOME',
                      'category': 'মাসিক চাঁদা',
                      'amount': tk * 100,
                      'payment_method': method,
                      'voucher_no': rNo,
                      'date': entryDate,
                      'note': '${member['name']} — $pTx',
                    });
                    int monthIndex = 0;
                    for (int c = sTot; c <= eTot; c++) {
                      final monthShare = share + (monthIndex < remainder ? 1 : 0);
                      await txn.insert('collections', {
                        'member_id': member['id'],
                        'year': c ~/ 12,
                        'month': (c % 12) + 1,
                        'amount': monthShare,
                        'receipt_no': rNo,
                        'date': entryDate,
                        'type': isRange ? 'RANGE' : 'MONTHLY',
                        'note': nC.text.trim(),
                        'cashbook_id': cashbookId,
                      });
                      monthIndex++;
                    }
                  });
                  Navigator.pop(ctx);
                  _refresh();
                  _showReceipt(member['name'].toString(), member['phone'], tk * 100, rNo, pTx);
                },
                child: const Text('জমা ও রসিদ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCashbookEntrySafely(int cashbookId, {bool deleteChandaRecords = true}) async {
    await _db!.transaction((txn) async {
      final rows = await txn.query('cashbook', where: 'id=?', whereArgs: [cashbookId], limit: 1);
      if (rows.isEmpty) return;
      final entry = rows.first;
      if (entry['category'] == 'মাসিক চাঁদা') {
        final linked = await txn.query('collections', where: 'cashbook_id=?', whereArgs: [cashbookId]);
        if (!deleteChandaRecords) {
          await txn.update('collections', {'cashbook_id': null}, where: 'cashbook_id=?', whereArgs: [cashbookId]);
        } else if (linked.isNotEmpty) {
          await txn.delete('collections', where: 'cashbook_id=?', whereArgs: [cashbookId]);
        } else {
          final note = (entry['note'] ?? '').toString();
          final separator = note.indexOf(' — ');
          final memberName = separator >= 0 ? note.substring(0, separator) : '';
          if (memberName.isNotEmpty) {
            final matchingBooks = await txn.query('cashbook', columns: ['id'], where: 'voucher_no=? AND date=? AND category=? AND note LIKE ?', whereArgs: [entry['voucher_no'], entry['date'], 'মাসিক চাঁদা', '$memberName — %']);
            final memberRows = await txn.query('members', columns: ['id'], where: 'name=?', whereArgs: [memberName]);
            if (matchingBooks.length == 1 && memberRows.length == 1) {
              await txn.delete('collections', where: 'member_id=? AND receipt_no=? AND date=?', whereArgs: [memberRows.first['id'], entry['voucher_no'], entry['date']]);
            }
          }
        }
      }
      await txn.delete('cashbook_items', where: 'cashbook_id=?', whereArgs: [cashbookId]);
      await txn.delete('cashbook', where: 'id=?', whereArgs: [cashbookId]);
    });
  }

  Future<void> _showCashbookDeleteDialog(Map<String, dynamic> entry, {VoidCallback? onDeleted}) async {
    final isChanda = entry['category'] == 'মাসিক চাঁদা';
    final cashbookId = (entry['id'] as num).toInt();
    await showDialog<void>(
      context: context,
      builder: (delCtx) => AlertDialog(
        title: Text(isChanda ? 'মাসিক চাঁদার রশিদ মুছুন' : 'এন্ট্রি মুছে ফেলবেন?'),
        content: Text(isChanda ? 'আপনি কোনটি মুছতে চান?' : 'আপনি কি নিশ্চিত "' + entry['category'].toString() + '" (' + BHelper.taka(entry['amount'] as int) + ') এন্ট্রিটি মুছে ফেলতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(delCtx), child: const Text('বাতিল')),
          if (isChanda)
            OutlinedButton(
              onPressed: () async {
                await _deleteCashbookEntrySafely(cashbookId, deleteChandaRecords: false);
                if (!mounted) return;
                Navigator.pop(delCtx);
                onDeleted?.call();
                _refresh();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ক্যাশবুক এন্ট্রি মুছে গেছে; সদস্যের চাঁদার রেকর্ড ও রশিদ রাখা হয়েছে।')));
              },
              child: const Text('শুধু ক্যাশবুক মুছুন'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
            onPressed: () async {
              await _deleteCashbookEntrySafely(cashbookId);
              if (!mounted) return;
              Navigator.pop(delCtx);
              onDeleted?.call();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isChanda ? 'ক্যাশবুক ও সদস্যের চাঁদার রেকর্ড—দুটিই মুছে ফেলা হয়েছে।' : 'এন্ট্রি মুছে ফেলা হয়েছে।')));
            },
            child: Text(isChanda ? 'দুটোই মুছুন' : 'হ্যাঁ, মুছুন'),
          ),
        ],
      ),
    );
  }
  Future<void> _syncChandaCashbook(Transaction txn, int cashbookId) async {
    final rows = await txn.query('collections', where: 'cashbook_id=?', whereArgs: [cashbookId]);
    if (rows.isEmpty) {
      await txn.delete('cashbook', where: 'id=?', whereArgs: [cashbookId]);
      return;
    }
    final total = rows.fold<int>(0, (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0));
    final member = await txn.query('members', columns: ['name'], where: 'id=?', whereArgs: [rows.first['member_id']], limit: 1);
    final memberName = member.isEmpty ? 'চাঁদা' : member.first['name'].toString();
    await txn.update('cashbook', {
      'amount': total,
      'note': _chandaCashbookNote(memberName, rows),
    }, where: 'id=?', whereArgs: [cashbookId]);
  }

  Future<void> _deleteCollectionReceiptGroup(Map<String, dynamic> member, Map<String, dynamic> entry) async {
    await _db!.transaction((txn) async {
      final groupRows = await txn.query(
        'collections',
        where: 'member_id=? AND receipt_no=? AND date=?',
        whereArgs: [member['id'], entry['receipt_no'], entry['date']],
      );
      if (groupRows.isEmpty) return;

      final cashbookIds = <int>{};
      for (final row in groupRows) {
        final linkedId = (row['cashbook_id'] as num?)?.toInt();
        if (linkedId != null) {
          cashbookIds.add(linkedId);
        } else {
          final matches = await txn.query(
            'cashbook',
            columns: ['id'],
            where: 'voucher_no=? AND date=? AND category=? AND note LIKE ?',
            whereArgs: [
              entry['receipt_no'],
              entry['date'],
              'মাসিক চাঁদা',
              "${member['name']} — %",
            ],
          );
          if (matches.length > 1) {
            throw StateError('একাধিক ক্যাশবুক এন্ট্রি মিলে গেছে; ভুল হিসাব এড়াতে সম্পূর্ণ এন্ট্রি মুছে ফেলা বন্ধ রাখা হয়েছে।');
          }
          if (matches.length == 1) {
            cashbookIds.add((matches.first['id'] as num).toInt());
          }
        }
      }

      await txn.delete(
        'collections',
        where: 'member_id=? AND receipt_no=? AND date=?',
        whereArgs: [member['id'], entry['receipt_no'], entry['date']],
      );
      for (final cashbookId in cashbookIds) {
        await _syncChandaCashbook(txn, cashbookId);
      }
    });
  }

  String _chandaCashbookNote(String memberName, List<Map<String, dynamic>> rows) {
    final periods = rows
        .map((r) => (r['year'] as int) * 12 + ((r['month'] as int) - 1))
        .toSet()
        .toList()
      ..sort();
    if (periods.isEmpty) return memberName;
    String fmt(int value) => '${BHelper.mNames[(value % 12) + 1]} ${value ~/ 12}';
    final continuous = List.generate(
      periods.length > 1 ? periods.length - 1 : 0,
      (i) => periods[i + 1] == periods[i] + 1,
    ).every((v) => v);
    final label = periods.length == 1
        ? fmt(periods.first)
        : continuous
            ? '${fmt(periods.first)} হতে ${fmt(periods.last)}'
            : periods.map(fmt).join(', ');
    return '$memberName — $label';
  }

  void _editCollection(Map<String, dynamic> member, Map<String, dynamic> h) {
    final aC = TextEditingController(text: ((h['amount'] as int) ~/ 100).toString());
    final rC = TextEditingController(text: h['receipt_no'].toString());
    final nC = TextEditingController(text: (h['note'] ?? '').toString());
    DateTime eDate = DateTime.tryParse(h['date'].toString()) ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: Text('${member['name']} — এন্ট্রি সংশোধন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('মাস: ${BHelper.mNames[h['month'] as int]} ${BHelper.toBn(h['year'])}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: eDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setD(() => eDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.teal.shade300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text('জমার তারিখ: ${BHelper.toBn(eDate.day)}/${BHelper.toBn(eDate.month)}/${BHelper.toBn(eDate.year)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const Icon(Icons.edit_calendar, size: 18, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
                TextField(controller: aC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'টাকার পরিমাণ')),
                TextField(controller: rC, decoration: const InputDecoration(labelText: 'রসিদ নং')),
                TextField(controller: nC, decoration: const InputDecoration(labelText: 'মন্তব্য')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white),
              onPressed: () async {
                int newTk = int.tryParse(aC.text) ?? 0;
                if (newTk <= 0) return;
                final newDateStr = DateTime(eDate.year, eDate.month, eDate.day, 12, 0).toIso8601String();
                final oldDateStr = h['date'].toString();
                final oldReceipt = h['receipt_no'].toString();
                final newReceipt = rC.text.trim().isEmpty ? oldReceipt : rC.text.trim();

                await _db!.transaction((txn) async {
                  int? cashbookId = (h['cashbook_id'] as num?)?.toInt();
                  Map<String, dynamic>? oldBook;
                  if (cashbookId != null) {
                    final found = await txn.query('cashbook', where: 'id=?', whereArgs: [cashbookId], limit: 1);
                    if (found.isNotEmpty) oldBook = found.first;
                  } else {
                    final matches = await txn.query(
                      'cashbook',
                      where: 'voucher_no=? AND date=? AND category=? AND note LIKE ?',
                      whereArgs: [oldReceipt, oldDateStr, 'মাসিক চাঁদা', "${member['name']} — %"],
                    );
                    if (matches.length > 1) throw StateError('একাধিক ক্যাশবুক এন্ট্রি মিলে গেছে; হিসাব নিরাপদ রাখতে সংশোধন বন্ধ রাখা হয়েছে।');
                    if (matches.length == 1) {
                      oldBook = matches.first;
                      cashbookId = (oldBook['id'] as num).toInt();
                    }
                  }

                  if (cashbookId == null || oldBook == null) {
                    final newId = await txn.insert('cashbook', {
                      'type': 'INCOME',
                      'category': 'মাসিক চাঁদা',
                      'amount': newTk * 100,
                      'payment_method': 'CASH',
                      'voucher_no': newReceipt,
                      'date': newDateStr,
                      'note': _chandaCashbookNote(member['name'].toString(), [h]),
                    });
                    await txn.update('collections', {
                      'amount': newTk * 100,
                      'receipt_no': newReceipt,
                      'date': newDateStr,
                      'note': nC.text.trim(),
                      'cashbook_id': newId,
                    }, where: 'id=?', whereArgs: [h['id']]);
                    await _syncChandaCashbook(txn, newId);
                  } else {
                    final sourceBook = oldBook!;
                    final linkedRows = await txn.query('collections', where: 'cashbook_id=?', whereArgs: [cashbookId]);
                    final mustSplit = linkedRows.length > 1 && (newDateStr != oldDateStr || newReceipt != oldReceipt);
                    if (mustSplit) {
                      final newId = await txn.insert('cashbook', {
                        'type': sourceBook['type'] ?? 'INCOME',
                        'category': sourceBook['category'] ?? 'মাসিক চাঁদা',
                        'amount': newTk * 100,
                        'payment_method': sourceBook['payment_method'] ?? 'CASH',
                        'voucher_no': newReceipt,
                        'date': newDateStr,
                        'note': _chandaCashbookNote(member['name'].toString(), [h]),
                      });
                      await txn.update('collections', {
                        'amount': newTk * 100,
                        'receipt_no': newReceipt,
                        'date': newDateStr,
                        'note': nC.text.trim(),
                        'cashbook_id': newId,
                      }, where: 'id=?', whereArgs: [h['id']]);
                      await _syncChandaCashbook(txn, cashbookId);
                      await _syncChandaCashbook(txn, newId);
                    } else {
                      await txn.update('collections', {
                        'amount': newTk * 100,
                        'receipt_no': newReceipt,
                        'date': newDateStr,
                        'note': nC.text.trim(),
                        'cashbook_id': cashbookId,
                      }, where: 'id=?', whereArgs: [h['id']]);
                      await txn.update('cashbook', {
                        'voucher_no': newReceipt,
                        'date': newDateStr,
                      }, where: 'id=?', whereArgs: [cashbookId]);
                      await _syncChandaCashbook(txn, cashbookId);
                    }
                  }
                });

                Navigator.pop(ctx);
                _refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('এন্ট্রি সফলভাবে সংশোধন হয়েছে!')));
                }
              },
              child: const Text('আপডেট'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReceiptForCollection(Map<String, dynamic> member, Map<String, dynamic> entry) async {
    // একই সদস্য, একই রসিদ নম্বর ও একই জমার তারিখের সব মাস এক রসিদে দেখানো হবে।
    final receiptNo = (entry['receipt_no'] ?? '').toString();
    final entryDate = (entry['date'] ?? '').toString();
    final rows = await _db!.query(
      'collections',
      where: 'member_id=? AND receipt_no=? AND date=?',
      whereArgs: [member['id'], receiptNo, entryDate],
      orderBy: 'year ASC, month ASC, id ASC',
    );

    final receiptRows = rows.isEmpty ? <Map<String, dynamic>>[entry] : rows;
    final totalAmount = receiptRows.fold<int>(
      0,
      (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0),
    );

    final periods = receiptRows
        .map((row) => (row['year'] as int) * 12 + ((row['month'] as int) - 1))
        .toSet()
        .toList()
      ..sort();

    String periodText;
    if (periods.length <= 1) {
      final period = periods.isEmpty
          ? ((entry['year'] as int) * 12 + ((entry['month'] as int) - 1))
          : periods.first;
      final year = period ~/ 12;
      final month = (period % 12) + 1;
      periodText = '${BHelper.mNames[month]} ${BHelper.toBn(year)}';
    } else {
      final isContinuous = List.generate(
        periods.length - 1,
        (index) => periods[index + 1] == periods[index] + 1,
      ).every((value) => value);

      String formatPeriod(int value) {
        final year = value ~/ 12;
        final month = (value % 12) + 1;
        return '${BHelper.mNames[month]} ${BHelper.toBn(year)}';
      }

      periodText = isContinuous
          ? '${formatPeriod(periods.first)} থেকে ${formatPeriod(periods.last)}'
          : periods.map(formatPeriod).join('، ');
    }

    _showReceipt(
      member['name'].toString(),
      member['phone'],
      totalAmount,
      receiptNo,
      periodText,
    );
  }

  void _showMonthDetailsDialog(Map<String, dynamic> member, int month, int year, List<Map<String, dynamic>> entries) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${BHelper.mNames[month]} ${BHelper.toBn(year)} — জমার বিবরণ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: entries.map((h) {
              final pText = '${BHelper.mNames[month]} ${BHelper.toBn(year)}';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('জমা: ${BHelper.taka(h['amount'] as int)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                        Text('রসিদ: ${h['receipt_no']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('তারিখ: ${h['date'].toString().substring(0, 10)}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    if (h['note'] != null && h['note'].toString().isNotEmpty)
                      Text('মন্তব্য: ${h['note']}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                    const Divider(height: 10),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 2,
                      runSpacing: 0,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.teal),
                          label: const Text('রশিদ PDF', style: TextStyle(fontSize: 11, color: Colors.teal)),
                          onPressed: () async {
                            await _showReceiptForCollection(member, h);
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                          label: const Text('এডিট', style: TextStyle(fontSize: 11, color: Colors.blueAccent)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _editCollection(member, h);
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.deepOrange),
                          label: const Text('সম্পূর্ণ এন্ট্রি', style: TextStyle(fontSize: 11, color: Colors.deepOrange)),
                          onPressed: () async {
                            final groupedRows = await _db!.query(
                              'collections',
                              where: 'member_id=? AND receipt_no=? AND date=?',
                              whereArgs: [member['id'], h['receipt_no'], h['date']],
                              orderBy: 'year ASC, month ASC',
                            );
                            if (!mounted) return;
                            final groupedTotal = groupedRows.fold<int>(
                              0,
                              (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0),
                            );
                            final groupedPeriods = groupedRows
                                .map((row) => '${BHelper.mNames[row['month'] as int]} ${BHelper.toBn(row['year'])}')
                                .toSet()
                                .toList();
                            showDialog(
                              context: context,
                              builder: (allDelCtx) => AlertDialog(
                                title: const Text('সম্পূর্ণ এন্ট্রি মুছে ফেলবেন?'),
                                content: Text(
                                  'একই রসিদের ${groupedPeriods.length} মাসের সব জমা একসঙ্গে মুছে যাবে।\n'
                                  '${groupedPeriods.join(', ')}\n'
                                  'মোট: ${BHelper.taka(groupedTotal)}\n\n'
                                  'সংশ্লিষ্ট নগদ আদায়ের হিসাবও সমন্বয় হবে।',
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(allDelCtx), child: const Text('না, রাখুন')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
                                    onPressed: () async {
                                      try {
                                        await _deleteCollectionReceiptGroup(member, h);
                                        if (!mounted) return;
                                        Navigator.pop(allDelCtx);
                                        Navigator.pop(ctx);
                                        _refresh();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('সম্পূর্ণ এন্ট্রি ও সংশ্লিষ্ট নগদ আদায়ের হিসাব মুছে ফেলা হয়েছে।')),
                                        );
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('মুছতে সমস্যা: $e')));
                                        }
                                      }
                                    },
                                    child: const Text('সব মাস মুছুন'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          label: const Text('মুছুন', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (delCtx) => AlertDialog(
                                title: const Text('এন্ট্রি মুছে ফেলবেন?'),
                                content: Text('$pText এর ${BHelper.taka(h['amount'] as int)} জমার এন্ট্রিটি কি নিশ্চিত মুছে ফেলতে চান?\n(এটি ক্যাশবুক থেকেও বাদ হয়ে যাবে)'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(delCtx), child: const Text('না, রাখুন')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
                                    onPressed: () async {
                                      try {
                                        await _db!.transaction((txn) async {
                                          int? cashbookId = (h['cashbook_id'] as num?)?.toInt();
                                          if (cashbookId == null) {
                                            final matches = await txn.query(
                                              'cashbook',
                                              where: 'voucher_no=? AND date=? AND category=? AND note LIKE ?',
                                              whereArgs: [h['receipt_no'], h['date'], 'মাসিক চাঁদা', "${member['name']} — %"],
                                            );
                                            if (matches.length > 1) {
                                              throw StateError('একাধিক ক্যাশবুক এন্ট্রি মিলে গেছে; ভুল হিসাব এড়াতে মুছে ফেলা বন্ধ রাখা হয়েছে।');
                                            }
                                            if (matches.length == 1) cashbookId = (matches.first['id'] as num).toInt();
                                          }
                                          await txn.delete('collections', where: 'id=?', whereArgs: [h['id']]);
                                          if (cashbookId != null) {
                                            await _syncChandaCashbook(txn, cashbookId);
                                          }
                                        });
                                        if (mounted) {
                                          Navigator.pop(delCtx);
                                          Navigator.pop(ctx);
                                          _refresh();
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('জমার এন্ট্রি ও সংশ্লিষ্ট ক্যাশবুক হিসাব আপডেট হয়েছে।')));
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('মুছতে সমস্যা: $e')));
                                        }
                                      }
                                    },
                                    child: const Text('হ্যাঁ, মুছুন'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ')),
        ],
      ),
    );
  }

  void _openPassbook(Map<String, dynamic> m) async {
    final mId = m['id'] as int, rate = m['monthly_rate'] as int, isY = m['member_type'] == 'YEARLY';
    final yCollections = await _db!.rawQuery(
      "SELECT * FROM collections WHERE member_id=? AND year=? ORDER BY id DESC",
      [mId, _cYear],
    );

    Map<int, List<Map<String, dynamic>>> mCollections = {};
    Map<int, int> mMap = {};
    for (var r in yCollections) {
      int mo = r['month'] as int;
      mCollections.putIfAbsent(mo, () => []).add(r);
      mMap[mo] = (mMap[mo] ?? 0) + ((r['amount'] as int));
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82, padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('নং ${BHelper.toBn(m['book_sl'] ?? m['id'])}। ${m['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.teal), onPressed: () => _addMember(member: m)),
                ]),
                Text('মোবাইল: ${BHelper.toBn(m['phone'] ?? "নেই")} | চাঁদা: ${BHelper.taka(isY ? rate * 12 : rate)}${isY ? "/বছর" : "/মাস"}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                if ((m['address'] ?? '').toString().trim().isNotEmpty)
                  Text('ঠিকানা: ${m['address']}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ])),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.teal.shade200)),
              child: Row(children: [
                const Icon(Icons.verified, color: Colors.teal, size: 16), const SizedBox(width: 6),
                Expanded(child: Text(m['lp_text'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colors.teal[900]),
                  icon: const Icon(Icons.send, size: 14), label: const Text('তাগাদা মেসেজ', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final msg = 'আসসালামু আলাইকুম ${m['name']} ভাই। $_mosqueName-এ আপনার চাঁদা ${m['lp_text']}। সময়মতো চাঁদাটি দিয়ে মসজিদ পরিচালনায় সহায়তার অনুরোধ রইল। আল্লাহ বরকত দিন।';
                    Clipboard.setData(ClipboardData(text: msg));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সম্মানজনক তাগাদা মেসেজ কপি হয়েছে!')));
                  },
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white), icon: const Icon(Icons.calendar_today, size: 14), label: const Text('এক মাস জমা', style: TextStyle(fontSize: 11)), onPressed: () { Navigator.pop(ctx); _collectFee(m, false); })),
              const SizedBox(width: 5),
              Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800], foregroundColor: Colors.white), icon: const Icon(Icons.date_range, size: 14), label: const Text('মেয়াদী জমা', style: TextStyle(fontSize: 11)), onPressed: () { Navigator.pop(ctx); _collectFee(m, true); })),
            ]),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${BHelper.toBn(_cYear)} সালের ১২ মাসের খাতা:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                const Text('(বক্সে ট্যাপ করে জমা দিন বা রশিদ দেখুন)', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.25,
                ),
                itemCount: 12,
                itemBuilder: (context, idx) {
                  final mo = idx + 1;
                  final p = mMap[mo] ?? 0;
                  // বাৎসরিক চাঁদায় ভাগের ভগ্নাংশজনিত ১ পয়সার পার্থক্য থাকলেও মাসটি পরিশোধিত দেখাবে; ধার্য টাকা/জমার অঙ্ক বদলাবে না।
                  final isP = isY ? p >= (rate - 1) : p >= rate;
                  final entries = mCollections[mo] ?? [];

                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (entries.isNotEmpty) {
                        _showMonthDetailsDialog(m, mo, _cYear, entries);
                      } else {
                        Navigator.pop(ctx);
                        _collectFee(m, false, targetMonth: mo, targetYear: _cYear);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        color: isP ? Colors.green.shade50 : (p > 0 ? Colors.orange.shade50 : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isP ? Colors.green.shade600 : (p > 0 ? Colors.orange.shade600 : Colors.red.shade300),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(BHelper.mNames[mo], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            isP ? 'পরিশোধ' : (p > 0 ? BHelper.taka(p) : 'বকেয়া'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isP ? Colors.green.shade800 : (p > 0 ? Colors.orange.shade900 : Colors.red.shade900),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isP ? Icons.receipt_long : Icons.add_circle_outline, size: 10, color: isP ? Colors.green.shade700 : Colors.red.shade700),
                              const SizedBox(width: 2),
                              Text(isP ? 'রশিদ দেখুন' : 'জমা নিন', style: TextStyle(fontSize: 9, color: isP ? Colors.green.shade700 : Colors.red.shade700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceipt(String name, dynamic phone, int amt, String rNo, String pText) {
    // প্রতিটি রসিদের জন্য আলাদা key; PDF capture-এর স্থিতিশীলতা বজায় থাকবে।
    final receiptKey = GlobalKey();
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF7FAF8),
        contentPadding: const EdgeInsets.all(12),
        content: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: RepaintBoundary(
              key: receiptKey,
              child: Container(
                width: 539,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD5B66B), width: 1.4),
                boxShadow: const [BoxShadow(color: Color(0x140D513F), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF075B46), Color(0xFF138568)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFDCC477), width: 1.2)),
                          child: const Icon(Icons.mosque, color: Color(0xFFFFE7A0), size: 27),
                        ),
                        const SizedBox(height: 8),
                        Text(_mosqueName, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, height: 1.35, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 3),
                        const Text('চাঁদা আদায়ের রসিদ', style: TextStyle(fontSize: 12, color: Color(0xFFE7F4EE), letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _receiptInfoPill('রসিদ নম্বর', rNo)),
                            const SizedBox(width: 8),
                            Expanded(child: _receiptInfoPill('তারিখ', '${BHelper.toBn(now.day)}/${BHelper.toBn(now.month)}/${BHelper.toBn(now.year)}')),
                          ],
                        ),
                        const SizedBox(height: 13),
                        const Text('দান কারীর তথ্য', style: TextStyle(fontSize: 11, color: Color(0xFF8A7540), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(color: const Color(0xFFF3F8F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0EAE3))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('দাতার নাম', style: TextStyle(fontSize: 9, color: Color(0xFF77847C), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF174D3E))),
                              if (phone != null && phone.toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.phone_android, size: 14, color: Color(0xFF648276)),
                                  const SizedBox(width: 5),
                                  Text(BHelper.toBn(phone), style: const TextStyle(fontSize: 11, color: Color(0xFF52675E))),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE9D9A6))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('দানের বিবরণ', style: TextStyle(fontSize: 11, color: Color(0xFF8A7540), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(pText, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF394B43), fontWeight: FontWeight.w600)),
                              const Divider(color: Color(0xFFE7D9B4), height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('দানের পরিমাণ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF315A49))),
                                  Text(BHelper.taka(amt), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF087653))),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text('কথায়: ${BHelper.amountInWords(amt)}', style: const TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF52675E), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(children: [
                              Container(width: 105, height: 1, color: const Color(0xFF9AA99F)),
                              const SizedBox(height: 5),
                              const Text('গ্রহণকারীর স্বাক্ষর', style: TextStyle(fontSize: 9, color: Color(0xFF718078))),
                            ]),
                            Column(children: [
                              Container(width: 105, height: 1, color: const Color(0xFF9AA99F)),
                              const SizedBox(height: 5),
                              const Text('দাতার স্বাক্ষর', style: TextStyle(fontSize: 9, color: Color(0xFF718078))),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Center(child: Text('আল্লাহ আপনাকে উত্তম প্রতিদান দান করুন', style: TextStyle(fontSize: 10, color: Color(0xFF8A7540), fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ),
                  Container(height: 5, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0B624B), Color(0xFFD6B65E), Color(0xFF0B624B)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)))),
                ],
              ),
            ),
          ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B624B), foregroundColor: Colors.white),
            icon: const Icon(Icons.picture_as_pdf, size: 15),
            label: const Text('PDF ডাউনলোড'),
            onPressed: () => _exportBoundaryToPdf(receiptKey, 'MosqueChanda_Receipt_$rNo', context, 'রসিদ PDF Download/MosqueChanda ফোল্ডারে সেভ হয়েছে!'),
          ),
        ],
      ),
    );
  }

  Widget _receiptInfoPill(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFF5F7F5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE4E9E4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF77847C))),
      const SizedBox(height: 2),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF234B3C))),
    ]),
  );
void _showAddCategoryDialog(bool isInc, Function(String) onAdded) {
    final cCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isInc ? 'নতুন আয়ের খাত যোগ করুন' : 'নতুন ব্যয়ের খাত যোগ করুন'),
        content: TextField(
          controller: cCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'খাতের নাম লিখুন...',
            labelText: 'খাত',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              final name = cCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await _db!.insert(
                  'custom_categories',
                  {'type': isInc ? 'INCOME' : 'EXPENSE', 'name': name},
                  conflictAlgorithm: ConflictAlgorithm.ignore,
                );
                onAdded(name);
                Navigator.pop(ctx);
                _refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('নতুন খাত "$name" যোগ হয়েছে!')));
                }
              } catch (_) {}
            },
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  void _showCashbookDetails(Map<String, dynamic> e) async {
    final cId = e['id'] as int;
    final isInc = e['type'] == 'INCOME';
    final isChanda = e['category'] == 'মাসিক চাঁদা';

    final items = await _db!.query('cashbook_items', where: 'cashbook_id=?', whereArgs: [cId], orderBy: 'id ASC');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['category'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('ভাউচার/রসিদ নং: ${e['voucher_no'] != null && e['voucher_no'] != '' ? e['voucher_no'] : "নেই"} | মাধ্যম: ${e['payment_method'] == "BANK" ? "ব্যাংক" : "নগদ"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    '${isInc ? "+ " : "- "}${BHelper.taka(e['amount'] as int)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isInc ? Colors.green[800] : Colors.red[800]),
                  ),
                ],
              ),
              const Divider(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('আইটেম / খরচের বিস্তারিত বিবরণ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  if (!isChanda)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInc ? Colors.teal[800] : Colors.red[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(isInc ? 'টাকা/কিস্তি যোগ' : 'খরচ/আইটেম যোগ', style: const TextStyle(fontSize: 11)),
                      onPressed: () => _showAddItemDialog(e, () {
                        Navigator.pop(ctx);
                        _refresh();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: items.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          e['note'] != null && e['note'].toString().isNotEmpty
                              ? 'বিবরণ: ${e['note']}'
                              : 'এই ভাউচারে আলাদা কোনো আইটেম যোগ করা হয়নি। উপরের বাটন দিয়ে যেকোনো সময় নতুন খরচ বা কিস্তি যোগ করতে পারেন।',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (c, idx) {
                          final it = items[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(it['title'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('তারিখ: ${it['date'].toString().substring(0, 10)}', style: const TextStyle(fontSize: 10)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(BHelper.taka(it['amount'] as int), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isInc ? Colors.green[800] : Colors.red[800])),
                                if (!isChanda)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                    onPressed: () async {
                                      await _db!.delete('cashbook_items', where: 'id=?', whereArgs: [it['id']]);
                                      final sumQ = await _db!.rawQuery("SELECT COALESCE(SUM(amount),0) as s FROM cashbook_items WHERE cashbook_id=?", [cId]);
                                      int newTot = (sumQ.first['s'] as int);
                                      await _db!.update('cashbook', {'amount': newTot}, where: 'id=?', whereArgs: [cId]);
                                      Navigator.pop(ctx);
                                      _refresh();
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('সম্পূর্ণ ভাউচার ডিলিট'),
                    onPressed: () => _showCashbookDeleteDialog(e, onDeleted: () {
                      if (ctx.mounted) Navigator.pop(ctx);
                    }),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('বন্ধ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(Map<String, dynamic> e, VoidCallback onSaved) {
    final titleC = TextEditingController();
    final amtC = TextEditingController();
    DateTime itemDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: Text(e['type'] == 'INCOME' ? 'নতুন টাকা / কিস্তি যোগ' : 'নতুন খরচ / আইটেম যোগ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: itemDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setD(() => itemDate = picked);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.teal.shade300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(
                              'তারিখ: ${BHelper.toBn(itemDate.day)}/${BHelper.toBn(itemDate.month)}/${BHelper.toBn(itemDate.year)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar, size: 16, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
                TextField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: e['type'] == 'INCOME' ? 'বিবরণ (যেমন: দোকান ২ ভাড়া)' : 'কাজের নাম / পণ্য (যেমন: রাজমিস্ত্রি মজুরি)',
                  ),
                ),
                TextField(
                  controller: amtC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'টাকার পরিমাণ'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: e['type'] == 'INCOME' ? Colors.teal[800] : Colors.red[800], foregroundColor: Colors.white),
              onPressed: () async {
                final t = titleC.text.trim();
                final amt = (int.tryParse(amtC.text) ?? 0) * 100;
                if (t.isEmpty || amt <= 0) return;

                final cId = e['id'] as int;
                final existingItems = await _db!.query('cashbook_items', where: 'cashbook_id=?', whereArgs: [cId]);

                if (existingItems.isEmpty && (e['amount'] as int) > 0) {
                  await _db!.insert('cashbook_items', {
                    'cashbook_id': cId,
                    'title': e['note'] != null && e['note'].toString().isNotEmpty ? e['note'] : e['category'],
                    'amount': e['amount'],
                    'date': e['date'],
                  });
                }

                await _db!.insert('cashbook_items', {
                  'cashbook_id': cId,
                  'title': t,
                  'amount': amt,
                  'date': DateTime(itemDate.year, itemDate.month, itemDate.day, 12, 0).toIso8601String(),
                });

                final sumQ = await _db!.rawQuery("SELECT COALESCE(SUM(amount),0) as s FROM cashbook_items WHERE cashbook_id=?", [cId]);
                int newTotal = (sumQ.first['s'] as int);
                await _db!.update('cashbook', {'amount': newTotal}, where: 'id=?', whereArgs: [cId]);

                Navigator.pop(ctx);
                onSaved();
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _addCashbook(bool isInc) {
    String cat = isInc ? _inCats.first : _outCats.first;
    String method = 'CASH';
    final aC = TextEditingController(), vC = TextEditingController(), nC = TextEditingController();
    DateTime entryDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: Text(isInc ? 'আয় যোগ' : 'ব্যয় / ভাউচার'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: entryDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setD(() => entryDate = picked);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isInc ? Colors.teal.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isInc ? Colors.teal.shade300 : Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 18, color: isInc ? Colors.teal : Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'তারিখ: ${BHelper.toBn(entryDate.day)}/${BHelper.toBn(entryDate.month)}/${BHelper.toBn(entryDate.year)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isInc ? Colors.teal : Colors.red),
                            ),
                          ],
                        ),
                        Icon(Icons.edit_calendar, size: 18, color: isInc ? Colors.teal : Colors.red),
                      ],
                    ),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: (isInc ? _inCats : _outCats).contains(cat) ? cat : (isInc ? _inCats.first : _outCats.first),
                        decoration: InputDecoration(labelText: isInc ? 'আয়ের খাত' : 'ব্যয়ের খাত'),
                        isExpanded: true,
                        items: (isInc ? _inCats : _outCats).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setD(() => cat = v!),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: isInc ? Colors.teal : Colors.red),
                      tooltip: 'নতুন খাত যোগ করুন',
                      onPressed: () => _showAddCategoryDialog(isInc, (newCat) {
                        setD(() {
                          cat = newCat;
                        });
                      }),
                    ),
                  ],
                ),

                DropdownButtonFormField<String>(
                  value: method, decoration: const InputDecoration(labelText: 'মাধ্যম'),
                  items: const [DropdownMenuItem(value: 'CASH', child: Text('নগদ ক্যাশ')), DropdownMenuItem(value: 'BANK', child: Text('ব্যাংক একাউন্ট'))],
                  onChanged: (v) => setD(() => method = v!),
                ),
                TextField(controller: aC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'টাকার পরিমাণ')),
                TextField(controller: vC, decoration: InputDecoration(labelText: isInc ? 'রসিদ নং (ঐচ্ছিক)' : 'ভাউচার নং (বাধ্যতামূলক)')),
                TextField(controller: nC, decoration: InputDecoration(labelText: isInc ? 'বিবরণ (যেমন: দোকান ১ ভাড়া)' : 'প্রথম কাজের নাম / বিবরণ (যেমন: সিমেন্ট কেনা)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isInc ? Colors.teal[800] : Colors.red[800], foregroundColor: Colors.white),
              onPressed: () async {
                int tk = int.tryParse(aC.text) ?? 0;
                if (tk <= 0) return;
                final dateStr = DateTime(entryDate.year, entryDate.month, entryDate.day, 12, 0).toIso8601String();
                
                int insId = await _db!.insert('cashbook', {
                  'type': isInc ? 'INCOME' : 'EXPENSE',
                  'category': cat,
                  'amount': tk * 100,
                  'payment_method': method,
                  'voucher_no': vC.text.trim(),
                  'date': dateStr,
                  'note': nC.text.trim(),
                });

                if (nC.text.trim().isNotEmpty) {
                  await _db!.insert('cashbook_items', {
                    'cashbook_id': insId,
                    'title': nC.text.trim(),
                    'amount': tk * 100,
                    'date': dateStr,
                  });
                }

                Navigator.pop(ctx);
                _refresh();
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _addTransfer() {
    String type = 'CASH_TO_BANK';
    final aC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('ক্যাশ ও ব্যাংক সমন্বয়'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type, decoration: const InputDecoration(labelText: 'ধরন'),
                items: const [DropdownMenuItem(value: 'CASH_TO_BANK', child: Text('ক্যাশ থেকে ব্যাংকে জমা')), DropdownMenuItem(value: 'BANK_TO_CASH', child: Text('ব্যাংক থেকে ক্যাশ উত্তোলন'))],
                onChanged: (v) => setD(() => type = v!),
              ),
              TextField(controller: aC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'টাকার পরিমাণ')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                int tk = int.tryParse(aC.text) ?? 0;
                if (tk <= 0) return;
                await _db!.insert('cashbook', {'type': 'TRANSFER', 'category': type == 'CASH_TO_BANK' ? 'ক্যাশ হতে ব্যাংকে জমা' : 'ব্যাংক হতে ক্যাশ উত্তোলন', 'amount': tk * 100, 'payment_method': type, 'voucher_no': 'TRF', 'date': DateTime.now().toIso8601String(), 'note': ''});
                Navigator.pop(ctx);
                _refresh();
              },
              child: const Text('স্থানান্তর'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _googleDriveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _autoBackupTimer?.cancel();
    _periodicAutoBackupTimer?.cancel();
    _pinCtrl.dispose();
    _sCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return Scaffold(
        backgroundColor: Colors.teal[900],
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 56, color: Colors.amber),
              const SizedBox(height: 8),
              Text(_mosqueName, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('পিন কোড দিন', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Container(
                width: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: TextField(controller: _pinCtrl, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold), decoration: const InputDecoration(counterText: '', border: InputBorder.none, hintText: '••••')),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                onPressed: () { if (_pinCtrl.text.trim() == _pin) setState(() => _locked = false); },
                child: const Text('আনলক'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 70,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque_rounded, color: Color(0xFFFFE7A0), size: 25),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                _mosqueName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25, letterSpacing: 0.15),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF086B60),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF063F37), Color(0xFF087F70), Color(0xFF11947D), Color(0xFF075D52)],
            ),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2ECE7))),
          boxShadow: [BoxShadow(color: const Color(0xFF174D43).withOpacity(0.09), blurRadius: 18, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
        currentIndex: _tab,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        selectedItemColor: const Color(0xFF087F70),
        unselectedItemColor: const Color(0xFF87948F),
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'চাঁদা খাতা'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'ক্যাশ খাতা'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'অডিট ও ব্যাকআপ'),
        ],
        iconSize: 25,
        selectedIconTheme: const IconThemeData(size: 27),
        showUnselectedLabels: true,
        elevation: 0,
      ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  Widget _topBox(String t, String v, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(4)),
      child: Column(children: [Text(t, style: const TextStyle(fontSize: 9, color: Colors.white70)), Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c))]),
    ),
  );

  void _showMosqueNameSettings() {
    final controller = TextEditingController(text: _mosqueName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মসজিদের নাম নির্ধারণ'),
        content: TextField(controller: controller, autofocus: true, maxLength: 100,
          decoration: const InputDecoration(labelText: 'মসজিদের পূর্ণ নাম')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () async {
            final value = controller.text.trim();
            if (value.isEmpty) return;
            await _db!.insert('settings', {'key': 'mosque_name', 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
            if (mounted) setState(() => _mosqueName = value);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('সংরক্ষণ')),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showPinSettings() {
    final pC = TextEditingController(text: _pin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পিন কোড সেট'),
        content: TextField(
          controller: pC,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: '৪ সংখ্যার পিন (মুছতে খালি রাখুন)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              _pin = pC.text.trim();
              await _db!.insert(
                'settings',
                {'key': 'app_pin', 'value': _pin},
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('সেভ'),
          ),
        ],
      ),
    );
  }

  void _showOpeningFundsSettings() {
    final cC = TextEditingController(text: (_opCash ~/ 100).toString());
    final bC = TextEditingController(text: (_opBank ~/ 100).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('শুরুর তহবিল নির্ধারণ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'পূর্বে ক্যাশে কত ছিল')),
            TextField(controller: bC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'পূর্বে ব্যাংকে কত ছিল')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              await _db!.insert(
                'settings',
                {'key': 'opening_cash', 'value': ((int.tryParse(cC.text) ?? 0) * 100).toString()},
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              await _db!.insert(
                'settings',
                {'key': 'opening_bank', 'value': ((int.tryParse(bC.text) ?? 0) * 100).toString()},
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('সেভ'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_tab == 0) return _buildChandaTab();
    if (_tab == 1) return _buildCashbookTab();
    return _buildAuditTab();
  }

  Future<void> _showThisMonthPaidMembers() async {
    final monthKey = '$_cYear-${_cMonth.toString().padLeft(2, '0')}';
    final monthName = '${BHelper.mNames[_cMonth]} ${BHelper.toBn(_cYear)}';
    final rows = await _db!.rawQuery(
      "SELECT m.id, m.book_sl, m.name, m.phone, SUM(c.amount) AS paid_amount, COUNT(c.id) AS entries "
      "FROM collections c INNER JOIN members m ON m.id = c.member_id "
      "WHERE substr(c.date,1,7)=? GROUP BY m.id, m.book_sl, m.name, m.phone "
      "ORDER BY m.book_sl ASC, m.id ASC",
      [monthKey],
    );
    if (!mounted) return;

    final reportKey = GlobalKey();
    final totalAmount = rows.fold<int>(
      0,
      (sum, row) => sum + ((row['paid_amount'] as num?)?.toInt() ?? 0),
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 560,
          height: MediaQuery.of(ctx).size.height * 0.86,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF075B50), Color(0xFF0B8878)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: Colors.white, size: 25),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '$monthName — এই মাসে জমাদানকারী',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('মোট জমা', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 3),
                                Text(
                                  BHelper.taka(totalAmount),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('জমাদানকারী সদস্য', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 3),
                                Text(
                                  '${BHelper.toBn(rows.length)} জন',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: RepaintBoundary(
                    key: reportKey,
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _mosqueName,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF075B50)),
                          ),
                          Text(
                            '$monthName — জমাদানকারীর তালিকা',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          const Divider(height: 22),
                          if (rows.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('এই মাসে এখনো কোনো সদস্যের চাঁদা জমা হয়নি।', textAlign: TextAlign.center),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: rows.map((r) {
                                final amount = (r['paid_amount'] as num?)?.toInt() ?? 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F8F6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFDCEBE5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFD8F2EB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          BHelper.toBn(r['book_sl'] ?? r['id']),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF087968)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (r['name'] ?? '').toString(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 17, height: 1.2, fontWeight: FontWeight.bold, color: Color(0xFF202B27)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              BHelper.taka(amount),
                                              maxLines: 1,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF087968)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F3EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('সর্বমোট জমা', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF075B50))),
                                Text(BHelper.taka(totalAmount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF075B50))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('বন্ধ'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF087968),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('PDF ডাউনলোড'),
                        onPressed: () => _exportBoundaryToMultiPagePdf(
                          reportKey,
                          'MosqueChanda_This_Month_Paid_${_cYear}_${_cMonth}',
                          ctx,
                          'এই মাসের জমাদানকারীর তালিকা PDF সেভ হয়েছে!',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setVisitReminder(Map<String, dynamic> member) async {
    final currentMonth = DateTime(_cYear, _cMonth, 1);
    final firstAllowed = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    final currentValue = (member['skip_until'] ?? '').toString();
    DateTime initial = firstAllowed;
    if (currentValue.length == 7) {
      final parsed = DateTime.tryParse('$currentValue-01');
      if (parsed != null && !parsed.isBefore(firstAllowed)) initial = parsed;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: DateTime(2035, 12, 31),
      helpText: 'কোন মাসে আবার যোগাযোগ করবেন?',
      fieldLabelText: 'পরবর্তী যোগাযোগের তারিখ',
    );
    if (picked == null) return;
    final value = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
    await _db!.update('members', {'skip_until': value}, where: 'id=?', whereArgs: [member['id']]);
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member['name']} — ${BHelper.mNames[picked.month]} ${BHelper.toBn(picked.year)} মাসে যোগাযোগের জন্য মনে রাখা হয়েছে।')),
      );
    }
  }

  Future<void> _clearVisitReminder(Map<String, dynamic> member) async {
    await _db!.update('members', {'skip_until': ''}, where: 'id=?', whereArgs: [member['id']]);
    await _refresh();
  }

  Widget _buildChandaTab() {
    final filtered = _members.where((m) {
      final n = m['name'].toString().toLowerCase(), p = (m['phone'] ?? '').toString(), s = (m['book_sl'] ?? '').toString();
      final match = n.contains(_search.toLowerCase()) || p.contains(_search) || s.contains(_search);
      if (!match) return false;
      if (_mFilter == 'MONTHLY') return m['member_type'] == 'MONTHLY' && m['status'] != 'CLOSED';
      if (_mFilter == 'YEARLY') return m['member_type'] == 'YEARLY' && m['status'] != 'CLOSED';
      if (_mFilter == 'CLOSED') return m['status'] == 'CLOSED';
      if (_mFilter == 'ALL') return m['status'] != 'CLOSED';
      return true;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'নতুন সদস্য',
        elevation: 4,
        backgroundColor: const Color(0xFF087F70),
        foregroundColor: Colors.white,
        onPressed: () => _addMember(),
        child: const Icon(Icons.person_add_alt_1_rounded, size: 21),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 4, 10, 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0EBE5)),
              boxShadow: [BoxShadow(color: const Color(0xFF315B4D).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
            ),
            child: _isSearchOpen
                ? Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            controller: _sCtrl,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'ক্রমিক, নাম বা মোবাইল দিয়ে খুঁজুন...',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.teal),
                              suffixIcon: _search.isNotEmpty
                                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _sCtrl.clear(); setState(() => _search = ''); })
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _isSearchOpen = false;
                            _search = '';
                            _sCtrl.clear();
                          });
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _cChip('ALL', 'সকল (${BHelper.toBn(_members.where((m)=>m['status']!='CLOSED').length)})'),
                              const SizedBox(width: 6),
                              _cChip('MONTHLY', 'মাসিক (${BHelper.toBn(_members.where((m)=>m['member_type']=='MONTHLY' && m['status']!='CLOSED').length)})'),
                              const SizedBox(width: 6),
                              _cChip('YEARLY', 'বাৎসরিক (${BHelper.toBn(_members.where((m)=>m['member_type']=='YEARLY' && m['status']!='CLOSED').length)})'),
                              const SizedBox(width: 6),
                              _cChip('CLOSED', 'ফাঁকা/বন্ধ (${BHelper.toBn(_members.where((m)=>m['status']=='CLOSED').length)})'),
                            ],
                          ),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.search, color: Colors.teal, size: 24), tooltip: 'খুঁজুন', onPressed: () => setState(() => _isSearchOpen = true)),
                    ],
                  ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE7F7F1), Color(0xFFF1FAF6)],
              ),
              border: Border(bottom: BorderSide(color: Color(0xFFD6EEE4))),
            ),
            child: Row(
              children: [
                // মাস নির্বাচন ও নগদ আদায়—দুই পাশে সমান প্রস্থ
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(-22, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 34),
                        onPressed: () {
                          setState(() {
                            if (_cMonth == 1) {
                              _cMonth = 12;
                              _cYear--;
                            } else {
                              _cMonth--;
                            }
                          });
                          _refresh();
                        },
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${BHelper.mNames[_cMonth]} ${BHelper.toBn(_cYear)}',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 34),
                        onPressed: () {
                          setState(() {
                            if (_cMonth == 12) {
                              _cMonth = 1;
                              _cYear++;
                            } else {
                              _cMonth++;
                            }
                          });
                          _refresh();
                        },
                      ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: _showThisMonthPaidMembers,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9F0DF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF69C49A), width: 1.2),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'নগদ আদায়: ${BHelper.taka(_mChanda)}',
                          maxLines: 1,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (ctx, idx) {
                final m = filtered[idx];
                final isCov = m['covered'] as bool;
                final isY = m['member_type'] == 'YEARLY';
                final st = m['status'];
                final bSl = m['book_sl'] ?? (idx + 1);
                final paidThisMonth = m['paid_this_month'] as bool? ?? false;
                final currentPeriod = '${_cYear}-${_cMonth.toString().padLeft(2, '0')}';
                final isNoVisitThisMonth = st == 'NO_VISIT' && (m['skip_visit_period'] ?? '') == currentPeriod;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                  elevation: 4,
                  shadowColor: const Color(0xFF174D43).withOpacity(0.13),
                  color: paidThisMonth
                      ? const Color(0xFFD4EEDB)
                      : (isNoVisitThisMonth ? const Color(0xFFF3EFF9) : const Color(0xFFFFF8EC)),
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: BorderSide(
                      color: paidThisMonth
                          ? const Color(0xFF4B9B63)
                          : (isNoVisitThisMonth ? const Color(0xFFB9A6DC) : const Color(0xFFBFCBC4)),
                      width: 1.15,
                    ),
                  ),
                  child: ListTile(
                  dense: false, visualDensity: const VisualDensity(vertical: 0),
                  tileColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(21)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  onTap: () => _openPassbook(m),
                  leading: Container(
                    width: 52, height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: paidThisMonth ? Colors.green.shade100 : (isNoVisitThisMonth ? const Color(0xFFE4D9FF) : (isCov ? Colors.teal.shade100 : Colors.orange.shade100)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: paidThisMonth ? Colors.green.shade700 : (isNoVisitThisMonth ? const Color(0xFF7654B5) : (isCov ? Colors.teal.shade600 : Colors.orange.shade700)),
                        width: 1.5,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          BHelper.toBn(bSl),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: paidThisMonth ? Colors.green.shade900 : (isNoVisitThisMonth ? const Color(0xFF6042A6) : (isCov ? Colors.teal.shade900 : Colors.orange.shade900)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        m['name'],
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: paidThisMonth
                              ? const Color(0xFF176B35)
                              : const Color(0xFF6042A6),
                        ),
                      ),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFFFF7E9), borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFFE8C58E))),
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(fontSize: 13, height: 1.1, fontWeight: FontWeight.w700, color: Color(0xFFC46A20)),
                                  children: [
                                    TextSpan(text: m['lp_text'].toString().replaceFirst(' পর্যন্ত পরিশোধিত', '')),
                                    const TextSpan(text: ' পর্যন্ত পরিশোধিত', style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFFFF7E9), borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFFE8D5B4))),
                              child: Text('ধার্য ${BHelper.taka(isY ? (m['monthly_rate'] as int) * 12 : (m['monthly_rate'] as int))}${isY ? "/বছর" : "/মাস"}', style: const TextStyle(fontSize: 13, height: 1.1, fontWeight: FontWeight.w700, color: Color(0xFFC46A20))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (isY)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                                child: const Text('বাৎসরিক', style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                              ),
                            if (st != 'ACTIVE' && st != 'NO_VISIT')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  st == 'RELOCATED' ? 'স্থানান্তরিত' : (st == 'CLOSED' ? 'ফাঁকা/বন্ধ' : 'মরহুম'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (isNoVisitThisMonth)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFE4D9FF), borderRadius: BorderRadius.circular(6)),
                                child: const Text('এই মাসে যাব না', style: TextStyle(fontSize: 11, color: Color(0xFF6042A6), fontWeight: FontWeight.bold)),
                              ),
                            if (paidThisMonth)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBFE7CA),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF31834B), width: 1.2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 10, color: Color(0xFF176B35)),
                                    SizedBox(width: 2),
                                    Text('এই মাসে আদায়', style: TextStyle(fontSize: 11, color: Color(0xFF176B35), fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cChip(String k, String l) => ChoiceChip(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    label: Text(
      l,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: _mFilter == k ? Colors.white : const Color(0xFF155B43),
      ),
    ),
    backgroundColor: const Color(0xFFF4FAF6),
    selected: _mFilter == k,
    selectedColor: const Color(0xFF087F55),
    showCheckmark: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: BorderSide(
        color: _mFilter == k ? const Color(0xFF087F55) : const Color(0xFFC8DED2),
        width: 1.1,
      ),
    ),
    onSelected: (v) { if (v) setState(() => _mFilter = k); },
  );

  void _openCashbookGroupPage(
    String title,
    List<Map<String, dynamic>> entries, {
    required Color accent,
    required bool isChanda,
    required String emptyText,
  }) {
    final total = entries.fold<int>(
      0,
      (sum, e) => sum + ((e['amount'] as num?)?.toInt() ?? 0),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageContext) => Scaffold(
          backgroundColor: const Color(0xFFF5F8F6),
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: accent.withOpacity(0.22)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${BHelper.mNames[_cMonth]} ${BHelper.toBn(_cYear)}', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text('${BHelper.toBn(entries.length)}টি এন্ট্রি', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                    Text(BHelper.taka(total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(child: Text(emptyText, style: const TextStyle(color: Colors.black54)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 18),
                        itemCount: entries.length,
                        itemBuilder: (ctx, index) {
                          final e = entries[index];
                          if (isChanda) {
                            final amount = (e['amount'] as num?)?.toInt() ?? 0;
                            final date = (e['date'] ?? '').toString();
                            final receipt = (e['receipt_no'] ?? '').toString();
                            final first = (e['first_period'] as num?)?.toInt();
                            final last = (e['last_period'] as num?)?.toInt();
                            String fmt(int v) => '${BHelper.mNames[(v - 1) % 12 + 1]} ${BHelper.toBn((v - 1) ~/ 12)}';
                            final period = first == null || last == null
                                ? 'মাসের তথ্য নেই'
                                : (first == last ? fmt(first) : '${fmt(first)} – ${fmt(last)}');
                            final cashbookId = (e['cashbook_id'] as num?)?.toInt();
                            final syntheticEntry = <String, dynamic>{
                              'id': cashbookId,
                              'category': 'মাসিক চাঁদা',
                              'amount': amount,
                              'date': date,
                              'voucher_no': receipt,
                              'type': 'INCOME',
                              'payment_method': 'CASH',
                              'note': '${e['member_name'] ?? 'সদস্য'} — মাসিক চাঁদা',
                            };
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              color: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFDCE9E2))),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(backgroundColor: accent.withOpacity(0.10), child: Icon(Icons.person_outline, color: accent, size: 20)),
                                title: Text((e['member_name'] ?? 'নাম পাওয়া যায়নি').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('$period | ${date.length >= 10 ? date.substring(0, 10) : date} | রশিদ: ${receipt.isEmpty ? "নেই" : receipt}', style: const TextStyle(fontSize: 10)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(BHelper.taka(amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accent)),
                                    if (cashbookId != null)
                                      IconButton(
                                        tooltip: 'মুছুন',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        onPressed: () => _showCashbookDeleteDialog(syntheticEntry),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final isInc = e['type'] == 'INCOME';
                          final isTransfer = e['type'] == 'TRANSFER';
                          final method = e['payment_method'];
                          final methodLabel = method == 'BANK'
                              ? 'ব্যাংক'
                              : (method == 'CASH_TO_BANK' ? 'ক্যাশ ➜ ব্যাংক' : (method == 'BANK_TO_CASH' ? 'ব্যাংক ➜ ক্যাশ' : 'নগদ'));
                          final date = (e['date'] ?? '').toString();
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFDCE9E2))),
                            child: ListTile(
                              dense: true,
                              onTap: () => _showCashbookDetails(e),
                              title: Row(
                                children: [
                                  Expanded(child: Text((e['category'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  Text('${isTransfer ? "" : (isInc ? "+ " : "- ")}${BHelper.taka((e['amount'] as num?)?.toInt() ?? 0)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isInc ? Colors.green[800] : (isTransfer ? Colors.blue[800] : Colors.red[800]))),
                                ],
                              ),
                              subtitle: Text('${date.length >= 10 ? date.substring(0, 10) : date} | $methodLabel${e['voucher_no'] != null && e['voucher_no'].toString().isNotEmpty ? " | ভাউচার: ${e['voucher_no']}" : ""}', style: const TextStyle(fontSize: 10)),
                              trailing: IconButton(
                                tooltip: 'মুছুন',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 19),
                                onPressed: () => _showCashbookDeleteDialog(e),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashbookTab() {
    final filtered = _cashList.where((e) {
      if (_cFilter == 'INCOME') return e['type'] == 'INCOME';
      if (_cFilter == 'EXPENSE') return e['type'] == 'EXPENSE';
      if (_cFilter == 'TRANSFER') return e['type'] == 'TRANSFER';
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 9),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF064F46), Color(0xFF0B8271)]),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            boxShadow: [BoxShadow(color: const Color(0xFF075B4F).withOpacity(0.20), blurRadius: 18, offset: const Offset(0, 7))],
          ),
          child: Row(children: [
            _topBox('হাতে নগদ', BHelper.taka(_cash), Colors.amber),
            const SizedBox(width: 4),
            _topBox('ব্যাংক স্থিতি', BHelper.taka(_bank), Colors.lightBlueAccent),
            const SizedBox(width: 4),
            _topBox('মোট তহবিল', BHelper.taka(_cash + _bank), Colors.greenAccent),
          ]),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0EBE6))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${BHelper.mNames[_cMonth]} ${BHelper.toBn(_cYear)} — ক্যাশবুক', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, size: 18), onPressed: () { setState(() { if (_cMonth == 1) { _cMonth = 12; _cYear--; } else { _cMonth--; } }); _refresh(); }),
              IconButton(icon: const Icon(Icons.arrow_forward, size: 18), onPressed: () { setState(() { if (_cMonth == 12) { _cMonth = 1; _cYear++; } else { _cMonth++; } }); _refresh(); }),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(children: [
            _sBox('আয়', BHelper.taka(_mInc), Colors.green),
            const SizedBox(width: 4),
            _sBox('ব্যয়', BHelper.taka(_mExp), Colors.redAccent),
            const SizedBox(width: 4),
            _sBox('উদ্বৃত্ত', BHelper.taka(_mInc - _mExp), Colors.teal),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white, padding: EdgeInsets.zero), icon: const Icon(Icons.add, size: 14), label: const Text('আয়', style: TextStyle(fontSize: 11)), onPressed: () => _addCashbook(true))),
            const SizedBox(width: 4),
            Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white, padding: EdgeInsets.zero), icon: const Icon(Icons.remove, size: 14), label: const Text('ব্যয়', style: TextStyle(fontSize: 11)), onPressed: () => _addCashbook(false))),
            const SizedBox(width: 4),
            IconButton.filled(style: IconButton.styleFrom(backgroundColor: Colors.blueGrey[800]), icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 16), onPressed: _addTransfer),
          ]),
        ),
        const Divider(height: 8),
        Expanded(
          child: Builder(builder: (context) {
            final chandaEntries = _cashChandaRows;
            final incomeEntries = filtered
                .where((e) => e['type'] == 'INCOME' && e['category'] != 'মাসিক চাঁদা')
                .toList();
            final expenseEntries = filtered.where((e) => e['type'] == 'EXPENSE').toList();
            final transferEntries = filtered.where((e) => e['type'] == 'TRANSFER').toList();
            final chandaTotal = chandaEntries.fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.toInt() ?? 0));
            final incomeTotal = incomeEntries.fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.toInt() ?? 0));
            final expenseTotal = expenseEntries.fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.toInt() ?? 0));
            final transferTotal = transferEntries.fold<int>(0, (sum, e) => sum + ((e['amount'] as num?)?.toInt() ?? 0));

            Widget groupCard({
              required String title,
              required String subtitle,
              required String amount,
              required IconData icon,
              required Color color,
              required VoidCallback onTap,
            }) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                elevation: 1,
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.24)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  leading: CircleAvatar(
                    radius: 23,
                    backgroundColor: color.withOpacity(0.11),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.black45),
                    ],
                  ),
                  onTap: onTap,
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(top: 5, bottom: 16),
              children: [
                groupCard(
                  title: 'মাসিক চাঁদা',
                  subtitle: '${BHelper.toBn(chandaEntries.length)}টি রিসিভের বিস্তারিত',
                  amount: BHelper.taka(chandaTotal),
                  icon: Icons.volunteer_activism,
                  color: const Color(0xFF087F55),
                  onTap: () => _openCashbookGroupPage('মাসিক চাঁদা', chandaEntries, accent: const Color(0xFF087F55), isChanda: true, emptyText: 'এই মাসে কোনো চাঁদা আদায় হয়নি।'),
                ),
                groupCard(
                  title: 'অন্যান্য আয়',
                  subtitle: '${BHelper.toBn(incomeEntries.length)}টি আয়ের এন্ট্রি',
                  amount: BHelper.taka(incomeTotal),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF16845F),
                  onTap: () => _openCashbookGroupPage('অন্যান্য আয়', incomeEntries, accent: const Color(0xFF16845F), isChanda: false, emptyText: 'এই মাসে অন্য কোনো আয় নেই।'),
                ),
                groupCard(
                  title: 'ব্যয়',
                  subtitle: '${BHelper.toBn(expenseEntries.length)}টি ব্যয়ের এন্ট্রি',
                  amount: BHelper.taka(expenseTotal),
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFC45B50),
                  onTap: () => _openCashbookGroupPage('ব্যয়', expenseEntries, accent: const Color(0xFFC45B50), isChanda: false, emptyText: 'এই মাসে কোনো ব্যয় নেই।'),
                ),
                groupCard(
                  title: 'টাকা স্থানান্তর',
                  subtitle: '${BHelper.toBn(transferEntries.length)}টি স্থানান্তরের এন্ট্রি',
                  amount: BHelper.taka(transferTotal),
                  icon: Icons.swap_horiz_rounded,
                  color: const Color(0xFF286B9A),
                  onTap: () => _openCashbookGroupPage('টাকা স্থানান্তর', transferEntries, accent: const Color(0xFF286B9A), isChanda: false, emptyText: 'এই মাসে কোনো টাকা স্থানান্তর হয়নি।'),
                ),
              ],
            );
          }),
        ),

      ],
    );
  }

  Widget _sBox(String t, String v, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: c.withAlpha(22), borderRadius: BorderRadius.circular(13), border: Border.all(color: c.withOpacity(0.13))),
      child: Column(children: [Text(t, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)), Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c))]),
    ),
  );

  void _showAuditPdfDialog(List<Map<String, Object?>> incs, List<Map<String, Object?>> exps) {
    final auditKey = GlobalKey();
    final now = DateTime.now();
    Widget amountRow(String label, int amount, Color color, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: strong ? 11 : 10, color: const Color(0xFF43574D), fontWeight: strong ? FontWeight.bold : FontWeight.normal))),
          Text('৳ ${BHelper.toBn(amount ~/ 100)}', style: TextStyle(fontSize: strong ? 12 : 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
    Widget categorySection(String title, List<Map<String, Object?>> rows, Color accent, int total, IconData icon) => Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE3EAE4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(color: accent.withOpacity(0.09), borderRadius: const BorderRadius.vertical(top: Radius.circular(9))),
            child: Row(children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 5, 11, 9),
            child: Column(
              children: [
                if (rows.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('এই মাসে কোনো তথ্য নেই', style: TextStyle(fontSize: 10, color: Color(0xFF8A9690)))),
                ...rows.map((r) => amountRow(r['category'].toString(), (r['s'] as int?) ?? 0, accent)),
                const Divider(color: Color(0xFFE6ECE7), height: 12),
                amountRow('মোট $title', total, accent, strong: true),
              ],
            ),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5F8F6),
        contentPadding: const EdgeInsets.all(10),
        content: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: RepaintBoundary(
              key: auditKey,
              child: Container(
                width: 539,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD7BD75), width: 1.3)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 15, 12, 13),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF075B46), Color(0xFF138568)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Column(children: [
                      const Icon(Icons.mosque, size: 25, color: Color(0xFFFFE7A0)),
                      const SizedBox(height: 5),
                      Text(_mosqueName, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text('মাসিক আয়-ব্যয়ের বিবরণী', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
                      const SizedBox(height: 5),
                      Text('${BHelper.mNames[_cMonth]} ${BHelper.toBn(_cYear)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFFE7A0))),
                    ]),
                  ),
                  const SizedBox(height: 9),
                  Align(alignment: Alignment.centerRight, child: Text('প্রস্তুতের তারিখ: ${BHelper.toBn(now.day)}/${BHelper.toBn(now.month)}/${BHelper.toBn(now.year)}', style: const TextStyle(fontSize: 9, color: Color(0xFF7B8981)))),
                  const SizedBox(height: 5),
                  Row(children: [
                    Expanded(child: _statementSummaryTile('মোট আয়', BHelper.taka(_mInc), const Color(0xFF16845F), Icons.trending_up)),
                    const SizedBox(width: 6),
                    Expanded(child: _statementSummaryTile('মোট ব্যয়', BHelper.taka(_mExp), const Color(0xFFC45B50), Icons.trending_down)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: _statementSummaryTile('হাতে নগদ', BHelper.taka(_cash), const Color(0xFF286B9A), Icons.payments_outlined)),
                    const SizedBox(width: 6),
                    Expanded(child: _statementSummaryTile('ব্যাংক স্থিতি', BHelper.taka(_bank), const Color(0xFF8A7134), Icons.account_balance_outlined)),
                  ]),
                  categorySection('আয়ের বিবরণী', incs, const Color(0xFF16845F), _mInc, Icons.south_west),
                  categorySection('ব্যয়ের বিবরণী', exps, const Color(0xFFC45B50), _mExp, Icons.north_east),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8D9AD)),
                    ),
                    child: Row(children: [
                      const Expanded(child: Text('সর্বমোট তহবিল', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF66552A)))),
                      Text(BHelper.taka(_cash + _bank), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B624B))),
                    ]),
                  ),
                  const SizedBox(height: 23),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(children: [
                      Container(width: 105, height: 1, color: const Color(0xFF9AA99F)),
                      const SizedBox(height: 5),
                      const Text('হিসাব প্রস্তুতকারীর স্বাক্ষর', style: TextStyle(fontSize: 8, color: Color(0xFF718078))),
                    ]),
                    Column(children: [
                      Container(width: 105, height: 1, color: const Color(0xFF9AA99F)),
                      const SizedBox(height: 5),
                      const Text('সভাপতি / সম্পাদকের স্বাক্ষর', style: TextStyle(fontSize: 8, color: Color(0xFF718078))),
                    ]),
                  ]),
                  const SizedBox(height: 11),
                  const Center(child: Text('স্বচ্ছতা ও আমানতদারিতায় আমাদের অঙ্গীকার', style: TextStyle(fontSize: 9, color: Color(0xFF8A7540), fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B624B), foregroundColor: Colors.white),
            icon: const Icon(Icons.picture_as_pdf, size: 15),
            label: const Text('PDF ডাউনলোড'),
            onPressed: () => _exportBoundaryToPdf(auditKey, 'MosqueChanda_Audit_${_cYear}_${_cMonth}', context, 'অডিট স্টেটমেন্ট PDF Download/MosqueChanda ফোল্ডারে সেভ হয়েছে!'),
          ),
        ],
      ),
    );
  }

  Widget _statementSummaryTile(String label, String value, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(9), border: Border.all(color: color.withOpacity(0.22))),
    child: Row(children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF748078))),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ])),
    ]),
  );

  Widget _buildAuditTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 3,
          shadowColor: const Color(0xFF087F70).withOpacity(0.14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
          color: const Color(0xFFE5F4F2),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('কমিটি মিটিং অডিট স্টেটমেন্ট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Text('মাসিক আয়-ব্যয়ের হিসাব PDF ডাউনলোড করুন অথবা হোয়াটসঅ্যাপে পাঠান', style: TextStyle(fontSize: 10, color: Colors.black54)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white),
                        icon: const Icon(Icons.picture_as_pdf, size: 14),
                        label: const Text('PDF স্টেটমেন্ট', style: TextStyle(fontSize: 11)),
                        onPressed: () async {
                          try {
                            if (_db == null) {
                              throw Exception('ডেটাবেস চালু হয়নি। অ্যাপটি বন্ধ করে আবার খুলুন।');
                            }
                            final mp = '$_cYear-${_cMonth.toString().padLeft(2, '0')}';
                            final incs = (await _db!.rawQuery("SELECT category, SUM(amount) as s FROM cashbook WHERE type='INCOME' AND substr(date,1,7)=? AND category!='মাসিক চাঁদা' GROUP BY category", [mp])).map((row) => Map<String, dynamic>.from(row)).toList();
                            final chandaRows = await _db!.rawQuery("SELECT COALESCE(SUM(amount),0) AS s FROM collections WHERE substr(date,1,7)=?", [mp]);
                            final chandaAmount = ((chandaRows.first['s'] as num?) ?? 0).toInt();
                            if (chandaAmount > 0) incs.add({'category': 'মাসিক চাঁদা', 's': chandaAmount});
                            final exps = await _db!.rawQuery("SELECT category, SUM(amount) as s FROM cashbook WHERE type='EXPENSE' AND substr(date,1,7)=? GROUP BY category", [mp]);
                            if (!mounted) return;
                            _showAuditPdfDialog(incs, exps);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('স্টেটমেন্ট খুলতে সমস্যা: $e'), duration: const Duration(seconds: 6)),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800], foregroundColor: Colors.white),
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('টেক্সট কপি', style: TextStyle(fontSize: 11)),
                        onPressed: () async {
                          final mp = '$_cYear-${_cMonth.toString().padLeft(2, '0')}';
                          final incs = (await _db!.rawQuery("SELECT category, SUM(amount) as s FROM cashbook WHERE type='INCOME' AND substr(date,1,7)=? AND category!='মাসিক চাঁদা' GROUP BY category", [mp])).map((row) => Map<String, dynamic>.from(row)).toList();
                          final chandaRows = await _db!.rawQuery("SELECT COALESCE(SUM(amount),0) AS s FROM collections WHERE substr(date,1,7)=?", [mp]);
                          final chandaAmount = (chandaRows.first['s'] as num).toInt();
                          if (chandaAmount > 0) incs.add({'category': 'মাসিক চাঁদা', 's': chandaAmount});
                          final exps = await _db!.rawQuery("SELECT category, SUM(amount) as s FROM cashbook WHERE type='EXPENSE' AND substr(date,1,7)=? GROUP BY category", [mp]);
                          StringBuffer sb = StringBuffer();
                          sb.writeln('🕌 $_mosqueName\nমাসিক অডিট স্টেটমেন্ট — ${BHelper.mNames[_cMonth]} $_cYear\n--------------------------\nআয়:');
                          for (var r in incs) { sb.writeln('• ${r['category']}: ৳${(r['s'] as int) ~/ 100}'); }
                          sb.writeln('মোট আয়: ৳${_mInc ~/ 100}\n\nব্যয়:');
                          for (var r in exps) { sb.writeln('• ${r['category']}: ৳${(r['s'] as int) ~/ 100}'); }
                          sb.writeln('মোট ব্যয়: ৳${_mExp ~/ 100}\n--------------------------\nতহবিল স্থিতি:\nহাতে নগদ: ৳${_cash ~/ 100}\nব্যাংক স্থিতি: ৳${_bank ~/ 100}\nসর্বমোট তহবিল: ৳${(_cash + _bank) ~/ 100}');
                          Clipboard.setData(ClipboardData(text: sb.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অডিট স্টেটমেন্ট কপি হয়েছে! হোয়াটসঅ্যাপে পাঠান।')));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          elevation: 3,
          shadowColor: const Color(0xFF263B44).withOpacity(0.09),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
          color: Colors.white,
          child: Column(
            children: [
              const ListTile(
                dense: true,
                leading: Icon(Icons.tune, color: Colors.teal),
                title: Text('অ্যাপ সেটিংস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('পিন কোড ও শুরুর তহবিল', style: TextStyle(fontSize: 10)),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                leading: const Icon(Icons.mosque_outlined, color: Colors.teal),
                title: const Text('মসজিদের নাম নির্ধারণ', style: TextStyle(fontSize: 12)),
                subtitle: Text(_mosqueName, style: const TextStyle(fontSize: 10)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showMosqueNameSettings,
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.lock_outline, color: Colors.teal),
                title: const Text('পিন কোড সেট / পরিবর্তন', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPinSettings,
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance_wallet, color: Colors.amber),
                title: const Text('শুরুর তহবিল নির্ধারণ', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showOpeningFundsSettings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // টেলিগ্রাম ক্লাউড ব্যাকআপ কার্ড
        Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shadowColor: const Color(0xFF263B44).withOpacity(0.08),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.send, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text('টেলিগ্রাম ক্লাউড ব্যাকআপ (অটো ও ম্যানুয়াল)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'অ্যাপে যেকোনো এন্ট্রি করার সাথে সাথে স্বয়ংক্রিয়ভাবে আপনার টেলিগ্রামে ব্যাকআপ ফাইল চলে যাবে। যেকোনো সময় নিচের বাটনে চাপ দিয়েও ব্যাকআপ পাঠাতে পারেন।',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('টেলিগ্রামে ব্যাকআপ পাঠান'),
                    onPressed: () => _sendBackupToTelegram(showToast: true),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Telegram সেটআপ / Bot Token দিন'),
                    onPressed: _configureTelegram,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.cloud_done, color: Colors.green, size: 23),
                  SizedBox(width: 8),
                  Text('Google Drive ক্লাউড ব্যাকআপ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 5),
                const Text(
                  'Google অ্যাকাউন্ট সংযুক্ত করে ডেটাবেসের JSON ব্যাকআপ Drive-এ রাখুন। অ্যাপ চালু ও ব্যবহার হলে স্বয়ংক্রিয় ব্যাকআপের চেষ্টা হবে; অনুমতি মেয়াদোত্তীর্ণ হলে আবার ব্যাকআপ বাটনে চাপ দিন।',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                    icon: const Icon(Icons.cloud_upload, size: 17),
                    label: const Text('Google Drive-এ ব্যাকআপ পাঠান'),
                    onPressed: () => _sendBackupToGoogleDrive(showToast: true, allowPrompt: true),
                  ),
                ),
                FutureBuilder<String>(
                  future: _readSetting('google_drive_last_backup'),
                  builder: (context, snapshot) {
                    final value = snapshot.data ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        value.isEmpty ? 'এখনো Google Drive ব্যাকআপ হয়নি' : 'সর্বশেষ ব্যাকআপ: ${value.replaceFirst('T', ' ').split('.').first}',
                        style: const TextStyle(fontSize: 9, color: Colors.black54),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 16),

        Card(
          margin: EdgeInsets.zero,
          elevation: 1.5,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: Colors.transparent,
          leading: const Icon(Icons.folder_open, color: Colors.green),
          title: const Text('JSON ফাইল থেকে সরাসরি রিস্টোর করুন', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          subtitle: const Text('ফোন থেকে .json ব্যাকআপ ফাইল নির্বাচন করে ডাটা ফিরিয়ে আনুন', style: TextStyle(fontSize: 9)),
          onTap: _pickJsonBackupAndRestore,
          ),
        ),

        Card(
          margin: EdgeInsets.zero,
          elevation: 1.5,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: Colors.transparent,
          leading: const Icon(Icons.settings_backup_restore, color: Colors.green),
          title: const Text('কোড পেস্ট করে রিস্টোর করুন', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          subtitle: const Text('টেলিগ্রাম বা ব্যাকআপ ফাইলের কোড পেস্ট করে ডাটা ফিরিয়ে আনুন', style: TextStyle(fontSize: 9)),
          onTap: () async {
            final c = TextEditingController();
            // টেলিগ্রাম থেকে কোড কপি করে আনলে নিজে থেকেই পেস্ট হয়ে যাবে
            try {
              final clipData = await Clipboard.getData(Clipboard.kTextPlain);
              if (clipData != null && clipData.text != null && clipData.text!.contains('mosque_chanda_master_v1')) {
                c.text = clipData.text!;
              }
            } catch (_) {}

            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('রিস্টোর কোড পেস্ট করুন'),
                content: TextField(
                  controller: c,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'এখানে কপি করা কোড পেস্ট করুন...',
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
                  ElevatedButton(
                    onPressed: () async {
                      final text = c.text.trim();
                      if (text.isEmpty) return;
                      await _restoreFromJsonString(text);
                      Navigator.pop(ctx);
                    },
                    child: const Text('রিস্টোর'),
                  ),
                ],
              ),
            );
          },
          ),
        ),
      ],
    );
  }
}