import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/placeholders/anime_character_placeholder.dart';
import 'package:otaku_world/core/ui/shimmers/reviews_shimmer_list.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/utils/navigation_helper.dart';

import '../../../bloc/profile/reviews/user_reviews_bloc.dart';
import '../../reviews/widgets/review_card.dart';

class UserReviews extends StatelessWidget {
  const UserReviews({
    super.key,
    required this.userId,
    this.isMyProfile = false,
  });

  final int userId;
  final bool isMyProfile;

  @override
  Widget build(BuildContext context) {
    final client = context.read<GraphqlClientCubit>().getClient()!;

    return BlocProvider(
      create: (context) => UserReviewsBloc(userId: userId)
        ..add(
          LoadData(client),
        ),
      child: BlocBuilder<UserReviewsBloc, PaginatedDataState>(
        builder: (context, state) {
          if (state is PaginatedDataLoading || state is PaginatedDataInitial) {
            return const ReviewsShimmerList();
          } else if (state is PaginatedDataLoaded) {
            if (state.list.isEmpty) {
              return Center(
                child: AnimeCharacterPlaceholder(
                  asset: Assets.charactersCigaretteGirl,
                  height: 150,
                  heading: 'No Reviews Yet',
                  subheading: isMyProfile
                      ? 'Share your thoughts by reviewing anime or manga '
                          'you\'ve watched or read.'
                      : 'This user hasn’t posted any reviews. '
                          'Check back later to see if they share their thoughts!',
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7.5,
              ),
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == state.list.length - 3 &&
                            state.hasNextPage) {
                          context.read<UserReviewsBloc>().add(LoadData(client));
                        }
                        final review = state.list[index];
                        return ReviewCard(
                          review: review,
                          onPressed: () =>
                              NavigationHelper.goToReviewDetailScreen(
                            context: context,
                            reviewId: review.id,
                            bloc: context.read<UserReviewsBloc>(),
                          ),
                        );
                      },
                      childCount: state.list.length,
                    ),
                  ),
                  if (state.hasNextPage)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            );
          } else if (state is PaginatedDataError) {
            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersCigaretteGirl,
                height: 150,
                subheading: state.message,
                onTryAgain: () {
                  context.read<UserReviewsBloc>().add(LoadData(client));
                },
              ),
            );
          } else {
            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersCigaretteGirl,
                height: 150,
                subheading: StringConstants.somethingWentWrongError,
                onTryAgain: () {
                  context.read<UserReviewsBloc>().add(LoadData(client));
                },
              ),
            );
          }
        },
      ),
    );
  }
}
