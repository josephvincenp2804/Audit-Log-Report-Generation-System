class Department {
  final int id;
  final String name;
  final String code;
  final String? description;

  Department({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
    );
  }
}

class Employee {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final int departmentId;
  final String? departmentName;
  final String jobTitle;
  final double salary;
  final String status;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.departmentId,
    this.departmentName,
    required this.jobTitle,
    required this.salary,
    required this.status,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      departmentId: json['department_id'] ?? 0,
      departmentName: json['department_name'],
      jobTitle: json['job_title'] ?? '',
      salary: (json['salary'] is num) ? (json['salary'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'Active',
    );
  }
}

