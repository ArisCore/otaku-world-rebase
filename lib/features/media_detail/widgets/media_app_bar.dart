import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:like_button/like_button.dart';
import 'package:otaku_world/bloc/media_detail/toggle_favorite_media/toggle_favorite_media_cubit.dart';
import 'package:otaku_world/core/ui/bottomsheet/helpers/share_helpers.dart';
import 'package:otaku_world/core/ui/bottomsheet/helpers/url_helpers.dart';
import 'package:otaku_world/core/ui/bottomsheet/option_bottom_sheet.dart';
import 'package:otaku_world/features/media_detail/widgets/status_row.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../core/ui/buttons/back_button.dart';
import '../../../core/ui/image_viewer.dart';
import '../../../core/ui/images/cover_image.dart';
import '../../../core/ui/tabs/custom_tab_bar.dart';
import '../../../generated/assets.dart';
import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import '../../../graphql/__generated/graphql/schema.graphql.dart';
import '../../../theme/colors.dart';
import '../../../utils/ui_utils.dart';
import 'info_col.dart';

class MediaAppBar extends StatefulWidget {
  const MediaAppBar({
    super.key,
    required this.media,
    required this.tabController,
    required this.tabs,
  });

  final Fragment$MediaDetailed media;
  final TabController tabController;
  final List<String> tabs;

  @override
  State<MediaAppBar> createState() => _MediaAppBarState();
}

class _MediaAppBarState extends State<MediaAppBar> {
  bool isLiked = true;

  @override
  void initState() {
    isLiked = widget.media.isFavourite;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final client =
        (context.read<GraphqlClientCubit>().state as GraphqlClientInitialized)
            .client;

    return SliverAppBar(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      pinned: true,
      expandedHeight: UIUtils.getWidgetHeight(
        targetWidgetHeight: 515,
        screenHeight: height,
      ),
      leading: CustomBackButton(
        onPressed: () {
          _onPopInvoked(context);
        },
      ),
      backgroundColor: AppColors.raisinBlack,
      surfaceTintColor: AppColors.raisinBlack,
      actions: [
        LikeButton(
          isLiked: isLiked,
          size: 25,
          likeBuilder: (isLiked) {
            return SvgPicture.asset(
              isLiked ? Assets.iconsFavourite : Assets.iconsLike,
            );
          },
          onTap: (isLiked) async {
            return toggleFavorite(context, client);
          },
        ),
        IconButton(
          onPressed: () {
            final mediaId = widget.media.id;
            OptionsBottomSheet.showOptionBottomSheet(
              context: context,
              onShareTap: () {
                ShareHelpers.mediaShareOptions(widget.media.id);
              },
              onViewOnAniListTap: () {
                final String? url = widget.media.siteUrl;
                if (url != null && url.isNotEmpty) {
                  UrlHelpers.launchUrlLink(
                    context,
                    url,
                  );
                }
              },
              onCopyLinkTap: () {
                final url = UrlHelpers.getMediaLocalUrl(mediaId);
                UrlHelpers.copyUrlToClipboard(context, url);
              },
            );
          },
          icon: SvgPicture.asset(
            Assets.iconsMoreVertical,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: buildPosterContent(
          context,
          widget.media,
          height,
          width,
          widget.tabController,
          widget.tabs,
        ),
      ),
      bottom: CustomTabBar(
        controller: widget.tabController,
        tabs: widget.tabs,
      ),
    );
  }

  Widget buildPosterContent(
    BuildContext context,
    Fragment$MediaDetailed media,
    double height,
    double width,
    TabController tabController,
    List<String> tabs,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: UIUtils.getWidgetHeight(
            targetWidgetHeight: 420,
            screenHeight: height,
          ),
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Container(
                  foregroundDecoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.00, -1.00),
                      end: Alignment(0, 1),
                      colors: [Color(0x001F1F1F), Color(0xFF202020)],
                    ),
                  ),
                  height: UIUtils.getWidgetHeight(
                    targetWidgetHeight: 220,
                    screenHeight: height,
                  ),
                  width: width,
                  child: GestureDetector(
                    onTap: () => media.bannerImage != null
                        ? showImage(
                            context,
                            media.bannerImage.toString(),
                            tag: media.bannerImage.toString(),
                          )
                        : null,
                    child: Hero(
                      tag: media.bannerImage.toString(),
                      child: CoverImage(
                        imageUrl: media.bannerImage.toString(),
                        type: media.type!,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 15,
                right: 10,
                child: SizedBox(
                  width: width - 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: UIUtils.getWidgetHeight(
                          targetWidgetHeight: 292,
                          screenHeight: height,
                        ),
                        width: UIUtils.getWidgetWidth(
                          targetWidgetWidth: 200,
                          screenWidth: width,
                        ),
                        child: GestureDetector(
                          onTap: () => media.coverImage?.extraLarge != null
                              ? showImage(
                                  context,
                                  media.coverImage!.extraLarge!,
                                  tag: media.coverImage!.extraLarge!,
                                )
                              : null,
                          child: Hero(
                            tag: media.coverImage!.extraLarge!,
                            child: CoverImage(
                              imageUrl: media.coverImage!.extraLarge!,
                              type: media.type!,
                              // placeHolderName: Assets.placeholders210x310,
                            ),
                          ),
                        ),
                      ),
                      InfoColumn(
                        averageScore: media.averageScore.toString(),
                        favourites: media.favourites.toString(),
                        popularity: media.popularity.toString(),
                        startDate: media.startDate?.year == null
                            ? ""
                            : media.startDate!.year.toString(),
                        episodes: media.episodes.toString(),
                        duration: media.duration.toString(),
                        format: media.format,
                        mediaType: media.type ?? Enum$MediaType.$unknown,
                        chapters: media.chapters.toString(),
                        volumes: media.volumes.toString(),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 15,
            right: 12,
          ),
          child: Text(
            media.title!.userPreferred.toString(),
            style: const TextStyle(
              overflow: TextOverflow.ellipsis,
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              height: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 15,
            right: 12,
            bottom: 8,
          ),
          child: StatusRow(
            airingSchedule: media.airingSchedule,
            status: media.status,
            fontSize: 14,
            alignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
          ),
        ),
      ],
    );
  }

  Future<bool?> toggleFavorite(
    BuildContext context,
    GraphQLClient client,
  ) async {
    final result = await ToggleFavoriteMediaCubit().toggleFavoriteMedia(
      client,
      mediaId: widget.media.id,
      type: widget.media.type!,
      isLiked: isLiked,
    );
    return result.fold(
      (error) {
        log('Got error: $error', name: 'ActivityLike');
        UIUtils.showSnackBar(context, error);
        return null;
      },
      (isLiked) {
        this.isLiked = isLiked;
        UIUtils.showSnackBar(
          context,
          isLiked ? 'Added to Favourites!' : 'Removed from Favourites!',
        );
        return isLiked;
      },
    );
  }

  void _onPopInvoked(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
