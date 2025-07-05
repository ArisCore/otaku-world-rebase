import 'dart:developer' as dev;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/filter/filter_anime/filter_anime_bloc.dart';
import 'package:otaku_world/core/ui/media_section/media_carousel_card.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../../constants/string_constants.dart';
import '../../../../core/ui/appbars/simple_app_bar.dart';
import '../../../../core/ui/placeholders/anime_character_placeholder.dart';
import '../../../../generated/assets.dart';
import '../../../../utils/ui_utils.dart';

class AnimeSliderScreen extends StatelessWidget {
  const AnimeSliderScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = CarouselSliderController();
    final size = MediaQuery.of(context).size;

    dev.log('Width: ${size.width} | Height: ${size.height}', name: 'Size');
    final List<Color> cardColors = [
      AppColors.sunsetOrange,
      AppColors.crayola,
      AppColors.kiwi,
    ];

    return Scaffold(
      appBar: const SimpleAppBar(
        title: 'Anime',
      ),
      body: BlocBuilder<FilterAnimeBloc, FilterAnimeState>(
        builder: (context, state) {
          if (state is FilterAnimeInitial || state is ResultsLoading) {
            return const Center(
              child: Text('Pleas wait loading..'),
            );
          } else if (state is ResultsLoaded) {
            return Center(
              child: CarouselSlider(
                carouselController: controller,
                options: CarouselOptions(
                  onPageChanged: (index, reason) {
                    if (index + 5 >= state.list.length) {
                      dev.log('Max scrolled', name: 'Media Slider');
                      final bloc = context.read<FilterAnimeBloc>();
                      final hasNextPage =
                          (bloc.state as ResultsLoaded).hasNextPage;
                      if (hasNextPage) {
                        final client = (context.read<GraphqlClientCubit>().state
                                as GraphqlClientInitialized)
                            .client;
                        bloc.add(LoadMore(client));
                      }
                    }
                  },
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.3,
                  viewportFraction: 0.7,
                  enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                  height: UIUtils.getWidgetHeight(
                    targetWidgetHeight: 650,
                    screenHeight: size.height,
                  ),
                ),
                items: state.list.asMap().entries.map((entry) {
                  int index = entry.key;
                  Fragment$MediaShort? media = entry.value;

                  return MediaCarouselCard(
                    width: UIUtils.getWidgetWidth(
                      targetWidgetWidth: 240,
                      screenWidth: size.width,
                    ),
                    screenWidth: size.width,
                    color: cardColors[index % cardColors.length],
                    media: media,
                  );
                }).toList(),
              ),
            );
          } else if (state is FilterError) {
            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersErenYeager,
                height: 300,
                subheading: state.message,
                onTryAgain: () {
                  final client = context.read<GraphqlClientCubit>().getClient();
                  if (client != null) {
                    context.read<FilterAnimeBloc>().add(LoadMore(client));
                  }
                },
                isError: true,
                isScrollable: true,
              ),
            );
          } else {
            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersNoInternet,
                height: 300,
                subheading: StringConstants.somethingWentWrongError,
                onTryAgain: () {
                  final client = context.read<GraphqlClientCubit>().getClient();
                  if (client != null) {
                    context.read<FilterAnimeBloc>().add(LoadMore(client));
                  }
                },
                isError: true,
                isScrollable: true,
              ),
            );
          }
        },
      ),
    );
  }
}
