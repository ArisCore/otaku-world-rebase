import 'package:flutter/material.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';
import 'package:otaku_world/utils/ui_utils.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../theme/colors.dart';

class GridShimmer extends StatelessWidget {
  const GridShimmer({
    super.key,
    required this.mediaType,
    this.crossAxisCount = 3,
    this.physics,
  });

  final Enum$MediaType mediaType;
  final int crossAxisCount;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GridView.builder(
      physics: physics,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: (mediaType == Enum$MediaType.ANIME)
                  ? BorderRadius.circular(15)
                  : BorderRadius.circular(5),
              child: Shimmer(
                child: AspectRatio(
                  aspectRatio: 100 / 148,
                  child: Container(
                    width: UIUtils.getWidgetWidth(
                      targetWidgetWidth: 100,
                      screenWidth: size.width,
                    ),
                    color: AppColors.blackOlive,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Shimmer(
                child: Container(
                  color: AppColors.blackOlive,
                  width: UIUtils.getWidgetWidth(
                    targetWidgetWidth: 80,
                    screenWidth: size.width,
                  ),
                  height: UIUtils.getWidgetHeight(
                    targetWidgetHeight: 10,
                    screenHeight: size.height,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      itemCount: 24,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 100 / 182,
      ),
    );
  }
}
