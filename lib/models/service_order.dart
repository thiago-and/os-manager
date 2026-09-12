class ServiceOrder {
  final int? id;
  final String code;
  final int customerId;
  final int? equipmentId;
  final int? technicianId;
  final String problemDescription;
  final String? imagePath;
  final String priority;
  final String status;
  final String openingDate;
  final String? expectedDate;
  final String? diagnosis;
  final String? solution;
  final double laborValue;
  final double materialValue;

  const ServiceOrder({
    this.id,
    required this.code,
    required this.customerId,
    this.equipmentId,
    this.technicianId,
    required this.problemDescription,
    this.imagePath,
    required this.priority,
    required this.status,
    required this.openingDate,
    this.expectedDate,
    this.diagnosis,
    this.solution,
    required this.laborValue,
    required this.materialValue,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'customer_id': customerId,
        'equipment_id': equipmentId,
        'technician_id': technicianId,
        'problem_description': problemDescription,
        'image_path': imagePath,
        'priority': priority,
        'status': status,
        'opening_date': openingDate,
        'expected_date': expectedDate,
        'diagnosis': diagnosis,
        'solution': solution,
        'labor_value': laborValue,
        'material_value': materialValue,
      };

  ServiceOrder.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int?,
        code = map['code'] as String,
        customerId = map['customer_id'] as int,
        equipmentId = map['equipment_id'] as int?,
        technicianId = map['technician_id'] as int?,
        problemDescription = map['problem_description'] as String,
        imagePath = map['image_path'] as String?,
        priority = map['priority'] as String,
        status = map['status'] as String,
        openingDate = map['opening_date'] as String,
        expectedDate = map['expected_date'] as String?,
        diagnosis = map['diagnosis'] as String?,
        solution = map['solution'] as String?,
        laborValue = (map['labor_value'] as num).toDouble(),
        materialValue = (map['material_value'] as num).toDouble();
}
