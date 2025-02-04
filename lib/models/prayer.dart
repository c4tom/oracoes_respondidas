class Prayer {
  final int? id;
  final String description;
  final DateTime createdAt;
  String? answer;
  DateTime? answeredAt;

  Prayer({
    this.id,
    required this.description,
    required this.createdAt,
    this.answer,
    this.answeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'answer': answer,
      'answeredAt': answeredAt?.toIso8601String(),
    };
  }

  factory Prayer.fromMap(Map<String, dynamic> map) {
    return Prayer(
      id: map['id'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      answer: map['answer'],
      answeredAt: map['answeredAt'] != null ? DateTime.parse(map['answeredAt']) : null,
    );
  }
}
