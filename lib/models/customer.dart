class Customer {
  final int? id;
  final String name;
  final String document;
  final String phone;
  final String email;
  final String address;

  const Customer({
    this.id,
    required this.name,
    required this.document,
    required this.phone,
    required this.email,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'document': document,
        'phone': phone,
        'email': email,
        'address': address,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] as String,
        document: map['document'] as String,
        phone: map['phone'] as String,
        email: map['email'] as String,
        address: map['address'] as String,
      );
}
