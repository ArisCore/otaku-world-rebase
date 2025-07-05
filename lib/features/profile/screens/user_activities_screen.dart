import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/profile/user_activities_bloc/user_activities_bloc.dart';
import 'package:otaku_world/constants/filter_constants.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/activities/list_activity_card.dart';
import 'package:otaku_world/core/ui/activities/message_activity_card.dart';
import 'package:otaku_world/core/ui/activities/text_activity_card.dart';
import 'package:otaku_world/core/ui/appbars/simple_app_bar.dart';
import 'package:otaku_world/core/ui/appbars/simple_sliver_app_bar.dart';
import 'package:otaku_world/features/reviews/widgets/bottom_sheet_component.dart';
import 'package:otaku_world/features/social/widgets/activity_shimmer_list.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';

import '../../../bloc/paginated_data/paginated_data_bloc.dart';
import '../../../config/router/router_constants.dart';
import '../../../core/ui/buttons/primary_fab.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../theme/colors.dart';

class UserActivitiesScreen extends StatefulWidget {
  const UserActivitiesScreen({
    super.key,
    required this.isCurrentUser,
    required this.userId,
  });

  final int userId;
  final bool isCurrentUser;

  @override
  State<UserActivitiesScreen> createState() => _UserActivitiesScreenState();
}

class _UserActivitiesScreenState extends State<UserActivitiesScreen> {
  String filter = 'All';
  late final ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = context.read<GraphqlClientCubit>().getClient()!;

    return BlocProvider(
      create: (context) => UserActivitiesBloc(userId: widget.userId)
        ..add(
          LoadData(client),
        ),
      child: BlocConsumer<UserActivitiesBloc, PaginatedDataState>(
        listenWhen: (previous, current) =>
            current is PaginatedDataLoaded &&
            previous is PaginatedDataLoaded &&
            previous.showProgress != current.showProgress,
        buildWhen: (previous, current) => true,
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
          if (state is PaginatedDataLoading || state is PaginatedDataInitial) {
            return _buildLoadingShimmer();
          } else if (state is PaginatedDataLoaded) {
            return Scaffold(
              floatingActionButton: PrimaryFAB(
                key: const ValueKey<String>('user_activities_fab'),
                controller: scrollController,
                asset: widget.isCurrentUser
                    ? Assets.iconsEdit
                    : Assets.iconsSendMessage,
                onPressed: () {
                  if (widget.isCurrentUser) {
                    _goToPostActivity(context.read<UserActivitiesBloc>());
                  } else {
                    _goToSendMessage(context.read<UserActivitiesBloc>());
                  }
                },
              ),
              body: RefreshIndicator(
                backgroundColor: AppColors.raisinBlack,
                onRefresh: () {
                  return Future.delayed(
                    const Duration(seconds: 2),
                    () {
                      if (context.mounted) {
                        context
                            .read<UserActivitiesBloc>()
                            .add(RefreshData(client));
                      }
                    },
                  );
                },
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SimpleSliverAppBar(
                      title: 'Activity',
                      floating: true,
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: IconButton(
                            onPressed: () =>
                                _showFilterOptions(context, client),
                            icon: SvgPicture.asset(
                              Assets.iconsFilterVertical,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliverList.builder(
                      itemCount: state.list.length,
                      itemBuilder: (context, index) {
                        final bloc = context.read<UserActivitiesBloc>();
                        if (index == state.list.length - 1 &&
                            state.hasNextPage) {
                          log('Loading more activities');
                          bloc.add(LoadData(client));
                        }

                        final activity = state.list[index];
                        if (activity is Fragment$ListActivity) {
                          return ListActivityCard(
                            activity: activity,
                            isProfile: true,
                            bloc: bloc,
                          );
                        } else if (activity is Fragment$MessageActivity) {
                          return MessageActivityCard(
                            activity: activity,
                            isProfile: true,
                            bloc: bloc,
                          );
                        } else if (activity is Fragment$TextActivity) {
                          return TextActivityCard(
                            activity: activity,
                            isProfile: true,
                            bloc: bloc,
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                    if (state.hasNextPage)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else if (state is PaginatedDataError) {
            return _buildErrorScaffold(
              message: state.message,
            );
          } else {
            return _buildErrorScaffold(
              message: StringConstants.somethingWentWrongError,
            );
          }
        },
      ),
    );
  }

  void _goToPostActivity(UserActivitiesBloc bloc) {
    context.push(
      RouteConstants.postNewActivity,
      extra: (Fragment$TextActivity activity) {
        bloc.addTextActivity(activity: activity);
      },
    );
  }

  void _goToSendMessage(UserActivitiesBloc bloc) {
    context.push(
      '${RouteConstants.sendMessage}?receiver_id=${widget.userId}',
      extra: (Fragment$MessageActivity activity) {
        bloc.addMessageActivity(activity: activity);
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return const Scaffold(
      appBar: SimpleAppBar(title: 'Activity'),
      body: ActivityShimmerList(),
    );
  }

  Widget _buildErrorScaffold({
    required String message,
  }) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Activity'),
      body: Center(
        child: AnimeCharacterPlaceholder(
          asset: Assets.charactersErenYeager,
          height: 300,
          subheading: message,
          onTryAgain: () {
            final bloc = context.read<UserActivitiesBloc>();
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

  void _showFilterOptions(BuildContext context, GraphQLClient client) {
    const filterOptions = FilterConstants.activitiesOptions;
    List<BottomSheetComponent> options = [
      BottomSheetComponent(
        iconName: Assets.iconsActivity,
        text: filterOptions[0],
        isSelected: filter == filterOptions[0],
        onTap: () => _select(context, client, filterOptions[0]),
      ),
      BottomSheetComponent(
        iconName: Assets.iconsStatus,
        text: filterOptions[1],
        isSelected: filter == filterOptions[1],
        onTap: () => _select(context, client, filterOptions[1]),
      ),
      BottomSheetComponent(
        iconName: Assets.iconsMessageBubble,
        text: filterOptions[2],
        isSelected: filter == filterOptions[2],
        onTap: () => _select(context, client, filterOptions[2]),
      ),
      BottomSheetComponent(
        iconName: Assets.iconsList,
        text: filterOptions[3],
        isSelected: filter == filterOptions[3],
        onTap: () => _select(context, client, filterOptions[3]),
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.raisinBlack,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.raisinBlack,
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
                    color: AppColors.darkGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...options,
              ],
            ),
          ),
        );
      },
    );
  }

  void _select(BuildContext context, GraphQLClient client, String option) {
    context.pop();
    if (filter == option) return;
    filter = option;
    context.read<UserActivitiesBloc>().changeType(
          client: client,
          activityType: option,
        );
  }
}
