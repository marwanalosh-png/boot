import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdvancedSettingsScreen extends StatefulWidget {
  final String baseUrl;
  const AdvancedSettingsScreen({super.key, required this.baseUrl});
  @override State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  List<dynamic> nets = [];
  int? selected;
  bool loading = false;

  Future<void> _load() async {
    setState(()=> loading = true);
    try {
      final r = await http.get(Uri.parse('${widget.baseUrl}/api/networks'));
      final j = json.decode(r.body) as Map<String,dynamic>;
      nets = (j['networks'] as List);
      if (nets.isNotEmpty && selected==null) selected = 0;
      setState((){});
    } finally { setState(()=> loading = false); }
  }

  Future<void> _save() async {
    setState(()=> loading = true);
    try {
      final body = json.encode({ 'networks': nets });
      await http.post(Uri.parse('${widget.baseUrl}/api/networks'), headers: { 'Content-Type': 'application/json' }, body: body);
      await http.post(Uri.parse('${widget.baseUrl}/api/networks/save'));
    } finally { setState(()=> loading = false); }
  }

  Future<void> _reset({bool keepEndpoints = true}) async {
    if (selected==null) return;
    final cid = (nets[selected!] as Map<String,dynamic>)['chainId'];
    setState(()=> loading = true);
    try {
      final body = json.encode({ 'chainId': cid, 'keepEndpoints': keepEndpoints });
      final r = await http.post(Uri.parse('${widget.baseUrl}/api/reset'), headers: { 'Content-Type': 'application/json' }, body: body);
      final j = json.decode(r.body) as Map<String,dynamic>;
      nets = (j['networks'] as List);
      setState((){});
    } finally { setState(()=> loading = false); }
  }

  @override void initState(){ super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final n = (selected!=null && selected! < nets.length) ? nets[selected!] as Map<String,dynamic> : null;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات المتقدمة')),
      body: loading ? const Center(child: CircularProgressIndicator()) : n==null ? const Center(child: Text('لا توجد شبكات')) : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          // Network selector
          Row(children:[
            const Text('الشبكة:'), const SizedBox(width: 8),
            DropdownButton<int>(
              value: selected,
              items: [ for (int i=0; i<nets.length; i++) DropdownMenuItem(value: i, child: Text('${nets[i]['name']} (id=${nets[i]['chainId']})')) ],
              onChanged: (v){ setState(()=> selected = v); },
            ),
            const Spacer(),
            Switch(value: n['enabled'] == true, onChanged: (v){ setState(()=> n['enabled'] = v); }),
          ]),
          const SizedBox(height: 12),
          Row(children:[ Expanded(child: TextField(
            decoration: const InputDecoration(labelText: 'RPC URL'), controller: TextEditingController(text: n['rpcUrl']),
            onChanged: (v){ n['rpcUrl'] = v; },
          )), const SizedBox(width: 8), Expanded(child: TextField(
            decoration: const InputDecoration(labelText: 'WSS URL'), controller: TextEditingController(text: n['wssUrl']),
            onChanged: (v){ n['wssUrl'] = v; },
          )), ]),
          const SizedBox(height: 8),
          Row(children:[ Expanded(child: TextField(
            decoration: const InputDecoration(labelText: 'Router'), controller: TextEditingController(text: n['router']),
            onChanged: (v){ n['router'] = v; },
          )), const SizedBox(width: 8), Expanded(child: TextField(
            decoration: const InputDecoration(labelText: 'Factory'), controller: TextEditingController(text: n['factory']),
            onChanged: (v){ n['factory'] = v; },
          )), ]),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Base Token'), controller: TextEditingController(text: n['baseToken']),
            onChanged: (v){ n['baseToken'] = v; },
          ),
          const Divider(height: 24),
                    // Numeric advanced controls
          Row(children:[
            Expanded(child: _NumberField(label: 'Budget (ETH)', value: (n['buyBudgetEth']??0).toString(), onChanged: (v){ n['buyBudgetEth'] = double.tryParse(v) ?? n['buyBudgetEth']; })),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: 'Slippage (bps)', value: (n['slippageBps']??0).toString(), onChanged: (v){ n['slippageBps'] = int.tryParse(v) ?? n['slippageBps']; })),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            Expanded(child: _NumberField(label: 'Splits', value: (n['splits']??1).toString(), onChanged: (v){ n['splits'] = int.tryParse(v) ?? n['splits']; })),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: 'Split delay (ms)', value: (n['splitDelayMs']??400).toString(), onChanged: (v){ n['splitDelayMs'] = int.tryParse(v) ?? n['splitDelayMs']; })),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            Expanded(child: _NumberField(label: 'TP %', value: (n['tpPct']??20).toString(), onChanged: (v){ n['tpPct'] = double.tryParse(v) ?? n['tpPct']; })),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: 'SL %', value: (n['slPct']??10).toString(), onChanged: (v){ n['slPct'] = double.tryParse(v) ?? n['slPct']; })),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            Expanded(child: _NumberField(label: 'Trailing stop %', value: (n['trailingStopPct']??0).toString(), onChanged: (v){ n['trailingStopPct'] = double.tryParse(v) ?? n['trailingStopPct']; })),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: 'Cooldown (sec)', value: (n['cooldownSec']??10).toString(), onChanged: (v){ n['cooldownSec'] = int.tryParse(v) ?? n['cooldownSec']; })),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            Expanded(child: _NumberField(label: 'Max buy tax (0..1)', value: (n['maxBuyTax']??0.15).toString(), onChanged: (v){ n['maxBuyTax'] = double.tryParse(v) ?? n['maxBuyTax']; })),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: 'Max sell tax (0..1)', value: (n['maxSellTax']??0.2).toString(), onChanged: (v){ n['maxSellTax'] = double.tryParse(v) ?? n['maxSellTax']; })),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            Expanded(child: _NumberField(label: 'Risk ≤ (0..1)', value: (n['riskThreshold']??0.5).toString(), onChanged: (v){ n['riskThreshold'] = double.tryParse(v) ?? n['riskThreshold']; })),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: 'Gas x', value: (n['gasMultiplier']??1.2).toString(), onChanged: (v){ n['gasMultiplier'] = double.tryParse(v) ?? n['gasMultiplier']; })),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            const Text('الوضع:'), const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'paper', label: Text('ورقي')), ButtonSegment(value: 'live', label: Text('فعلي'))],
              selected: { (n['mode'] as String? ?? 'paper') },
              onSelectionChanged: (s){ setState(()=> n['mode'] = s.first); },
            ),
          ]),
          const SizedBox(height: 16),
                    Row(children:[
            Expanded(child: CheckboxListTile(title: const Text('يتطلب توثيق العقد'), value: n['requireVerified'] == true, onChanged: (v){ setState(()=> n['requireVerified'] = v); })),
            Expanded(child: CheckboxListTile(title: const Text('يتطلب ترك الملكية'), value: n['requireOwnerRenounced'] == true, onChanged: (v){ setState(()=> n['requireOwnerRenounced'] = v); })),
          ]),
          Row(children:[
            Expanded(child: CheckboxListTile(title: const Text('يتطلب تفعيل التداول'), value: n['requireTradingEnabled'] == true, onChanged: (v){ setState(()=> n['requireTradingEnabled'] = v); })),
            const SizedBox(width: 8),
          ]),
          const SizedBox(height: 8),
          Row(children:[
            FilledButton(onPressed: loading?null:_save, child: const Text('حفظ')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: loading?null:()=> _reset(keepEndpoints: true), child: const Text('إعادة الإعدادات (الموصى بها)')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: loading?null:()=> _reset(keepEndpoints: false), child: const Text('إعادة ضبط كامل')),
          ]),
        ]),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label; final String value; final void Function(String) onChanged;
  const _NumberField({required this.label, required this.value, required this.onChanged, super.key});
  @override Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: value);
    return TextField(decoration: InputDecoration(labelText: label), controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: onChanged);
  }
}

