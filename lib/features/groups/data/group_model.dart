import 'group_type.dart';

/// Mirrors `public.groups`.
class Group {
  final String id;
  final String name;
  final GroupType groupType;
  final bool simplifyByDefault;
  final String? avatarUrl;
  final String inviteToken;
  final String createdBy;
  final String whiteboard;

  const Group({
    required this.id,
    required this.name,
    required this.groupType,
    required this.simplifyByDefault,
    required this.avatarUrl,
    required this.inviteToken,
    required this.createdBy,
    required this.whiteboard,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        groupType: GroupType.fromJson(json['group_type'] as String),
        simplifyByDefault: json['simplify_by_default'] as bool? ?? true,
        avatarUrl: json['avatar_url'] as String?,
        inviteToken: json['invite_token'] as String,
        createdBy: json['created_by'] as String,
        whiteboard: json['whiteboard'] as String? ?? '',
      );
}

/// Mirrors a `public.group_members` row joined with its `profiles` row —
/// the shape the group detail screen actually needs (name/avatar alongside
/// membership metadata), rather than forcing two separate lookups per member.
class GroupMember {
  final String userId;
  final String role;
  final String firstName;
  final String lastName;
  final String? pictureUrl;

  const GroupMember({
    required this.userId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.pictureUrl,
  });

  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';
  bool get isOwner => role == 'owner';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>;
    return GroupMember(
      userId: json['user_id'] as String,
      role: json['role'] as String,
      firstName: profile['first_name'] as String,
      lastName: profile['last_name'] as String? ?? '',
      pictureUrl: profile['picture_url'] as String?,
    );
  }
}
