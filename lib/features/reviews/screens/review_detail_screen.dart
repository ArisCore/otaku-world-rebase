import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/media_detail/reviews/media_review_bloc.dart';
import 'package:otaku_world/bloc/reviews/review_detail/review_detail_bloc.dart';
import 'package:otaku_world/bloc/reviews/reviews/reviews_bloc.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/core/ui/markdown_v2/markdown.dart';
import 'package:otaku_world/core/ui/shimmers/review_detail_shimmer.dart';
import 'package:otaku_world/features/media_detail/widgets/banner_image.dart';
import 'package:otaku_world/features/reviews/widgets/bottom_sheet_component.dart';
import 'package:otaku_world/features/reviews/widgets/review_by_user.dart';
import 'package:otaku_world/features/reviews/widgets/review_card.dart';
import 'package:otaku_world/features/reviews/widgets/review_profile_photo.dart';
import 'package:otaku_world/features/reviews/widgets/review_rating.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';
import 'package:otaku_world/utils/ui_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../bloc/profile/reviews/user_reviews_bloc.dart';
import '../../../bloc/viewer/viewer_bloc.dart';
import '../../../config/router/router_constants.dart';
import '../../../core/ui/appbars/simple_app_bar.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../graphql/__generated/graphql/reviews/post_review.graphql.dart';
import '../../../theme/colors.dart';
import '../../../utils/formatting_utils.dart';
import '../../../utils/navigation_helper.dart';

class ReviewDetailScreen extends StatefulWidget {
  const ReviewDetailScreen({super.key, this.bloc});

  final Bloc? bloc;

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late int reviewId;

