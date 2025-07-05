import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/filter/collections/tags/media_tags_cubit.dart';
import 'package:otaku_world/core/ui/filters/custom_slider.dart';
import 'package:otaku_world/utils/ui_utils.dart';

import '../../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../../constants/string_constants.dart';
import '../../../../theme/colors.dart';
import '../../error_text.dart';
import '../custom_chips.dart';
import '../custom_choice_chip.dart';

class MediaTagsChips extends StatelessWidget {
  const MediaTagsChips({
    super.key,
    required this.selectedTags,
    required this.minTagRank,
    required this.onTagRankSet,
    required this.onTagSelected,
    required this.onTagUnselected,
  });

  final List<String> selectedTags;
  final int? minTagRank;
  final void Function(double value) onTagRankSet;
  final void Function(String tag) onTagSelected;
  final void Function(String tag) onTagUnselected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
            ),
            const SizedBox(width: 10),
            const Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: 'Press and hold on tags for information',
              showDuration: Duration(seconds: 5),
              child: Icon(
                Icons.info,
                color: AppColors.white,
                size: 25,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomSlider(
          title: 'Minimum Tag Percentage',
          titleStyle: Theme.of(context).textTheme.displayMedium,
          initialValue: minTagRank,
          minRange: 0,
          maxRange: 100,
          onChangeEnd: onTagRankSet,
        ),
        const SizedBox(height: 20),
        BlocBuilder<MediaTagsCubit, MediaTagsState>(
          builder: (context, state) {
            final client = (context.read<GraphqlClientCubit>().state
                    as GraphqlClientInitialized)
                .client;
            if (state is MediaTagsInitial) {
              context.read<MediaTagsCubit>().loadMediaTags(client);
              return const CircularProgressIndicator();
            } else if (state is MediaTagsLoading) {
              return const CircularProgressIndicator();
            } else if (state is MediaTagsLoaded) {
              final tagsMap = state.mediaTags.entries.toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tagsMap.length,
                itemBuilder: (context, index) {
                  final title = tagsMap[index].key.replaceAll('-', ' / ');
                  final tags = tagsMap[index].value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                    ),
                    child: CustomChips(
                      title: title,
                      titleStyle:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                      chipList: tags.map((tag) {
                        return GestureDetector(
                          onLongPress: () => UIUtils.showInfoDialog(
                            context,
                            tag.name,
                            tag.description ?? 'No description available!',
                          ),
                          child: CustomChoiceChip(
                            label: tag.name,
                            value: tag.name,
                            onSelected: onTagSelected,
                            onUnselected: onTagUnselected,
                            selected: selectedTags.contains(tag.name),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            } else if (state is MediaTagsError) {
              return ErrorText(
                message: state.message,
                onTryAgain: () {
                  context.read<MediaTagsCubit>().loadMediaTags(client);
                },
              );
            } else {
              return ErrorText(
                message: StringConstants.somethingWentWrongError,
                onTryAgain: () {
                  context.read<MediaTagsCubit>().loadMediaTags(client);
                },
              );
            }
          },
        ),
      ],
    );
  }
}
