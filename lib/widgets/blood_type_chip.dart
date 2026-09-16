import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BloodTypeChip extends StatelessWidget {
  final String bloodType;
  final bool isSelected;
  final ValueChanged<String>? onSelected;
  final double size;

  const BloodTypeChip({
    super.key,
    required this.bloodType,
    this.isSelected = false,
    this.onSelected,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected != null ? () => onSelected!(bloodType) : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.red : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.red : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.red.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          bloodType,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
