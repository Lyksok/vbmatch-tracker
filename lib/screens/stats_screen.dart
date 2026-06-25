import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';

class StatsScreen extends StatelessWidget {
  final VolleyballMatch match;
  const StatsScreen({Key? key, required this.match}) : super(key: key);

  // Helper to compile player stats
  _PlayerStats _calculatePlayerStats(Player player) {
    int aces = 0;
    int attacks = 0;
    int blocks = 0;
    int serveErrors = 0;
    int attackErrors = 0;
    int receptionErrors = 0;
    int otherErrors = 0;

    for (var set in match.sets) {
      for (var event in set.events) {
        if (event.playerId == player.id) {
          switch (event.action) {
            case PointAction.ace:
              aces++;
              break;
            case PointAction.attaque:
              attacks++;
              break;
            case PointAction.contre:
              blocks++;
              break;
            case PointAction.fauteService:
              serveErrors++;
              break;
            case PointAction.fauteAttaque:
              attackErrors++;
              break;
            case PointAction.erreurReception:
              receptionErrors++;
              break;
            case PointAction.fauteFiletAutre:
              otherErrors++;
              break;
            default:
              break;
          }
        }
      }
    }

    return _PlayerStats(
      player: player,
      aces: aces,
      attacks: attacks,
      blocks: blocks,
      serveErrors: serveErrors,
      attackErrors: attackErrors,
      receptionErrors: receptionErrors,
      otherErrors: otherErrors,
    );
  }

  // Calculate stats for team events (no specific player)
  _PlayerStats _calculateTeamStats() {
    int aces = 0;
    int attacks = 0;
    int blocks = 0;
    int serveErrors = 0;
    int attackErrors = 0;
    int receptionErrors = 0;
    int otherErrors = 0;

    for (var set in match.sets) {
      for (var event in set.events) {
        if (event.playerId == null) {
          switch (event.action) {
            case PointAction.ace:
              aces++;
              break;
            case PointAction.attaque:
              attacks++;
              break;
            case PointAction.contre:
              blocks++;
              break;
            case PointAction.fauteService:
              serveErrors++;
              break;
            case PointAction.fauteAttaque:
              attackErrors++;
              break;
            case PointAction.erreurReception:
              receptionErrors++;
              break;
            case PointAction.fauteFiletAutre:
              otherErrors++;
              break;
            default:
              break;
          }
        }
      }
    }

    return _PlayerStats(
      player: Player(id: 'team', name: 'Équipe / Non spécifié', number: 0),
      aces: aces,
      attacks: attacks,
      blocks: blocks,
      serveErrors: serveErrors,
      attackErrors: attackErrors,
      receptionErrors: receptionErrors,
      otherErrors: otherErrors,
    );
  }

  // Get total opponent errors (points won by us without action)
  int get _opponentErrors {
    int count = 0;
    for (var set in match.sets) {
      for (var event in set.events) {
        if (event.winningTeam == 'us' && event.action == PointAction.erreurAdverse) {
          count++;
        }
      }
    }
    return count;
  }

  // Get total opponent winners (points won by them without our error)
  int get _opponentWinners {
    int count = 0;
    for (var set in match.sets) {
      for (var event in set.events) {
        if (event.winningTeam == 'them' && event.action == PointAction.pointAdversaire) {
          count++;
        }
      }
    }
    return count;
  }

