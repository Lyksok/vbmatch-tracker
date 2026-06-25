import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';
import 'match_setup_screen.dart';
import 'match_screen.dart';
import 'stats_screen.dart';
import 'teams_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<VolleyballMatch> _matches = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final matches = await _storageService.getAllMatches();
    setState(() {
      _matches = matches;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    // Format: "25 juin 2026 à 12:34" in French
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year à $hour:$minute';
  }

  Future<void> _deleteMatch(String matchId, String matchName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le match ?'),
        content: Text(
          'Voulez-vous vraiment supprimer définitivement le match "$matchName" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteMatch(matchId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match supprimé avec succès'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _loadMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background Slate 100
      appBar: AppBar(
        title: const Text(
          'Volley Score 🏐',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A), // Dark slate 900
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: _loadMatches,
            ),
        ],
      ),
      body: _currentIndex == 0
          ? (_isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  )
                : _matches.isEmpty
                ? _buildEmptyState()
                : _buildMatchList())
          : const TeamsTab(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'new_match_fab',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchSetupScreen(),
                  ),
                );
                if (result == true) {
                  _loadMatches();
                }
              },
              backgroundColor: const Color(
                0xFFF59E0B,
              ), // Volleyball Orange/Amber
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'NOUVEAU MATCH',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            _loadMatches();
          }
        },
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF64748B),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_volleyball),
            label: 'Matchs',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Collectifs'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_volleyball,
                size: 72,
                color: Color(0xFF3B82F6), // Cool Blue
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun match enregistré',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Commencez à suivre vos matchs et collecter des statistiques en créant votre premier match de volley-ball !',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchSetupScreen(),
                  ),
                );
                if (result == true) {
                  _loadMatches();
                }
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'Créer un Match',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(VolleyballMatch match) {
    final statusColor = match.isFinished
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    final statusText = match.isFinished ? 'Terminé' : 'En cours';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (match.isFinished) {
            // Navigate to stats
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatsScreen(match: match),
              ),
            );
            _loadMatches(); // Refresh list in case stats screen triggered adjustments
          } else {
            // Resume match
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchScreen(match: match),
              ),
            );
            if (result == true) {
              _loadMatches();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(match.date),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  // Team Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collectif : ${match.teamName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format : ${match.winningSetsNeeded} sets gagnants',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score summary
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${match.setsWonUs}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: match.setsWonUs >= match.setsWonThem
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const Text(
                          ' - ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '${match.setsWonThem}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: match.setsWonThem >= match.setsWonUs
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: 'Supprimer',
                    onPressed: () => _deleteMatch(match.id, match.name),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatsScreen(match: match),
                        ),
                      );
                      _loadMatches();
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Statistiques'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (match.isFinished) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StatsScreen(match: match),
                          ),
                        );
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchScreen(match: match),
                          ),
                        );
                        if (result == true) {
                          _loadMatches();
                        }
                      }
                    },
                    icon: Icon(
                      match.isFinished ? Icons.visibility : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(match.isFinished ? 'Voir' : 'Reprendre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: match.isFinished
                          ? const Color(0xFF64748B)
                          : const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
