import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/appbars/simple_app_bar.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../bloc/viewer/viewer_bloc.dart';
import '../../../core/ui/buttons/primary_button.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../generated/assets.dart';
import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import '../../../utils/ui_utils.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool isModified = false;
  Fragment$Settings user = Fragment$Settings(id: 0, name: '');

  @override
  Widget build(BuildContext context) {
    final client = context.read<GraphqlClientCubit>().getClient()!;

    return Scaffold(
      appBar: const SimpleAppBar(
        title: 'Notifications Settings',
      ),
      floatingActionButton: isModified
          ? PrimaryButton(
              onTap: () {
                context.read<ViewerBloc>().add(
                      UpdateUser(client: client, user: user),
                    );
              },
              label: 'Save',
              height: 50,
              verticalPadding: 10,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: BlocConsumer<ViewerBloc, ViewerState>(
        listenWhen: (previous, current) =>
            previous is ViewerLoaded &&
            current is ViewerLoaded &&
            previous.showProcess != current.showProcess,
        listener: (context, state) {
          if (state is ViewerLoaded) {
            if (state.showProcess) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const PopScope(
                  canPop: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (state.showError) {
              context.pop();
              UIUtils.showSnackBar(context, state.error!);
            } else {
              setState(() {
                isModified = false;
                context.pop();
              });
              UIUtils.showSnackBar(context, 'Settings Updated!');
            }
          }
        },
        builder: (context, state) {
          if (state is ViewerInitial) {
            context.read<ViewerBloc>().add(LoadViewer(client));
          }

          if (state is ViewerInitial || state is ViewerLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ViewerLoaded) {
            user = isModified
                ? user
                : user.copyWith(
                    options: Fragment$Settings$options(
                      notificationOptions:
                          state.user.options?.notificationOptions
                              ?.map(
                                (e) =>
                                    Fragment$Settings$options$notificationOptions(
                                  enabled: e?.enabled,
                                  type: e?.type,
                                ),
                              )
                              .toList(),
                    ),
                  );
            // log('Notification options: ${user.options?.notificationOptions}');

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Activity Subscriptions',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontFamily: 'Poppins-Medium',
                              ),
                    ),
                    const SizedBox(height: 15),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.ACTIVITY_REPLY,
                      text: 'Automatically subscribe me to activity I create',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.ACTIVITY_REPLY,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.ACTIVITY_REPLY_SUBSCRIBED,
                      text: 'Automatically subscribe me to activity I reply to',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.ACTIVITY_REPLY_SUBSCRIBED,
                          value,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Social',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontFamily: 'Poppins-Medium',
                              ),
                    ),
                    const SizedBox(height: 15),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.FOLLOWING,
                      text: 'When someone follows me',
                      onChange: (value) {
                        changeOption(Enum$NotificationType.FOLLOWING, value);
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.ACTIVITY_MESSAGE,
                      text: 'When I receive message',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.ACTIVITY_MESSAGE,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.ACTIVITY_MENTION,
                      text:
                          'When I am @ mentioned in an activity or activity reply',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.ACTIVITY_MENTION,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.ACTIVITY_LIKE,
                      text: 'When someone likes my activity',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.ACTIVITY_LIKE,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.ACTIVITY_REPLY_LIKE,
                      text: 'When someone likes my reply',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.ACTIVITY_REPLY_LIKE,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.THREAD_COMMENT_REPLY,
                      text: 'When someone replies my forum comment',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.THREAD_COMMENT_REPLY,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.THREAD_COMMENT_MENTION,
                      text: 'When I am @ mentioned in a forum comment',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.THREAD_COMMENT_MENTION,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.THREAD_COMMENT_LIKE,
                      text: 'When someone likes my forum comment',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.THREAD_COMMENT_LIKE,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.THREAD_SUBSCRIBED,
                      text:
                          'When someone replies to a forum thread I’m subscribed to',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.THREAD_SUBSCRIBED,
                          value,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      type: Enum$NotificationType.THREAD_LIKE,
                      text: 'When someone likes my forum thread',
                      onChange: (value) {
                        changeOption(
                          Enum$NotificationType.THREAD_LIKE,
                          value,
                        );
                      },
                    ),
                    const SizedBox(height: 55),
                  ],
                ),
              ),
            );
          } else if (state is ViewerError) {
            return _buildErrorWidget(
              message: state.message,
              context: context,
            );
          } else {
            return _buildErrorWidget(
              message: StringConstants.somethingWentWrongError,
              context: context,
            );
          }
        },
      ),
    );
  }

  Widget _buildErrorWidget({
    required String message,
    required BuildContext context,
  }) {
    return Center(
      child: AnimeCharacterPlaceholder(
        asset: Assets.charactersCigaretteGirl,
        height: 300,
        subheading: message,
        onTryAgain: () {
          final bloc = context.read<ViewerBloc>();
          final client = context.read<GraphqlClientCubit>().getClient();
          if (client != null) {
            bloc.add(LoadViewer(client));
          }
        },
        isError: true,
        isScrollable: true,
      ),
    );
  }

  void changeOption(Enum$NotificationType type, bool value) {
    log('Changing to: $value');
    log('Notifications: ${user.options?.notificationOptions?.map((e) => e?.type).toList()}');
    final index = user.options?.notificationOptions?.indexWhere(
          (e) => e?.type == type,
        ) ??
        -1;
    log('Index: $index');
    if (index != -1) {
      var option = user.options?.notificationOptions?[index];
      setState(() {
        if (!isModified) {
          isModified = true;
        }
        user.options?.notificationOptions?[index] = option?.copyWith(
          enabled: value,
        );
        log('Option: ${option?.type} | ${user.options?.notificationOptions?[index]?.enabled}');
      });
    }
  }

  Widget _buildOption(
    BuildContext context, {
    required Enum$NotificationType type,
    required String text,
    required Function(bool) onChange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: user.options?.notificationOptions
                    ?.firstWhere(
                      (e) => e?.type == type,
                    )
                    ?.enabled ??
                false,
            activeColor: AppColors.sunsetOrange,
            inactiveTrackColor: AppColors.htmlGray,
            thumbColor: const WidgetStatePropertyAll(AppColors.white),
            onChanged: onChange,
          ),
        ],
      ),
    );
  }
}
