import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/graphql_client/graphql_client_cubit.dart';
import 'package:otaku_world/bloc/profile/user_stats/user_stats_bloc.dart';
import 'package:otaku_world/constants/filter_constants.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/error_text.dart';
import 'package:otaku_world/core/ui/filters/custom_dropdown.dart';
import 'package:otaku_world/features/profile/widgets/stats/genre/genre_stats.dart';
import 'package:otaku_world/features/profile/widgets/stats/overview/anime_stats_overview.dart';
import 'package:otaku_world/features/profile/widgets/stats/overview/manga_stats_overview.dart';
import 'package:otaku_world/features/profile/widgets/stats/staff/staff_stats.dart';
import 'package:otaku_world/features/profile/widgets/stats/studios/studio_stats.dart';
import 'package:otaku_world/features/profile/widgets/stats/tags/tags_stats.dart';
import 'package:otaku_world/features/profile/widgets/stats/voice_actors/voice_actor_stats.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/user/user_stats.graphql.dart';
import 'package:otaku_world/theme/colors.dart';

class UserStats extends StatefulWidget {
  const UserStats({super.key, required this.userId, this.scrollKey});

  final int userId;
  final GlobalKey<ExtendedNestedScrollViewState>? scrollKey;

  @override
  State<UserStats> createState() => _UserStatsState();
}

class _UserStatsState extends State<UserStats> {
  bool isAnime = true;
  StatsOption option = StatsOption.overview;

  @override
  Widget build(BuildContext context) {
    final client = context.read<GraphqlClientCubit>().getClient()!;
    final dropdownOptions = isAnime
        ? StatsOption.values
        : [
            StatsOption.overview,
            StatsOption.genres,
            StatsOption.tags,
            StatsOption.staff,
          ];

    return BlocProvider(
      create: (context) => UserStatsBloc(userId: widget.userId),
      child: BlocBuilder<UserStatsBloc, UserStatsState>(
        builder: (context, state) {
          if (state is UserStatsInitial) {
            context.read<UserStatsBloc>().add(LoadUserStats(client));
          }
          if (state is UserStatsLoading || state is UserStatsInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserStatsLoaded) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _OptionDropdownDelegate(
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAnime ? 'Anime' : 'Manga',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontFamily: 'Poppins',
                                    ),
                              ),
                              Switch(
                                value: isAnime,
                                activeTrackColor: AppColors.sunsetOrange,
                                inactiveTrackColor: AppColors.japaneseIndigo,
                                activeColor: AppColors.white,
                                inactiveThumbColor: AppColors.white,
                                onChanged: (value) {
                                  setState(() {
                                    isAnime = value;
                                    if (!isAnime &&
                                        (option == StatsOption.voiceActors ||
                                            option == StatsOption.studios)) {
                                      option = StatsOption.overview;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          CustomDropdown(
                            key: UniqueKey(),
                            dropdownItems: dropdownOptions
                                .map((e) => e.displayName)
                                .toList(),
                            initialValue: option.displayName,
                            onChange: (value) async {
                              if (widget.scrollKey?.currentState != null) {
                                final position = widget.scrollKey!.currentState!
                                    .innerController.positions.first;
                                if (position.viewportDimension > 680) {
                                  await widget
                                      .scrollKey?.currentState?.innerController
                                      .animateTo(
                                    0,
                                    duration: const Duration(microseconds: 1),
                                    curve: Curves.ease,
                                  );
                                }
                              }
                              setState(() {
                                option = FilterConstants.statsOptionFromString(
                                  value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildStats(
                    animeStats: state.animeStats,
                    mangaStats: state.mangaStats,
                  ),
                ],
              ),
            );
          } else if (state is UserStatsError) {
            return ErrorText(
              message: state.message,
              onTryAgain: () {},
            );
          } else {
            return ErrorText(
              message: StringConstants.somethingWentWrongError,
              onTryAgain: () {},
            );
          }
        },
      ),
    );
  }

  Widget _buildStats({
    required Fragment$UserStatistics animeStats,
    required Fragment$UserStatistics mangaStats,
  }) {
    switch (option) {
      case StatsOption.overview:
        return isAnime
            ? AnimeStatsOverview(stats: animeStats)
            : MangaStatsOverview(stats: mangaStats);
      case StatsOption.genres:
        return isAnime
            ? GenreStats(
                key: UniqueKey(),
                genres: animeStats.genres,
                type: Enum$MediaType.ANIME,
              )
            : GenreStats(
                key: UniqueKey(),
                genres: mangaStats.genres,
                type: Enum$MediaType.MANGA,
              );
      case StatsOption.tags:
        return isAnime
            ? TagsStats(
                key: UniqueKey(),
                tags: animeStats.tags,
                type: Enum$MediaType.ANIME,
              )
            : TagsStats(
                key: UniqueKey(),
                tags: mangaStats.tags,
                type: Enum$MediaType.MANGA,
              );
      case StatsOption.voiceActors:
        return VoiceActorStats(
          key: UniqueKey(),
          voiceActors: animeStats.voiceActors,
        );
      case StatsOption.studios:
        return StudioStats(
          key: UniqueKey(),
          studios: animeStats.studios,
        );
      case StatsOption.staff:
        return isAnime
            ? StaffStats(
                key: UniqueKey(),
                staff: animeStats.staff,
                type: Enum$MediaType.ANIME,
              )
            : StaffStats(
                key: UniqueKey(),
                staff: mangaStats.staff,
                type: Enum$MediaType.MANGA,
              );
    }
  }
}

class _OptionDropdownDelegate extends SliverPersistentHeaderDelegate {
  const _OptionDropdownDelegate(this.child);

  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      color: AppColors.raisinBlack,
      child: child,
    );
  }

  @override
  double get maxExtent => 110;

  @override
  double get minExtent => 110;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
