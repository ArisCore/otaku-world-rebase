import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/core/ui/appbars/simple_app_bar.dart';
import 'package:otaku_world/core/ui/appbars/simple_sliver_app_bar.dart';
import 'package:otaku_world/core/ui/shimmers/reviews_shimmer_list.dart';
import 'package:otaku_world/features/reviews/widgets/review_bottom_sheet.dart';
import 'package:otaku_world/features/reviews/widgets/review_card.dart';

import '../../../bloc/reviews/reviews/reviews_bloc.dart';
import '../../../core/ui/media_section/scroll_to_top_button.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../generated/assets.dart';
import '../../../theme/colors.dart';
import '../../../utils/navigation_helper.dart';

class ReviewScreen extends HookWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    dev.log('Rebuilding Some screen', name: 'ReviewScreen');
    final reviewsScrollController = useScrollController();
    final reviewBloc = context.read<ReviewsBloc>();
    useEffect(() {
      reviewsScrollController.addListener(() {
        final maxScroll = reviewsScrollController.position.maxScrollExtent;
        final currentScroll = reviewsScrollController.position.pixels;

        if (currentScroll == maxScroll) {
          dev.log('Max scrolled', name: 'Reviews Screen');

          final reviewBloc = context.read<ReviewsBloc>();

          final hasNextPage =
              (reviewBloc.state as PaginatedDataLoaded).hasNextPage;
          if (hasNextPage) {
            final client = (context
                .read<GraphqlClientCubit>()
                .state
            as GraphqlClientInitialized)
                .client;
            reviewBloc.add(LoadData(client));
          }
        }
      });
      return null;
    });

    return BlocBuilder<ReviewsBloc, PaginatedDataState>(
      buildWhen: (previous, current) => true,
      builder: (context, state) {
        dev.log('Rebuilding review list');
        if (state is PaginatedDataInitial) {
          final client = (context
              .read<GraphqlClientCubit>()
              .state
          as GraphqlClientInitialized)
              .client;
          reviewBloc.add(LoadData(client));
          return _buildLoadingScaffold();
        } else if (state is PaginatedDataLoading) {
          return _buildLoadingScaffold();
        } else if (state is PaginatedDataLoaded) {
          return Scaffold(
            floatingActionButton: ScrollToTopFAB(
              controller: reviewsScrollController,
              tag: 'review_fab',
            ),
            body: RefreshIndicator(
              backgroundColor: AppColors.raisinBlack,
              onRefresh: () => _refreshPage(context),
              child: CustomScrollView(
                clipBehavior: Clip.none,
                controller: reviewsScrollController,
                slivers: [
                  SimpleSliverAppBar(
                    title: 'Reviews',
                    floating: true,
                    isPinned: false,
                    actions: [
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            backgroundColor: AppColors.darkCharcoal,
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return ReviewBottomSheet(
                                reviewsBloc: reviewBloc,
                              );
                            },
                          );
                        },
                        icon: SvgPicture.asset(
                          Assets.iconsFilterVertical,
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(10.0),
                    sliver: SliverList.builder(
                      itemBuilder: (context, index) {
                        final review = state.list[index]!;
                        return ReviewCard(
                          review: review,
                          onPressed: () =>
                              NavigationHelper.goToReviewDetailScreen(
                                context: context,
                                reviewId: review.id,
                                bloc: context.read<ReviewsBloc>(),
                              ),
                        );
                      },
                      itemCount: state.list.length,
                    ),
                  ),
                  if (state.hasNextPage)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        return _buildErrorScaffold(context);
      },
    );
  }

  Future<void> _refreshPage(BuildContext context) async {
    final client =
        (context
            .read<GraphqlClientCubit>()
            .state as GraphqlClientInitialized)
            .client;
    context.read<ReviewsBloc>().add(RefreshData(client));
  }

  Widget _buildErrorScaffold(BuildContext context) {
    return Scaffold(
      appBar: const SimpleAppBar(
        title: 'Reviews',
      ),
      body: AnimeCharacterPlaceholder(
        asset: Assets.charactersCigaretteGirl,
        height: 300,
        heading: 'Something went wrong!',
        subheading: 'Please check your internet connection or try again later.',
        onTryAgain: () {
          _refreshPage(context);
        },
        isError: true,
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      appBar: SimpleAppBar(title: 'Reviews'),
      body: ReviewsShimmerList(),
    );
  }
}
