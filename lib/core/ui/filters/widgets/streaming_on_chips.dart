import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/filter/collections/external_links/anime/anime_platforms_cubit.dart';
import 'package:otaku_world/bloc/filter/filter_anime/filter_anime_bloc.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/core/ui/filters/custom_chips.dart';
import 'package:otaku_world/core/ui/filters/custom_choice_chip.dart';

import '../../../../constants/string_constants.dart';

class AnimePlatformsChips extends StatelessWidget {
  const AnimePlatformsChips({super.key, required this.selectedPlatforms});

  final List<String> selectedPlatforms;

  @override
  Widget build(BuildContext context) {
    final client =
        (context.read<GraphqlClientCubit>().state as GraphqlClientInitialized)
            .client;
    final bloc = context.read<FilterAnimeBloc>();
    return BlocBuilder<AnimePlatformsCubit, AnimePlatformsState>(
      builder: (context, state) {
        if (state is AnimePlatformsInitial) {
          context.read<AnimePlatformsCubit>().loadAnimePlatforms(client);
          return const Center(child: CircularProgressIndicator());
        } else if (state is AnimePlatformsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AnimePlatformsLoaded) {
          return CustomChips(
            title: 'Streaming On',
            chipList: state.platforms.map((p) {
              return p == null
                  ? const SizedBox()
                  : CustomChoiceChip(
                      label: p,
                      value: p,
                      selected: selectedPlatforms.contains(p),
                      onSelected: (platform) {
                        bloc.add(SelectPlatform(platform));
                      },
                      onUnselected: (platform) {
                        bloc.add(UnselectPlatform(platform));
                      },
                    );
            }).toList(),
          );
        } else if (state is AnimePlatformsError) {
          return ErrorText(
            message: state.message,
            onTryAgain: () {
              context.read<AnimePlatformsCubit>().loadAnimePlatforms(client);
            },
          );
        } else {
          return ErrorText(
            message: StringConstants.somethingWentWrongError,
            onTryAgain: () {
              context.read<AnimePlatformsCubit>().loadAnimePlatforms(client);
            },
          );
        }
      },
    );
  }
}
