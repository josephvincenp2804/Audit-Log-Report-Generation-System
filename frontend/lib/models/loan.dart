class Loan {
  final int id;
  final String loanNumber;
  final String loanType;
  final String borrowerName;
  final double principalAmount;
  final double interestRate;
  final String tenurePeriod;
  final double docFee;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.loanNumber,
    required this.loanType,
    required this.borrowerName,
    required this.principalAmount,
    required this.interestRate,
    required this.tenurePeriod,
    required this.docFee,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      loanNumber: json['loan_number'] as String? ?? '',
      loanType: json['loan_type'] as String? ?? 'General Loan',
      borrowerName: json['borrower_name'] as String? ?? 'Unknown Borrower',
      principalAmount: (json['principal_amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      tenurePeriod: json['tenure_period'] as String? ?? '12 Months',
      docFee: (json['doc_fee'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_number': loanNumber,
      'loan_type': loanType,
      'borrower_name': borrowerName,
      'principal_amount': principalAmount,
      'interest_rate': interestRate,
      'tenure_period': tenurePeriod,
      'doc_fee': docFee,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
