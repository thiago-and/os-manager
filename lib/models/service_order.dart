enum ServiceStatus { open, assigned, inProgress, waitingPart, completed, canceled }

enum Priority { low, medium, high, urgent }

extension ServiceStatusLabel on ServiceStatus {
  String get label {
    switch (this) {
      case ServiceStatus.open:
        return 'Aberta';
      case ServiceStatus.assigned:
        return 'Atribuída';
      case ServiceStatus.inProgress:
        return 'Em atendimento';
      case ServiceStatus.waitingPart:
        return 'Aguardando peça';
      case ServiceStatus.completed:
        return 'Concluída';
      case ServiceStatus.canceled:
        return 'Cancelada';
    }
  }
}

extension PriorityLabel on Priority {
  String get label => switch (this) {
        Priority.low => 'Baixa',
        Priority.medium => 'Média',
        Priority.high => 'Alta',
        Priority.urgent => 'Urgente',
      };
}

class ServiceOrder {
  final int? id;
  final String code;
  final int customerId;
  final int? technicianId;
  final String equipment;
  final String problemDescription;
  final String? imagePath;
  final Priority priority;
  final ServiceStatus status;
  final DateTime openingDate;
  final DateTime? expectedDate;
  final String diagnosis;
  final String solution;
  final double laborValue;
  final double materialValue;

  const ServiceOrder({
    this.id,
    required this.code,
    required this.customerId,
    this.technicianId,
    required this.equipment,
    required this.problemDescription,
    this.imagePath,
    required this.priority,
    required this.status,
    required this.openingDate,
    this.expectedDate,
    required this.diagnosis,
    required this.solution,
    required this.laborValue,
    required this.materialValue,
  });

  double get totalValue => laborValue + materialValue;

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'customer_id': customerId,
        'technician_id': technicianId,
        'equipment': equipment,
        'problem_description': problemDescription,
        'image_path': imagePath,
        'priority': priority.name,
        'status': status.name,
        'opening_date': openingDate.toIso8601String(),
        'expected_date': expectedDate?.toIso8601String(),
        'diagnosis': diagnosis,
        'solution': solution,
        'labor_value': laborValue,
        'material_value': materialValue,
      };

  factory ServiceOrder.fromMap(Map<String, dynamic> map) => ServiceOrder(
        id: map['id'] as int?,
        code: map['code'] as String,
        customerId: map['customer_id'] as int,
        technicianId: map['technician_id'] as int?,
        equipment: map['equipment'] as String,
        problemDescription: map['problem_description'] as String,
        imagePath: map['image_path'] as String?,
        priority: Priority.values.byName(map['priority'] as String),
        status: ServiceStatus.values.byName(map['status'] as String),
        openingDate: DateTime.parse(map['opening_date'] as String),
        expectedDate: map['expected_date'] == null
            ? null
            : DateTime.parse(map['expected_date'] as String),
        diagnosis: map['diagnosis'] as String? ?? '',
        solution: map['solution'] as String? ?? '',
        laborValue: (map['labor_value'] as num).toDouble(),
        materialValue: (map['material_value'] as num).toDouble(),
      );
}
