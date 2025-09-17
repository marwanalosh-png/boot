import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'core/locale_controller.dart';
\nimport 'advanced_settings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final urlCtrl = TextEditingController(text: 'http://10.0.2.2:8787');
  Map<String,dynamic>? st;
  List<Map<String,dynamic>> events = [];
  WebSocketChannel? ch;
  bool loading = false;

  Future<void> _connect() async {
    setState(()=> loading = true);
    try {
      final api = BotApi(urlCtrl.text.trim());
      final s = await api.status();
      ch?.sink.close();
      ch = api.stream();
      ch!.stream.listen((msg){
        try {
          final m = json.decode(msg) as Map<String,dynamic>;
          setState(()=> events.insert(0, m));
        } catch(_){}
      });
      setState(()=> st = s);
    } finally { setState(()=> loading = false); }
  }

  @override
  void dispose(){ ch?.sink.close(); urlCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final running = st?['running'] == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(tooltip: 'الشبكات', icon: const Icon(Icons.hub), onPressed: () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_)=> NetworksScreen(baseUrl: urlCtrl.text.trim()))); }),\n          IconButton(tooltip: 'الصفقات', icon: const Icon(Icons.shopping_bag), onPressed: () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_)=> TradesScreen(baseUrl: urlCtrl.text.trim()))); }), onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_)=> NetworksScreen(baseUrl: urlCtrl.text.trim())));
          }),
          IconButton(tooltip: 'تبديل اللغة', icon: const Icon(Icons.translate), onPressed: ()=> context.read<LocaleController>().toggle()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children:[
              Expanded(child: TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'عنوان الخادم (http://..)'))),
              const SizedBox(width: 8),
              FilledButton(onPressed: loading? null : _connect, child: const Text('اتصال')),
            ]),
            const SizedBox(height: 8),
            Row(children:[
              Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Text('الحالة: ' + (running? 'قيد التشغيل' : 'متوقف')),
                if (st!=null && st!['networks']!=null) ...[
                  Text('الشبكات: ' + ((st!['networks'] as List).length.toString())),
                ],
              ])))),
              const SizedBox(width: 8),
              SizedBox(height: 64, child: Row(children:[
                FilledButton.icon(onPressed: () async { final api = BotApi(urlCtrl.text.trim()); final s = await api.start(); setState(()=> st = s); }, icon: const Icon(Icons.play_arrow), label: const Text('تشغيل الكل')),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: () async { final api = BotApi(urlCtrl.text.trim()); final s = await api.stop(); setState(()=> st = s); }, icon: const Icon(Icons.stop), label: const Text('إيقاف الكل')),
              ]))
            ]),
            const Divider(height: 24),
            Align(alignment: Alignment.centerLeft, child: Text('الأحداث', style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            Expanded(child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (_, i){
                final e = events[i];
                final label = [e['network']??'', e['type']??''].where((x)=> (x??'').toString().isNotEmpty).join(' • ');
                return ListTile(
                  leading: Icon({ 'status': Icons.info, 'detection': Icons.visibility, 'trade': Icons.shopping_cart, 'error': Icons.error }[e['type']] ?? Icons.bolt),
                  title: Text(label),
                  subtitle: Text((){ final d=e['data'] as Map<String,dynamic>?; final lq = d==null?null:d['liquidityUsd']; return lq==null? json.encode(d??{}).toString() : ('سيولة تقديرية: ' + lq.toStringAsFixed(2) + ' USD'); }()),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

class NetworksScreen extends StatelessWidget {
  final String baseUrl;
  const NetworksScreen({super.key, required this.baseUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشبكات')),
      body: NetworksBody(baseUrl: baseUrl),
    );
  }
}

class NetworksBody extends StatefulWidget {
  final String baseUrl;
  const NetworksBody({super.key, required this.baseUrl});
  @override State<NetworksBody> createState() => _NetworksBodyState();
}

class _NetworksBodyState extends State<NetworksBody> {
  List<dynamic> nets = [];
  bool loading = false;

  Future<void> _load() async {
    setState(()=> loading = true);
    try {
      final r = await http.get(Uri.parse('${widget.baseUrl}/api/networks'));
      final j = json.decode(r.body) as Map<String,dynamic>;
      setState(()=> nets = j['networks'] as List);
    } finally { setState(()=> loading = false); }
  }

  Future<void> _save() async {
    setState(()=> loading = true);
    try {
      final body = json.encode({ 'networks': nets });
      final r = await http.post(Uri.parse('${widget.baseUrl}/api/networks'), headers: { 'Content-Type': 'application/json' }, body: body);
      if (r.statusCode>=400) throw Exception('Save failed');
      await _load();
    } finally { setState(()=> loading = false); }
  }

  @override void initState(){ super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Column(children:[
      Row(children:[
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: loading?null:_load, icon: const Icon(Icons.refresh), label: const Text('تحديث')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: loading?null:_save, icon: const Icon(Icons.save), label: const Text('حفظ')),
      ]),
      const Divider(height: 16),
      Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        itemCount: nets.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i){
          final n = nets[i] as Map<String,dynamic>;
          return ListTile(
            title: Text('${n['name']} (chainId=${n['chainId']})'),
            subtitle: Text('mode=${n['mode']} • risk<=${n['riskThreshold']} • slip=${n['slippageBps']}bps'),
            trailing: Switch(value: (n['enabled']==true), onChanged: (v){ setState(()=> n['enabled'] = v); }),
          );
        },
      )),
    ]);
  }
}


