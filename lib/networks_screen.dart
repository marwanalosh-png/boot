import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworksScreen extends StatefulWidget {
  final String baseUrl;
  const NetworksScreen({super.key, required this.baseUrl});
  @override State<NetworksScreen> createState() => _NetworksScreenState();
}

class _NetworksScreenState extends State<NetworksScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('الشبكات'), actions: [
        IconButton(onPressed: loading?null:_load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: loading?null:_save, icon: const Icon(Icons.save)),
      ]),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        itemCount: nets.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i){
          final n = nets[i] as Map<String,dynamic>;
          return ListTile(
            title: Text('${n['name']} (chainId=${n['chainId']})'),
            subtitle: Text('mode=${n['mode']} • risk<=${n['riskThreshold']} • slip=${n['slippageBps']}bps'),
            trailing: Switch(
              value: (n['enabled'] == true),
              onChanged: (v){ setState(()=> n['enabled'] = v); },
            ),
          );
        },
      ),
    );
  }
}
