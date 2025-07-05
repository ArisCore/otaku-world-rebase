import 'package:flutter/material.dart';
import 'package:otaku_world/theme/colors.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ReviewDetailShimmer extends StatelessWidget {
  const ReviewDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.htmlGray;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer(
            child: Container(
              color: color,
              height: 340,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    width: 53,
                    height: 10,
                  ),
                ),
                const SizedBox(height: 10),
                Shimmer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    width: 330,
                    height: 42,
                  ),
                ),
                const SizedBox(height: 10),
                Shimmer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    width: 240,
                    height: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClipOval(
                      child: Shimmer(
                        child: Container(
                          color: color,
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Shimmer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        width: 60,
                        height: 20,
                      ),
                    ),
      
                  ],
                ),
                const SizedBox(height: 10),
                Shimmer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    width: 150,
                    height: 10,
                  ),
                ),
                const SizedBox(height: 5),
                Shimmer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    width: 235,
                    height: 10,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(3, (index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          height: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Shimmer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          width: 300,
                          height: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Shimmer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          width: 320,
                          height: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Shimmer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          width: 260,
                          height: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Shimmer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          width: 295,
                          height: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Shimmer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          width: 115,
                          height: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
