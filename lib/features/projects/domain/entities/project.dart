class Project {
  final int id;
  final String name;
  final String colorHex;
  final String? iconName;

  const Project({
    required this.id,
    required this.name,
    required this.colorHex,
    this.iconName,
  });

  Project copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? iconName,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
