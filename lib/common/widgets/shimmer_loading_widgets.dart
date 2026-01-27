import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// Shimmer base colors for consistent loading effect
class ShimmerColors {
  static const Color baseColor = Color(0xFFE0E0E0);
  static const Color highlightColor = Color(0xFFF5F5F5);
}

/// Shimmer loading widget for list items (TalepKarti skeleton)
class TalepKartiShimmer extends StatelessWidget {
  const TalepKartiShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: ShimmerColors.baseColor,
        highlightColor: ShimmerColors.highlightColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and status
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(width: 120, height: 14, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Content lines
              Container(
                width: double.infinity,
                height: 12,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity * 0.8,
                height: 12,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity * 0.6,
                height: 12,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 100, height: 12, color: Colors.white),
                  Container(width: 80, height: 12, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading for list views
class ListShimmer extends StatelessWidget {
  final int itemCount;
  final Widget itemShimmer;

  const ListShimmer({
    super.key,
    this.itemCount = 5,
    this.itemShimmer = const TalepKartiShimmer(),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: itemShimmer,
      ),
    );
  }
}

/// Simple circular shimmer for small loading indicators
class CircularShimmer extends StatelessWidget {
  final double size;

  const CircularShimmer({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ShimmerColors.baseColor,
      highlightColor: ShimmerColors.highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Shimmer for form fields (dropdown, input, etc.)
class FormFieldShimmer extends StatelessWidget {
  final double? width;
  final double height;

  const FormFieldShimmer({super.key, this.width, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ShimmerColors.baseColor,
      highlightColor: ShimmerColors.highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Shimmer for detail screen sections
class DetailSectionShimmer extends StatelessWidget {
  final int lineCount;

  const DetailSectionShimmer({super.key, this.lineCount = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: ShimmerColors.baseColor,
        highlightColor: ShimmerColors.highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Container(width: 150, height: 18, color: Colors.white),
            const SizedBox(height: 16),
            // Lines
            ...List.generate(
              lineCount,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(width: 100, height: 14, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(child: Container(height: 14, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
