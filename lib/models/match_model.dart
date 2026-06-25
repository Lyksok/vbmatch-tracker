
enum PointAction {
  ace('Ace (Service Gagnant)', true),
  attaque('Attaque Gagnante', true),
  contre('Bloc Gagnant', true),
  erreurAdverse('Erreur Adverse (Point Gagné)', true),
  fauteService('Faute de Service (Point Perdu)', false),
  fauteAttaque("Faute d'Attaque (Point Perdu)", false),
  erreurReception('Erreur Réception/Défense (Point Perdu)', false),
  fauteFiletAutre('Faute Filet / Autre (Point Perdu)', false),
  pointAdversaire('Point Direct Adverse', false),
  none('Ignoré', null);

  final String label;
  final bool? isPositive; // true: we scored, false: opponent scored, null: ignore stats
  const PointAction(this.label, this.isPositive);

  static PointAction fromString(String val) {
    return PointAction.values.firstWhere(
      (e) => e.name == val,
      orElse: () => PointAction.none,
    );
  }
}

class Player {
  final String id;
  final String name;
  final int number;

  Player({
    required this.id,
    required this.name,
    required this.number,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      number: map['number'] ?? 0,
    );
  }

  String get displayName => '#$number $name';
}

class PointEvent {
  final String id;
  final String winningTeam; // 'us' or 'them'
  final PointAction action;
  final String? playerId; // ID of the player, or null if team action or opponent error

  PointEvent({
    required this.id,
    required this.winningTeam,
    required this.action,
    this.playerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'winningTeam': winningTeam,
      'action': action.name,
      'playerId': playerId,
    };
  }

  factory PointEvent.fromMap(Map<String, dynamic> map) {
    return PointEvent(
      id: map['id'] ?? '',
      winningTeam: map['winningTeam'] ?? 'us',
      action: PointAction.fromString(map['action'] ?? 'none'),
      playerId: map['playerId'],
    );
  }
}

class VolleyballSet {
  final int setNumber;
  final List<PointEvent> events;
  int scoreUs;
  int scoreThem;
  bool isFinished;

  VolleyballSet({
    required this.setNumber,
    List<PointEvent>? events,
    this.scoreUs = 0,
    this.scoreThem = 0,
    this.isFinished = false,
  }) : this.events = events ?? [];

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'events': events.map((e) => e.toMap()).toList(),
      'scoreUs': scoreUs,
      'scoreThem': scoreThem,
      'isFinished': isFinished,
    };
  }

  factory VolleyballSet.fromMap(Map<String, dynamic> map) {
    var set = VolleyballSet(
      setNumber: map['setNumber'] ?? 1,
      scoreUs: map['scoreUs'] ?? 0,
      scoreThem: map['scoreThem'] ?? 0,
      isFinished: map['isFinished'] ?? false,
    );
    if (map['events'] != null) {
      for (var e in map['events']) {
        set.events.add(PointEvent.fromMap(e));
      }
    }
    return set;
  }

  void recalculateScore() {
    int us = 0;
    int them = 0;
    for (var event in events) {
      if (event.winningTeam == 'us') {
        us++;
      } else {
        them++;
      }
    }
    scoreUs = us;
    scoreThem = them;
  }
}

class VolleyballMatch {
  final String id;
  String name;
  String teamName; // User's team name
  String? teamId; // Associated team ID
  final List<Player> players;
  final List<VolleyballSet> sets;
  int winningSetsNeeded; // 2 (match in 3 sets) or 3 (match in 5 sets)
  bool isFinished;
  DateTime date;
  bool ignoreStats;

