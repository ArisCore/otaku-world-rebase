import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/bloc/filter/collections/external_links/manga/manga_platforms_cubit.dart';
import 'package:otaku_world/bloc/filter/filter_manga/filter_manga_bloc.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/core/ui/filters/custom_chips.dart';
import 'package:otaku_world/core/ui/filters/custom_choice_chip.dart';

class MangaPlatformsChips extends StatelessWidget {
  const MangaPlatformsChips({super.key, required this.selectedPlatforms});

  final List<String> selectedPlatforms;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FilterMangaBloc>();
    return BlocBuilder<MangaPlatformsCubit, MangaPlatformsState>(
      builder: (context, state) {
        final client = (context.read<GraphqlClientCubit>().state
                as GraphqlClientInitialized)
            .client;
        if (state is MangaPlatformsInitial) {
          loadPublishingOnChips(
            context,
            client,
          );
          return const Center(child: CircularProgressIndicator());
        } else if (state is MangaPlatformsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MangaPlatformsLoaded) {
          return CustomChips(
            title: 'Readable On',
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
        } else if (state is MangaPlatformsError) {
          return ErrorText(
            message: state.message,
            onTryAgain: () {
              loadPublishingOnChips(
                context,
                client,
              );
            },
          );
        } else {
          return ErrorText(
            onTryAgain: () {
              loadPublishingOnChips(
                context,
                client,
              );
            },
          );
        }
      },
    );
  }

  void loadPublishingOnChips(BuildContext context, GraphQLClient client) {
    context.read<MangaPlatformsCubit>().loadMangaPlatforms(client);
  }
}
