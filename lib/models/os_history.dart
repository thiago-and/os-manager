class OSHistory {
  final int? id;
  final int serviceOrderId;
  final String date;
  final String status;
  final String description;
  final String userName;

  const OSHistory({
    this.id,
    required this.serviceOrderId,
    required this.date,
    required this.status,
    required this.description,
    required this.userName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'service_order_id': serviceOrderId,
        'date': date,
        'status': status,
        'description': description,
        'user_name': userName,
      };

  OSHistory.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int?,
        serviceOrderId = map['service_order_id'] as int,
        date = map['date'] as String,
        status = map['status'] as String,
        description = map['description'] as String,
        userName = map['user_name'] as String;
}
