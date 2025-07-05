import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/bloc/profile/user_notifications/user_notifications_bloc.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/placeholders/anime_character_placeholder.dart';
import 'package:otaku_world/features/profile/widgets/notifications/notification_card.dart';
import 'package:otaku_world/features/profile/widgets/shimmers/notifications_shimmer.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../constants/filter_constants.dart';
import '../../../core/ui/appbars/simple_app_bar.dart';
import '../../../core/ui/appbars/simple_sliver_app_bar.dart';
import '../../../core/ui/error_text.dart';
import '../../../generated/assets.dart';
import '../../../theme/colors.dart';
import '../../reviews/widgets/bottom_sheet_component.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key, required this.resetCount});

  final VoidCallback resetCount;

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  String filter = 'All';
  bool resetCount = true;

  @override
  Widget build(BuildContext context) {
    final client = context.read<GraphqlClientCubit>().getClient()!;

    return BlocProvider(
      create: (context) => UserNotificationsBloc()
        ..add(
          LoadData(client),
        ),
      child: BlocListener<UserNotificationsBloc, PaginatedDataState>(
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
                return WillPopScope(
                  onWillPop: () async => false,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );
          } else {
            context.pop();
          }
        },
        child: BlocBuilder<UserNotificationsBloc, PaginatedDataState>(
          builder: (context, state) {
            if (state is PaginatedDataLoading ||
                state is PaginatedDataInitial) {
              return _buildLoadingShimmer();
            } else if (state is PaginatedDataLoaded) {
              if (resetCount) {
                widget.resetCount();
                resetCount = false;
              }

              return Scaffold(
                body: RefreshIndicator(
                  backgroundColor: AppColors.raisinBlack,
                  onRefresh: () {
                    return Future.delayed(const Duration(seconds: 2), () {
                      context.read<UserNotificationsBloc>().add(
                            RefreshData(client),
                          );
                    });
                  },
                  child: CustomScrollView(
                    slivers: [
                      SimpleSliverAppBar(
                        floating: true,
                        title: 'Notifications',
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
                      state.list.isEmpty
                          ? const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 50,
                                ),
                                child: AnimeCharacterPlaceholder(
                                  asset: Assets.charactersChillBoy,
                                  heading: 'No Notifications to Show',
                                  subheading:
                                      'New notifications will be displayed here when they arrive.',
                                ),
                              ),
                            )
                          : SliverList.builder(
                              itemCount: state.list.length,
                              itemBuilder: (context, index) {
                                final bloc =
                                    context.read<UserNotificationsBloc>();
                                if (index == state.list.length - 1 &&
                                    state.hasNextPage) {
                                  bloc.add(LoadData(client));
                                }

                                return NotificationCard(
                                  notification: state.list[index],
                                );
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
                onPressed: () {
                  context.read<UserNotificationsBloc>().add(LoadData(client));
                },
              );
            } else {
              return _buildErrorScaffold(
                message: StringConstants.somethingWentWrongError,
                onPressed: () {
                  context.read<UserNotificationsBloc>().add(LoadData(client));
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return const Scaffold(
      appBar: SimpleAppBar(title: 'Notifications'),
      body: NotificationsShimmer(),
    );
  }

  Widget _buildErrorScaffold({
    required String message,
    required VoidCallback onPressed,
  }) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Notifications'),
      body: Center(
        child: ErrorText(
          message: message,
          onTryAgain: onPressed,
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context, GraphQLClient client) {
    const filterOptions = FilterConstants.notificationOptions;
    List<BottomSheetComponent> options = [
      BottomSheetComponent(
        iconName: Assets.iconsNotification,
        text: filterOptions[0],
        isSelected: filter == filterOptions[0],
        onTap: () => _select(context, client, filterOptions[0]),
      ),
      BottomSheetComponent(
        iconName: Assets.iconsCalendar,
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
        iconName: Assets.iconsUserGroup2,
        text: filterOptions[3],
        isSelected: filter == filterOptions[3],
        onTap: () => _select(context, client, filterOptions[3]),
      ),
      BottomSheetComponent(
        iconName: Assets.iconsUserGroup,
        text: filterOptions[4],
        isSelected: filter == filterOptions[4],
        onTap: () => _select(context, client, filterOptions[4]),
      ),
      BottomSheetComponent(
        iconName: Assets.iconsMedia,
        text: filterOptions[5],
        isSelected: filter == filterOptions[5],
        onTap: () => _select(context, client, filterOptions[5]),
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
    context.read<UserNotificationsBloc>().setNotificationType(
          client: client,
          type: option,
        );
  }
}
