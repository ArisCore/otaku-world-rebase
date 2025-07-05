import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/bloc/media_list/media_list/media_list_bloc.dart';
import 'package:otaku_world/constants/settings_constants.dart';
import 'package:otaku_world/core/ui/appbars/simple_app_bar.dart';
import 'package:otaku_world/core/ui/filters/custom_check_box.dart';
import 'package:otaku_world/core/ui/filters/custom_dropdown.dart';
import 'package:otaku_world/features/settings/widgets/advanced_scoring.dart';
import 'package:otaku_world/features/settings/widgets/custom_lists.dart';
import 'package:otaku_world/features/settings/widgets/list_activity_options.dart';
import 'package:otaku_world/features/settings/widgets/reorder_list.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/user/viewer.graphql.dart';
import 'package:otaku_world/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../bloc/viewer/viewer_bloc.dart';
import '../../../constants/string_constants.dart';
import '../../../core/ui/buttons/primary_button.dart';
import '../../../core/ui/dialogs/alert_dialog.dart';
import '../../../core/ui/error_text.dart';
import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import '../../../utils/ui_utils.dart';

class ListSettings extends StatefulWidget {
  const ListSettings({super.key});

  @override
  State<ListSettings> createState() => _ListSettingsState();
}

class _ListSettingsState extends State<ListSettings> {
  bool isModified = false;
  Fragment$Settings user = Fragment$Settings(id: 0, name: '');

