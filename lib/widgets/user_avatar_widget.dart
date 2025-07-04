import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';

class UserAvatarWidget extends StatelessWidget {
  final String userId;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final String? label; // Optional label below avatar

  const UserAvatarWidget({
    Key? key,
    required this.userId,
    this.size = 50,
    this.showBorder = false,
    this.borderColor,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: showBorder
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(size / 2),
                  border: Border.all(
                    color: borderColor ?? Colors.grey.shade300,
                    width: 2,
                  ),
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: RandomAvatar(
              userId,
              height: size,
              width: size,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// Example usage in a user list
class UserListExample extends StatelessWidget {
  final List<Map<String, String>> users = [
    {'id': 'user1', 'email': 'user1@example.com'},
    {'id': 'user2', 'email': 'user2@example.com'},
    {'id': 'user3', 'email': 'user3@example.com'},
  ];

  UserListExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: UserAvatarWidget(
            userId: user['id']!,
            size: 40,
            showBorder: true,
          ),
          title: Text(user['email']!),
          subtitle: Text('ID: ${user['id']}'),
        );
      },
    );
  }
}