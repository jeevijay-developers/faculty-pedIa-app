import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTap;
  
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.showBorder = false,
    this.borderColor,
    this.onTap,
  });
  
  String get _initials {
    if (name == null || name!.isEmpty) return 'FP';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name!.substring(0, name!.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppColors.primary,
                width: 2,
              )
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    
    return avatar;
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final double? size;
  
  const StatusBadge({
    super.key,
    required this.status,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text = status;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'live':
      case 'ongoing':
        color = AppColors.success;
        break;
      case 'upcoming':
      case 'scheduled':
        color = AppColors.info;
        break;
      case 'completed':
      case 'ended':
        color = AppColors.grey500;
        break;
      case 'cancelled':
      case 'inactive':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey500;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: size ?? 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class RatingWidget extends StatelessWidget {
  final double rating;
  final int? count;
  final double size;
  final bool showCount;
  
  const RatingWidget({
    super.key,
    required this.rating,
    this.count,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: AppColors.accent,
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.875,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showCount && count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: AppColors.grey500,
            ),
          ),
        ],
      ],
    );
  }
}

class PriceWidget extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final double? discount;
  final double fontSize;
  
  const PriceWidget({
    super.key,
    required this.price,
    this.originalPrice,
    this.discount,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discount != null && discount! > 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${price.toInt()}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        if (hasDiscount && originalPrice != null) ...[
          const SizedBox(width: 8),
          Text(
            '₹${originalPrice!.toInt()}',
            style: TextStyle(
              fontSize: fontSize * 0.7,
              color: AppColors.grey500,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${discount!.toInt()}% OFF',
              style: TextStyle(
                fontSize: fontSize * 0.55,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
