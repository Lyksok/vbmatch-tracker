import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';

class TeamStatsScreen extends StatefulWidget {
  final Team team;
  const TeamStatsScreen({Key? key, required this.team}) : super(key: key);

  @override
  State<TeamStatsScreen> createState() => _TeamStatsScreenState();
}

class _TeamStatsScreenState extends State<TeamStatsScreen> {
  final StorageService _storageService = StorageService();
  List<VolleyballMatch> _teamMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final allMatches = await _storageService.getAllMatches();
    // Filter matches played by this team (by ID if available, otherwise by Name)
    final teamMatches = allMatches.where((m) => m.teamId == widget.team.id || m.teamName == widget.team.name).toList();
    setState(() {
      _teamMatches = teamMatches;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Stats : ${widget.team.name}'),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
      );
    }

    if (_teamMatches.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Stats : ${widget.team.name}'),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Aucune statistique pour ${widget.team.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jouez des matchs en sélectionnant ce collectif pour accumuler et analyser vos statistiques !',
                  style: TextStyle(color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Compile Stats
    int matchesPlayed = _teamMatches.length;
    int matchesWon = 0;
    int matchesLost = 0;
    int setsWon = 0;
    int setsLost = 0;

    int totalAces = 0;
    int totalAttacks = 0;
    int totalBlocks = 0;

    int totalServeErrors = 0;
    int totalAttackErrors = 0;
    int totalReceptionErrors = 0;
    int totalOtherErrors = 0;

    int totalOpponentErrors = 0;
    int totalOpponentWinners = 0;

    // Aggregate stats per player
    final Map<String, _PlayerAggregatedStats> playerStatsMap = {};
    for (var player in widget.team.players) {
      playerStatsMap[player.id] = _PlayerAggregatedStats(player: player);
    }

    for (var match in _teamMatches) {
      if (match.isFinished) {
        if (match.setsWonUs > match.setsWonThem) {
          matchesWon++;
        } else {
          matchesLost++;
        }
      }
      setsWon += match.setsWonUs;
      setsLost += match.setsWonThem;

      for (var set in match.sets) {
        for (var event in set.events) {
          final isUs = event.winningTeam == 'us';
          final pid = event.playerId;

          // Track player stats (even if player is not in current team list anymore, e.g. deleted but has history)
          if (pid != null) {
            // Find player or create dummy one
            if (!playerStatsMap.containsKey(pid)) {
              // Find player name from match players
              final matchPlayer = match.players.firstWhere(
                (p) => p.id == pid,
                orElse: () => Player(id: pid, name: 'Joueur inconnu', number: 0),
              );
              playerStatsMap[pid] = _PlayerAggregatedStats(player: matchPlayer);
            }

            final pStats = playerStatsMap[pid]!;
            switch (event.action) {
              case PointAction.ace:
                pStats.aces++;
                totalAces++;
                break;
              case PointAction.attaque:
                pStats.attacks++;
                totalAttacks++;
                break;
              case PointAction.contre:
                pStats.blocks++;
                totalBlocks++;
                break;
              case PointAction.fauteService:
                pStats.serveErrors++;
                totalServeErrors++;
                break;
              case PointAction.fauteAttaque:
                pStats.attackErrors++;
                totalAttackErrors++;
                break;
              case PointAction.erreurReception:
                pStats.receptionErrors++;
                totalReceptionErrors++;
                break;
              case PointAction.fauteFiletAutre:
                pStats.otherErrors++;
                totalOtherErrors++;
                break;
              default:
                break;
            }
          } else {
            // Team actions (playerId is null)
            switch (event.action) {
              case PointAction.ace:
                totalAces++;
                break;
              case PointAction.attaque:
                totalAttacks++;
                break;
              case PointAction.contre:
                totalBlocks++;
                break;
              case PointAction.fauteService:
                totalServeErrors++;
                break;
              case PointAction.fauteAttaque:
                totalAttackErrors++;
                break;
              case PointAction.erreurReception:
                totalReceptionErrors++;
                break;
              case PointAction.fauteFiletAutre:
                totalOtherErrors++;
                break;
              case PointAction.erreurAdverse:
                if (isUs) totalOpponentErrors++;
                break;
              case PointAction.pointAdversaire:
                if (!isUs) totalOpponentWinners++;
                break;
              default:
                break;
            }
          }
        }
      }
    }

    int totalUsPoints = totalAces + totalAttacks + totalBlocks + totalOpponentErrors;
    int totalThemPoints = totalOpponentWinners + totalServeErrors + totalAttackErrors + totalReceptionErrors + totalOtherErrors;

    final sortedPlayersList = playerStatsMap.values.toList()
      ..sort((a, b) => b.netContribution.compareTo(a.netContribution));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(widget.team.name),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: "Bilan global"),
              Tab(icon: Icon(Icons.people), text: "Stats Joueurs"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Color(0xFFF59E0B),
            indicatorWeight: 3,
          ),
        ),
        body: TabBarView(
          children: [
            // Overview Tab
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Quick Summary Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Bilan des Matchs',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('Matchs', '$matchesPlayed'),
                            _buildSummaryItem('Victoires', '$matchesWon', color: Colors.green),
                            _buildSummaryItem('Défaites', '$matchesLost', color: Colors.red),
                            _buildSummaryItem(
                              'Ratio V/D',
                              matchesLost > 0 ? (matchesWon / matchesLost).toStringAsFixed(2) : '$matchesWon.00',
                            ),
                          ],
                        ),
                        const Divider(height: 32, thickness: 1),
                        const Text(
                          'Bilan des Sets',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('Sets Gagnés', '$setsWon', color: const Color(0xFF3B82F6)),
                            _buildSummaryItem('Sets Perdus', '$setsLost', color: const Color(0xFFEF4444)),
                            _buildSummaryItem(
                              'Ratio S+/S-',
                              setsLost > 0 ? (setsWon / setsLost).toStringAsFixed(2) : '$setsWon.00',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Points won detail
                _buildSectionHeader('Points marqués par le collectif (${totalUsPoints} pts au total)'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatBar('Attaques Gagnantes', totalAttacks, totalUsPoints, const Color(0xFF3B82F6)),
                        _buildStatBar('Blocs Gagnants', totalBlocks, totalUsPoints, const Color(0xFF10B981)),
                        _buildStatBar('Aces (Services gagnants)', totalAces, totalUsPoints, const Color(0xFFF59E0B)),
                        _buildStatBar('Erreurs de l\'adversaire', totalOpponentErrors, totalUsPoints, const Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Points lost detail
                _buildSectionHeader('Points concédés à l\'adversaire (${totalThemPoints} pts au total)'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatBar('Points directs adverse', totalOpponentWinners, totalThemPoints, const Color(0xFFEF4444)),
                        _buildStatBar('Nos fautes de service', totalServeErrors, totalThemPoints, const Color(0xFFF43F5E)),
                        _buildStatBar('Nos fautes d\'attaque', totalAttackErrors, totalThemPoints, const Color(0xFFFB7185)),
                        _buildStatBar('Nos erreurs de réception', totalReceptionErrors, totalThemPoints, const Color(0xFFFDA4AF)),
                        _buildStatBar('Nos fautes de filet / autres', totalOtherErrors, totalThemPoints, const Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),

            // Player Stats Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Cumul des joueurs'),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 18,
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('Joueur', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Aces', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Att', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Blcs', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Err', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('ErrS', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('ErrA', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('ErrR', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text('Bilan', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        ],
                        rows: sortedPlayersList.map((pStats) {
                          final isPositiveBilan = pStats.netContribution >= 0;
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                '${pStats.player.name} (${pStats.player.number})',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              )),
                              DataCell(Text('${pStats.totalPoints}')),
                              DataCell(Text('${pStats.aces}')),
                              DataCell(Text('${pStats.attacks}')),
                              DataCell(Text('${pStats.blocks}')),
                              DataCell(Text('${pStats.totalErrors}')),
                              DataCell(Text('${pStats.serveErrors}')),
                              DataCell(Text('${pStats.attackErrors}')),
                              DataCell(Text('${pStats.receptionErrors}')),
                              DataCell(
                                Text(
                                  '${isPositiveBilan ? "+" : ""}${pStats.netContribution}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPositiveBilan ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Légende des colonnes :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                        SizedBox(height: 4),
                        Text('- Pts : Total points marqués (Aces + Attaques + Blocs)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('- Att / Blcs : Attaques gagnantes / Blocs gagnants', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('- Err / ErrS / ErrA / ErrR : Total fautes / Fautes service / Fautes attaque / Erreurs réception', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('- Bilan : Points marqués moins Fautes commises (Contribution nette)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildStatBar(String title, int count, int total, Color color) {
    final double percent = total > 0 ? count / total : 0;
    final int displayPercent = (percent * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
              ),
              Text(
                '$count ($displayPercent%)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerAggregatedStats {
  final Player player;
  int aces = 0;
  int attacks = 0;
  int blocks = 0;
  int serveErrors = 0;
  int attackErrors = 0;
  int receptionErrors = 0;
  int otherErrors = 0;

  _PlayerAggregatedStats({required this.player});

  int get totalPoints => aces + attacks + blocks;
  int get totalErrors => serveErrors + attackErrors + receptionErrors + otherErrors;
  int get netContribution => totalPoints - totalErrors;
}
