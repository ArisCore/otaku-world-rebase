import 'dart:developer' as dev;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/media_section/media_carousel_card.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/theme/colors.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../generated/assets.dart';
import '../../../utils/ui_utils.dart';
import '../appbars/simple_app_bar.dart';
import '../placeholders/anime_character_placeholder.dart';

class MediaSliderScreen<B extends PaginatedDataBloc> extends StatelessWidget {
  const MediaSliderScreen({
    super.key,
    required this.sectionHeader,
  });

  final String sectionHeader;

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
      appBar: SimpleAppBar(
        title: sectionHeader,
      ),
      body: BlocBuilder<B, PaginatedDataState>(
        builder: (context, state) {
          if (state is PaginatedDataInitial || state is PaginatedDataLoading) {
            return const Center(
              child: Text('Pleas wait loading..'),
            );
          } else if (state is PaginatedDataLoaded) {
            return Center(
              child: CarouselSlider(
                carouselController: controller,
                options: CarouselOptions(
                  onPageChanged: (index, reason) {
                    if (index + 5 >= state.list.length) {
                      dev.log('Max scrolled', name: 'Media Slider');
                      final bloc = context.read<B>();
                      final hasNextPage =
                          (bloc.state as PaginatedDataLoaded).hasNextPage;
                      if (hasNextPage) {
                        final client = (context.read<GraphqlClientCubit>().state
                                as GraphqlClientInitialized)
                            .client;
                        bloc.add(LoadData(client));
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
          } else if (state is PaginatedDataError) {
            return Center(
              child: AnimeCharacterPlaceholder(
                asset: Assets.charactersChillBoy,
                height: 300,
                subheading: state.message,
                onTryAgain: () {
                  final client = context.read<GraphqlClientCubit>().getClient();
                  if (client != null) {
                    context.read<B>().add(
                          LoadData(client),
                        );
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
                    context.read<B>().add(
                          LoadData(client),
                        );
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
