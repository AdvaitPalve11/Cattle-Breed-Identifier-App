class Prediction {
  final int? id;
  final String breed;
  final double confidence; // 0.0 - 100.0
  final String imagePath; // local file path
  final int timestamp; // epoch millis

  Prediction({this.id, required this.breed, required this.confidence, required this.imagePath, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'breed': breed,
      'confidence': confidence,
      'imagePath': imagePath,
      'timestamp': timestamp,
    };
  }

  factory Prediction.fromMap(Map<String, dynamic> map) {
    return Prediction(
      id: map['id'] as int?,
      breed: map['breed'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      imagePath: map['imagePath'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}
