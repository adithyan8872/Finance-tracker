import 'package:flutter/material.dart';
import 'package:finance/models/transaction.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final ValueChanged<Category> onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return GestureDetector(
      onTap: () => onTap(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? c : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? c : c.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 15, color: isSelected ? Colors.white : c),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
