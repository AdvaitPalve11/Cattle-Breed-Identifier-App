import 'dart:io';
import 'package:flutter/material.dart';
import 'models/prediction.dart';
import 'services/db_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Prediction> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DBProvider().getAllPredictions();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    await DBProvider().deletePrediction(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('No history yet'));

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final p = _items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: p.imagePath.isNotEmpty ? Image.file(File(p.imagePath), width: 56, height: 56, fit: BoxFit.cover) : null,
            title: Text(p.breed),
            subtitle: Text('Confidence: ${p.confidence.toStringAsFixed(1)}%\n${DateTime.fromMillisecondsSinceEpoch(p.timestamp)}'),
            isThreeLine: true,
            trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(p.id!)),
            onTap: () {
              // Show full-screen image
              if (p.imagePath.isNotEmpty) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(p.breed)), body: Center(child: Image.file(File(p.imagePath))))));
              }
            },
          ),
        );
      },
    );
  }
}
