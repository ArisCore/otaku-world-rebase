import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/charcter_detail/media/character_media_bloc.dart';
import 'package:otaku_world/features/character_detail/widgets/character_media_card.dart';

import '../../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../bloc/paginated_data/paginated_data_bloc.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../core/ui/shimmers/detail_screens/list/character_list_shimmer.dart';
import '../../../core/ui/widgets/language_selection_mixin.dart';
import '../../../core/ui/widgets/media_filter_widget.dart';
import '../../../generated/assets.dart';
import '../../../graphql/__generated/graphql/character-detail/character_media.graphql.dart';

class CharacterMediaList extends StatefulWidget {
  const CharacterMediaList({super.key});

  @override
  State<CharacterMediaList> createState() => _CharacterMediaListState();
}

class _CharacterMediaListState extends State<CharacterMediaList>
    with LanguageSelectionMixin {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CharacterMediaBloc>();
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          final characterBloc = context.read<CharacterMediaBloc>();
          final hasNextPage =
              (characterBloc.state as PaginatedDataLoaded).hasNextPage;
          if (hasNextPage) {
            final client = (context.read<GraphqlClientCubit>().state
                    as GraphqlClientInitialized)
                .client;
            characterBloc.add(LoadData(client));
          }
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            sliver: SliverToBoxAdapter(
              child: buildLanguageDropdown(),
            ),
          ),
          // Media Filter Widget
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            sliver: SliverToBoxAdapter(
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
          ),
          // BlocBuilder for Media List
          BlocBuilder<CharacterMediaBloc, PaginatedDataState>(
            builder: (context, state) {
              if (state is PaginatedDataInitial ||
                  state is PaginatedDataLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.all(10),
                  sliver: SliverList.separated(
                    itemCount: 5,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        const CharacterCardShimmer(),
                  ),
                );
              } else if (state is PaginatedDataLoaded) {
                List<Query$getCharacterMedia$Character$media$edges?>
                    characters = state.list
                        as List<Query$getCharacterMedia$Character$media$edges?>;
                loadLanguagesFromVoiceActors(characters);

                if (characters.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: AnimeCharacterPlaceholder(
                    asset: Assets.charactersErenYeager,
                    heading: 'No Characters Available',
                    subheading:
                        'Looks like there aren’t any characters to display right now.',
                    isScrollable: true,
                  ));
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(10),
                  sliver: SliverList.separated(
                    itemCount: characters.length,
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
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: Center(
                  child: AnimeCharacterPlaceholder(
                    asset: Assets.charactersNoInternet,
                    height: 300,
                    heading: 'Something went wrong!',
                    subheading:
                        'Please check your internet connection or try again later.',
                    onTryAgain: () {
                      final client = (context.read<GraphqlClientCubit>().state
                              as GraphqlClientInitialized)
                          .client;
                      context.read<CharacterMediaBloc>().add(
                            LoadData(client),
                          );
                    },
                    isError: true,
                    isScrollable: true,
                  ),
                ),
              );
            },
          ),
          // Loading Indicator for Pagination
          BlocBuilder<CharacterMediaBloc, PaginatedDataState>(
            builder: (context, state) {
              if (state is PaginatedDataLoaded && state.hasNextPage) {
                return const SliverPadding(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
                  sliver: SliverToBoxAdapter(
                    child: CharacterCardShimmer(),
                  ),
                );
              }
              return const SliverToBoxAdapter();
            },
          ),
        ],
      ),
    );
  }
}
