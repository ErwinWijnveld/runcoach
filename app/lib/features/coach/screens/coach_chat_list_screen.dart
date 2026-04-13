import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/providers/coach_provider.dart';

class CoachChatListScreen extends ConsumerWidget {
  const CoachChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final api = ref.read(coachApiProvider);
          final response = await api.createConversation({'title': 'New Chat'});
          final id = response['data']['id'];
          ref.invalidate(conversationsProvider);
          if (context.mounted) context.go('/coach/chat/$id');
        },
        backgroundColor: AppColors.warmBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No conversations yet'),
                  SizedBox(height: 8),
                  Text('Start a chat with your AI coach'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return ListTile(
                title: Text(conv.title),
                subtitle: Text(conv.createdAt),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/coach/chat/${conv.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
