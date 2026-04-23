import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/relative_time.dart';
import 'package:app/core/widgets/app_header.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/router/app_router.dart' show kBottomNavReservedHeight;
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/models/conversation.dart';
import 'package:app/features/coach/providers/coach_provider.dart';

const _goldAccent = Color(0xFF785600);

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
    if (context.mounted) context.push('/coach/chat/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return GradientScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: conversationsAsync.when(
                loading: () => const AppSpinner(),
                error: (err, _) => AppErrorState(
                  title: 'Error: $err',
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
                data: (conversations) => _ListBody(
                  conversations: conversations,
                  onNewChat: () => _createConversation(context, ref),
                  onTapConversation: (id) => context.push('/coach/chat/$id'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  final List<Conversation> conversations;
  final VoidCallback onNewChat;
  final ValueChanged<String> onTapConversation;

  const _ListBody({
    required this.conversations,
    required this.onNewChat,
    required this.onTapConversation,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'AI Coach',
                    style: RunCoreText.serifTitle(size: 38, height: 1.0),
                  ),
                ),
                CircleIconButton(icon: Icons.add, onTap: onNewChat),
              ],
            ),
          ),
        ),
        if (conversations.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, kBottomNavReservedHeight),
            sliver: SliverList.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationTile(
                  conversation: conv,
                  onTap: () => onTapConversation(conv.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A37280F),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        conversation.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRelativeTimeString(conversation.createdAt),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _goldAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.tertiary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.chat_bubble_2,
              size: 64,
              color: AppColors.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a chat with your AI coach',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
