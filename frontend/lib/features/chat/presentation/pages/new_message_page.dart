import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/usecases/get_following_usecase.dart';
import 'chat_conversation_page.dart';

/// Picks who to message from the people you follow — the backend's
/// "friends" concept (see grpc_client/friends.py) is just your following
/// list, so that's the natural pool of people you can start a DM with.
class NewMessagePage extends ConsumerStatefulWidget {
  const NewMessagePage({super.key});

  @override
  ConsumerState<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends ConsumerState<NewMessagePage> {
  late final Future<List<User>> _future = _load();

  Future<List<User>> _load() {
    final myId = ref.read(authViewModelProvider).valueOrNull!.id;
    return ref.read(getFollowingUsecaseProvider)(myId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New message')),
      body: FutureBuilder<List<User>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error}',
                style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
              ),
            );
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Text(
                'Follow people to start messaging them.',
                style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
              ),
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final fullName = '${user.firstname} ${user.lastname}'.trim();
              return ListTile(
                leading: _Avatar(imageUrl: user.imageUrl),
                title: Text(
                  fullName.isNotEmpty ? fullName : user.username,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight),
                ),
                subtitle: Text(
                  '@${user.username}',
                  style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
                ),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ChatConversationPage(
                        partnerId: user.id,
                        partnerName: fullName.isNotEmpty ? fullName : user.username,
                        partnerImageUrl: user.imageUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
      child: ClipOval(
        child: Container(
          color: AppColors.backgroundDark,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 20, color: AppColors.textLight)
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
