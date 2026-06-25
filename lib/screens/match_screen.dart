import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';
import 'stats_screen.dart';

class MatchScreen extends StatefulWidget {
  final VolleyballMatch match;
  const MatchScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final StorageService _storageService = StorageService();
  late VolleyballMatch _match;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
  }

  Future<void> _saveMatch() async {
    await _storageService.saveMatch(_match);
  }

  void _handlePoint(String winningTeam) {
    if (_match.ignoreStats) {
      // Just add the point directly
      setState(() {
        _match.addPoint(winningTeam, PointAction.none, null);
      });
      _saveMatch();
    } else {
      // Show bottom sheet to log action and player
      _showPointLoggingSheet(winningTeam);
    }
  }

  void _showPointLoggingSheet(String winningTeam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return _PointLoggingSheet(
          winningTeam: winningTeam,
          players: _match.players,
          onCompleted: (action, playerId) {
            setState(() {
              _match.addPoint(winningTeam, action, playerId);
            });
            _saveMatch();
          },
        );
      },
    );
  }

  void _handleUndo() {
    if (_match.currentSet.events.isEmpty && _match.sets.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun point à annuler')),
      );
      return;
    }
    setState(() {
      _match.undoLastPoint();
    });
    _saveMatch();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dernier point annulé'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_match.isFinished) {
      return true;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter le match ?'),
        content: const Text('Le match est sauvegardé automatiquement. Vous pourrez le reprendre à tout moment depuis l\'accueil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CONTINUER À NOTER', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64748B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('QUITTER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Dark Background for high contrast scoring
        appBar: AppBar(
          title: Text(_match.name),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context, true);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: 'Statistiques',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatsScreen(match: _match)),
                );
                setState(() {}); // Refresh in case stats screen triggered changes
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Previous Sets Summary
              _buildSetsSummary(),

              // Sets Won Row
              _buildSetsWonCounters(),

              // Active Set Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'SET ${_match.sets.length}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),

              // Main Scoreboard
              Expanded(
                child: _match.isFinished ? _buildFinishedState() : _buildScoreboard(),
              ),

              // Bottom control bar (Undo, Switch Stats)
              _buildControlPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetsSummary() {
    final completedSets = _match.sets.where((s) => s.isFinished).toList();
    if (completedSets.isEmpty) {
      return const SizedBox(height: 8);
    }

    final scoreStrings = completedSets.map((s) => '${s.scoreUs}-${s.scoreThem}').join(', ');
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Text(
          'Sets précédents : $scoreStrings',
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSetsWonCounters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // US Sets won
          Row(
            children: List.generate(_match.winningSetsNeeded, (index) {
              final active = index < _match.setsWonUs;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? const Color(0xFF3B82F6) : Colors.transparent,
                  border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                ),
              );
            }),
          ),
          const Text(
            'SETS GAGNÉS',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          // THEM Sets won
          Row(
            children: List.generate(_match.winningSetsNeeded, (index) {
              final active = index < _match.setsWonThem;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? const Color(0xFFEF4444) : Colors.transparent,
                  border: Border.all(color: const Color(0xFFEF4444), width: 2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    final activeSet = _match.currentSet;
    final isUsServing = _match.servingTeam == 'us';
    final isThemServing = _match.servingTeam == 'them';

    return Row(
      children: [
        // US Team Panel
        Expanded(
          child: GestureDetector(
            onTap: () => _handlePoint('us'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _match.teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isUsServing ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isUsServing ? const Color(0xFF3B82F6) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Text(
                      '${activeSet.scoreUs}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: isUsServing ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_volleyball, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'AU SERVICE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Middle Divider
        Container(
          width: 1,
          color: const Color(0xFF334155),
          height: double.infinity,
        ),

        // THEM Team Panel
        Expanded(
          child: GestureDetector(
            onTap: () => _handlePoint('them'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Adversaires',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isThemServing ? const Color(0xFF7F1D1D) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isThemServing ? const Color(0xFFEF4444) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Text(
                      '${activeSet.scoreThem}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: isThemServing ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_volleyball, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'AU SERVICE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedState() {
    final winnerText = _match.setsWonUs >= _match.winningSetsNeeded
        ? 'Victoire de ${_match.teamName} ! 🏆'
        : 'Victoire des Adversaires';
    final winnerColor = _match.setsWonUs >= _match.winningSetsNeeded ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _match.setsWonUs >= _match.winningSetsNeeded ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 80,
              color: winnerColor,
            ),
            const SizedBox(height: 24),
            Text(
              winnerText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Score final : ${_match.setsWonUs} sets à ${_match.setsWonThem}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatsScreen(match: _match)),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('VOIR LES STATISTIQUES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Ignore stats switch
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Ignorer les stats',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Saisie rapide',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  value: _match.ignoreStats,
                  activeColor: const Color(0xFFF59E0B),
                  onChanged: (val) {
                    setState(() {
                      _match.ignoreStats = val;
                    });
                    _saveMatch();
                  },
                ),
              ),

              // Undo button
              ElevatedButton.icon(
                onPressed: _handleUndo,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('ANNULER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF475569),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (!_match.isFinished)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: const Text(
                'Astuce : Tapez sur le score d\'une équipe pour ajouter un point.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

class _PointLoggingSheet extends StatefulWidget {
  final String winningTeam;
  final List<Player> players;
  final Function(PointAction, String?) onCompleted;

  const _PointLoggingSheet({
    Key? key,
    required this.winningTeam,
    required this.players,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<_PointLoggingSheet> createState() => _PointLoggingSheetState();
}

class _PointLoggingSheetState extends State<_PointLoggingSheet> {
  PointAction? _selectedAction;
  String? _selectedPlayerId;

  // Track if we need to show player selection
  bool get _requiresPlayer {
    if (_selectedAction == null) return false;
    // Opponent error or Opponent winner don't require player attribution
    if (_selectedAction == PointAction.erreurAdverse || _selectedAction == PointAction.pointAdversaire) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isUs = widget.winningTeam == 'us';

    // Filter actions depending on who won the point
    final availableActions = isUs
        ? [PointAction.ace, PointAction.attaque, PointAction.contre, PointAction.erreurAdverse]
        : [
            PointAction.fauteService,
            PointAction.fauteAttaque,
            PointAction.erreurReception,
            PointAction.fauteFiletAutre,
            PointAction.pointAdversaire
          ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUs ? 'Point pour vous ! 🎉' : 'Point adverse 🏐',
                style: TextStyle(
                  color: isUs ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1: Action Selection
          const Text(
            'Comment s\'est terminé le point ?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableActions.map<Widget>((action) {
              final isSelected = _selectedAction == action;
              return ChoiceChip(
                label: Text(action.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedAction = selected ? action : null;
                    _selectedPlayerId = null; // Reset player if action changed
                  });

                  // If action doesn't require player selection, complete immediately
                  if (selected && !_requiresPlayer) {
                    widget.onCompleted(action, null);
                    Navigator.pop(context);
                  }
                },
                selectedColor: const Color(0xFF2563EB),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),

          // Step 2: Player Selection (only if required and action selected)
          if (_requiresPlayer && widget.players.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              _selectedAction == PointAction.ace ||
                      _selectedAction == PointAction.attaque ||
                      _selectedAction == PointAction.contre
                  ? 'Quel joueur a marqué ?'
                  : 'Quel joueur a fait la faute ?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Team Option
                    ChoiceChip(
                      avatar: const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.people, size: 14, color: Colors.black54),
                      ),
                      label: const Text('L\'Équipe (Non spécifié)'),
                      selected: _selectedPlayerId == 'team',
                      onSelected: (selected) {
                        if (selected) {
                          widget.onCompleted(_selectedAction!, null);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    // Specific Players
                    ...widget.players.map<Widget>((player) {
                      final isSelected = _selectedPlayerId == player.id;
                      return ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: isSelected ? Colors.white30 : const Color(0xFFEFF6FF),
                          foregroundColor: isSelected ? Colors.white : const Color(0xFF1D4ED8),
                          child: Text(player.number.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        label: Text(player.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            widget.onCompleted(_selectedAction!, player.id);
                            Navigator.pop(context);
                          }
                        },
                        selectedColor: const Color(0xFFF59E0B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ] else if (_requiresPlayer && widget.players.isEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Aucun joueur configuré dans l\'équipe. Le point sera attribué à l\'équipe.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  widget.onCompleted(_selectedAction!, null);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                child: const Text('Valider pour l\'Équipe'),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
