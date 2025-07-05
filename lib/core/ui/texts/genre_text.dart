import 'package:flutter/material.dart';

class GenreText extends StatelessWidget {
  const GenreText({
    super.key,
    this.genres,
    required this.genreStyle,
    required this.indicatorStyle,
  });

  final List<String?>? genres;
  final TextStyle? genreStyle;
  final TextStyle? indicatorStyle;

  @override
  Widget build(BuildContext context) {
    if (genres == null) return const Text('No genre');

    List<InlineSpan> textSpans = [];

    for (int i = 0; i < genres!.length; i++) {
      String genre = genres![i].toString();
      textSpans.add(
        TextSpan(
          text: genre,
          style: genreStyle,
        ),
      );

      if (i != genres!.length - 1) {
        textSpans.add(
          TextSpan(
            text: ' · ',
            style: indicatorStyle,
          ),
        );
      }
    }
    return RichText(
      text: TextSpan(
        children: textSpans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}
