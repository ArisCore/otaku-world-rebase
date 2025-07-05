import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/activities/message_activity_card.dart';
import 'package:otaku_world/core/ui/placeholders/anime_character_placeholder.dart';
import 'package:otaku_world/features/social/widgets/activity_shimmer_list.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../bloc/social/activities/activities_bloc.dart';
import '../../../core/ui/activities/list_activity_card.dart';
import '../../../core/ui/activities/text_activity_card.dart';

class ActivitiesList extends StatefulWidget {
  const ActivitiesList({
    super.key,
    required this.isFollowing,
  });

  final bool isFollowing;

  @override
  State<ActivitiesList> createState() => _ActivitiesListState();
}

class _ActivitiesListState extends State<ActivitiesList>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final client =
        (context.read<GraphqlClientCubit>().state as GraphqlClientInitialized)
            .client;
    final activitiesBloc = context.read<ActivitiesBloc>();

    return BlocBuilder<ActivitiesBloc, ActivitiesState>(
      builder: (context, state) {
        if (state is ActivitiesInitial) {
          activitiesBloc.add(LoadActivities(client));
          return const ActivityShimmerList();
        } else if (state is ActivitiesLoading) {
          return const ActivityShimmerList();
        } else if (state is ActivitiesLoaded) {
          final activities = widget.isFollowing
              ? state.followingActivities
              : state.globalActivities;
          return RefreshIndicator(
            backgroundColor: AppColors.raisinBlack,
            onRefresh: () => _refresh(client, activitiesBloc),
            child: activities.isEmpty
                ? const Center(
                    child: AnimeCharacterPlaceholder(
                      asset: Assets.charactersCigaretteGirl,
                      heading: 'Nothing to Show',
                      subheading: 'Looks like there are no activities yet!',
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == activities.length - 1) {
                              log('Loading more activities');
                              activitiesBloc.add(
                                LoadMoreActivities(
                                  client: client,
                                  isFollowing: widget.isFollowing,
                                ),
                              );
                            }

                            final activity = activities[index];
                            if (activity is Fragment$TextActivity) {
                              return TextActivityCard(
                                activity: activity,
                                bloc: activitiesBloc,
                              );
                            } else if (activity is Fragment$ListActivity) {
                              return ListActivityCard(
                                activity: activity,
                                bloc: activitiesBloc,
                              );
                            } else if (activity is Fragment$MessageActivity) {
                              return MessageActivityCard(
                                activity: activity,
                                bloc: activitiesBloc,
                              );
                            } else {
                              return const SizedBox();
                            }
                          },
                          childCount: activities.length,
                        ),
                      ),
                      if (widget.isFollowing && state.hasNextPageFollowing)
                        _buildLoader(),
                      if (!widget.isFollowing && state.hasNextPageGlobal)
                        _buildLoader()
                    ],
                  ),
          );
        } else if (state is ActivitiesError) {
          return Center(
            child: AnimeCharacterPlaceholder(
              asset: Assets.charactersCigaretteGirl,
              heading: 'Nothing to Show',
              subheading: 'Looks like there are no activities yet!',
              isError: true,
              onTryAgain: () => activitiesBloc.add(LoadActivities(client)),
            ),
          );
        } else {
          return Center(
            child: AnimeCharacterPlaceholder(
              asset: Assets.charactersCigaretteGirl,
              heading: 'Nothing to Show',
              subheading: StringConstants.somethingWentWrongError,
              isError: true,
              onTryAgain: () => activitiesBloc.add(LoadActivities(client)),
            ),
          );
        }
      },
    );
  }

  Future<void> _refresh(GraphQLClient client, ActivitiesBloc bloc) async {
    bloc.add(RefreshActivities(client));
  }

  Widget _buildLoader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