  VolleyballMatch({
    required this.id,
    required this.name,
    this.teamName = 'Mon Équipe',
    this.teamId,
    required this.players,
    List<VolleyballSet>? sets,
    this.winningSetsNeeded = 3,
    this.isFinished = false,
    DateTime? date,
    this.ignoreStats = false,
  })  : this.sets = sets ?? [VolleyballSet(setNumber: 1)],
        this.date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teamName': teamName,
      'teamId': teamId,
      'players': players.map((p) => p.toMap()).toList(),
      'sets': sets.map((s) => s.toMap()).toList(),
      'winningSetsNeeded': winningSetsNeeded,
      'isFinished': isFinished,
      'date': date.toIso8601String(),
      'ignoreStats': ignoreStats,
    };
  }

  factory VolleyballMatch.fromMap(Map<String, dynamic> map) {
    var match = VolleyballMatch(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      teamName: map['teamName'] ?? 'Mon Équipe',
      teamId: map['teamId'],
      players: (map['players'] as List?)?.map((p) => Player.fromMap(p)).toList() ?? [],
      winningSetsNeeded: map['winningSetsNeeded'] ?? 3,
      isFinished: map['isFinished'] ?? false,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      ignoreStats: map['ignoreStats'] ?? false,
    );

    if (map['sets'] != null) {
      match.sets.clear();
      for (var s in map['sets']) {
        match.sets.add(VolleyballSet.fromMap(s));
      }
    }
    return match;
  }

  VolleyballSet get currentSet => sets.last;

  int get setsWonUs {
    int count = 0;
    for (var s in sets) {
      if (s.isFinished && s.scoreUs > s.scoreThem) {
        count++;
      }
    }
    return count;
  }

  int get setsWonThem {
    int count = 0;
    for (var s in sets) {
      if (s.isFinished && s.scoreThem > s.scoreUs) {
        count++;
      }
    }
    return count;
  }

  bool isDecidingSet(int setNumber) {
    if (winningSetsNeeded == 2) {
      return setNumber == 3;
    } else {
      return setNumber == 5;
    }
  }

  void addPoint(String winningTeam, PointAction action, String? playerId) {
    if (isFinished) return;

    var activeSet = currentSet;
    if (activeSet.isFinished) return;

    // Create and add event
    var event = PointEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      winningTeam: winningTeam,
      action: action,
      playerId: playerId,
    );
    activeSet.events.add(event);
    activeSet.recalculateScore();

    // Check if the current set is finished
    int targetPoints = isDecidingSet(activeSet.setNumber) ? 15 : 25;
    if (activeSet.scoreUs >= targetPoints && activeSet.scoreUs >= activeSet.scoreThem + 2) {
      activeSet.isFinished = true;
    } else if (activeSet.scoreThem >= targetPoints && activeSet.scoreThem >= activeSet.scoreUs + 2) {
      activeSet.isFinished = true;
    }

    // Check if match is finished
    if (setsWonUs >= winningSetsNeeded || setsWonThem >= winningSetsNeeded) {
      isFinished = true;
    } else if (activeSet.isFinished) {
      // Start a new set if the match is not finished
      sets.add(VolleyballSet(setNumber: activeSet.setNumber + 1));
    }
  }

  void undoLastPoint() {
    if (sets.isEmpty) return;

    var activeSet = currentSet;

    // If the active set is empty, but we have a previous set, we need to backtrack
    if (activeSet.events.isEmpty && sets.length > 1) {
      sets.removeLast(); // Remove empty set
      activeSet = currentSet;
      activeSet.isFinished = false; // Reopen previous set
      isFinished = false;           // Reopen match
    }

    if (activeSet.events.isNotEmpty) {
      activeSet.events.removeLast();
      activeSet.recalculateScore();
      activeSet.isFinished = false;
      isFinished = false;
    }
  }

  // Helper to check who is serving.
  // In volleyball, the server is determined by the team that won the last point.
  // For the very first point, we default to us.
  String get servingTeam {
    if (currentSet.events.isEmpty) {
      if (sets.length > 1) {
        var prevSet = sets[sets.length - 2];
        if (prevSet.events.isNotEmpty) {
          return prevSet.events.last.winningTeam;
        }
      }
      return 'us';
    }
    return currentSet.events.last.winningTeam;
  }
}

class Team {
  final String id;
  final String name;
  final String type; // '3x3', '4x4', '6x6'
  final List<Player> players;

  Team({
    required this.id,
    required this.name,
    required this.type,
    required this.players,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'players': players.map((p) => p.toMap()).toList(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '6x6',
      players: (map['players'] as List?)?.map((p) => Player.fromMap(p)).toList() ?? [],
    );
  }
}
