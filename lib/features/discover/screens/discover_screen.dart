import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:otaku_world/core/ui/discover_header.dart';
import 'package:otaku_world/features/discover/widgets/discover_image_placeholder_card.dart';
import 'package:otaku_world/generated/assets.dart';
import 'package:otaku_world/services/caching/image_cache_manager.dart';

import '../../../config/router/router_constants.dart';
import '../../../core/ui/widgets/double_back_pop_widget.dart';

class DiscoverScreen extends HookWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    log('Building discover screen', name: 'Discover');

    return DoubleBackPopWidget(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const DiscoverHeader(
              title: "Ignite your Anime \nAdventure",
              subtitle:
                  "Immerse Yourself in a World of Discovery, Uncovering Exciting"
                  " Anime, Fascinating Mangas, and Iconic Characters.",
            ),
            const SizedBox(height: 10),
            DiscoverImageCard(
              onTap: () {
                context.push(RouteConstants.discoverAnime);
              },
              assetName: Assets.discoverPlaceholdersAnime,
            ),
            const SizedBox(height: 20),
            DiscoverImageCard(
              onTap: () {
                context.push(RouteConstants.discoverManga);
              },
              assetName: Assets.discoverPlaceholdersManga,
            ),
            const SizedBox(height: 20),
            DiscoverImageCard(
              onTap: () {
                context.push(RouteConstants.discoverCharacters);
              },
              assetName: Assets.discoverPlaceholdersCharacters,
            ),
            const SizedBox(height: 20),
            DiscoverImageCard(
              onTap: () {
                context.push(RouteConstants.discoverStaff);
              },
              assetName: Assets.discoverPlaceholdersStaff,
            ),
            const SizedBox(height: 20),
            DiscoverImageCard(
              onTap: () {
                context.push(RouteConstants.discoverStudios);
              },
              assetName: Assets.discoverPlaceholdersStudios,
            ),
            /* DiscoverCard(
              onTap: () {
                context.push(RouteConstants.discoverAnime);
              },
              title: 'Anime',
              beginColors: AppColors.raisinBlack,
              endColors: ColorConstants.discoverColors[0],
              child: DiscoverCardImage(
                radius: 15.0,
                angle: 0.11,
                posters: PosterUtils.getRandomImages(
                  AnimeImageConstants.animePosters,
                ),
                type: 'Anime',
              ),
            ),
            DiscoverCard(
              onTap: () {
                context.push(RouteConstants.discoverManga);
              },
              title: 'Manga',
              beginColors: AppColors.raisinBlack,
              endColors: ColorConstants.discoverColors[1],
              child: DiscoverCardImage(
                radius: 5.0,
                angle: 0.11,
                posters: PosterUtils.getRandomImages(
                  MangaImageConstants.mangaPosters,
                ),
                type: 'Manga',
              ),
            ),
            DiscoverCard(
              onTap: () {
                context.push(RouteConstants.discoverCharacters);
              },
              title: "Characters",
              beginColors: AppColors.raisinBlack,
              endColors: ColorConstants.discoverColors[2],
              child: const DiscoverCharacterPosters(),
            ),
            DiscoverCard(
              onTap: () {
                context.push(RouteConstants.discoverStaff);
              },
              title: 'Staff',
              beginColors: AppColors.raisinBlack,
              endColors: ColorConstants.discoverColors[3],
              child: DiscoverCardImage(
                radius: 15.0,
                angle: 0.11,
                posters: PosterUtils.getRandomImages(
                  StaffImageConstants.staffPosters,
                ),
                type: 'Staff',
              ),
            ),
            DiscoverCard(
              onTap: () {
                context.push(RouteConstants.discoverStudios);
              },
              title: "Studios",
              beginColors: AppColors.raisinBlack,
              endColors: ColorConstants.discoverColors[4],
              child: const DiscoverStudiosPosters(),
            ),*/
          ],
        ),
      ),
    );
  }
}

class DiscoverCharacterPosters extends StatelessWidget {
  const DiscoverCharacterPosters({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 308,
          height: 135,
          child: Image.asset(Assets.charactersCharacters),
        ),
      ],
    );
  }
}

class DiscoverStudiosPosters extends StatelessWidget {
  const DiscoverStudiosPosters({
    super.key,
    this.radius = 15,
  });

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: -0.15,
                  child: Container(
                    width: 141,
                    height: 74,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Image.asset(
                      Assets.studiosKyotoAnimation,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 135,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 135,
                ),
                Transform.rotate(
                  angle: 0.1,
                  child: Container(
                    width: 140,
                    height: 105,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Image.asset(
                      Assets.studiosToeiAnimation,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }
}

class DiscoverCardImage extends StatelessWidget {
  const DiscoverCardImage({
    super.key,
    this.angle = 0.0,
    this.radius = 0.0,
    required this.posters,
    required this.type,
  });

  final double radius;
  final double angle;
  final List<String> posters;
  final String type;

  @override
  Widget build(BuildContext context) {
    List<String> assets;
    switch (type) {
      case 'Anime':
        assets = [
          Assets.animeDemonSlayer,
          Assets.animeFrieren,
          Assets.animeNaruto,
        ];
        break;
      case 'Manga':
        assets = [
          Assets.mangaOnePunchMan,
          Assets.mangaHorimiya,
          Assets.mangaSpyxfamily,
        ];
        break;
      default:
        assets = [
          Assets.staffKenjirou,
          Assets.staffKana,
          Assets.staffMamoru,
        ];
        break;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: -angle,
              child: Container(
                height: 125,
                width: 85,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: _buildImage(
                  url: posters[0],
                  asset: assets[0],
                ),
              ),
            ),
            const SizedBox(
              width: 85,
            ),
            Transform.rotate(
              angle: angle,
              child: Container(
                height: 125,
                width: 85,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 3,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: _buildImage(
                  url: posters[2],
                  asset: assets[2],
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 150,
          width: 95,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 3,
                offset: Offset.zero,
              ),
            ],
          ),
          child: _buildImage(
            url: posters[1],
            asset: assets[1],
          ),
        ),
      ],
    );
  }

  Widget _buildImage({required String url, required String asset}) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: ImageCacheManager.instance,
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
        );
      },
      placeholder: (context, url) {
        return Image.asset(
          asset,
          fit: BoxFit.cover,
        );
      },
      errorWidget: (context, url, error) {
        return Image.asset(
          asset,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
