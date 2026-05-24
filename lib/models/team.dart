class Team {
  final String name;
  final String captain;

  final int pj; // partidos jugados
  final int pg; // ganados
  final int pp; // perdidos
  final int pf; // puntos a favor
  final int pc; // puntos en contra
  final int pts; // puntos en tabla

  Team({
    required this.name,
    required this.captain,
    required this.pj,
    required this.pg,
    required this.pp,
    required this.pf,
    required this.pc,
    required this.pts,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'captain': captain,
      'pj': pj,
      'pg': pg,
      'pp': pp,
      'pf': pf,
      'pc': pc,
      'pts': pts,
    };
  }
}