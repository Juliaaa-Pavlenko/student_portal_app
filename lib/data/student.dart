class Student {
  final String firstName;
  final String lastName;
  final String group;
  final String specialty;
  final String studentId;
  final String phone;
  final String email;
  final String bio;
  final String imagePath;

  Student({
    required this.firstName,
    required this.lastName,
    required this.group,
    required this.specialty,
    required this.studentId,
    required this.phone,
    required this.email,
    required this.bio,
    required this.imagePath,
  });

  factory Student.fromMap(Map<String, dynamic> data) {
    return Student(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      group: data['group'] ?? '',
      specialty: data['specialty'] ?? '',
      studentId: data['studentId'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      // Якщо в базі немає картинки, беремо локальну заглушку
      imagePath: data['imagePath'] ?? 'assets/photo.jpg',
    );
  }
}