  // Generate French CSV data
  String _generateCSV(List<_PlayerStats> playerStatsList, _PlayerStats teamStats) {
    final buffer = StringBuffer();
    
    // Headers (using semi-colon for French Excel compatibility)
    buffer.writeln('Joueur;Numéro;Aces;Attaques Gagnantes;Blocs Gagnants;Total Points Marqués;Fautes de Service;Fautes d\'Attaque;Fautes de Réception;Fautes de Filet/Autres;Total Fautes Commises;Bilan (Points - Fautes)');

    // Helper to format a row
    void writeRow(_PlayerStats stats) {
      buffer.writeln('${stats.player.name};'
          '${stats.player.id == 'team' ? '' : stats.player.number};'
          '${stats.aces};'
          '${stats.attacks};'
          '${stats.blocks};'
          '${stats.totalPoints};'
          '${stats.serveErrors};'
          '${stats.attackErrors};'
          '${stats.receptionErrors};'
          '${stats.otherErrors};'
          '${stats.totalErrors};'
          '${stats.netContribution}');
    }

    // Write players rows
    for (var stats in playerStatsList) {
      writeRow(stats);
    }

    // Write team actions row
    writeRow(teamStats);

    // Totals calculation
    int totalAces = playerStatsList.fold(0, (sum, item) => sum + item.aces) + teamStats.aces;
    int totalAttacks = playerStatsList.fold(0, (sum, item) => sum + item.attacks) + teamStats.attacks;
    int totalBlocks = playerStatsList.fold(0, (sum, item) => sum + item.blocks) + teamStats.blocks;
    int totalPoints = playerStatsList.fold(0, (sum, item) => sum + item.totalPoints) + teamStats.totalPoints;
    int totalServeErrors = playerStatsList.fold(0, (sum, item) => sum + item.serveErrors) + teamStats.serveErrors;
    int totalAttackErrors = playerStatsList.fold(0, (sum, item) => sum + item.attackErrors) + teamStats.attackErrors;
    int totalReceptionErrors = playerStatsList.fold(0, (sum, item) => sum + item.receptionErrors) + teamStats.receptionErrors;
    int totalOtherErrors = playerStatsList.fold(0, (sum, item) => sum + item.otherErrors) + teamStats.otherErrors;
    int totalErrors = playerStatsList.fold(0, (sum, item) => sum + item.totalErrors) + teamStats.totalErrors;
    int netContr = totalPoints - totalErrors;

    buffer.writeln('TOTAL EQUIPE;;$totalAces;$totalAttacks;$totalBlocks;$totalPoints;$totalServeErrors;$totalAttackErrors;$totalReceptionErrors;$totalOtherErrors;$totalErrors;$netContr');
    buffer.writeln('Erreurs de l\'adversaire (Points offerts);;;;;$_opponentErrors;;;;;;');
    buffer.writeln('Points directs de l\'adversaire (Subis);;;;;$_opponentWinners;;;;;;');

    return buffer.toString();
  }

