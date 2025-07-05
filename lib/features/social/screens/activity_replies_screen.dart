import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/media_detail/social/social_bloc.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/bloc/profile/user_activities_bloc/user_activities_bloc.dart';
import 'package:otaku_world/bloc/social/activities/activities_bloc.dart';
import 'package:otaku_world/bloc/social/activity/activity_bloc.dart';
import 'package:otaku_world/bloc/social/activity_replies/activity_replies_bloc.dart';
import 'package:otaku_world/config/router/router_constants.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/activities/activity_reply_card.dart';
import 'package:otaku_world/core/ui/buttons/primary_fab.dart';
import 'package:otaku_world/core/ui/placeholders/anime_character_placeholder.dart';
import 'package:otaku_world/core/ui/shimmers/activity_shimmer_card.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../core/ui/appbars/simple_app_bar.dart';
import '../../../core/ui/appbars/simple_sliver_app_bar.dart';

class ActivityRepliesScreen extends HookWidget {
  const ActivityRepliesScreen({super.key, required this.bloc});

  final Bloc bloc;

  @override
  Widget build(BuildContext context) {
    final client =
        (context.read<GraphqlClientCubit>().state as GraphqlClientInitialized)
            .client;
    final activityRepliesBloc = context.read<ActivityRepliesBloc>();

    final repliesScrollController = useScrollController();

    useEffect(() {
      repliesScrollController.addListener(() {
        final maxScroll = repliesScrollController.position.maxScrollExtent;
        final currentScroll = repliesScrollController.position.pixels;

        if (currentScroll == maxScroll) {
          log('Max scrolled', name: 'Reviews Screen');

          final hasNextPage =
              (activityRepliesBloc.state as PaginatedDataLoaded).hasNextPage;
          if (hasNextPage) {
            final client = (context.read<GraphqlClientCubit>().state
                    as GraphqlClientInitialized)
                .client;
            activityRepliesBloc.add(LoadData(client));
          }
        }
      });
      return null;
    });

    return BlocConsumer<ActivityRepliesBloc, PaginatedDataState>(
      listenWhen: (previous, current) =>
          current is PaginatedDataLoaded &&
          previous is PaginatedDataLoaded &&
          previous.showProgress != current.showProgress,
      listener: (context, state) {
        if (state is PaginatedDataLoaded && state.showProgress) {
          showDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: true,
            builder: (context) {
              return const PopScope(
                canPop: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        } else {
          context.pop();
        }
      },
      builder: (context, state) {
        if (state is PaginatedDataInitial) {
          activityRepliesBloc.add(LoadData(client));
          return _buildLoadingScaffold();
        } else if (state is PaginatedDataLoading) {
          return _buildLoadingScaffold();
        } else if (state is PaginatedDataLoaded) {
          return Scaffold(
            floatingActionButton: PrimaryFAB(
              controller: repliesScrollController,
              onPressed: () {
                context.push(
                  '${RouteConstants.replyActivity}'
                  '?id=${activityRepliesBloc.activityId}',
                  extra: (Fragment$ActivityReply activityReply) {
                    activityRepliesBloc.addReply(activityReply);
                    if (bloc is ActivitiesBloc) {
                      (bloc as ActivitiesBloc).updateReplyCount(
                        activityId: activityReply.activityId ?? 0,
                        increase: true,
                      );
                    } else if (bloc is SocialBloc) {
                      (bloc as SocialBloc).updateReplyCount(
                        activityId: activityReply.activityId ?? 0,
                        increase: true,
                      );
                    } else if (bloc is UserActivitiesBloc) {
                      (bloc as UserActivitiesBloc).updateReplyCount(
                        activityId: activityReply.activityId ?? 0,
                        increase: true,
                      );
                    } else if (bloc is ActivityBloc) {
                      (bloc as ActivityBloc).add(
                        const UpdateReplyCount(
                          increase: true,
                        ),
                      );
                    }
                  },
                );
              },
            ),
            body: RefreshIndicator(
              backgroundColor: AppColors.raisinBlack,
              onRefresh: () => _refreshData(client, activityRepliesBloc),
              child: CustomScrollView(
                clipBehavior: Clip.none,
                controller: repliesScrollController,
                slivers: [
                  const SimpleSliverAppBar(
                    title: 'Replies',
                    floating: true,
                    isPinned: false,
                  ),
                  (state.list.isEmpty)
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 100),
                            child: Center(
                              child: AnimeCharacterPlaceholder(
                                asset: Assets.charactersCigaretteGirl,
                                heading: 'Nothing to Show',
                                subheading:
                                    "Looks like there are no replies yet, Try adding one!",
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final activityReply =
                                  state.list[index] as Fragment$ActivityReply;
                              return ActivityReplyCard(
                                activityReply: activityReply,
                                onDeleted: () {
                                  if (bloc is ActivitiesBloc) {
                                    (bloc as ActivitiesBloc).updateReplyCount(
                                      activityId: activityReply.activityId ?? 0,
                                      increase: false,
                                    );
                                  } else if (bloc is SocialBloc) {
                                    (bloc as SocialBloc).updateReplyCount(
                                      activityId: activityReply.activityId ?? 0,
                                      increase: false,
                                    );
                                  } else if (bloc is UserActivitiesBloc) {
                                    (bloc as UserActivitiesBloc)
                                        .updateReplyCount(
                                      activityId: activityReply.activityId ?? 0,
                                      increase: false,
                                    );
                                  } else if (bloc is ActivityBloc) {
                                    (bloc as ActivityBloc).add(
                                      const UpdateReplyCount(
                                        increase: false,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            childCount: state.list.length,
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
        } else if (state is PaginatedDataError) {
          return _buildErrorScaffold(
            state.message,
            context,
          );
        } else {
          return _buildErrorScaffold(
            StringConstants.somethingWentWrongError,
            context,
          );
        }
      },
    );
  }

  Future<void> _refreshData(
    GraphQLClient client,
    ActivityRepliesBloc bloc,
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    bloc.add(RefreshData(client));
  }

  Widget _buildErrorScaffold(String message, BuildContext context) {
    return Scaffold(
      appBar: const SimpleAppBar(
        title: 'Replies',
      ),
      body: Center(
        child: AnimeCharacterPlaceholder(
          asset: Assets.charactersCigaretteGirl,
          height: 300,
          subheading: message,
          onTryAgain: () {
            final bloc = context.read<ActivityRepliesBloc>();
            final client = context.read<GraphqlClientCubit>().getClient();
            if (client != null) {
              bloc.add(LoadData(client));
            }
          },
          isError: true,
          isScrollable: true,
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Replies'),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return const ActivityShimmerCard();
        },
      ),
    );
  }
}
