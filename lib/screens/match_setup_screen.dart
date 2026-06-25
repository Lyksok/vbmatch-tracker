import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';
import 'match_screen.dart';
import 'team_management_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({Key? key}) : super(key: key);

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _matchNameController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();

  List<Team> _allTeams = [];
  Team? _selectedTeam;
  bool _isLoading = true;

  int _winningSetsNeeded = 3; // Default to 3 sets to win (best of 5)
  bool _ignoreStats = false;

  // Track match-specific customization for selected team
  final Map<String, int> _playerCustomNumbers = {}; // playerId -> customNumber
  final Map<String, bool> _playerAbsentees = {}; // playerId -> isAbsent

  @override
  void initState() {
    super.initState();
    // Pre-fill match name with current date
    final now = DateTime.now();
    _matchNameController.text = 'Match du ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _loadTeams();
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    final teams = await _storageService.loadTeams();
    setState(() {
      _allTeams = teams;
      _isLoading = false;
    });
  }

  void _onTeamSelected(Team? team) {
    setState(() {
      _selectedTeam = team;
      if (team != null) {
        _teamNameController.text = team.name;
        _playerCustomNumbers.clear();
        _playerAbsentees.clear();
        for (var p in team.players) {
          _playerCustomNumbers[p.id] = p.number;
          _playerAbsentees[p.id] = false; // present by default
        }
      } else {
        _teamNameController.clear();
      }
    });
  }

  Future<void> _createAndStartMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un collectif.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Filter active/present players
    final presentPlayers = _selectedTeam!.players
        .where((p) => _playerAbsentees[p.id] == false)
        .toList();

    // 1. Validate team format active players limit
    int minRequired = 6;
    if (_selectedTeam!.type == '3x3') minRequired = 3;
    if (_selectedTeam!.type == '4x4') minRequired = 4;

    if (presentPlayers.length < minRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Format ${_selectedTeam!.type} : vous devez avoir au moins $minRequired joueur(s) présent(s). Actuellement : ${presentPlayers.length}.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. Validate jersey number uniqueness for present players
    final presentNumbers = presentPlayers.map((p) => _playerCustomNumbers[p.id]!).toList();
    if (presentNumbers.toSet().length != presentNumbers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : Deux joueurs présents ne peuvent pas avoir le même numéro pour un match.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Create match players with their custom numbers for this match
    final List<Player> matchPlayers = presentPlayers.map((p) {
      return Player(
        id: p.id,
        name: p.name,
        number: _playerCustomNumbers[p.id]!,
      );
    }).toList();

    // Create match object
    final match = VolleyballMatch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _matchNameController.text.trim(),
      teamName: _teamNameController.text.trim(),
      teamId: _selectedTeam!.id,
      players: matchPlayers,
      winningSetsNeeded: _winningSetsNeeded,
      ignoreStats: _ignoreStats,
    );

    // Save match to storage
    await _storageService.saveMatch(match);

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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nouveau Match 🏐'),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nouveau Match 🏐'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 2,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    // Team selection dropdown
                    if (_allTeams.isEmpty)
                      _buildNoTeamsCard()
                    else
                      DropdownButtonFormField<Team>(
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner le collectif',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        value: _selectedTeam,
                        items: _allTeams.map((team) {
                          return DropdownMenuItem<Team>(
                            value: team,
                            child: Text('${team.name} (${team.type})'),
                          );
                        }).toList(),
                        onChanged: _onTeamSelected,
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner un collectif';
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

            // Section 2: Team Players list & verification
            if (_selectedTeam != null && !_ignoreStats) ...[
              _buildSectionHeader('Composition & Numéros pour ce Match'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Format de collectif : ${_selectedTeam!.type} (min. ${(_selectedTeam!.type == '3x3' ? 3 : _selectedTeam!.type == '4x4' ? 4 : 6)} joueurs actifs requis)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedTeam!.players.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Ce collectif n\'a aucun joueur. Allez dans l\'onglet Collectifs pour en ajouter.',
                            style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedTeam!.players.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final player = _selectedTeam!.players[index];
                            final isAbsent = _playerAbsentees[player.id] ?? false;
                            final customNumber = _playerCustomNumbers[player.id] ?? player.number;

                            return Row(
                              children: [
                                // Absent/Present Toggle
                                Switch(
                                  value: !isAbsent, // Active means PRESENT
                                  activeColor: const Color(0xFF10B981),
                                  inactiveThumbColor: Colors.red,
                                  inactiveTrackColor: Colors.red.shade100,
                                  onChanged: (present) {
                                    setState(() {
                                      _playerAbsentees[player.id] = !present;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Player Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isAbsent ? Colors.grey : const Color(0xFF0F172A),
                                          decoration: isAbsent ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      if (isAbsent)
                                        const Text(
                                          'Absent',
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        )
                                      else
                                        Text(
                                          'Numéro par défaut : #${player.number}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                // Jersey number editing
                                if (!isAbsent)
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      initialValue: customNumber.toString(),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(
                                        labelText: 'N°',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        final num = int.tryParse(val);
                                        if (num != null) {
                                          _playerCustomNumbers[player.id] = num;
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

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

  Widget _buildNoTeamsCard() {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Aucun collectif disponible',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vous devez créer au moins un collectif dans l\'onglet Collectifs avant de pouvoir démarrer un match avec des statistiques.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeamManagementScreen()),
                );
                if (result == true) {
                  _loadTeams();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Créer un collectif maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
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
