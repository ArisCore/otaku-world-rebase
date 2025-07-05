import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:otaku_world/bloc/search/search_bloc/search_bloc.dart';
import 'package:otaku_world/bloc/search/search_studios/search_studios_bloc.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/features/search/widgets/studio_card.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../bloc/search/search_base/search_base_bloc.dart';
import '../../../constants/string_constants.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../generated/assets.dart';

class ResultStudiosList extends HookWidget {
  const ResultStudiosList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final searchStudiosBloc = context.read<SearchBloc>().searchBlocs[4];

    useEffect(() {
      controller.addListener(() {
        final maxScroll = controller.position.maxScrollExtent;
        final currentScroll = controller.position.pixels;

        if (currentScroll == maxScroll) {
          dev.log('Max scrolled', name: 'StudioSearch');

          final hasNextPage =
              (searchStudiosBloc.state as SearchResultLoaded).hasNextPage;
          if (hasNextPage) {
            final client = (context.read<GraphqlClientCubit>().state
                    as GraphqlClientInitialized)
                .client;
            searchStudiosBloc.add(LoadMore(client));
          }
        }
      });
      return null;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      child: BlocBuilder<SearchStudiosBloc, SearchBaseState>(
        bloc: searchStudiosBloc as SearchStudiosBloc,
        builder: (context, state) {
          if (state is SearchInitial) {
            return const AnimeCharacterPlaceholder(
              asset: Assets.charactersSchoolGirl,
              height: 300,
              heading: 'Find what interests you!',
              subheading:
                  'Browse through our extensive library and find your next favorite.',
            );
          } else if (state is SearchResultLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is SearchError) {
            return ErrorText(message: state.message, onTryAgain: () {});
          } else if (state
              is SearchResultLoaded<Fragment$SearchResultStudio?>) {
            final list = state.list;
            final hasNextPage = state.hasNextPage;

            return list.isEmpty
                ? const AnimeCharacterPlaceholder(
                    asset: Assets.charactersErenYeager,
                    heading: 'Oops! No matches found!',
                    subheading: 'Try searching something else.',
                  )
                : CustomScrollView(
                    scrollDirection: Axis.vertical,
                    clipBehavior: Clip.none,
                    controller: controller,
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ResultStudioCard(studio: list[index]);
                          },
                          childCount: list.length,
                        ),
                      ),
                      if (hasNextPage)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  );
          } else {
            return const AnimeCharacterPlaceholder(
              height: 300,
              asset: Assets.charactersErenYeager,
              subheading: StringConstants.somethingWentWrongError,
            );
          }
        },
      ),
    );
  }
}
