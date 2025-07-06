// lib/models/keyword.dart
class Keyword {
  int? id;
  String keywordText;

  Keyword({
    this.id,
    required this.keywordText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyword_text': keywordText,
    };
  }

  factory Keyword.fromMap(Map<String, dynamic> map) {
    return Keyword(
      id: map['id'],
      keywordText: map['keyword_text'],
    );
  }

  @override
  String toString() {
    return 'Keyword{id: $id, keywordText: $keywordText}';
  }
}