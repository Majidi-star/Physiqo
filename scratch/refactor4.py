import os
import re

file_path = r'd:\Physiqo\lib\screens\chat_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add providerServed inside the AiStreamEvent listener
if "providerServed: event.providerServed" not in content:
    content = content.replace(
        "msgs[index] = streamingMsg.copyWith(content: finalContent);",
        "msgs[index] = streamingMsg.copyWith(content: finalContent, providerServed: event.providerServed);"
    )
    content = content.replace(
        "final completedMsg = streamingMsg.copyWith(content: finalContent);",
        "final completedMsg = _activeSession!.messages.firstWhere((m) => m.id == streamingMsg.id, orElse: () => streamingMsg).copyWith(content: finalContent);"
    )

# Add UI for providerServed in ChatBubble
ui_provider = """
                        if (widget.message.providerServed != null && isCoach) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Served by ${widget.message.providerServed}',
                            style: AppTheme.labelMd.copyWith(
                              color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
"""

if "widget.message.providerServed != null && isCoach" not in content:
    content = content.replace(
        "if (widget.message.isEdited) ...[",
        ui_provider + "                        if (widget.message.isEdited) ...["
    )

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done phase 4")
