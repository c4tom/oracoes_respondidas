import 'tag.dart';

class Prayer {
  final int? id;
  final String description;
  final DateTime createdAt;
  String? answer;
  DateTime? answeredAt;
  List<Tag> tags;

  Prayer({
    this.id,
    required this.description,
    required this.createdAt,
    this.answer,
    this.answeredAt,
    this.tags = const [],
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
      tags: [],  // Tags serão carregadas separadamente
    );
  }
}
