import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/filter/filter_manga/filter_manga_bloc.dart';
import 'package:otaku_world/core/ui/filters/custom_check_box.dart';

class MangaCheckBoxOptions extends StatelessWidget {
  const MangaCheckBoxOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FilterMangaBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCheckBox(
          label: 'Hide Manga on My list',
          value: 'hideMyManga',
          initialValue: bloc.appliedFilter.hideMyManga,
          onChanged: () {
            bloc.add(ToggleHideMangaOnList());
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
