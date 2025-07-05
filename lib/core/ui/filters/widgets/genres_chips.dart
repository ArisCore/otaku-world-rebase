import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/filter/collections/genres/genre_cubit.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/core/ui/filters/custom_chips.dart';
import 'package:otaku_world/core/ui/filters/custom_choice_chip.dart';

import '../../../../constants/string_constants.dart';

class GenresChips extends StatelessWidget {
  const GenresChips({
    super.key,
    required this.selectedGenres,
    required this.onSelected,
    required this.onUnselected,
  });

  final List<String> selectedGenres;
  final void Function(String genre) onSelected;
  final void Function(String genre) onUnselected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenreCubit, GenreState>(
      builder: (context, state) {
        final client = (context.read<GraphqlClientCubit>().state
                as GraphqlClientInitialized)
            .client;
        if (state is GenreInitial) {
          context.read<GenreCubit>().loadAnimeGenre(client);
          return const Center(child: CircularProgressIndicator());
        } else if (state is GenreLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GenreLoaded) {
          return CustomChips(
            title: 'Genres',
            chipList: state.genres.map((genre) {
              return genre == null
                  ? const SizedBox()
                  : CustomChoiceChip(
                      label: genre,
                      value: genre,
                      onSelected: onSelected,
                      onUnselected: onUnselected,
                      selected: selectedGenres.contains(genre),
                    );
            }).toList(),
          );
        } else if (state is GenreError) {
          return ErrorText(
            message: state.message,
            onTryAgain: () {
              context.read<GenreCubit>().loadAnimeGenre(client);
            },
          );
        } else {
          return ErrorText(
            message: StringConstants.somethingWentWrongError,
            onTryAgain: () {
              context.read<GenreCubit>().loadAnimeGenre(client);
            },
          );
        }
      },
    );
  }
}
