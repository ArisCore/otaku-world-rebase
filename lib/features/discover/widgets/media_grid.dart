import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/images/cover_image.dart';
import '../../../generated/assets.dart';
import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import '../../../theme/colors.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({super.key, required this.list, required this.hasNextPage});

  final List<Fragment$MediaShort?> list;
  final bool hasNextPage;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              childAspectRatio: 0.5556,
            ),
            // const SliverGridDelegateWithMaxCrossAxisExtent(
            //   maxCrossAxisExtent: 150,
            //   crossAxisSpacing: 10,
            //   mainAxisSpacing: 0.001,
            //   childAspectRatio: 0.5556,
            // ),
            delegate: SliverChildBuilderDelegate(
              childCount: list.length,
              (context, index) {
                return _buildMediaCard(context, list[index]);
              },
            ),
          ),
        ),
        if (hasNextPage)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaCard(BuildContext context, Fragment$MediaShort? media) {
    if (media == null) return const SizedBox();

    return GestureDetector(
      onTap: () => context.push('/media-detail?id=${media.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 7.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 169,
                  width: 115,
                  child: CoverImage(
                    imageUrl: media.coverImage!.large!,
                    type: media.type!,
                    // placeHolderName: Assets.placeholders115x169,
                  ),
                ),
                // Mean score
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildMeanScore(
                    context,
                    media.meanScore,
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
                getTitle(media.title) ?? 'No Title',
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

  String? getTitle(Fragment$MediaShort$title? title) {
    return title?.english ?? title?.romaji ?? title?.native;
  }

  Widget _buildMeanScore(BuildContext context, int? meanScore) {
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
          SvgPicture.asset(Assets.iconsStar),
          const SizedBox(
            width: 1,
          ),
          Text(
            (meanScore == null) ? '0' : meanScore.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'Roboto-Condensed',
                ),
          ),
        ],
      ),
    );
  }
}
