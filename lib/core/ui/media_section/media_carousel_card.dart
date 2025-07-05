import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/texts/genre_text.dart';
import 'package:otaku_world/features/media_detail/widgets/status_row.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';

import '../../../features/media_detail/widgets/info_data.dart';
import '../../../generated/assets.dart';
import '../../../graphql/__generated/graphql/schema.graphql.dart';
import '../../../services/caching/image_cache_manager.dart';
import '../../../theme/colors.dart';
import '../../../utils/formatting_utils.dart';
import '../../../utils/navigation_helper.dart';
import '../../../utils/ui_utils.dart';
import '../buttons/primary_button.dart';
import '../placeholders/poster_placeholder.dart';

class MediaCarouselCard extends StatelessWidget {
  const MediaCarouselCard({
    super.key,
    required this.width,
    required this.screenWidth,
    required this.color,
    required this.media,
  });

  final double width;
  final double screenWidth;
  final Color color;
  final Fragment$MediaShort? media;

  @override
  Widget build(BuildContext context) {
    if (media == null) return const SizedBox();

    return Container(
      width: width,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: media!.type == Enum$MediaType.ANIME
              ? BorderRadius.circular(20)
              : BorderRadius.circular(15),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, AppColors.japaneseIndigo],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                child: _buildMediaPoster(
                  media?.coverImage?.extraLarge,
                  media!.type!,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      media!.title!.userPreferred!,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    InfoData(
                      iconName: Assets.iconsFavourite,
                      separateWidth: 3,
                      info: media!.favourites.toString(),
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    const SizedBox(height: 15),
                    StatusRow(
                      airingSchedule: media!.airingSchedule,
                      status: media!.status,
                      fontSize: 12,
                      alignment: MainAxisAlignment.center,
                    ),
                    const SizedBox(height: 15),
                    GenreText(
                      genres: media!.genres,
                      genreStyle:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                      indicatorStyle:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.sunsetOrange,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                    ),
                    const SizedBox(height: 20),
                    _buildMediaDetails(context, media!),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: _buildButtonOptions(
              screenWidth,
              context,
              media!.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonOptions(double screenWidth, BuildContext context, int id) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PrimaryButton(
          onTap: () {},
          label: 'Add to List',
          color: AppColors.darkCharcoal,
          width: UIUtils.getWidgetWidth(
            targetWidgetWidth: 100,
            screenWidth: screenWidth,
          ),
          fontSize: 14,
          horizontalPadding: 0,
          verticalPadding: 7,
          radius: 8,
          isSmall: true,
        ),
        PrimaryButton(
          onTap: () => NavigationHelper.goToMediaDetailScreen(
            context: context,
            mediaId: id,
          ),
          label: 'View more',
          width: UIUtils.getWidgetWidth(
            targetWidgetWidth: 100,
            screenWidth: screenWidth,
          ),
          fontSize: 14,
          horizontalPadding: 0,
          verticalPadding: 7,
          radius: 8,
          isSmall: true,
        ),
      ],
    );
  }

  Widget _buildMediaDetails(BuildContext context, Fragment$MediaShort media) {
    String mediaFormatEpChap = '';
    String mediaStartYear = '';
    String mediaStartYearLabel = '';
    if (media.type == Enum$MediaType.MANGA) {
      mediaFormatEpChap = (media.chapters == null)
          ? '${StringConstants.nullStringPlaceHolder}chap'
          : '${media.chapters} chap';

      mediaStartYear =
          (media.startDate == null) ? '?' : '${media.startDate!.year}';
      mediaStartYearLabel = 'start year';
    } else {
      mediaFormatEpChap = (media.episodes == null)
          ? '${StringConstants.nullStringPlaceHolder}ep'
          : '${media.episodes} ep';

      mediaStartYear =
          '${FormattingUtils.getSeasonString(media.season)} ${media.seasonYear ?? StringConstants.nullStringPlaceHolder}';
      mediaStartYearLabel = 'season';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMediaDetail(
          context,
          FormattingUtils.getMediaFormatString(media.format),
          mediaFormatEpChap,
        ),
        if (media.meanScore != null) ...[
          SvgPicture.asset(Assets.iconsLineVertical),
          _buildMediaDetail(
            context,
            '${media.meanScore}%',
            'score',
          ),
        ],
        SvgPicture.asset(Assets.iconsLineVertical),
        _buildMediaDetail(
          context,
          mediaStartYear,
          mediaStartYearLabel,
        ),
      ],
    );
  }

  Widget _buildMediaDetail(BuildContext context, String text, String subtext) {
    return Column(
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          subtext,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: AppColors.white.withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }

  Widget _buildMediaPoster(String? imageUrl, Enum$MediaType type) {
    return (imageUrl != null)
        ? AspectRatio(
            aspectRatio: 21 / 30,
            child: CachedNetworkImage(
              cacheManager: ImageCacheManager.instance,
              imageUrl: imageUrl,
              fit: BoxFit.fill,
              imageBuilder: (context, imageProvider) {
                return ClipRRect(
                  borderRadius: (type == Enum$MediaType.ANIME)
                      ? BorderRadius.circular(12)
                      : BorderRadius.circular(5),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.fill,
                  ),
                );
              },
              placeholder: (context, url) {
                return _buildPlaceholderImage210x310(type);
              },
            ),
          )
        : _buildPlaceholderImage210x310(type);
  }

  Widget _buildPlaceholderImage210x310(Enum$MediaType type) {
    return ClipRRect(
      borderRadius: (type == Enum$MediaType.ANIME)
          ? BorderRadius.circular(15)
          : BorderRadius.circular(5),
      child: const PosterPlaceholder(size: 100),
    );
  }
}
