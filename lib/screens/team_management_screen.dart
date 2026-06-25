import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';

class TeamManagementScreen extends StatefulWidget {
  final Team? team; // If null, we are creating a new team
  const TeamManagementScreen({Key? key, this.team}) : super(key: key);

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _playerNumberController = TextEditingController();
  
  // Custom controller for Autocomplete field view
  TextEditingController? _playerNameController;

  String _selectedType = '6x6'; // Default format
  List<Player> _teamPlayers = [];
  List<Player> _globalPlayers = [];
  
  Player? _selectedGlobalPlayer;

  @override
  void initState() {
    super.initState();
    _loadGlobalPlayers();

    if (widget.team != null) {
      _teamNameController.text = widget.team!.name;
      _selectedType = widget.team!.type;
      _teamPlayers = List.from(widget.team!.players);
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _playerNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadGlobalPlayers() async {
    final players = await _storageService.loadGlobalPlayers();
    setState(() {
      _globalPlayers = players;
    });
  }

  void _addPlayer() {
    final name = _playerNameController?.text.trim() ?? '';
    final numberStr = _playerNumberController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom du joueur ne peut pas être vide'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final number = int.tryParse(numberStr);
    if (number == null || number < 1 || number > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro doit être un entier entre 1 et 99'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Check if number is already taken in this team
    if (_teamPlayers.any((p) => p.number == number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le numéro $number est déjà utilisé dans ce collectif'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      // Determine if we reuse a global player's ID or create a new one
      String playerId;
      if (_selectedGlobalPlayer != null && _selectedGlobalPlayer!.name.toLowerCase() == name.toLowerCase()) {
        playerId = _selectedGlobalPlayer!.id;
      } else {
        // Search global players by name just in case they didn't tap the suggestion
        final existing = _globalPlayers.firstWhere(
          (p) => p.name.toLowerCase() == name.toLowerCase(),
          orElse: () => Player(id: '', name: '', number: 0),
        );
        playerId = existing.id.isNotEmpty ? existing.id : DateTime.now().millisecondsSinceEpoch.toString();
      }

      _teamPlayers.add(Player(
        id: playerId,
        name: name,
        number: number,
      ));

      // Sort by jersey number
      _teamPlayers.sort((a, b) => a.number.compareTo(b.number));
      
      // Clear inputs
      _playerNameController?.clear();
      _playerNumberController.clear();
      _selectedGlobalPlayer = null;
    });
  }

  void _removePlayer(String id) {
    setState(() {
      _teamPlayers.removeWhere((p) => p.id == id);
    });
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final allTeams = await _storageService.loadTeams();
    final teamId = widget.team?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final teamName = _teamNameController.text.trim();

    final updatedTeam = Team(
      id: teamId,
      name: teamName,
      type: _selectedType,
      players: _teamPlayers,
    );

    if (widget.team == null) {
      allTeams.add(updatedTeam);
    } else {
      final index = allTeams.indexWhere((t) => t.id == teamId);
      if (index != -1) {
        allTeams[index] = updatedTeam;
      } else {
        allTeams.add(updatedTeam);
      }
    }

    // Save teams list
    await _storageService.saveTeams(allTeams);

    // Update global players database
    // Add any team player that doesn't exist globally (or update their default number)
    final List<Player> updatedGlobalPlayers = List.from(_globalPlayers);
    for (var player in _teamPlayers) {
      final existingIndex = updatedGlobalPlayers.indexWhere(
        (gp) => gp.id == player.id || gp.name.toLowerCase() == player.name.toLowerCase()
      );
      if (existingIndex == -1) {
        updatedGlobalPlayers.add(player);
      } else {
        // Optional: Update default number if they changed it
        // Or keep original default number
      }
    }
    await _storageService.saveGlobalPlayers(updatedGlobalPlayers);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.team == null ? 'Nouveau Collectif 🏐' : 'Modifier le Collectif'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Section 1: Team details
            _buildSectionHeader('Détails du Collectif'),
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
                      controller: _teamNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nom du collectif',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir un nom pour le collectif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Format de jeu (type de collectif) :',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['3x3', '4x4', '6x6'].map((type) {
                        final isSelected = _selectedType == type;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedType = type);
                                }
                              },
                              selectedColor: const Color(0xFF3B82F6),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                              checkmarkColor: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Players addition
            _buildSectionHeader('Joueurs du Collectif'),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player Number
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _playerNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'N° (défaut)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Player Name with Autocomplete
                        Expanded(
                          flex: 5,
                          child: RawAutocomplete<Player>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<Player>.empty();
                              }
                              return _globalPlayers.where((Player option) {
                                return option.name
                                    .toLowerCase()
                                    .contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            displayStringForOption: (Player option) => option.name,
                            onSelected: (Player selection) {
                              setState(() {
                                _selectedGlobalPlayer = selection;
                                _playerNameController?.text = selection.name;
                                _playerNumberController.text = selection.number.toString();
                              });
                            },
                            fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              _playerNameController = textEditingController;
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nom du joueur',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_add_alt_1),
                                ),
                              );
                            },
                            optionsViewBuilder: (
                              BuildContext context,
                              AutocompleteOnSelected<Player> onSelected,
                              Iterable<Player> options,
                            ) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  color: Colors.white,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.55,
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final Player option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    option.name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '#${option.number}',
                                                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
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
                    if (_teamPlayers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Aucun joueur dans le collectif pour le moment.',
                          style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teamPlayers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final player = _teamPlayers[index];
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
                            subtitle: const Text('Numéro de maillot par défaut'),
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

            // Save Button
            ElevatedButton(
              onPressed: _saveTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                widget.team == null ? 'CRÉER LE COLLECTIF 🚀' : 'SAUVEGARDER LE COLLECTIF 💾',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
