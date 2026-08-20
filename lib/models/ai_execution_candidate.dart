class AiExecutionCandidate {
  final String provider;
  final String modelId;
  final String? apiKey;
  final String? baseUrl;
  final Duration timeoutDuration;
  final bool isVisionCapable;

  const AiExecutionCandidate({
    required this.provider,
    required this.modelId,
    this.apiKey,
    this.baseUrl,
    required this.timeoutDuration,
    required this.isVisionCapable,
  });
}
