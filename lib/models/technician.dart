class Technician {
  final int? id;
  final String name;
  final String contact;
  final String specialty;
  final bool isActive;

  const Technician({
    this.id,
    required this.name,
    required this.contact,
    required this.specialty,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'contact': contact,
        'specialty': specialty,
        'is_active': isActive ? 1 : 0,
      };

  factory Technician.fromMap(Map<String, dynamic> map) => Technician(
        id: map['id'] as int?,
        name: map['name'] as String,
        contact: map['contact'] as String,
        specialty: map['specialty'] as String,
        isActive: map['is_active'] == 1,
      );
}
