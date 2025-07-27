import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:intl/intl.dart';

import 'package:studora/app/data/models/conversation_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';

class ElegantMessageCard extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const ElegantMessageCard({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOfMessage = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    if (dateOfMessage == today) {
      return DateFormat.jm().format(timestamp);
    } else if (dateOfMessage == yesterday) {
      return "Yesterday";
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat.E().format(timestamp);
    } else {
      return DateFormat.yMd().format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final otherUserId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final otherUserName =
        conversation.participantNames[otherUserId] ?? 'Unknown User';
    final otherUserAvatarUrl = conversation.participantAvatars[otherUserId];
    final unreadCount = conversation.unreadCounts[currentUserId] ?? 0;
    final bool hasUnread = unreadCount > 0;
    final bool isLastMessageByMe =
        conversation.lastMessageSenderId == currentUserId;

    final RelatedItem? primaryItem = conversation.relatedItems.isNotEmpty
        ? conversation.relatedItems.first
        : null;
    final int additionalItemsCount = conversation.relatedItems.length > 1
        ? conversation.relatedItems.length - 1
        : 0;

    final Color cardBgColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
        : (hasUnread
              ? theme.colorScheme.primary.withValues(
                  alpha: isDarkMode ? 0.1 : 0.06,
                )
              : theme.colorScheme.surface);
    final BorderSide cardBorderSide = isSelected
        ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
        : BorderSide(
            color: hasUnread
                ? theme.colorScheme.primary.withValues(
                    alpha: isDarkMode ? 0.3 : 0.4,
                  )
                : theme.dividerColor.withValues(alpha: isDarkMode ? 0.15 : 0.2),
            width: hasUnread ? 1.5 : 1.0,
          );
    return Card(
      elevation: isSelected || hasUnread ? 1.0 : 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: cardBorderSide,
      ),
      color: cardBgColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        otherUserAvatarUrl != null &&
                            otherUserAvatarUrl.isNotEmpty
                        ? NetworkImage(otherUserAvatarUrl)
                        : null,
                    child:
                        (otherUserAvatarUrl == null ||
                            otherUserAvatarUrl.isEmpty)
                        ? Text(
                            otherUserName.isNotEmpty
                                ? otherUserName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  if (isSelected)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUserName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: hasUnread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      "${isLastMessageByMe ? 'You: ' : ''}${conversation.lastMessageSnippet ?? 'No messages yet.'}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasUnread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (primaryItem != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.tag_fill,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                primaryItem.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                            if (additionalItemsCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+$additionalItemsCount',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTimestamp(
                      conversation.lastMessageTimestamp.toLocal(),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasUnread
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 11.5,
                    ),
                  ),
                  SizedBox(height: hasUnread && !isSelected ? 6.0 : 20.0),
                  if (hasUnread && !isSelected && unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7.0,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: isDarkMode ? 0.3 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
