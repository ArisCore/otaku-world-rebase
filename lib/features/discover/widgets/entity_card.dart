import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';

import '../../../core/ui/images/cover_image.dart';
import '../../../generated/assets.dart';
import '../../../theme/colors.dart';

class EntityCard extends StatelessWidget {
  const EntityCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.favorites,
    this.rightMargin = 0,
    this.onTap,
  });

  final String title;
  final String? imageUrl;
  final int? favorites;
  final double rightMargin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: rightMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 115,
                  child: AspectRatio(
                    aspectRatio: 100 / 150,
                    child: CoverImage(
                      imageUrl: imageUrl ?? '',
                      type: Enum$MediaType.ANIME,
                      // placeHolderName: Assets.placeholders115x170,
                    ),
                  ),
                ),
                // Mean score
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildFavorites(
                    context,
                    favorites,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            // Manga title
            SizedBox(
              width: 115,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Roboto-Condensed',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavorites(BuildContext context, int? favorites) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 3,
      ),
      decoration: ShapeDecoration(
        color: AppColors.raisinBlack.withValues(alpha:0.6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(5),
          ),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            Assets.iconsFavourite,
            width: 15,
          ),
          const SizedBox(
            width: 3,
          ),
          Text(
            (favorites == null) ? '0' : favorites.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'Roboto-Condensed',
                ),
          ),
        ],
      ),
    );
  }
}