  @override
  Widget build(BuildContext context) {
    final client =
        (context.read<GraphqlClientCubit>().state as GraphqlClientInitialized)
            .client;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _onPopInvoked(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const SimpleAppBar(

          bgColor: AppColors.transparent,
        ),
        body: BlocBuilder<ReviewDetailBloc, ReviewDetailState>(
          builder: (context, state) {
            if (state is ReviewDetailInitial) {
              context
                  .read<ReviewDetailBloc>()
                  .add(LoadReviewDetail(client: client));
              return const ReviewDetailShimmer();
            } else if (state is ReviewDetailLoading) {
              return const ReviewDetailShimmer();
            } else if (state is ReviewDetailLoaded) {
              final review = state.review;
              reviewId = review.id;

              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // cover image
                    Stack(
                      children: [
                        SizedBox(
                          height: UIUtils.getWidgetHeight(
                            targetWidgetHeight: 340,
                            screenHeight: height,
                          ),
                          width: width,
                          child: BannerImage(
                            url:
                            review.media!.coverImage!.extraLarge.toString(),
                            // placeHolderName: Assets.placeholders340x72,
                          ),
                        ),
                        Positioned(
                          bottom: -0.5,
                          child: Container(
                            height: UIUtils.getWidgetHeight(
                              targetWidgetHeight: 340,
                              screenHeight: height,
                            ),
                            width: width,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.raisinBlack,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 10),
                      child: Text(
                        '${_getMediaType(review.mediaType!)} Review',
                        style:
                        Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    _buildTitleSection(
                      width,
                      review,
                      context,
                      review.mediaId,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: buildSummaryText(
                        summary: review.summary.toString(),
                        context: context,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: _buildProfileSection(context, review),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        FormattingUtils.formatUnixTimestamp(review.createdAt)
                            .toString(),
                        style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'Roboto',
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 10),
                      child: Text(
                        "(Last Updated on ${FormattingUtils.formatUnixTimestamp(review.createdAt).toString()})",
                        style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'Roboto',
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15.0,
                        right: 15,
                        bottom: 10,
                      ),
                      // child: MarkdownWidget(data: review.body.toString()),
                      child: MyMarkdownWidgetV2(data: review.body.toString()),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(
                    //     left: 15.0,
                    //     right: 15,
                    //     bottom: 10,
                    //   ),
                    //   child: Text(
                    //     review.body.toString(),
                    //     style: Theme.of(context).textTheme.titleLarge,
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 15,
                        bottom: 30,
                      ),
                      child: ReviewRating(
                        review: review,
                        onRatingUpdated: (userRating) {
                          _updateReview(
                            rating: userRating,
                            id: state.review.id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersErenYeager,
                height: 300,
                heading: 'Something went wrong!',
                subheading:
                'Please check your internet connection or try again later.',
                onTryAgain: () {
                  context
                      .read<ReviewDetailBloc>()
                      .add(LoadReviewDetail(client: client));
                },
                isError: true,
              ),
            );
          },
        ),
      ),
    );
  }

  void _updateReview({
    Enum$ReviewRating? rating,
    required int id,
    bool isDeleted = false,
    Mutation$SaveReview$SaveReview? savedReview,
  }) {
    if (widget.bloc != null) {
      dev.log('Updating rating');
      if (widget.bloc is ReviewsBloc) {
        (widget.bloc as ReviewsBloc).updateReviewRating(
          reviewId: id,
          userRating: rating,
          isDeleted: isDeleted,
          savedReview: savedReview,
        );
      } else if (widget.bloc is MediaReviewBloc) {
        (widget.bloc as MediaReviewBloc).updateReviewRating(
          reviewId: id,
          userRating: rating,
          isDeleted: isDeleted,
          savedReview: savedReview,
        );
      } else if (widget.bloc is UserReviewsBloc) {
        (widget.bloc as UserReviewsBloc).updateReviewRating(
          reviewId: id,
          userRating: rating,
          isDeleted: isDeleted,
          savedReview: savedReview,
        );
      }
    }
  }

  void _onPopInvoked(BuildContext context) {
    dev.log('Pop called!', name: 'ReviewDetail');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  String _getMediaType(Enum$MediaType type) {
    return type == Enum$MediaType.ANIME ? 'Anime' : 'Manga';
  }

  Widget _buildTitleSection(
    double screenWidth,
    Fragment$ReviewDetail review,
    BuildContext context,
    int id,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 15),
          width: UIUtils.getWidgetWidth(
            targetWidgetWidth: 280,
            screenWidth: screenWidth,
          ),
          child: ReviewByUser(
            mediaTitle: review.media!.title!.userPreferred.toString(),
            userName: review.user!.name.toString(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: () {
              showModalBottomSheetCustom(context, id, review.user?.id);
            },
            icon: SvgPicture.asset(Assets.iconsMoreHorizontal),
          ),
        )
      ],
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    Fragment$ReviewDetail review,
  ) {
    return GestureDetector(
      onTap: () => NavigationHelper.goToProfileScreen(
        context: context,
        userId: review.user!.id,
      ),
      child: Row(
        children: [
          ReviewProfilePhoto(
            profilePicUrl: review.user!.avatar!.medium.toString(),
            radius: 25,
          ),
          const SizedBox(
            width: 10,
          ),
          Text(
            review.user!.name.toString(),
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  void showModalBottomSheetCustom(
    BuildContext context,
    int mediaId,
    int? reviewUserId,
  ) {
    final userId = context.read<ViewerBloc>().getNullableUser()?.id;

    showModalBottomSheet(
      backgroundColor: AppColors.darkCharcoal,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.darkCharcoal,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          // height: 180,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  width: 50,
                  decoration: ShapeDecoration(
                    color: AppColors.lightSilver,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                if (userId == reviewUserId) ...[
                  BottomSheetComponent(
                    onTap: () {
                      context.pop();
                      final result = context.push(
                        '${RouteConstants.postReview}?userId=$userId&mediaId=$mediaId',
                      );
                      if (result is bool) {
                        _updateReview(id: reviewId, isDeleted: result as bool);
                      } else if (result is Mutation$SaveReview$SaveReview) {
                        _updateReview(
                          id: reviewId,
                          savedReview: result as Mutation$SaveReview$SaveReview,
                        );
                      }
                    },
                    iconName: Assets.iconsEdit,
                    text: 'Edit this review',
                  ),
                ],
                BottomSheetComponent(
                  onTap: () {
                    context.pop(); //to close the bottom sheet
                    NavigationHelper.goToMediaDetailScreen(
                      context: context,
                      mediaId: mediaId,
                    );
                  },
                  iconName: Assets.iconsOpenLink2,
                  text: 'Open Media Page',
                ),
                BottomSheetComponent(
                  onTap: () async {
                    final Uri reviewUri = Uri(
                      scheme: 'https',
                      host: 'anilist.co',
                      path: 'review/$reviewId',
                    );
                    context.pop();
                    await launchUrl(
                      reviewUri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  iconName: Assets.iconsLinkSquare,
                  text: 'View on AniList',
                ),
                BottomSheetComponent(
                  onTap: () {
                    // TODO: Repair this
                    Share.share(
                      "Check out this anime review: https://otaku-world-8a7f4.firebaseapp.com/"
                      "review-detail?id=$reviewId",
                    );
                    context.pop();
                  },
                  iconName: Assets.iconsShare,
                  text: 'Share',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
