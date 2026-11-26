class Farm {
  const Farm({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.speciesFocus,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerName;
  final String email;
  final String speciesFocus;
  final DateTime? createdAt;

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      ownerName: (json['owner_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      speciesFocus: (json['species_focus'] ?? 'caprinos').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'email': email,
      'species_focus': speciesFocus,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
