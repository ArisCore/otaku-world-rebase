import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:otaku_world/bloc/discover/studios/most_favorite_studios_bloc.dart';
import 'package:otaku_world/bloc/paginated_data/paginated_data_bloc.dart';
import 'package:otaku_world/core/ui/shimmers/grid_shimmer.dart';
import 'package:otaku_world/features/discover/widgets/entity_grid.dart';
import 'package:otaku_world/graphql/__generated/graphql/fragments.graphql.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';

import '../../../../bloc/graphql_client/graphql_client_cubit.dart';
import '../../../../constants/string_constants.dart';
import '../../../../core/ui/error_text.dart';

class DiscoverStudiosSection extends HookWidget {
  const DiscoverStudiosSection({super.key});

  @override
  Widget build(BuildContext context) {
    final client =
        (context.read<GraphqlClientCubit>().state as GraphqlClientInitialized)
            .client;
    final studiosBloc = context.read<MostFavoriteStudiosBloc>();

    return BlocBuilder<MostFavoriteStudiosBloc, PaginatedDataState>(
      builder: (context, state) {
        if (state is PaginatedDataInitial) {
          studiosBloc.add(LoadData(client));
          return const GridShimmer(
            mediaType: Enum$MediaType.ANIME,
            physics: NeverScrollableScrollPhysics(),
          );
        } else if (state is PaginatedDataLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Text(
                  'Most Favorite Studios',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFamily: 'Roboto-Condensed',
                      ),
                ),
              ),
              const SizedBox(height: 10),
              const GridShimmer(
                mediaType: Enum$MediaType.ANIME,
                physics: NeverScrollableScrollPhysics(),
              ),
            ],
          );
        } else if (state is PaginatedDataLoaded) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            // padding: const EdgeInsets.only(left: 15),
            child: EntityGrid<Fragment$SearchResultStudio>(
              title: 'Most Favorite Studios',
              list: state.list as List<Fragment$SearchResultStudio?>,
              hasNextPage: state.hasNextPage,
            ),
          );
        } else if (state is PaginatedDataError) {
          return ErrorText(
            message: state.message,
            onTryAgain: () {
              final client = context.read<GraphqlClientCubit>().getClient();
              if (client != null) {
                studiosBloc.add(LoadData(client));
              }
            },
          );
        } else {
          return ErrorText(
            message: StringConstants.somethingWentWrongError,
            onTryAgain: () {
              final client = context.read<GraphqlClientCubit>().getClient();
              if (client != null) {
                studiosBloc.add(LoadData(client));
              }
            },
          );
        }
      },
    );
  }
}
