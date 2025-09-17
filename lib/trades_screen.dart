import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TradesScreen extends StatefulWidget {
  final String baseUrl;
  const TradesScreen({super.key, required this.baseUrl});
  @override State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  List<dynamic> trades = [];
  bool loading = false;

  Future<void> _load() async {
    setState(()=> loading = true);
    try {
      final r = await http.get(Uri.parse('${widget.baseUrl}/api/trades'));
      final j = json.decode(r.body) as Map<String,dynamic>;
      setState(()=> trades = (j['trades'] as List));
    } finally { setState(()=> loading = false); }
  }

  @override void initState(){ super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصفقات'), actions:[ IconButton(onPressed: loading?null:_load, icon: const Icon(Icons.refresh)) ]),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        itemCount: trades.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i){
          final t = trades[i] as Map<String,dynamic>;
          return ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: Text('${t['type']} • ${t['network'] ?? ''}'),
            subtitle: Text(json.encode(t)),
          );
        },
      ),
    );
  }
}
