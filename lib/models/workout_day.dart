abstract class WorkoutItem {
  Map<String, dynamic> toJson();
  
  static WorkoutItem fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'superset') {
      return SupersetItem.fromJson(json);
    } else {
      return SingleMoveItem.fromJson(json);
    }
  }
}

class SingleMoveItem extends WorkoutItem {
  final String exerciseId;

  SingleMoveItem(this.exerciseId);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'single',
    'exerciseId': exerciseId,
  };

  factory SingleMoveItem.fromJson(Map<String, dynamic> json) {
    return SingleMoveItem(json['exerciseId'] as String);
  }
}

class SupersetItem extends WorkoutItem {
  final List<String> exerciseIds;

  SupersetItem(this.exerciseIds);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'superset',
    'exerciseIds': exerciseIds,
  };

  factory SupersetItem.fromJson(Map<String, dynamic> json) {
    return SupersetItem(List<String>.from(json['exerciseIds'] as List));
  }
}

class WorkoutDay {
  final String date; // YYYY-MM-DD
  final String title;
  final String focus;
  final List<WorkoutItem> items;

  WorkoutDay({
    required this.date,
    required this.title,
    required this.focus,
    required this.items,
  });

  WorkoutDay copyWith({
    String? date,
    String? title,
    String? focus,
    List<WorkoutItem>? items,
  }) {
    return WorkoutDay(
      date: date ?? this.date,
      title: title ?? this.title,
      focus: focus ?? this.focus,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'title': title,
    'focus': focus,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      focus: json['focus'] as String? ?? '',
      items: (json['items'] as List?)
          ?.map((e) => WorkoutItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
