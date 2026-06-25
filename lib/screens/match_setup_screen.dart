import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';
import 'match_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({Key? key}) : super(key: key);

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _matchNameController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController(text: 'Mon Équipe');
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerNumberController = TextEditingController();

  int _winningSetsNeeded = 3; // Default to 3 sets to win (best of 5)
  bool _ignoreStats = false;
  final List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill match name with current date
    final now = DateTime.now();
    _matchNameController.text = 'Match du ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _loadLastSavedTeam();
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _teamNameController.dispose();
    _playerNameController.dispose();
    _playerNumberController.dispose();
    super.dispose();
  }

  // Load the last saved squad to avoid re-typing
  Future<void> _loadLastSavedTeam() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/last_team.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        if (data['teamName'] != null) {
          _teamNameController.text = data['teamName'];
        }
        if (data['players'] != null) {
          final List playersList = data['players'];
          setState(() {
            _players.clear();
            for (var p in playersList) {
              _players.add(Player.fromMap(p));
            }
          });
        }
      }
    } catch (e) {
      print('Error loading last team: $e');
    }
  }

  // Save the squad for future matches
  Future<void> _saveLastTeam() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/last_team.json');
      final data = {
        'teamName': _teamNameController.text,
        'players': _players.map((p) => p.toMap()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving last team: $e');
    }
  }

  void _addPlayer() {
    final name = _playerNameController.text.trim();
    final numberStr = _playerNumberController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du joueur ne peut pas être vide')),
      );
      return;
    }

    final number = int.tryParse(numberStr);
    if (number == null || number < 1 || number > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le numéro doit être un entier entre 1 et 99')),
      );
      return;
    }

    // Check if number is already taken
    if (_players.any((p) => p.number == number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le numéro $number est déjà utilisé par un autre joueur')),
      );
      return;
    }

    setState(() {
      _players.add(Player(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        number: number,
      ));
      // Sort players by number
      _players.sort((a, b) => a.number.compareTo(b.number));
      _playerNameController.clear();
      _playerNumberController.clear();
    });
  }

  void _removePlayer(String id) {
    setState(() {
      _players.removeWhere((p) => p.id == id);
    });
  }

  void _loadQuickTeam() {
    setState(() {
      _players.clear();
      final names = ['Lucas', 'Thomas', 'Hugo', 'Arthur', 'Maxime', 'Julien'];
      final numbers = [4, 7, 9, 10, 12, 18];
      for (int i = 0; i < names.length; i++) {
        _players.add(Player(
          id: 'quick_${i}_${DateTime.now().millisecondsSinceEpoch}',
          name: names[i],
          number: numbers[i],
        ));
      }
    });
  }

  Future<void> _createAndStartMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un joueur pour pouvoir saisir des statistiques.'),
          backgroundColor: Colors.amber,
        ),
      );
    }

    // Create match object
    final match = VolleyballMatch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _matchNameController.text.trim(),
      teamName: _teamNameController.text.trim(),
      players: List.from(_players),
      winningSetsNeeded: _winningSetsNeeded,
      ignoreStats: _ignoreStats,
    );

    // Save match to storage
    await _storageService.saveMatch(match);
    // Save team config for next time
    await _saveLastTeam();

    // Navigate to scoring screen and replace setup in navigation stack
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MatchScreen(match: match),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nouveau Match 🏐'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Section 1: Match Config
            _buildSectionHeader('Configuration du Match'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _matchNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du match',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir un nom pour le match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _teamNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de votre équipe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Veuillez saisir le nom de l'équipe";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Format de victoire :',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('2 sets gagnants (Best of 3)'),
                            selected: _winningSetsNeeded == 2,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _winningSetsNeeded = 2);
                              }
                            },
                            selectedColor: const Color(0xFF3B82F6),
                            labelStyle: TextStyle(
                              color: _winningSetsNeeded == 2 ? Colors.white : Colors.black87,
                            ),
                            checkmarkColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('3 sets gagnants (Best of 5)'),
                            selected: _winningSetsNeeded == 3,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _winningSetsNeeded = 3);
                              }
                            },
                            selectedColor: const Color(0xFF3B82F6),
                            labelStyle: TextStyle(
                              color: _winningSetsNeeded == 3 ? Colors.white : Colors.black87,
                            ),
                            checkmarkColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Ignorer les statistiques par défaut'),
                      subtitle: const Text('Compte uniquement les points sans attribuer les actions aux joueurs.'),
                      value: _ignoreStats,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (val) {
                        setState(() => _ignoreStats = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Players Config
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Composition de l\'équipe'),
                TextButton.icon(
                  onPressed: _loadQuickTeam,
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Équipe type'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Player Add Form
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _playerNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'N°',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _playerNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nom du joueur',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Player List
                    if (_players.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Aucun joueur configuré pour le moment.\nAjoutez des joueurs ou utilisez le bouton "Équipe type".',
                          style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _players.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final player = _players[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: const Color(0xFF1D4ED8),
                              child: Text(player.number.toString()),
                            ),
                            title: Text(
                              player.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => _removePlayer(player.id),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Start Match Button
            ElevatedButton(
              onPressed: _createAndStartMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Emerald Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'COMMENCER LE MATCH 🚀',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}