  void _exportCSV(BuildContext context, List<_PlayerStats> playerStatsList, _PlayerStats teamStats) {
    final csv = _generateCSV(playerStatsList, teamStats);
    Clipboard.setData(ClipboardData(text: csv)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Statistiques copiées au format CSV (Prêt pour Excel) !'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Compile stats
    final playerStatsList = match.players.map((p) => _calculatePlayerStats(p)).toList();
    final teamStats = _calculateTeamStats();

    // Calculations for overview charts
    int usAces = playerStatsList.fold(0, (sum, item) => sum + item.aces) + teamStats.aces;
    int usAttacks = playerStatsList.fold(0, (sum, item) => sum + item.attacks) + teamStats.attacks;
    int usBlocks = playerStatsList.fold(0, (sum, item) => sum + item.blocks) + teamStats.blocks;
    int usTotalEarned = usAces + usAttacks + usBlocks;
    int usOpponentErrors = _opponentErrors;
    int usGrandTotal = usTotalEarned + usOpponentErrors;

    int themServeErrors = playerStatsList.fold(0, (sum, item) => sum + item.serveErrors) + teamStats.serveErrors;
    int themAttackErrors = playerStatsList.fold(0, (sum, item) => sum + item.attackErrors) + teamStats.attackErrors;
    int themReceptionErrors = playerStatsList.fold(0, (sum, item) => sum + item.receptionErrors) + teamStats.receptionErrors;
    int themOtherErrors = playerStatsList.fold(0, (sum, item) => sum + item.otherErrors) + teamStats.otherErrors;
    int themTotalErrors = themServeErrors + themAttackErrors + themReceptionErrors + themOtherErrors;
    int themOpponentWinners = _opponentWinners;
    int themGrandTotal = themTotalErrors + themOpponentWinners;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('Statistiques du Match'),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Copier en CSV',
              onPressed: () => _exportCSV(context, playerStatsList, teamStats),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: "Vue d'ensemble"),
              Tab(icon: Icon(Icons.list_alt), text: "Stats Joueurs"),
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
            _buildOverviewTab(
              context,
              usAces,
              usAttacks,
              usBlocks,
              usOpponentErrors,
              usGrandTotal,
              themServeErrors,
              themAttackErrors,
              themReceptionErrors,
              themOtherErrors,
              themOpponentWinners,
              themGrandTotal,
            ),
            // Player Stats Tab
            _buildPlayerStatsTab(playerStatsList, teamStats),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    int aces,
    int attacks,
    int blocks,
    int oppErrors,
    int totalUs,
    int serveErr,
    int attackErr,
    int recepErr,
    int otherErr,
    int oppWinners,
    int totalThem,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Match Result Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  match.name,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      match.teamName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '${match.setsWonUs} - ${match.setsWonThem}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Adversaires',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  match.isFinished ? 'Match Terminé' : 'Match En cours',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: match.isFinished ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Earned points Breakdown (US)
        _buildSectionHeader('Détail des points marqués par notre équipe (${totalUs} pts)'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (totalUs == 0)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune donnée enregistrée pour ce match.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  )
                else ...[
                  _buildStatBar('Attaques Gagnantes', attacks, totalUs, const Color(0xFF3B82F6)),
                  _buildStatBar('Blocs Gagnants', blocks, totalUs, const Color(0xFF10B981)),
                  _buildStatBar('Aces (Services gagnants)', aces, totalUs, const Color(0xFFF59E0B)),
                  _buildStatBar('Erreurs de l\'adversaire', oppErrors, totalUs, const Color(0xFF64748B)),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Points Given/Conceded breakdown
        _buildSectionHeader('Détail des points concédés à l\'adversaire (${totalThem} pts)'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (totalThem == 0)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune donnée enregistrée pour ce match.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  )
                else ...[
                  _buildStatBar('Points directs adverse', oppWinners, totalThem, const Color(0xFFEF4444)),
                  _buildStatBar('Nos fautes de service', serveErr, totalThem, const Color(0xFFF43F5E)),
                  _buildStatBar('Nos fautes d\'attaque', attackErr, totalThem, const Color(0xFFFB7185)),
                  _buildStatBar('Nos erreurs de réception', recepErr, totalThem, const Color(0xFFFDA4AF)),
                  _buildStatBar('Nos fautes de filet / autres', otherErr, totalThem, const Color(0xFF94A3B8)),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick CSV copy button card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF0F172A),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.table_chart, color: Color(0xFFF59E0B), size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Exporter pour Excel ou Google Sheets',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Copiez les statistiques au format CSV (avec séparateur point-virgule) pour les ouvrir instantanément dans un tableur.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Compile stats again for callback
                    final list = match.players.map((p) => _calculatePlayerStats(p)).toList();
                    final team = _calculateTeamStats();
                    _exportCSV(context, list, team);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('COPIER LES STATISTIQUES (CSV)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPlayerStatsTab(List<_PlayerStats> playerStatsList, _PlayerStats teamStats) {
    if (playerStatsList.isEmpty && teamStats.totalPoints == 0 && teamStats.totalErrors == 0) {
      return const Center(
        child: Text('Aucune statistique de joueur disponible.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Statistiques individuelles'),
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
                rows: [
                  // Individual Player Rows
                  ...playerStatsList.map((stats) {
                    final isPositiveBilan = stats.netContribution >= 0;
                    return DataRow(
                      cells: [
                        DataCell(Text('${stats.player.name} (${stats.player.number})', style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text('${stats.totalPoints}')),
                        DataCell(Text('${stats.aces}')),
                        DataCell(Text('${stats.attacks}')),
                        DataCell(Text('${stats.blocks}')),
                        DataCell(Text('${stats.totalErrors}')),
                        DataCell(Text('${stats.serveErrors}')),
                        DataCell(Text('${stats.attackErrors}')),
                        DataCell(Text('${stats.receptionErrors}')),
                        DataCell(
                          Text(
                            '${isPositiveBilan ? "+" : ""}${stats.netContribution}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositiveBilan ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  // Team Actions Row
                  DataRow(
                    color: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                    cells: [
                      const DataCell(Text('Équipe (Non spécifié)', style: TextStyle(fontStyle: FontStyle.italic))),
                      DataCell(Text('${teamStats.totalPoints}')),
                      DataCell(Text('${teamStats.aces}')),
                      DataCell(Text('${teamStats.attacks}')),
                      DataCell(Text('${teamStats.blocks}')),
                      DataCell(Text('${teamStats.totalErrors}')),
                      DataCell(Text('${teamStats.serveErrors}')),
                      DataCell(Text('${teamStats.attackErrors}')),
                      DataCell(Text('${teamStats.receptionErrors}')),
                      DataCell(
                        Text(
                          '${teamStats.netContribution >= 0 ? "+" : ""}${teamStats.netContribution}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: teamStats.netContribution >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                Text('- Pts : Total points marqués par le joueur (Aces + Attaques + Blocs)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text('- Att / Blcs : Attaques gagnantes / Blocs gagnants', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text('- Err / ErrS / ErrA / ErrR : Total fautes / Fautes service / Fautes attaque / Erreurs réception', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text('- Bilan : Points marqués moins Fautes commises (Contribution nette)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
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

// Inner helper class to group player statistics
class _PlayerStats {
  final Player player;
  final int aces;
  final int attacks;
  final int blocks;
  final int serveErrors;
  final int attackErrors;
  final int receptionErrors;
  final int otherErrors;

  _PlayerStats({
    required this.player,
    required this.aces,
    required this.attacks,
    required this.blocks,
    required this.serveErrors,
    required this.attackErrors,
    required this.receptionErrors,
    required this.otherErrors,
  });

  int get totalPoints => aces + attacks + blocks;
  int get totalErrors => serveErrors + attackErrors + receptionErrors + otherErrors;
  int get netContribution => totalPoints - totalErrors;
}
