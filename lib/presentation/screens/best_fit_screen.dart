import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/models/best_fit.dart';

class BestFitScreen extends StatefulWidget {
  final String playerId;
  final String? playerName;
  final String baseUrl;

  const BestFitScreen({
    super.key,
    required this.playerId,
    this.playerName,
    this.baseUrl = 'http://localhost:8000',
  });

  @override
  State<BestFitScreen> createState() => _BestFitScreenState();
}

class _BestFitScreenState extends State<BestFitScreen> {
  final TextEditingController _maxAgeController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  BestFit? _bestFitData;

  @override
  void initState() {
    super.initState();
    _fetchBestFit();
  }

  @override
  void dispose() {
    _maxAgeController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchBestFit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, String>{};
      final maxAge = _maxAgeController.text.trim();
      final maxPrice = _maxPriceController.text.trim();

      if (maxAge.isNotEmpty) queryParams['max_age'] = maxAge;
      if (maxPrice.isNotEmpty) queryParams['max_value_eur'] = maxPrice;

      final uri = Uri.parse('${widget.baseUrl}/best-fit/${widget.playerId}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Gagal memuat data (HTTP ${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format respons JSON tidak sesuai');
      }

      setState(() {
        _bestFitData = BestFit.fromJson(decoded);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final needs = _bestFitData?.needs ?? {};
    final keep = _bestFitData?.keep ?? {};
    final candidates = (_bestFitData?.candidates ?? []).take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playerName != null
              ? 'Best Fit: ${widget.playerName}'
              : 'Find Replacement (Best-Fit)',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _maxAgeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maks. Umur',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maks. Harga (EUR)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fetchBestFit,
                  child: const Text('Terapkan Filter'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        _maxAgeController.clear();
                        _maxPriceController.clear();
                        _fetchBestFit();
                      },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            if (needs.isNotEmpty) ...[
              Text(
                'Needs (Kekurangan yang ingin ditutup):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: needs.entries.map((e) {
                  return Chip(
                    label: Text('${e.key}: +${e.value.toStringAsFixed(1)}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (keep.isNotEmpty) ...[
              Text(
                'Keep (Kelebihan yang dijaga):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: keep.entries.map((e) {
                  return Chip(
                    label: Text('${e.key}: ${e.value.toStringAsFixed(1)}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Kandidat Pengganti (Top ${candidates.length}):',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (candidates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Tidak ada kandidat ditemukan dengan filter tersebut.'),
                ),
              )
            else
              ...candidates.map((candidate) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                candidate.player.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Fit: ${candidate.fit.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${candidate.player.club} • ${candidate.player.position} • ${candidate.player.age}y • ${candidate.player.marketValueLabel}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Kemiripan: ${candidate.similarity.toStringAsFixed(1)}%'),
                            Text('Gain: ${(candidate.gain * 100).toStringAsFixed(0)}%'),
                            Text('Loss: ${(candidate.loss * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            candidate.why,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
