class Waypoint {
  final String name;
  final String coordinate;
  final String postId;

  Waypoint({
    required this.name,
    required this.coordinate,
    required this.postId,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      name: json['name'],
      coordinate: json['coordinate'],
      postId: json['postId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coordinate': coordinate,
      'postId': postId,
    };
  }
}
