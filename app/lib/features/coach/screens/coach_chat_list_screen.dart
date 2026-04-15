import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/providers/coach_provider.dart';

class CoachChatListScreen extends ConsumerWidget {
  const CoachChatListScreen({super.key});

  Future<void> _createConversation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final api = ref.read(coachApiProvider);
    final response = await api.createConversation({'title': 'New Chat'});
    final id = response['data']['id'];
    ref.invalidate(conversationsProvider);
    if (context.mounted) context.go('/coach/chat/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: AppColors.cream.withValues(alpha: 0.92),
            border: null,
            largeTitle: const Text('AI Coach'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _createConversation(context, ref),
              child: const Icon(
                CupertinoIcons.square_pencil,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          conversationsAsync.when(
            loading: () => const SliverFillRemaining(child: AppSpinner()),
            error: (err, _) => SliverFillRemaining(
              child: AppErrorState(
                title: 'Error: $err',
                onRetry: () => ref.invalidate(conversationsProvider),
              ),
            ),
            data: (conversations) {
              if (conversations.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_2,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a chat with your AI coach',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return AppCard(
                      onTap: () => context.go('/coach/chat/${conv.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conv.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  conv.createdAt,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
