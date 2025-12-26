import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const AppNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: Container(
        width: width,
        height: height,
        color: AppColors.grey200,
      ),
    );
    
    final defaultError = Container(
      width: width,
      height: height,
      color: AppColors.grey100,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.grey400,
        size: 32,
      ),
    );
    
    if (imageUrl == null || imageUrl!.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: errorWidget ?? defaultError,
      );
    }
    
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? defaultPlaceholder,
        errorWidget: (context, url, error) => errorWidget ?? defaultError,
      ),
    );
  }
}
