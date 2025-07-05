import 'package:flutter/material.dart';
import 'package:otaku_world/features/discover/widgets/entity_card.dart';

import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import '../../../utils/navigation_helper.dart';

class EntityGrid<E> extends StatelessWidget {
  const EntityGrid({
    super.key,
    required this.list,
    required this.hasNextPage,
    this.title = 'Results',
    this.showTitle = true,
  });

  final List<E?> list;
  final bool hasNextPage;
  final String title;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontFamily: 'Roboto-Condensed',
                ),
          ),
        if (showTitle) const SizedBox(height: 10),
        CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  childAspectRatio: 100 / 185,
                  // crossAxisSpacing: 10,
                  // mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: list.length,
                  (context, index) {
                    if (list[index] == null) return const SizedBox();

                    if (E == Fragment$SearchResultCharacter) {
                      final character =
                          list[index] as Fragment$SearchResultCharacter;
                      return EntityCard(
                        title: character.name?.userPreferred ?? ' - - ',
                        imageUrl: character.image?.large,
                        favorites: character.favourites,
                        onTap: () {
                          NavigationHelper.goToCharacterDetailScreen(
                            context: context,
                            characterId: character.id,
                          );
                        },
                      );
                    } else if (E == Fragment$CharacterShort) {
                      final character = list[index] as Fragment$CharacterShort;
                      return EntityCard(
                        title: character.name?.userPreferred ?? ' - - ',
                        imageUrl: character.image?.large,
                        favorites: character.favourites,
                        onTap: () {
                          NavigationHelper.goToCharacterDetailScreen(
                            context: context,
                            characterId: character.id,
                          );
                        },
                      );
                    } else if (E == Fragment$SearchResultStaff) {
                      final staff = list[index] as Fragment$SearchResultStaff;
                      return EntityCard(
                        title: staff.name?.userPreferred ?? ' - - ',
                        imageUrl: staff.image?.large,
                        favorites: staff.favourites,
                        onTap: () {
                          NavigationHelper.goToStaffDetailScreen(
                            context: context,
                            staffId: staff.id,
                          );
                        },
                      );
                    } else if (E == Fragment$StaffShort) {
                      final staff = list[index] as Fragment$StaffShort;
                      return EntityCard(
                        title: staff.name?.userPreferred ?? ' - - ',
                        imageUrl: staff.image?.large,
                        favorites: staff.favourites,
                        onTap: () {
                          NavigationHelper.goToStaffDetailScreen(
                            context: context,
                            staffId: staff.id,
                          );
                        },
                      );
                    } else if (E == Fragment$SearchResultStudio) {
                      final studio = list[index] as Fragment$SearchResultStudio;
                      final media = studio.media?.nodes?[0];
                      String poster = '';
                      if (media != null) {
                        poster = (media.isAdult ?? true)
                            ? ''
                            : (media.coverImage?.large ?? '');
                      }

                      return EntityCard(
                        title: studio.name,
                        imageUrl: poster,
                        favorites: studio.favourites,
                        onTap: () {
                          NavigationHelper.goToStudioDetailScreen(
                            context: context,
                            studioId: studio.id,
                          );
                        },
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
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
        ),
      ],
    );
  }
}
