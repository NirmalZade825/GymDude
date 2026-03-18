class Exercise {
  final String title;
  final String muscle;
  final String level;
  final String image;

  Exercise({
    required this.title,
    required this.muscle,
    required this.level,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'muscle': muscle,
      'level': level,
      'image': image,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      title: map['title'] ?? '',
      muscle: map['muscle'] ?? '',
      level: map['level'] ?? '',
      image: map['image'] ?? '',
    );
  }
}
