import '../../../core/ui/shimmers/detail_screens/shimmer_details.dart';

class DiscoverImageCard extends StatelessWidget {
  const DiscoverImageCard({
    super.key,
    required this.assetName,
    required this.onTap,
  });

  final String assetName;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          assetName,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
