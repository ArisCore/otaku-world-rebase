import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/core/ui/media_section/media_card.dart';
import 'package:otaku_world/theme/colors.dart';
import 'package:otaku_world/utils/formatting_utils.dart';

import '../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import '../../../utils/ui_utils.dart';
import '../error_text.dart';
import '../shimmers/shimmer_loader_list.dart';

class MediaCards<B extends PaginatedDataBloc> extends HookWidget {
  const MediaCards({
    super.key,
    required this.label,
    this.horizontalPadding = 15,
    required this.onMorePressed,
    required this.heroTag,
  });

  final String label;
  final double horizontalPadding;
  final VoidCallback onMorePressed;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'Roboto-Condensed',
                      ),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: onMorePressed,
                    child: Text(
                      "View all",
                      style:
                          Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: AppColors.sunsetOrange,
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Media list
        BlocBuilder<B, PaginatedDataState>(
          builder: (context, state) {
            if (state is PaginatedDataInitial) {
              final client = (context.read<GraphqlClientCubit>().state
                      as GraphqlClientInitialized)
                  .client;
              context.read<B>().add(LoadData(client));
              return ShimmerLoaderList(
                widgetWidth: UIUtils.getWidgetWidth(
                  targetWidgetWidth: 115,
                  screenWidth: screenWidth,
                ),
                widgetHeight: UIUtils.getWidgetHeight(
                  targetWidgetHeight: 169,
                  screenHeight: screenHeight,
                ),
                height: UIUtils.getWidgetHeight(
                  targetWidgetHeight: 169,
                  screenHeight: screenHeight,
                ),
                widgetBorder: 10,
                direction: Axis.vertical,
              );
            } else if (state is PaginatedDataLoading) {
              return ShimmerLoaderList(
                widgetWidth: UIUtils.getWidgetWidth(
                  targetWidgetWidth: 115,
                  screenWidth: screenWidth,
                ),
                widgetHeight: UIUtils.getWidgetHeight(
                  targetWidgetHeight: 169,
                  screenHeight: screenHeight,
                ),
                height: UIUtils.getWidgetHeight(
                  targetWidgetHeight: 169,
                  screenHeight: screenHeight,
                ),
                widgetBorder: 10,
                direction: Axis.vertical,
              );
            } else if (state is PaginatedDataLoaded) {
              return _buildMediaList(
                state.list as List<Fragment$MediaShort?>,
              );
            } else if (state is PaginatedDataError) {
              return ErrorText(
                message: state.message,
                onTryAgain: () {
                  final client = (context.read<GraphqlClientCubit>().state
                          as GraphqlClientInitialized)
                      .client;
                  context.read<B>().add(LoadData(client));
                },
              );
            } else {
              return ErrorText(
                message: StringConstants.somethingWentWrongError,
                onTryAgain: () {
                  final client = (context.read<GraphqlClientCubit>().state
                  as GraphqlClientInitialized)
                      .client;
                  context.read<B>().add(LoadData(client));
                },
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildMediaList(
    List<Fragment$MediaShort?> mediaList,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: MediaCard(
          index: index + 1,
          startColors: FormattingUtils.getSelectMediaCardColors(index: index),
          media: mediaList[index],
        ),
      ),
      separatorBuilder: (context, index) => const SizedBox(
        height: 10,
      ),
      itemCount: 10,
    );
  }
}
