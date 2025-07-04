import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:otaku_world/core/ui/markdown_v2/markdown.dart';

import '../../../../generated/assets.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/formatting_utils.dart';

class TextActivityPreview extends StatelessWidget {
  const TextActivityPreview({
    super.key,
    required this.text,
    required this.userName,
    required this.userAvatar,
  });

  final String text;
  final String userName;
  final String userAvatar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.japaneseIndigo,
              AppColors.darkCharcoal,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUser(context),
            const SizedBox(height: 10),
            // Main content
            // MarkdownWidget(data: text),
            MyMarkdownWidgetV2(data: text),
            // Other details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    _buildOption(context, asset: Assets.iconsLike),
                    const SizedBox(width: 10),
                    _buildOption(context, asset: Assets.iconsComment),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(Assets.iconsMoreHorizontal),
                )
              ],
            ),
            const SizedBox(height: 5),
            Text(
              FormattingUtils.formatUnixTimestamp(
                DateTime.now().millisecondsSinceEpoch,
                isFromAniList: false,
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white.withValues(alpha:0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required String asset}) {
    return Row(
      children: [
        SvgPicture.asset(asset, width: 25),
        const SizedBox(width: 5),
        Text(
          '0',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildUser(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.sunsetOrange),
            ),
          ),
          // padding: const EdgeInsets.all(1),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: userAvatar,
              imageBuilder: (context, imageProvider) {
                return Image(image: imageProvider, fit: BoxFit.cover);
              },
              placeholder: (context, url) {
                return _buildPlaceholderProfile();
              },
              errorWidget: (context, url, error) {
                return _buildPlaceholderProfile();
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            userName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderProfile() {
    return Container(
      padding: const EdgeInsets.all(3),
      color: AppColors.darkGray,
      child: SvgPicture.asset(Assets.assetsLogoBw),
    );
  }
}
