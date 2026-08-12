enum ChatMessageRole { system, user, coach, tool }

class ChatMessage {
  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isEdited;
  final String? toolCallId;
  final String? toolName;
  final String? toolArgs;
  final List<String>? images;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isEdited = false,
    this.toolCallId,
    this.toolName,
    this.toolArgs,
    this.images,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isEdited': isEdited,
        if (toolCallId != null) 'toolCallId': toolCallId,
        if (toolName != null) 'toolName': toolName,
        if (toolArgs != null) 'toolArgs': toolArgs,
        if (images != null) 'images': images,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: ChatMessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isEdited: json['isEdited'] as bool? ?? false,
        toolCallId: json['toolCallId'] as String?,
        toolName: json['toolName'] as String?,
        toolArgs: json['toolArgs'] as String?,
        images: json['images'] != null ? List<String>.from(json['images'] as List) : null,
      );

  ChatMessage copyWith({
    String? content,
    bool? isEdited,
    List<String>? images,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isEdited: isEdited ?? this.isEdited,
      toolCallId: toolCallId,
      toolName: toolName,
      toolArgs: toolArgs,
      images: images ?? this.images,
    );
  }
}
