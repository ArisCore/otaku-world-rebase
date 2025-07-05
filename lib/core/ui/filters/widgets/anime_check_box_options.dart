import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/filter/filter_anime/filter_anime_bloc.dart';
import 'package:otaku_world/core/ui/filters/custom_check_box.dart';

class AnimeCheckBoxOptions extends StatelessWidget {
  const AnimeCheckBoxOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FilterAnimeBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCheckBox(
          label: 'Hide Anime on My list',
          value: 'hideMyAnime',
          initialValue: bloc.appliedFilter.hideMyAnime,
          onChanged: () {
            bloc.add(ToggleHideAnimeOnList());
          },
        ),
        CustomCheckBox(
          label: 'Doujin (Not licensed)',
          value: 'doujin',
          initialValue: !bloc.appliedFilter.isLicensed,
          onChanged: () {
            bloc.add(ToggleDoujin());
          },
        ),
        CustomCheckBox(
          label: 'Adult',
          value: 'adult',
          initialValue: bloc.appliedFilter.isAdult,
          onChanged: () {
            bloc.add(ToggleAdult());
          },
        ),
      ],
    );
  }
}
