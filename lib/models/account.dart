class Account {
  final String id;
  final String name;
  final String? photoPath;

  Account({
    required this.id,
    required this.name,
    this.photoPath,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      photoPath: json['photoPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
    };
  }
}
