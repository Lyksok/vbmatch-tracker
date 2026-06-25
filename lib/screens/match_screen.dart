import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';
import 'stats_screen.dart';
import 'point_logging_screen.dart';

class MatchScreen extends StatefulWidget {
  final VolleyballMatch match;
  const MatchScreen({super.key, required this.match});

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
      // Show full screen page to log action and player
      _showPointLoggingScreen(winningTeam);
    }
  }

  Future<void> _showPointLoggingScreen(String winningTeam) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PointLoggingScreen(
          winningTeam: winningTeam,
          teamName: _match.teamName,
          players: _match.players,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _match.addPoint(winningTeam, result.action, result.playerId);
      });
      _saveMatch();
    }
  }

  Future<void> _renameMatch() async {
    final controller = TextEditingController(text: _match.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier l\'intitulé du match'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nom du match',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _match.name = newName;
      });
      await _saveMatch();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nom du match mis à jour')));
    }
  }

  void _handleUndo() {
    if (_match.currentSet.events.isEmpty && _match.sets.length == 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucun point à annuler')));
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
        content: const Text(
          'Le match est sauvegardé automatiquement. Vous pourrez le reprendre à tout moment depuis l\'accueil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CONTINUER À NOTER',
              style: TextStyle(color: Color(0xFF3B82F6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64748B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        backgroundColor: const Color(
          0xFF0F172A,
        ), // Dark Background for high contrast scoring
        appBar: AppBar(
          title: InkWell(
            onTap: _renameMatch,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(_match.name, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),
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
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(match: _match),
                  ),
                );
                setState(
                  () {},
                ); // Refresh in case stats screen triggered changes
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
                child: _match.isFinished
                    ? _buildFinishedState()
                    : _buildScoreboard(),
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

    final scoreStrings = completedSets
        .map((s) => '${s.scoreUs}-${s.scoreThem}')
        .join(', ');
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
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
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
                      color: isUsServing
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isUsServing
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_volleyball,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AU SERVICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                      color: isThemServing
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isThemServing
                            ? const Color(0xFFEF4444)
                            : Colors.transparent,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_volleyball,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AU SERVICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
    final winnerColor = _match.setsWonUs >= _match.winningSetsNeeded
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _match.setsWonUs >= _match.winningSetsNeeded
                  ? Icons.emoji_events
                  : Icons.sentiment_dissatisfied,
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
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(match: _match),
                  ),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('VOIR LES STATISTIQUES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Saisie rapide',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  value: _match.ignoreStats,
                  activeThumbColor: const Color(0xFFF59E0B),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          if (!_match.isFinished)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: const Text(
                'Astuce : Tapez sur le score d\'une équipe pour ajouter un point.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
