import 'package:flutter/material.dart';

/// Emoji rating widget for experience feedback
class EmojiRating extends StatelessWidget {
  final int value;
  final String emoji;
  final int groupValue;
  final ValueChanged<int> onChanged;

  const EmojiRating({
    super.key,
    required this.value,
    required this.emoji,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(selected ? 12 : 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: selected ? 32 : 24),
        ),
      ),
    );
  }
}

/// Toggle row for binary Yes/No questions
class ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
          children: [
            _buildMiniSegment('Non', !value, () => onChanged(false)),
            const SizedBox(width: 8),
            _buildMiniSegment('Oui', value, () => onChanged(true)),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniSegment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B365D) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
