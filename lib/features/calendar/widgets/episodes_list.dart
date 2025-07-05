import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:otaku_world/bloc/calendar/week_calendar/day/day_bloc.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../constants/string_constants.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../core/ui/shimmers/calendar_shimmer_card.dart';
import '../../../core/ui/shimmers/shimmer_list.dart';
import '../../../generated/assets.dart';
import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import 'calendar_card.dart';

class EpisodesList extends HookWidget {
  const EpisodesList({
    super.key,
    required this.dayBloc,
    required this.client,
    this.clipBehaviour = Clip.none,
  });

  final DayBloc dayBloc;
  final GraphQLClient client;
  final Clip clipBehaviour;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    useEffect(() {
      scrollController.addListener(() {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;

        if (currentScroll >= maxScroll - 120 * 5) {
          dev.log('Max scrolled', name: 'Media');
          final hasNextPage = (dayBloc.state as EpisodesLoaded).hasNextPage;
          if (hasNextPage) {
            dayBloc.add(LoadDay(client));
          }
        }
      });
      return null;
    }, const []);

    return BlocBuilder<DayBloc, DayState>(
      bloc: dayBloc,
      builder: (context, state) {
        if (state is DayInitial) {
          dayBloc.add(LoadDay(client));
          return const SizedBox();
        } else if (state is EpisodesLoading) {
          return const ShimmerList(
            child: CalendarShimmerCard(),
          );
        } else if (state is EpisodesLoaded) {
          dev.log('Rebuilding episodes list', name: 'Calendar');
          return _buildCalendarCardsList(
            state.episodes,
            state.hasNextPage,
            scrollController,
          );
        } else if (state is DayError) {
          return Center(
            child: AnimeCharacterPlaceholder(
              asset: Assets.charactersErenYeager,
              heading: 'Nothing to Show',
              subheading: state.message,
              isError: true,
              onTryAgain: () => dayBloc.add(LoadDay(client)),
            ),
          );
        } else {
          return Center(
            child: AnimeCharacterPlaceholder(
              asset: Assets.charactersCigaretteGirl,
              subheading: StringConstants.somethingWentWrongError,
              isError: true,
              onTryAgain: () => dayBloc.add(LoadDay(client)),
            ),
          );
        }
      },
    );
  }

  Widget _buildCalendarCardsList(
    List<Fragment$CalendarAiringSchedule?> schedules,
    bool hasNextPage,
    ScrollController controller,
  ) {
    return RefreshIndicator(
      backgroundColor: AppColors.raisinBlack,
      onRefresh: () async {
        dayBloc.add(RefreshDay(client));
      },
      child: CustomScrollView(
        clipBehavior: clipBehaviour,
        controller: controller,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  CalendarCard(airingSchedule: schedules[index]!),
              childCount: schedules.length,
            ),
          ),
          if (hasNextPage)
            ...List.generate(
              5,
              (index) => const SliverToBoxAdapter(
                child: CalendarShimmerCard(),
              ),
            ),
        ],
      ),
    );
  }
}
