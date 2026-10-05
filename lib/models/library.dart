class PhotoFolder {
  final String id;
  String name;
  final List<String> photoIds;
  PhotoFolder({required this.id, required this.name, List<String>? photoIds})
    : photoIds = photoIds ?? [];
  factory PhotoFolder.fromJson(Map<String, dynamic> json) => PhotoFolder(
    id: json['id'],
    name: json['name'],
    photoIds: List<String>.from(json['photoIds'] ?? []),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoIds': photoIds,
  };
}

class UserProfile {
  final String name;
  final String username;
  final String email;
  final String bio;
  final String? avatar;
  const UserProfile({
    this.name = '',
    this.username = '',
    this.email = '',
    this.bio = '',
    this.avatar,
  });
  String get initials => name.trim().isEmpty
      ? 'IH'
      : name
            .trim()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s[0])
            .join()
            .toUpperCase();
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] ?? '',
    username: j['username'] ?? '',
    email: j['email'] ?? '',
    bio: j['bio'] ?? '',
    avatar: j['avatar'],
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'username': username,
    'email': email,
    'bio': bio,
    'avatar': avatar,
  };
}
