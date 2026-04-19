import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final bool showLabel;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.showLabel = false,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      isUser: data['isUser'] ?? false,
      text: data['text'] ?? '',
      showLabel: data['showLabel'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'isUser': isUser,
        'text': text,
        'showLabel': showLabel,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
