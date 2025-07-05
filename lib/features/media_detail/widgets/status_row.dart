import 'package:flutter/material.dart';
import 'package:otaku_world/graphql/__generated/graphql/schema.graphql.dart';

import '../../../core/ui/texts/status_text.dart';
import '../../../graphql/__generated/graphql/fragments.graphql.dart';
import '../../../utils/formatting_utils.dart';

class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.airingSchedule,
    required this.status,
    required this.fontSize,
    required this.alignment,
    this.mainAxisSize = MainAxisSize.min,
  });

  final MainAxisAlignment alignment;
  final double fontSize;
  final Fragment$MediaShort$airingSchedule? airingSchedule;
  final Enum$MediaStatus? status;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    if (airingSchedule?.nodes != null && airingSchedule!.nodes!.isNotEmpty) {
      return Row(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: alignment,
        children: [
          StatusText(
            status: status,
            fontSize: fontSize,
          ),
          const SizedBox(
            width: 20,
          ),
          SizedBox(
            width: 99,
            child: Text(
              "Ep. ${airingSchedule!.nodes![0]!.episode}: ${FormattingUtils.formatDurationFromSeconds(airingSchedule!.nodes![0]!.timeUntilAiring)}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return StatusText(
        status: status,
        fontSize: fontSize,
      );
    }
  }
}
