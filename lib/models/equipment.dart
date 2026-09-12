class Equipment {
  final int? id;
  final int customerId;
  final String type;
  final String brand;
  final String model;
  final String serialNumber;
  final String patrimony;
  final String observations;

  const Equipment({
    this.id,
    required this.customerId,
    required this.type,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.patrimony,
    required this.observations,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'type': type,
        'brand': brand,
        'model': model,
        'serial_number': serialNumber,
        'patrimony': patrimony,
        'observations': observations,
      };

  Equipment.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int?,
        customerId = map['customer_id'] as int,
        type = map['type'] as String,
        brand = map['brand'] as String,
        model = map['model'] as String,
        serialNumber = map['serial_number'] as String,
        patrimony = map['patrimony'] as String,
        observations = map['observations'] as String;
}