  @override
  Widget build(BuildContext context) {
    final client = context.read<GraphqlClientCubit>().getClient()!;

    return Scaffold(
      // resizeToAvoidBottomInset: true,
      appBar: const SimpleAppBar(
        title: 'List Settings',
      ),
      floatingActionButton: isModified
          ? PrimaryButton(
              onTap: () => _updateSettings(context, client),
              label: 'Save',
              height: 50,
              verticalPadding: 10,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          child: BlocConsumer<ViewerBloc, ViewerState>(
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
                    // context.read<AnimeListBloc>().add(
                    //       UpdateListSettings(
                    //         options: state.user.mediaListOptions,
                    //       ),
                    //     );
                    // context.read<MangaListBloc>().add(
                    //       UpdateListSettings(
                    //         options: state.user.mediaListOptions,
                    //       ),
                    //     );
                    context.read<AnimeListBloc>().add(LoadMediaList(
                          client: client,
                          loadForSettings: true,
                        ));
                    context.read<MangaListBloc>().add(LoadMediaList(
                          client: client,
                          loadForSettings: true,
                        ));
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
                        mediaListOptions: Fragment$MediaListOptions(
                          scoreFormat: state.user.mediaListOptions?.scoreFormat,
                          rowOrder: state.user.mediaListOptions?.rowOrder,
                          animeList: state.user.mediaListOptions?.animeList,
                          mangaList: state.user.mediaListOptions?.mangaList,
                        ),
                        options: Fragment$Settings$options(
                          disabledListActivity:
                              state.user.options?.disabledListActivity,
                        ),
                      );
                log('Custom list: ${user.mediaListOptions?.animeList?.customLists}');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    CustomDropdown(
                      title: 'Scoring System',
                      dropdownItems: SettingsConstants.scoringSystems,
                      initialValue: SettingsConstants.getScoringSystemString(
                        user.mediaListOptions?.scoreFormat,
                      ),
                      onChange: (format) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            scoreFormat: SettingsConstants.getScoringSystem(
                              format,
                            ),
                          ),
                        );
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomDropdown(
                      title: 'Default List Order',
                      dropdownItems: SettingsConstants.listOrders,
                      initialValue: SettingsConstants.getListOrderString(
                        user.mediaListOptions?.rowOrder,
                      ),
                      onChange: (order) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            rowOrder: SettingsConstants.getListOrder(order),
                          ),
                        );
                        log('Row order: ${user.mediaListOptions?.rowOrder}');
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Split Completed List Section by Format',
                      style: Theme.of(context).textTheme.displaySmall!.copyWith(
                            fontFamily: 'Poppins-Medium',
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CustomCheckBox(
                          label: 'Anime List',
                          value: '',
                          onChanged: () {
                            user = user.copyWith(
                              mediaListOptions: user.mediaListOptions?.copyWith(
                                animeList:
                                    user.mediaListOptions?.animeList?.copyWith(
                                  splitCompletedSectionByFormat: !(user
                                          .mediaListOptions
                                          ?.animeList
                                          ?.splitCompletedSectionByFormat ??
                                      false),
                                ),
                              ),
                            );
                            log('Split anime list: ${user.mediaListOptions?.animeList?.splitCompletedSectionByFormat}');
                            update();
                          },
                          initialValue: user.mediaListOptions?.animeList
                                  ?.splitCompletedSectionByFormat ??
                              false,
                        ),
                        const SizedBox(width: 20),
                        CustomCheckBox(
                          label: 'Manga List',
                          value: '',
                          onChanged: () {
                            user = user.copyWith(
                              mediaListOptions: user.mediaListOptions?.copyWith(
                                mangaList:
                                    user.mediaListOptions?.mangaList?.copyWith(
                                  splitCompletedSectionByFormat: !(user
                                          .mediaListOptions
                                          ?.mangaList
                                          ?.splitCompletedSectionByFormat ??
                                      false),
                                ),
                              ),
                            );
                            log('Split manga list: ${user.mediaListOptions?.mangaList?.splitCompletedSectionByFormat}');
                            update();
                          },
                          initialValue: user.mediaListOptions?.mangaList
                                  ?.splitCompletedSectionByFormat ??
                              false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AdvancedScoring(
                      list: user.mediaListOptions?.animeList?.advancedScoring ??
                          [],
                      isEnabled: (user.mediaListOptions?.animeList
                                  ?.advancedScoringEnabled ??
                              false) ||
                          (user.mediaListOptions?.mangaList
                                  ?.advancedScoringEnabled ??
                              false),
                      onChangeEnabled: (value) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            animeList:
                                user.mediaListOptions?.animeList?.copyWith(
                              advancedScoringEnabled: value,
                            ),
                            mangaList:
                                user.mediaListOptions?.mangaList?.copyWith(
                              advancedScoringEnabled: value,
                            ),
                          ),
                        );
                        update();
                        log('Advanced: ${user.mediaListOptions?.animeList?.advancedScoringEnabled}'
                            '| ${user.mediaListOptions?.mangaList?.advancedScoringEnabled}');
                      },
                      onChangeList: (list) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            animeList:
                                user.mediaListOptions?.animeList?.copyWith(
                              advancedScoring: list,
                            ),
                            mangaList:
                                user.mediaListOptions?.mangaList?.copyWith(
                              advancedScoring: list,
                            ),
                          ),
                        );
                        update();
                        log('Advanced: ${user.mediaListOptions?.animeList?.advancedScoring}'
                            '| ${user.mediaListOptions?.mangaList?.advancedScoring}');
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomLists(
                      list: user.mediaListOptions?.animeList?.customLists ?? [],
                      type: Enum$MediaType.ANIME,
                      onChange: (list) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            animeList:
                                user.mediaListOptions?.animeList?.copyWith(
                              customLists: list,
                            ),
                          ),
                        );
                        log('Anime list: ${user.mediaListOptions?.animeList}');
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomLists(
                      list: user.mediaListOptions?.mangaList?.customLists ?? [],
                      type: Enum$MediaType.MANGA,
                      onChange: (list) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            mangaList:
                                user.mediaListOptions?.mangaList?.copyWith(
                              customLists: list,
                            ),
                          ),
                        );
                        log('Manga list: ${user.mediaListOptions?.mangaList}');
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    ListActivityOptions(
                      options: user.options!,
                      onChange: (status) {
                        int? index =
                            user.options?.disabledListActivity?.indexWhere(
                          (e) => e?.type == status,
                        );
                        if (index != null && index != -1) {
                          final activity =
                              user.options?.disabledListActivity?[index];
                          user.options?.disabledListActivity![index] =
                              Query$Viewer$Viewer$options$disabledListActivity(
                            type: activity?.type,
                            disabled: !(activity?.disabled ?? false),
                          );
                          log('Updated activity: ${activity?.type} | ${activity?.disabled}');
                          update();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ReorderList(
                      list:
                          user.mediaListOptions?.animeList?.sectionOrder ?? [],
                      type: Enum$MediaType.ANIME,
                      onChange: (list) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            animeList:
                                user.mediaListOptions?.animeList?.copyWith(
                              sectionOrder: list,
                            ),
                          ),
                        );
                        log('${user.mediaListOptions?.animeList?.sectionOrder}');
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    ReorderList(
                      list:
                          user.mediaListOptions?.mangaList?.sectionOrder ?? [],
                      type: Enum$MediaType.MANGA,
                      onChange: (list) {
                        user = user.copyWith(
                          mediaListOptions: user.mediaListOptions?.copyWith(
                            mangaList:
                                user.mediaListOptions?.mangaList?.copyWith(
                              sectionOrder: list,
                            ),
                          ),
                        );
                        log('${user.mediaListOptions?.mangaList?.sectionOrder}');
                        update();
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildVisitWebsite(),
                    const SizedBox(height: 75),
                  ],
                );
              } else if (state is ViewerError) {
                return ErrorText(
                  message: state.message,
                  onTryAgain: () {
                    context.read<ViewerBloc>().add(LoadViewer(client));
                  },
                );
              } else {
                return ErrorText(
                  message: StringConstants.somethingWentWrongError,
                  onTryAgain: () {
                    context.read<ViewerBloc>().add(LoadViewer(client));
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _updateSettings(BuildContext context, GraphQLClient client) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CustomAlertDialog(
          title: StringConstants.settingsConfirmationHeading,
          body: StringConstants.listSettingsConfirmationWarning,
          confirmText: 'Save',
          onConfirm: () {
            dialogContext.pop();
            context.read<ViewerBloc>().add(
                  UpdateUser(client: client, user: user),
                );
          },
          onCancel: dialogContext.pop,
        );
      },
    );
  }

  void update() {
    if (!isModified) {
      setState(() {
        isModified = true;
      });
    }
  }

  Widget _buildVisitWebsite() {
    return GestureDetector(
      onTap: () {
        final url = Uri(
          scheme: 'https',
          host: 'anilist.co',
          path: '/settings/lists',
        );
        launchUrl(url);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: AppColors.secondaryGradient,
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Visit AniList website to access all settings.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Poppins',
                    ),
              ),
            ),
            const SizedBox(width: 10),
            SvgPicture.asset(Assets.iconsLinkSquare),
          ],
        ),
      ),
    );
  }
}
