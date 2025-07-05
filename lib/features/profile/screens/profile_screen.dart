import 'dart:developer';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/profile/profile/profile_bloc.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/appbars/simple_app_bar.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/features/profile/widgets/keep_alive_tab.dart';
import 'package:otaku_world/features/profile/widgets/profile_app_bar.dart';
import 'package:otaku_world/features/profile/widgets/stats/user_stats.dart';
import 'package:otaku_world/features/profile/widgets/user_favorites.dart';
import 'package:otaku_world/features/profile/widgets/user_overview.dart';
import 'package:otaku_world/features/profile/widgets/user_reviews.dart';
import 'package:otaku_world/features/profile/widgets/user_social.dart';
import 'package:otaku_world/theme/colors.dart';

class ProfileScreen extends HookWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    log('Building profile screen');
    final tabController = useTabController(initialLength: 5);
    final profileBloc = context.read<ProfileBloc>();
    final client = context.read<GraphqlClientCubit>().getClient();
    final scrollViewKey = GlobalKey<ExtendedNestedScrollViewState>();

    return Scaffold(
      body: BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (previous, current) {
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          if (state is ProfileInitial) {
            if (client == null) {
              return _buildErrorScaffold(
                message: ActivityConstants.clientError,
                onPressed: () {
                  profileBloc.add(LoadProfile(client!));
                },
              );
            }
            profileBloc.add(LoadProfile(client));
            return _buildLoadingScaffold();
          } else if (state is ProfileLoading) {
            return _buildLoadingScaffold();
          } else if (state is ProfileLoaded) {
            return RefreshIndicator(
              backgroundColor: AppColors.raisinBlack,
              displacement: 60,
              onRefresh: () {
                return Future.delayed(const Duration(seconds: 1), () {
                  context.read<ProfileBloc>().add(LoadProfile(client!));
                });
              },
              notificationPredicate: (notification) {
                return notification.depth == 2;
              },
              child: ExtendedNestedScrollView(
                key: scrollViewKey,
                onlyOneScrollInBody: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  ProfileAppBar(
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
                        isMyProfile: false,
                      ),
                    ),
                    KeepAliveTab(
                      child: UserReviews(
                        userId: state.user.id,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is ProfileError) {
            return _buildErrorScaffold(
              message: state.message,
              onPressed: () {
                profileBloc.add(LoadProfile(client!));
              },
            );
          } else {
            return _buildErrorScaffold(
              message: StringConstants.somethingWentWrongError,
              onPressed: () {
                profileBloc.add(LoadProfile(client!));
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return const Scaffold(
      appBar: SimpleAppBar(title: 'Profile'),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold({
    required String message,
    required VoidCallback onPressed,
  }) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Profile'),
      body: Center(
        child: ErrorText(
          message: message,
          onTryAgain: onPressed,
        ),
      ),
    );
  }
}
