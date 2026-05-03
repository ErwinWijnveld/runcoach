import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/relative_time.dart';
import 'package:app/core/widgets/app_header.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/intro_fx.dart';
import 'package:app/router/app_router.dart' show kBottomNavReservedHeight;
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/models/conversation.dart';
import 'package:app/features/coach/providers/coach_provider.dart';

const _goldAccent = Color(0xFF785600);

class CoachChatListScreen extends ConsumerStatefulWidget {
  const CoachChatListScreen({super.key});

  @override
  ConsumerState<CoachChatListScreen> createState() =>
      _CoachChatListScreenState();
}

class _CoachChatListScreenState extends ConsumerState<CoachChatListScreen> {
  bool _autoCreateFired = false;

  Future<void> _createConversation({bool fromAutoCreate = false}) async {
    try {
      final api = ref.read(coachApiProvider);
      final response = await api.createConversation({'title': 'New Chat'});
      final id = response['data']['id'];
      ref.invalidate(conversationsProvider);
      if (mounted) context.push('/coach/chat/$id');
    } catch (_) {
      // If the auto-create failed, let the user fall back to the empty
      // state UI so they can retry via the "+" button.
      if (fromAutoCreate && mounted) {
        setState(() => _autoCreateFired = false);
      }
      rethrow;
    }
  }

  Future<void> _deleteConversation(String id) async {
    try {
      await ref.read(coachApiProvider).deleteConversation(id);
    } catch (_) {
      // Surface failure with a Cupertino alert; the row stays in place
      // because we invalidate below regardless.
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Could not delete chat'),
            content: const Text('Please try again.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      ref.invalidate(conversationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                data: (conversations) {
                  if (conversations.isEmpty) {
                    if (!_autoCreateFired) {
                      _autoCreateFired = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _createConversation(fromAutoCreate: true)
                              .catchError((_) {});
                        }
                      });
                    }
                    return const AppSpinner();
                  }
                  return IntroFx(
                    child: _ListBody(
                      conversations: conversations,
                      onNewChat: () => _createConversation(),
                      onTapConversation: (id) => context.push('/coach/chat/$id'),
                      onDeleteConversation: (id) => _deleteConversation(id),
                    ),
                  );
                },
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
  final ValueChanged<String> onDeleteConversation;

  const _ListBody({
    required this.conversations,
    required this.onNewChat,
    required this.onTapConversation,
    required this.onDeleteConversation,
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
                    'Coach chat',
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
                  key: ValueKey(conv.id),
                  conversation: conv,
                  onTap: () => onTapConversation(conv.id),
                  onDelete: () => onDeleteConversation(conv.id),
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
  final VoidCallback onDelete;

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      groupTag: 'coach-chats',
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: CupertinoColors.transparent,
            foregroundColor: CupertinoColors.white,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.trash, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
      child: _ConversationCard(conversation: conversation, onTap: onTap),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.onTap});

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
