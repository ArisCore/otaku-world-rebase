import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/charcter_detail/media/character_media_bloc.dart';
import 'package:otaku_world/core/ui/widgets/language_selection_mixin.dart';
import 'package:otaku_world/core/ui/widgets/media_filter_widget.dart';
import 'package:otaku_world/features/character_detail/widgets/character_media_card.dart';
import 'package:otaku_world/utils/extensions.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../bloc/paginated_data/paginated_data_bloc.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../core/ui/shimmers/detail_screens/list/character_list_shimmer.dart';
import '../../../generated/assets.dart';
import '../../../graphql/__generated/graphql/character-detail/character_media.graphql.dart';

class CharacterMediaShortList extends StatefulWidget {
  const CharacterMediaShortList({super.key});

  @override
  State<CharacterMediaShortList> createState() =>
      _CharacterMediaShortListState();
}

class _CharacterMediaShortListState extends State<CharacterMediaShortList>
    with LanguageSelectionMixin {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CharacterMediaBloc>();
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: buildLanguageDropdown(),
        ),
        SliverToBoxAdapter(
          child: 10.height,
        ),
        SliverToBoxAdapter(
          child: MediaFilterWidget(
            mediaSortNotifier: bloc.mediaSortNotifier,
            isOnMyListNotifier: bloc.isOnMyList,
            onApplyFilters: () {
              final client = (context.read<GraphqlClientCubit>().state
                      as GraphqlClientInitialized)
                  .client;
              bloc.applyFilter(client: client);
            },
            bloc: bloc,
          ),
        ),
        SliverToBoxAdapter(
          child: 5.height,
        ),
        BlocBuilder<CharacterMediaBloc, PaginatedDataState>(
          builder: (context, state) {
            if (state is PaginatedDataInitial ||
                state is PaginatedDataLoading) {
              return _buildListLoading();
            } else if (state is PaginatedDataLoaded) {
              List<Query$getCharacterMedia$Character$media$edges?> characters =
                  state.list
                      as List<Query$getCharacterMedia$Character$media$edges?>;
              loadLanguagesFromVoiceActors(characters);

              if (characters.isEmpty) {
                return const SliverToBoxAdapter(
                  child: AnimeCharacterPlaceholder(
                    asset: Assets.charactersErenYeager,
                    heading: 'No Anime/Manga Available',
                    subheading:
                        'Looks like there aren’t any Anime/Manga to display right now.',
                    isScrollable: true,
                  ),
                );
              }
              return SliverList.separated(
                itemCount: characters.length,
                // +1 for the dropdown +1 for filters
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final media = characters[index]!.node!;
                  final voiceActor = characters[index]!
                      .voiceActorRoles!
                      .where((voiceActorRole) =>
                          voiceActorRole!.voiceActor!.languageV2 ==
                          selectedLanguage)
                      .toList();

                  return CharacterMediaCard(
                    media: media,
                    voiceActor: voiceActor.isNotEmpty
                        ? voiceActor.first?.voiceActor
                        : null,
                  );
                },
              );
            }

            return SliverToBoxAdapter(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersNoInternet,
                height: 300,
                heading: 'Something went wrong!',
                subheading:
                    'Please check your internet connection or try again later.',
                onTryAgain: () {
                  context.read<CharacterMediaBloc>().add(
                        LoadData(
                          (context.read<GraphqlClientCubit>().state
                                  as GraphqlClientInitialized)
                              .client,
                        ),
                      );
                },
                isError: true,
                isScrollable: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListLoading() {
    return SliverList.separated(
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => const CharacterCardShimmer(),
    );
  }
}
