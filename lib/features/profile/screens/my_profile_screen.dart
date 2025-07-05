import 'dart:developer';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/profile/my_profile/my_profile_bloc.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/appbars/simple_app_bar.dart';
import 'package:otaku_world/features/profile/widgets/keep_alive_tab.dart';
import 'package:otaku_world/features/profile/widgets/my_profile_app_bar.dart';
import 'package:otaku_world/features/profile/widgets/stats/user_stats.dart';
import 'package:otaku_world/features/profile/widgets/user_favorites.dart';
import 'package:otaku_world/features/profile/widgets/user_overview.dart';
import 'package:otaku_world/features/profile/widgets/user_reviews.dart';
import 'package:otaku_world/features/profile/widgets/user_social.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../generated/assets.dart';

class MyProfileScreen extends HookWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    log('Building profile screen');
    final tabController = useTabController(initialLength: 5);
    final profileBloc = context.read<MyProfileBloc>();
    final client = context.read<GraphqlClientCubit>().getClient();
    final scrollViewKey = GlobalKey<ExtendedNestedScrollViewState>();

    return Scaffold(
      body: BlocBuilder<MyProfileBloc, MyProfileState>(
        buildWhen: (previous, current) {
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          if (state is MyProfileInitial) {
            if (client == null) {
              return _buildErrorScaffold(
                message: ActivityConstants.clientError,
                context: context,
              );
            }
            profileBloc.add(LoadProfile(client));
            return _buildLoadingScaffold();
          } else if (state is MyProfileLoading) {
            return _buildLoadingScaffold();
          } else if (state is MyProfileLoaded) {
            return RefreshIndicator(
              backgroundColor: AppColors.raisinBlack,
              displacement: 60,
              onRefresh: () {
                return Future.delayed(
                  const Duration(seconds: 1),
                  () {
                    if (context.mounted) {
                      profileBloc.add(LoadProfile(client!));
                    }
                  },
                );
              },
              notificationPredicate: (notification) {
                return notification.depth == 2;
              },
              child: ExtendedNestedScrollView(
                key: scrollViewKey,
                onlyOneScrollInBody: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  MyProfileAppBar(
                    key: const PageStorageKey('profile_app_bar'),
                    user: state.user,
                    tabController: tabController,
                  ),
                ],
                pinnedHeaderSliverHeightBuilder: () {
                  return 130;
                },
                body: TabBarView(
                  controller: tabController,
                  children: [
                    KeepAliveTab(
                      child: UserOverview(
                        user: state.user,
                        followingCount: state.followingCount,
                        followerCount: state.followerCount,
                      ),
                    ),
                    KeepAliveTab(
                      child: UserFavorites(
                        userId: state.user.id,
                      ),
                    ),
                    KeepAliveTab(
                      child: UserStats(
                        userId: state.user.id,
                        scrollKey: scrollViewKey,
                      ),
                    ),
                    KeepAliveTab(
                      child: UserSocial(
                        userId: state.user.id,
                        scrollKey: scrollViewKey,
                        isMyProfile: true,
                      ),
                    ),
                    KeepAliveTab(
                      child: UserReviews(
                        userId: state.user.id,
                        isMyProfile: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is MyProfileError) {
            return _buildErrorScaffold(
              message: state.message,
              context: context,
            );
          } else {
            return _buildErrorScaffold(
              message: StringConstants.somethingWentWrongError,
              context: context,
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      appBar: SimpleAppBar(title: 'My Profile'),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold({
    required String message,
    required BuildContext context,
  }) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'My Profile'),
      body: Center(
        child: AnimeCharacterPlaceholder(
          asset: Assets.charactersErenYeager,
          height: 300,
          subheading: message,
          onTryAgain: () {
            final profileBloc = context.read<MyProfileBloc>();
            final client = context.read<GraphqlClientCubit>().getClient();
            if (client != null) {
              profileBloc.add(LoadProfile(client));
            }
          },
          isError: true,
          isScrollable: true,
        ),
      ),
    );
  }
}
