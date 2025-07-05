import 'dart:developer';

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/profile/user_social_bloc/user_social_bloc.dart';
import 'package:otaku_world/bloc/viewer/viewer_bloc.dart';
import 'package:otaku_world/constants/filter_constants.dart';
import 'package:otaku_world/core/ui/bottomsheet/helpers/url_helpers.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/core/ui/filters/custom_dropdown.dart';
import 'package:otaku_world/core/ui/placeholders/anime_character_placeholder.dart';
import 'package:otaku_world/features/profile/widgets/shimmers/social_shimmer.dart';
import 'package:otaku_world/features/profile/widgets/user_card.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/string_constants.dart';
import '../../../core/ui/dialogs/alert_dialog.dart';
import '../../../theme/colors.dart';
import '../../../utils/ui_utils.dart';
import '../../reviews/widgets/bottom_sheet_component.dart';

class UserSocial extends StatelessWidget {
  const UserSocial({
    super.key,
    required this.userId,
    required this.isMyProfile,
    this.scrollKey,
  });

  final int userId;
  final bool isMyProfile;
  final GlobalKey<ExtendedNestedScrollViewState>? scrollKey;

  @override
  Widget build(BuildContext context) {
    log('Scroll view key: $scrollKey');
    final client = context.read<GraphqlClientCubit>().getClient();

    return BlocProvider(
      create: (context) =>
          UserSocialBloc(userId: userId, isMyProfile: isMyProfile)
            ..add(
              LoadSocialData(client!),
            ),
      child: BlocListener<UserSocialBloc, UserSocialState>(
        listenWhen: (previous, current) =>
            current is UserSocialLoaded &&
            previous is UserSocialLoaded &&
            previous.showProgress != current.showProgress,
        listener: (context, state) {
          if (state is UserSocialLoaded) {
            if (state.showProgress) {
              showDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: true,
                builder: (context) {
                  return PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) {
                        return;
                      }
                    },
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              );
            } else {
              context.pop();
              if (state.error != null) {
                UIUtils.showSnackBar(context, state.error!);
              }
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _OptionDropdownDelegate(
                  Builder(builder: (context) {
                    return CustomDropdown(
                      dropdownItems: FilterConstants.socialOptions,
                      initialValue: FilterConstants.socialOptions[0],
                      onChange: (option) {
                        context.read<UserSocialBloc>().add(
                              ChangeType(
                                isFollowing:
                                    option == 'Following' ? true : false,
                              ),
                            );
                        if (scrollKey?.currentState != null) {
                          final position = scrollKey!
                              .currentState!.innerController.positions.first;
                          log('Position: $position');
                          if (position.viewportDimension > 680) {
                            scrollKey?.currentState?.innerController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.ease,
                            );
                          }
                        }
                      },
                    );
                  }),
                ),
              ),
              BlocBuilder<UserSocialBloc, UserSocialState>(
                buildWhen: (previous, current) => true,
                builder: (context, state) {
                  if (state is UserSocialLoading) {
                    return const SocialShimmer();
                  } else if (state is UserSocialLoaded) {
                    log('Loaded state: $state', name: 'UserSocialBloc');
                    final list =
                        state.isFollowing ? state.followings : state.followers;

                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AnimeCharacterPlaceholder(
                            asset: state.isFollowing
                                ? Assets.charactersCigaretteGirl
                                : Assets.charactersErenYeager,
                            height: 150,
                            heading: state.isFollowing
                                ? 'Not Following Anyone'
                                : 'No Followers Yet',
                            subheading: state.isFollowing
                                ? 'Follow people to see their profiles here.'
                                : isMyProfile
                                    ? 'Looks like no one is following you right now.'
                                    : 'This user doesn’t have any followers right now. Be the first to follow them!',
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == list.length - 5) {
                            context.read<UserSocialBloc>().add(
                                  LoadMoreData(
                                    client: client!,
                                    isFollowing: state.isFollowing,
                                  ),
                                );
                          }
                          final user = list[index];
                          if (user == null) return const SizedBox();
                          return UserCard(
                            user: user,
                            onMorePressed: () {
                              _showOptions(context, user);
                            },
                          );
                        },
                        childCount: list.length,
                      ),
                    );
                  } else if (state is UserSocialError) {
                    return SliverToBoxAdapter(
                      child: ErrorText(
                        message: state.message,
                        onTryAgain: () {},
                      ),
                    );
                  } else if (state is UserSocialError) {
                    return SliverToBoxAdapter(
                      child: ErrorText(
                        message: state.message,
                        onTryAgain: () {
                          if (client != null) {
                            context.read<UserSocialBloc>().add(
                                  LoadSocialData(client),
                                );
                          }
                        },
                      ),
                    );
                  } else {
                    return SliverToBoxAdapter(
                      child: ErrorText(
                        message: StringConstants.somethingWentWrongError,
                        onTryAgain: () {
                          if (client != null) {
                            context.read<UserSocialBloc>().add(
                                  LoadSocialData(client),
                                );
                          }
                        },
                      ),
                    );
                  }
                },
              ),
              BlocBuilder<UserSocialBloc, UserSocialState>(
                builder: (context, state) {
                  if (state is UserSocialLoaded) {
                    if (state.isFollowing && state.hasNextPageFollowing) {
                      return _buildLoader();
                    } else if (!state.isFollowing &&
                        state.hasNextPageFollowers) {
                      return _buildLoader();
                    } else {
                      return const SliverToBoxAdapter();
                    }
                  } else {
                    return const SliverToBoxAdapter();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const SliverToBoxAdapter(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showOptions(BuildContext context, Fragment$User user) {
    List<BottomSheetComponent> options = [];
    final isCurrentUser =
        (context.read<ViewerBloc>().state as ViewerLoaded).user.id == user.id;

    if (!(user.isFollowing ?? false) && !isCurrentUser) {
      options.add(
        BottomSheetComponent(
          iconName: Assets.iconsFollow,
          text: 'Follow',
          onTap: () => _followUser(context, user.id),
        ),
      );
    } else if (!isCurrentUser) {
      options.add(
        BottomSheetComponent(
          iconName: Assets.iconsUnfollow,
          text: 'Unfollow',
          onTap: () => _unfollowUser(context, user.id),
        ),
      );
    }

    options.add(
      BottomSheetComponent(
        iconName: Assets.iconsShare,
        text: 'Share Profile',
        onTap: () => _shareProfile(context, user.id),
      ),
    );
    options.add(
      BottomSheetComponent(
        iconName: Assets.iconsLinkSquare,
        text: 'View on AniList',
        onTap: () => _viewOnAniList(context, user.name),
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCharcoal,
      isScrollControlled: true,
      useRootNavigator: true,
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
          child: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 20),
                ...options
              ],
            ),
          ),
        );
      },
    );
  }

  void _followUser(BuildContext context, int userId) {
    context.pop();
    context.read<UserSocialBloc>().add(
          FollowUser(
            client: context.read<GraphqlClientCubit>().getClient()!,
            userId: userId,
          ),
        );
  }

  void _unfollowUser(BuildContext context, int userId) {
    context.pop();
    _showUnfollowConfirmation(context, userId);
  }

  void _showUnfollowConfirmation(BuildContext context, int userId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CustomAlertDialog(
          title: 'Unfollow user?',
          body: StringConstants.unfollowConfirmation,
          confirmText: 'Unfollow',
          onConfirm: () {
            dialogContext.pop();
            context.read<UserSocialBloc>().add(
                  UnfollowUser(
                    client: context.read<GraphqlClientCubit>().getClient()!,
                    userId: userId,
                  ),
                );
          },
          onCancel: dialogContext.pop,
        );
      },
    );
  }

  void _shareProfile(BuildContext context, int userId) {
    context.pop();
    final uri = Uri(
      scheme: 'https',
      host: 'otaku-world-8a7f4.firebaseapp.com',
      path: '/profile',
      queryParameters: {
        'id': userId.toString(),
      },
    );
    Share.share('Bhai ni profile check karo: ${uri.toString()}');
  }

  void _viewOnAniList(BuildContext context, String userName) {
    context.pop();
    final Uri reviewUri = Uri(
      scheme: 'https',
      host: 'anilist.co',
      path: 'user/$userName',
    );
    UrlHelpers.launchUri(
      context,
      reviewUri,
    );
  }
}

class _OptionDropdownDelegate extends SliverPersistentHeaderDelegate {
  const _OptionDropdownDelegate(this.child);

  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      color: AppColors.raisinBlack,
      child: child,
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
