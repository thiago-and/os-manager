class UsedItem {
  final int? id;
  final int serviceOrderId;
  final String description;
  final double value;

  const UsedItem({
    this.id,
    required this.serviceOrderId,
    required this.description,
    required this.value,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'service_order_id': serviceOrderId,
        'description': description,
        'value': value,
      };

  factory UsedItem.fromMap(Map<String, dynamic> map) => UsedItem(
        id: map['id'] as int?,
        serviceOrderId: map['service_order_id'] as int,
        description: map['description'] as String,
        value: (map['value'] as num).toDouble(),
      );
}
