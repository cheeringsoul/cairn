import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_provider.dart';

class HttpProxyPage extends StatefulWidget {
  const HttpProxyPage({super.key});

  @override
  State<HttpProxyPage> createState() => _HttpProxyPageState();
}

class _HttpProxyPageState extends State<HttpProxyPage> {
  late final TextEditingController _controller;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _controller = TextEditingController(text: settings.httpProxy);
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final settings = context.read<SettingsProvider>();
    final isDirty = _controller.text.trim() != settings.httpProxy;
    if (isDirty != _dirty) setState(() => _dirty = isDirty);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = context.read<SettingsProvider>();
    await settings.setHttpProxy(_controller.text.trim());
    if (mounted) {
      setState(() => _dirty = false);
      Navigator.pop(context);
    }
  }

  Future<void> _clear() async {
    final settings = context.read<SettingsProvider>();
    _controller.clear();
    await settings.setHttpProxy('');
    if (mounted) {
      setState(() => _dirty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP 代理',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _dirty ? _save : null,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'http://127.0.0.1:7890',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '填写 Clash / Surge 等代理工具的本地端口。留空则直连。\n'
            '格式：host:port 或 http://host:port',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _controller.text.trim().isEmpty ? null : _clear,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('清除代理'),
              style: TextButton.styleFrom(foregroundColor: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
