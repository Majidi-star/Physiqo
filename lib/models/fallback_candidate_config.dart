import 'dart:convert';

class FallbackCandidateConfig {
  final String id;
  final String provider;
  final String modelId;
  final bool isEnabled;

  const FallbackCandidateConfig({
    required this.id,
    required this.provider,
    required this.modelId,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'modelId': modelId,
        'isEnabled': isEnabled,
      };

  factory FallbackCandidateConfig.fromJson(Map<String, dynamic> json) =>
      FallbackCandidateConfig(
        id: json['id'] as String,
        provider: json['provider'] as String,
        modelId: json['modelId'] as String,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
      
  static List<FallbackCandidateConfig> decodeList(String jsonStr) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => FallbackCandidateConfig.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static String encodeList(List<FallbackCandidateConfig> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }
}
