import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const MosqueChandaApp());
}

class MosqueChandaApp extends StatelessWidget {
  const MosqueChandaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'মসজিদ চাঁদা',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F65)), scaffoldBackgroundColor: const Color(0xFFF4F7F5)),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String mosqueName = 'আমাদের মসজিদ';
  Map<String, int> summary = {'members': 0, 'collections': 0, 'income': 0, 'expense': 0};
  List<Map<String, Object?>> members = [];
  bool loading = true;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    final n = await AppDatabase.instance.getSetting('mosque_name');
    final s = await AppDatabase.instance.getSummary();
    final m = await AppDatabase.instance.getMembers();
    if (!mounted) return;
    setState(() { mosqueName = n ?? 'আমাদের মসজিদ'; summary = s; members = m; loading = false; });
  }

  String bn(Object? value) {
    const en = '0123456789'; const bnDigits = '০১২৩৪৫৬৭৮৯';
    return value.toString().split('').map((c) => en.contains(c) ? bnDigits[en.indexOf(c)] : c).join();
  }

  void msg(String value) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }

  Future<void> editMosqueName() async {
    final c = TextEditingController(text: mosqueName);
    final v = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('মসজিদের নাম'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'মসজিদের নাম লিখুন')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('সংরক্ষণ'))],
    ));
    if (v != null && v.isNotEmpty) { await AppDatabase.instance.setSetting('mosque_name', v); await refresh(); }
    c.dispose();
  }

  Future<void> addMember() async {
    final name = TextEditingController(); final phone = TextEditingController(); final amount = TextEditingController(text: '১০০');
    String type = 'MONTHLY';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('নতুন সদস্য'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'সদস্যের নাম *')),
        const SizedBox(height: 10), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'মোবাইল নম্বর')),
        const SizedBox(height: 10), DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'চাঁদার ধরন'), items: const [DropdownMenuItem(value: 'MONTHLY', child: Text('মাসিক')), DropdownMenuItem(value: 'YEARLY', child: Text('বাৎসরিক'))], onChanged: (v) => setD(() => type = v ?? 'MONTHLY')),
        const SizedBox(height: 10), TextField(controller: amount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'নির্ধারিত চাঁদা (টাকা)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('সংরক্ষণ'))],
    )));
    if (ok == true) {
      if (name.text.trim().isEmpty) { msg('সদস্যের নাম লিখুন'); }
      else { await AppDatabase.instance.addMember(name: name.text.trim(), phone: phone.text.trim(), type: type, amount: int.tryParse(amount.text) ?? 0); await refresh(); msg('সদস্য সংরক্ষণ হয়েছে'); }
    }
    name.dispose(); phone.dispose(); amount.dispose();
  }

  Future<void> collect(Map<String, Object?> member) async {
    final amount = TextEditingController(text: (member['amount'] ?? 0).toString()); final note = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text((member['name'] as String) + ' — চাঁদা আদায়'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'আদায়ের পরিমাণ (টাকা)')),
        const SizedBox(height: 10), TextField(controller: note, decoration: const InputDecoration(labelText: 'বিবরণ (ঐচ্ছিক)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('আদায় সংরক্ষণ'))],
    ));
    if (ok == true) {
      final a = int.tryParse(amount.text) ?? 0;
      if (a <= 0) { msg('সঠিক টাকার পরিমাণ লিখুন'); }
      else { await AppDatabase.instance.addCollection(memberId: member['id'] as int, amount: a, date: DateTime.now(), note: note.text.trim()); await refresh(); msg('চাঁদা আদায় সংরক্ষণ হয়েছে'); }
    }
    amount.dispose(); note.dispose();
  }

  Future<void> addTransaction() async {
    final title = TextEditingController(); final amount = TextEditingController(); String type = 'INCOME';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('নতুন হিসাব এন্ট্রি'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'বিবরণ')),
        const SizedBox(height: 10), TextField(controller: amount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'টাকার পরিমাণ')),
        const SizedBox(height: 10), DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'ধরন'), items: const [DropdownMenuItem(value: 'INCOME', child: Text('আয়')), DropdownMenuItem(value: 'EXPENSE', child: Text('ব্যয়'))], onChanged: (v) => setD(() => type = v ?? 'INCOME')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('সংরক্ষণ'))],
    )));
    if (ok == true) {
      final a = int.tryParse(amount.text) ?? 0;
      if (title.text.trim().isEmpty || a <= 0) { msg('বিবরণ ও সঠিক টাকার পরিমাণ দিন'); }
      else { await AppDatabase.instance.addTransaction(title: title.text.trim(), amount: a, type: type, date: DateTime.now()); await refresh(); setState(() {}); msg('হিসাব সংরক্ষণ হয়েছে'); }
    }
    title.dispose(); amount.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [dashboard(), memberPage(), accountsPage(), settingsPage()];
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(mosqueName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('মসজিদ হিসাব ব্যবস্থাপনা', style: TextStyle(fontSize: 11)),
      ]), actions: [IconButton(onPressed: editMosqueName, icon: const Icon(Icons.edit_outlined), tooltip: 'মসজিদের নাম পরিবর্তন')]),
      body: loading ? const Center(child: CircularProgressIndicator()) : pages[tab],
      floatingActionButton: tab == 1 ? FloatingActionButton.extended(onPressed: addMember, icon: const Icon(Icons.person_add_alt_1), label: const Text('সদস্য যোগ')) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'হোম'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'সদস্য'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'হিসাব'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'সেটিংস'),
      ]),
    );
  }

  Widget dashboard() => RefreshIndicator(onRefresh: refresh, child: ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF087F65), Color(0xFF13A27E)]), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('মোট চাঁদা আদায়', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 5), Text('৳ ' + bn(summary['collections']), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), Text('সদস্য সংখ্যা: ' + bn(summary['members']) + ' জন', style: const TextStyle(color: Colors.white)),
    ])),
    const SizedBox(height: 18), const Text('হিসাবের সারসংক্ষেপ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55, children: [
      stat('সদস্য', summary['members'] ?? 0, Icons.groups, const Color(0xFF1976D2)),
      stat('চাঁদা আদায়', summary['collections'] ?? 0, Icons.volunteer_activism, const Color(0xFF087F65), money: true),
      stat('অন্যান্য আয়', summary['income'] ?? 0, Icons.trending_up, Colors.green, money: true),
      stat('ব্যয়', summary['expense'] ?? 0, Icons.trending_down, Colors.red, money: true),
    ]),
    const SizedBox(height: 18), const Text('দ্রুত কাজ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
    Row(children: [Expanded(child: quick(Icons.person_add_alt, 'সদস্য যোগ', () { setState(() => tab = 1); addMember(); })), const SizedBox(width: 10), Expanded(child: quick(Icons.receipt_long, 'হিসাব দেখুন', () => setState(() => tab = 2)))]),
  ]));

  Widget stat(String title, int value, IconData icon, Color color, {bool money = false}) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Icon(icon, color: color, size: 24), Text((money ? '৳ ' : '') + bn(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(title, style: TextStyle(color: Colors.grey.shade600)),
  ]));

  Widget quick(IconData icon, String label, VoidCallback action) => InkWell(onTap: action, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(icon, color: const Color(0xFF087F65)), const SizedBox(width: 8), Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)))])));

  Widget memberPage() => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'নাম বা মোবাইল নম্বর দিয়ে খুঁজুন'), onChanged: (q) async { final r = await AppDatabase.instance.searchMembers(q); if (mounted) setState(() => members = r); })),
    Expanded(child: members.isEmpty ? const Center(child: Text('এখনো কোনো সদস্য যোগ করা হয়নি')) : ListView.separated(padding: const EdgeInsets.all(12), itemCount: members.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (ctx, i) {
      final m = members[i]; final n = m['name'] as String;
      return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFE0F2EC), child: Text(n.isEmpty ? '?' : n.substring(0, 1), style: const TextStyle(color: Color(0xFF087F65)))),
        title: Text(n, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text((m['type'] == 'YEARLY' ? 'বাৎসরিক' : 'মাসিক') + ' • ৳ ' + bn(m['amount']) + ((m['phone'] as String).isEmpty ? '' : ' • ' + (m['phone'] as String))),
        trailing: IconButton(onPressed: () => collect(m), icon: const Icon(Icons.add_circle, color: Color(0xFF087F65), size: 29), tooltip: 'চাঁদা আদায়'),
      ));
    })),
  ]);

  Widget accountsPage() => FutureBuilder<List<Map<String, Object?>>>(future: AppDatabase.instance.getTransactions(), builder: (ctx, snap) {
    final rows = snap.data ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [const Expanded(child: Text('আয়-ব্যয়ের খাতা', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), FilledButton.icon(onPressed: addTransaction, icon: const Icon(Icons.add), label: const Text('নতুন এন্ট্রি'))]),
      const SizedBox(height: 12),
      if (rows.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('এখনো কোনো আয় বা ব্যয়ের এন্ট্রি নেই'))),
      ...rows.map((r) => Card(color: Colors.white, child: ListTile(
        leading: Icon(r['type'] == 'INCOME' ? Icons.arrow_downward : Icons.arrow_upward, color: r['type'] == 'INCOME' ? Colors.green : Colors.red),
        title: Text(r['title'] as String), subtitle: Text(r['date'] as String), trailing: Text('৳ ' + bn(r['amount']), style: const TextStyle(fontWeight: FontWeight.bold)),
      ))),
    ]);
  });

  Widget settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('মসজিদের পরিচিতি', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(mosqueName),
      const SizedBox(height: 12), OutlinedButton.icon(onPressed: editMosqueName, icon: const Icon(Icons.edit), label: const Text('মসজিদের নাম পরিবর্তন')),
    ])),
    const SizedBox(height: 12), const ListTile(leading: Icon(Icons.storage_outlined), title: Text('ডেটা সংরক্ষণ'), subtitle: Text('এই সংস্করণে তথ্য ফোনের SQLite ডেটাবেসে অফলাইনে থাকে।')),
    const ListTile(leading: Icon(Icons.info_outline), title: Text('অ্যাপ সংস্করণ'), subtitle: Text('১.০.০ • প্রাথমিক সংস্করণ')),
  ]);
}
