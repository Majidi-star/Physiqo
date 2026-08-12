import '../services/ai_service.dart';

class AiStreamEvent {
  final String deltaText;
  final bool isDone;
  final List<AiToolCall>? toolCalls;

  AiStreamEvent({
    this.deltaText = '',
    this.isDone = false,
    this.toolCalls,
  });
}
