class Player {
  final String name;
  final String team;
  final int points;

  Player({
    required this.name,
    required this.team,
    required this.points,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'team': team,
      'points': points,
    };
  }
}