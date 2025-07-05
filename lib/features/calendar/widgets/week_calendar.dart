import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../bloc/calendar/week_calendar/week_calendar_bloc.dart';
import '../../../constants/string_constants.dart';
import '../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../generated/assets.dart';
import 'calendar_tab_bar.dart';
import 'episodes_list.dart';

class WeekCalendar extends StatelessWidget {
  const WeekCalendar({
    super.key,
    required this.client,
    required this.tabController,
  });

  final GraphQLClient client;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekCalendarBloc, WeekCalendarState>(
      builder: (context, state) {
        if (state is WeekCalendarInitialized) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              CalendarTabBar(
                tabController: tabController,
                dayBlocs: state.days,
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: TabBarView(
                  // physics: const NeverScrollableScrollPhysics(),
                  controller: tabController,
                  children: List.generate(
                    7,
                    (index) {
                      return EpisodesList(
                        dayBloc: state.days[index],
                        client: client,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        } else if (state is WeekCalendarError) {
          return Center(
            child: AnimeCharacterPlaceholder(
              asset: Assets.charactersErenYeager,
              heading: 'Nothing to Show',
              subheading: state.message,
              isError: true,
              onTryAgain: () =>
                  context.read<WeekCalendarBloc>().add(RefreshCalendar()),
            ),
          );
        } else {
          return Center(
            child: AnimeCharacterPlaceholder(
              asset: Assets.charactersCigaretteGirl,
              subheading: StringConstants.somethingWentWrongError,
              isError: true,
              onTryAgain: () =>
                  context.read<WeekCalendarBloc>().add(RefreshCalendar()),
            ),
          );
        }
      },
    );
  }
}
