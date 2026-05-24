class MatchModel {
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final String status;
  final int createdAt;
  final List<Map<String, dynamic>> scorersA;
  final List<Map<String, dynamic>> scorersB;
  final String mvpA;
  final String mvpB;
  final int period;
  final int timeLeft;
  final int timeoutA;
  final int timeoutB;

  MatchModel({
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    required this.status,
    required this.createdAt,
    required this.scorersA,
    required this.scorersB,
    required this.mvpA,
    required this.mvpB,
    required this.period,
    required this.timeLeft,
    required this.timeoutA,
    required this.timeoutB,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamA': teamA,
      'teamB': teamB,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'status': status,
      'createdAt': createdAt,
      'scorersA': scorersA,
      'scorersB': scorersB,
      'mvpA': mvpA,
      'mvpB': mvpB,
      'period': period,
      'timeLeft': timeLeft,
      'timeoutA': timeoutA,
      'timeoutB': timeoutB,
    };
  }
}

