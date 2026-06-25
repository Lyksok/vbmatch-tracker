import 'package:flutter/material.dart';
import '../models/match_model.dart';

class PointLoggingScreen extends StatefulWidget {
  final String winningTeam;
  final String teamName;
  final List<Player> players;

  const PointLoggingScreen({
    super.key,
    required this.winningTeam,
    required this.teamName,
    required this.players,
  });

  @override
  State<PointLoggingScreen> createState() => _PointLoggingScreenState();
}

class _PointLoggingScreenState extends State<PointLoggingScreen> {
  int _currentStep = 1; // 1: Action, 2: Player
  PointAction? _selectedAction;

  // Check if the selected action requires player attribution
  bool get _requiresPlayer {
    if (_selectedAction == null) return false;
    if (_selectedAction == PointAction.erreurAdverse ||
        _selectedAction == PointAction.pointAdversaire) {
      return false;
    }
    return true;
  }

  void _onActionSelected(PointAction action) {
    setState(() {
      _selectedAction = action;
    });

    if (_requiresPlayer && widget.players.isNotEmpty) {
      setState(() {
        _currentStep = 2;
      });
    } else {
      // Return action and null player
      Navigator.pop(context, _LoggingResult(action: action, playerId: null));
    }
  }

  void _onPlayerSelected(String? playerId) {
    if (_selectedAction != null) {
      Navigator.pop(
        context,
        _LoggingResult(action: _selectedAction!, playerId: playerId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUs = widget.winningTeam == 'us';

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Dark slate background matching the scoring board
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(
          isUs
              ? 'Point pour ${widget.teamName} 🎉'
              : 'Point pour les Adversaires 🏐',
          style: TextStyle(
            color: isUs ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _currentStep == 1
              ? _buildActionStep(isUs)
              : _buildPlayerStep(),
        ),
      ),
    );
  }

  Widget _buildActionStep(bool isUs) {
    // Actions selection
    final availableActions = isUs
        ? [
            PointAction.ace,
            PointAction.attaque,
            PointAction.contre,
            PointAction.erreurAdverse,
          ]
        : [
            PointAction.fauteService,
            PointAction.fauteAttaque,
            PointAction.erreurReception,
            PointAction.fauteFiletAutre,
            PointAction.pointAdversaire,
          ];

    return Column(
      key: const ValueKey('ActionStep'),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Text(
            'Comment s\'est terminé le point ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isUs
                ? _buildUsActionsGrid(availableActions)
                : _buildThemActionsGrid(availableActions),
          ),
        ),
      ],
    );
  }

  // Grid for US actions (4 options -> 2x2 grid)
  Widget _buildUsActionsGrid(List<PointAction> actions) {
    final cardColors = [
      const Color(0xFF1E3A8A), // Deep Blue for Ace
      const Color(0xFF0D9488), // Teal for Attaque
      const Color(0xFF059669), // Emerald for Contre
      const Color(0xFF475569), // Slate for Opponent Error
    ];

    final cardIcons = [
      Icons.flash_on,
      Icons.sports_volleyball,
      Icons.front_hand,
      Icons.sentiment_satisfied,
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  actions[0],
                  cardColors[0],
                  cardIcons[0],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  actions[1],
                  cardColors[1],
                  cardIcons[1],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  actions[2],
                  cardColors[2],
                  cardIcons[2],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  actions[3],
                  cardColors[3],
                  cardIcons[3],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Grid for THEM actions (5 options + 1 Cancel option -> 2x3 grid)
  Widget _buildThemActionsGrid(List<PointAction> actions) {
    final cardColors = [
      const Color(0xFF9F1239), // Dark Rose for service fault
      const Color(0xFFBE123C), // Rose for attack fault
      const Color(0xFFE11D48), // Bright Rose for reception error
      const Color(0xFF881337), // Wine for net fault
      const Color(0xFF475569), // Slate for direct opponent point
    ];

    final cardIcons = [
      Icons.sync_problem,
      Icons.trending_down,
      Icons.security_update_warning,
      Icons.grid_off,
      Icons.sports_volleyball,
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  actions[0],
                  cardColors[0],
                  cardIcons[0],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  actions[1],
                  cardColors[1],
                  cardIcons[1],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  actions[2],
                  cardColors[2],
                  cardIcons[2],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  actions[3],
                  cardColors[3],
                  cardIcons[3],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  actions[4],
                  cardColors[4],
                  cardIcons[4],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  elevation: 4,
                  color: const Color(0xFF334155),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.white70,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Retour / Annuler',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(PointAction action, Color color, IconData icon) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onActionSelected(action),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerStep() {
    final title =
        _selectedAction == PointAction.ace ||
            _selectedAction == PointAction.attaque ||
            _selectedAction == PointAction.contre
        ? 'Quel joueur a marqué ?'
        : 'Quel joueur a fait la faute ?';

    return Column(
      key: const ValueKey('PlayerStep'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Action sélectionnée : ${_selectedAction?.label}',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              itemCount:
                  widget.players.length +
                  2, // Players + Team option + Back option
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Team action card
                  return _buildPlayerCard(
                    name: 'Le Collectif\n(Non spécifié)',
                    number: 'C',
                    color: const Color(0xFF1E293B),
                    textColor: Colors.blue.shade300,
                    onTap: () => _onPlayerSelected(null),
                  );
                } else if (index == widget.players.length + 1) {
                  // Back button card
                  return _buildPlayerCard(
                    name: 'Changer l\'action',
                    number: '←',
                    color: const Color(0xFF334155),
                    textColor: Colors.white70,
                    onTap: () {
                      setState(() {
                        _currentStep = 1;
                        _selectedAction = null;
                      });
                    },
                  );
                } else {
                  // Regular player card
                  final player = widget.players[index - 1];
                  return _buildPlayerCard(
                    name: player.name,
                    number: player.number.toString(),
                    color: const Color(0xFF1E293B),
                    textColor: Colors.white,
                    onTap: () => _onPlayerSelected(player.id),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required String number,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Result wrapper class
class _LoggingResult {
  final PointAction action;
  final String? playerId;

  _LoggingResult({required this.action, this.playerId});
}
