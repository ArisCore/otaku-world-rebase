import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/core/ui/images/cover_image.dart';
import 'package:otaku_world/core/ui/list_progress_indicator.dart';
import 'package:otaku_world/core/ui/media_section/scroll_to_left_button.dart';
import 'package:otaku_world/core/ui/shimmers/shimmer_loader_list.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/theme/colors.dart';
import 'package:otaku_world/utils/ui_utils.dart';

import '../../../utils/navigation_helper.dart';

class MediaSection<B extends PaginatedDataBloc> extends HookWidget {
  const MediaSection({
    super.key,
    required this.label,
    this.leftPadding = 15,
    required this.onSliderPressed,
    required this.onMorePressed,
    required this.heroTag,
  });

  final String label;
  final double leftPadding;
  final VoidCallback onSliderPressed;
  final VoidCallback onMorePressed;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    final scrollController = useScrollController();

    useEffect(() {
      scrollController.addListener(() {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;

        if (currentScroll == maxScroll) {
          final bloc = context.read<B>();
          final hasNextPage = (bloc.state as PaginatedDataLoaded).hasNextPage;
          if (hasNextPage) {
            final client = (context.read<GraphqlClientCubit>().state
                    as GraphqlClientInitialized)
                .client;
            bloc.add(LoadData(client));
          }
        }
      });
      return null;
    }, const []);

    return BlocBuilder<B, PaginatedDataState>(
      builder: (context, state) {
        if (state is PaginatedDataInitial) {
          final client = context.read<GraphqlClientCubit>().getClient()!;
          context.read<B>().add(LoadData(client));
          return _buildLoadingShimmer(context);
        } else if (state is PaginatedDataLoading) {
          return _buildLoadingShimmer(context);
        } else if (state is PaginatedDataLoaded) {
          // return _buildLoadingShimmer(context);
          if (state.list.isEmpty) return const SizedBox();
          return Padding(
            padding: EdgeInsets.only(
              left: leftPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Text(
                        label,
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontFamily: 'Roboto-Condensed',
                                ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: onSliderPressed,
                          icon: Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              // bottom: 10,
                            ),
                            child: SvgPicture.asset(Assets.iconsViewSlider),
                          ),
                        ),
                        IconButton(
                          onPressed: onMorePressed,
                          icon: Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                            ),
                            child: SvgPicture.asset(Assets.iconsArrowRight),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Media list
                _buildMediaList(
                  state.list as List<Fragment$MediaShort?>,
                  state.hasNextPage,
                  scrollController,
                ),
              ],
            ),
          );
        } else if (state is PaginatedDataError) {
          return ErrorText(
            message: state.message,
            onTryAgain: () {
              final client = context.read<GraphqlClientCubit>().getClient()!;
              context.read<B>().add(LoadData(client));
            },
          );
        } else {
          return ErrorText(
            message: StringConstants.somethingWentWrongError,
            onTryAgain: () {
              final client = context.read<GraphqlClientCubit>().getClient()!;
              context.read<B>().add(LoadData(client));
            },
          );
        }
      },
    );
  }

  // return _buildMediaList(
  // state.list as List<Fragment$MediaShort?>,
  // state.hasNextPage,
  // scrollController,
  // );

  Widget _buildLoadingShimmer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'Roboto-Condensed',
                      ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        // bottom: 10,
                      ),
                      child: SvgPicture.asset(Assets.iconsViewSlider),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                      ),
                      child: SvgPicture.asset(Assets.iconsArrowRight),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Media list
          ShimmerLoaderList(
            widgetWidth: UIUtils.getWidgetWidth(
              targetWidgetWidth: 115,
              screenWidth: screenWidth,
            ),
            widgetHeight: UIUtils.getWidgetHeight(
              targetWidgetHeight: 169,
              screenHeight: screenHeight,
            ),
            height: UIUtils.getWidgetHeight(
              targetWidgetHeight: 169,
              screenHeight: screenHeight,
            ),
            widgetBorder: 10,
            direction: Axis.horizontal,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaList(
    List<Fragment$MediaShort?> mediaList,
    bool hasNextPage,
    ScrollController controller,
  ) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          CustomScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            controller: controller,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildMediaCard(context, mediaList[index]),
                  childCount: mediaList.length,
                ),
              ),
              if (hasNextPage)
                const SliverToBoxAdapter(
                  child: ListProgressIndicator(),
                ),
            ],
          ),
          ScrollToLeftFAB(controller: controller, tag: heroTag),
        ],
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, Fragment$MediaShort? media) {
    if (media == null) return const SizedBox();

    return GestureDetector(
      onTap: () => NavigationHelper.goToMediaDetailScreen(
        context: context,
        mediaId: media.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(
          right: 15,
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
                    // placeHolderName: Assets.placeholders115x170,
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
        color: AppColors.raisinBlack.withValues(alpha: 0.6),
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
