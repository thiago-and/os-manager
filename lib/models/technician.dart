class Technician {
  final int? id;
  final String name;
  final String contact;
  final String specialty;
  final bool isActive;
  final String? matricula;
  final String? photoPath;

  const Technician({
    this.id,
    required this.name,
    required this.contact,
    required this.specialty,
    required this.isActive,
    this.matricula,
    this.photoPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'contact': contact,
        'specialty': specialty,
        'is_active': isActive ? 1 : 0,
        'matricula': matricula,
        'photo_path': photoPath,
      };

  Technician.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int?,
        name = map['name'] as String,
        contact = map['contact'] as String,
        specialty = map['specialty'] as String,
        isActive = (map['is_active'] as int) == 1,
        matricula = map['matricula'] as String?,
        photoPath = map['photo_path'] as String?;
}
