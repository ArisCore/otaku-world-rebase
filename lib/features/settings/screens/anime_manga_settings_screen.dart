import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/viewer/viewer_bloc.dart';
import 'package:otaku_world/constants/settings_constants.dart';
import 'package:otaku_world/core/ui/appbars/simple_app_bar.dart';
import 'package:otaku_world/core/ui/filters/custom_check_box.dart';
import 'package:otaku_world/core/ui/filters/custom_dropdown.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/utils/ui_utils.dart';

import '../../../constants/string_constants.dart';
import '../../../core/ui/buttons/primary_button.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../generated/assets.dart';

class AnimeMangaSettingsScreen extends StatefulWidget {
  const AnimeMangaSettingsScreen({super.key});

  @override
  State<AnimeMangaSettingsScreen> createState() =>
      _AnimeMangaSettingsScreenState();
}

class _AnimeMangaSettingsScreenState extends State<AnimeMangaSettingsScreen> {
  bool isModified = false;
  Fragment$Settings user = Fragment$Settings(id: 0, name: '');

  @override
  Widget build(BuildContext context) {
    final client = context.read<GraphqlClientCubit>().getClient()!;
    log('Initial user: ${user.options}');

    return Scaffold(
      appBar: const SimpleAppBar(
        title: 'Anime & Manga Settings',
      ),
      floatingActionButton: isModified
          ? PrimaryButton(
              onTap: () {
                log(
                  'Time to update: ${user.options?.activityMergeTime}',
                  name: 'Time',
                );
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
      floatingActionButtonAnimator: ScalingFabAnimator(),
      body: BlocConsumer<ViewerBloc, ViewerState>(
        listenWhen: (previous, current) =>
            previous is ViewerLoaded &&
            current is ViewerLoaded &&
            previous.showProcess != current.showProcess,
        listener: (context, state) {
          log('Listening to changes: $state');
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
            log('User loaded', name: 'Settings');
            user = isModified
                ? user
                : user.copyWith(
                    id: state.user.id,
                    name: state.user.name,
                    options: Fragment$Settings$options(
                      titleLanguage: state.user.options?.titleLanguage,
                      staffNameLanguage: state.user.options?.staffNameLanguage,
                      activityMergeTime: state.user.options?.activityMergeTime,
                      airingNotifications:
                          state.user.options?.airingNotifications,
                      displayAdultContent:
                          state.user.options?.displayAdultContent,
                    ),
                  );
            // printUser();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdown(
                      title: 'Title Language',
                      dropdownItems: SettingsConstants.titleLanguages,
                      initialValue: SettingsConstants.getTitleLanguageString(
                        user.options?.titleLanguage,
                      ),
                      onChange: (titleLanguage) {
                        user = user.copyWith(
                          options: user.options?.copyWith(
                            titleLanguage: SettingsConstants.getTitleLanguage(
                              titleLanguage,
                            ),
                          ),
                        );
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomDropdown(
                      title: 'Staff & Character Name Language',
                      dropdownItems: SettingsConstants.staffLanguages,
                      initialValue: SettingsConstants.getStaffLanguageString(
                        user.options?.staffNameLanguage,
                      ),
                      onChange: (staffLanguage) {
                        user = user.copyWith(
                          options: user.options?.copyWith(
                            staffNameLanguage:
                                SettingsConstants.getStaffLanguage(
                              staffLanguage,
                            ),
                          ),
                        );
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomDropdown(
                      title: 'Activity Merge Time',
                      description:
                          'Episode and chapter activity created within this '
                          'time period will be merged together (E.g. Watched episodes 10-12)',
                      dropdownItems: SettingsConstants.activityMergeTimes,
                      // initialValue: SettingsConstants.activityMergeTimes[0],
                      initialValue: SettingsConstants.getMergeTimeFromMinutes(
                        user.options?.activityMergeTime,
                      ),
                      onChange: (time) {
                        user = user.copyWith(
                          options: user.options!.copyWith(
                            activityMergeTime:
                                SettingsConstants.getMinutesFromMergeTime(
                              time,
                            ),
                          ),
                        );
                        log('Time: ${user.options?.activityMergeTime}',
                            name: 'Time');
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomCheckBox(
                      label: 'Airing Anime Notification',
                      value: '',
                      onChanged: () {
                        user = user.copyWith(
                          options: user.options?.copyWith(
                            airingNotifications:
                                !(user.options?.airingNotifications ?? false),
                          ),
                        );
                        update();
                      },
                      initialValue: user.options?.airingNotifications ?? false,
                    ),
                    CustomCheckBox(
                      label: '18+ Content',
                      value: '',
                      onChanged: () {
                        user = user.copyWith(
                          options: user.options?.copyWith(
                            displayAdultContent:
                                !(user.options?.displayAdultContent ?? false),
                          ),
                        );
                        update();
                      },
                      initialValue: user.options?.displayAdultContent ?? false,
                    ),
                  ],
                ),
              ),
            );
          } else if (state is ViewerError) {
            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersChillBoy,
                height: 300,
                subheading: state.message,
                onTryAgain: () {
                  context.read<ViewerBloc>().add(LoadViewer(client));
                },
                isError: true,
                isScrollable: true,
              ),
            );
          } else {
            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersNoInternet,
                height: 300,
                subheading: StringConstants.somethingWentWrongError,
                onTryAgain: () {
                  context.read<ViewerBloc>().add(LoadViewer(client));
                },
                isError: true,
                isScrollable: true,
              ),
            );
          }
        },
      ),
    );
  }

  void update() {
    if (!isModified) {
      setState(() {
        isModified = true;
      });
    }
    log(
      'Title: ${user.options?.titleLanguage} | Staff: ${user.options?.staffNameLanguage} | \n'
      'Time: ${user.options?.activityMergeTime} | Notification: ${user.options?.airingNotifications} | Adult: ${user.options?.displayAdultContent}',
    );
  }
}

class ScalingFabAnimator extends FloatingActionButtonAnimator {
  @override
  Offset getOffset({
    required Offset? begin,
    required Offset? end,
    required double progress,
  }) {
    return Offset.lerp(begin, end, progress)!;
  }

  @override
  Animation<double> getScaleAnimation({Animation<double>? parent}) {
    return parent!;
  }

  @override
  Animation<double> getRotationAnimation({required Animation<double> parent}) {
    return const AlwaysStoppedAnimation(0);
  }
}
