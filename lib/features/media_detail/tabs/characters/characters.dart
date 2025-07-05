import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/media_detail/characters/characters_bloc.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/core/ui/placeholders/anime_character_placeholder.dart';
import 'package:otaku_world/core/ui/widgets/language_selection_mixin.dart';
import 'package:otaku_world/graphql/__generated/graphql/details/characters.graphql.dart';
import 'package:otaku_world/utils/extensions.dart';

import '../../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../../core/ui/shimmers/detail_screens/list/character_list_shimmer.dart';
import '../../../../generated/assets.dart';
import '../../../../graphql/__generated/graphql/schema.graphql.dart';
import 'widgets/character_card.dart';

class Characters extends StatefulWidget {
  const Characters({super.key});

  @override
  State<Characters> createState() => _CharactersState();
}

class _CharactersState extends State<Characters> with LanguageSelectionMixin {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharactersBloc, PaginatedDataState>(
      builder: (context, state) {
        if (state is PaginatedDataInitial) {
          final client = (context.read<GraphqlClientCubit>().state
                  as GraphqlClientInitialized)
              .client;
          context.read<CharactersBloc>().add(LoadData(client));
          return const CharacterListShimmer();
        } else if (state is PaginatedDataLoading) {
          return const CharacterListShimmer();
        } else if (state is PaginatedDataLoaded) {
          List<Query$Characters$Media$characters$edges?> characters =
              state.list as List<Query$Characters$Media$characters$edges?>;
          loadLanguagesFromVoiceActors(characters);
          if (characters.isEmpty) {
            return const AnimeCharacterPlaceholder(
              asset: Assets.charactersErenYeager,
              heading: 'No Characters Available',
              subheading:
                  'Looks like there aren’t any characters to display right now.',
              isScrollable: true,
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                final characterBloc = context.read<CharactersBloc>();
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
                SliverPadding(
                  padding: const EdgeInsets.all(10),
                  sliver: SliverList.separated(
                    itemCount: characters.length,
                    separatorBuilder: (context, index) => const SizedBox(
                      height: 10,
                    ),
                    itemBuilder: (context, index) {
                      final character = characters[index]!.node!;
                      final voiceActor = characters[index]!
                          .voiceActorRoles!
                          .where((voiceActorRole) =>
                              voiceActorRole!.voiceActor!.languageV2 ==
                              selectedLanguage)
                          .toList();

                      return CharacterCard(
                        animeCharacter: character,
                        characterRole: toJson$Enum$CharacterRole(
                          characters[index]?.role ??
                              Enum$CharacterRole.$unknown,
                        ).toString().capitalize(),
                        voiceActor: voiceActor.isEmpty
                            ? null
                            : voiceActor.first?.voiceActor,
                      );
                    },
                  ),
                ),
                if (state.hasNextPage)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                    sliver: SliverToBoxAdapter(
                      child: CharacterCardShimmer(),
                    ),
                  ),
              ],
            ),
          );
        }
        return AnimeCharacterPlaceholder(
          asset: Assets.charactersNoInternet,
          heading: 'Something went wrong!',
          subheading:
              'Please check your internet connection or try again later.',
          onTryAgain: () {
            context.read<CharactersBloc>().add(
                  LoadData(
                    (context.read<GraphqlClientCubit>().state
                            as GraphqlClientInitialized)
                        .client,
                  ),
                );
          },
          isError: true,
          isScrollable: true,
        );
      },
    );
  }
}
