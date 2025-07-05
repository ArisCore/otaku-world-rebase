import 'package:flutter/material.dart';
import 'package:otaku_world/constants/string_constants.dart';
import 'package:otaku_world/theme/colors.dart';

class ErrorText extends StatelessWidget {
  const ErrorText({
    super.key,
    this.message = StringConstants.somethingWentWrongError,
    required this.onTryAgain,
  });

  final String message;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: onTryAgain,
            child: Text(
              'Try again',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.sunsetOrange,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
