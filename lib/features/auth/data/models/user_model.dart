class UserModel {
  final String? name;
  final String? number;
  final int? age;
  final String? gender;
  final String? designation;
  final Map<String, String>? postOffice;

  UserModel({
    this.name,
    this.number,
    this.age,
    this.gender,
    this.designation,
    this.postOffice,
  });

  // Convert UserModel to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'age': age,
      'gender': gender,
      'designation': designation,
      'postOffice': postOffice,
    };
  }

  // Create UserModel from a Map (useful for retrieving data)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'],
      number: map['number'],
      age: map['age'],
      gender: map['gender'],
      designation: map['designation'],
      postOffice: Map<String, String>.from(map['postOffice'] ?? {}),
    );
  }
}
