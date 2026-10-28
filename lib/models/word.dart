/// Una palabra de vocabulario (inglés, traducción al español y fonética).
///
/// El formato JSON es el mismo que usaba la versión web original
/// (`gridlearn.words.v1`), por lo que los datos guardados siguen siendo válidos.
class Word {
  const Word({
    required this.id,
    required this.english,
    required this.spanish,
    this.phonetic = '',
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String english;
  final String spanish;
  final String phonetic;
  final int createdAt;
  final int? updatedAt;

  Word copyWith({
    String? english,
    String? spanish,
    String? phonetic,
    int? updatedAt,
  }) {
    return Word(
      id: id,
      english: english ?? this.english,
      spanish: spanish ?? this.spanish,
      phonetic: phonetic ?? this.phonetic,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: '${json['id']}',
      english: '${json['english'] ?? ''}',
      spanish: '${json['spanish'] ?? ''}',
      phonetic: '${json['phonetic'] ?? ''}',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'english': english,
        'spanish': spanish,
        'phonetic': phonetic,
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
