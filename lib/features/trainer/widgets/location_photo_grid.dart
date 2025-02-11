import 'package:flutter/material.dart';

class LocationPhotoGrid extends StatelessWidget {
  final List<String> photoUrls;
  final double maxHeight;
  final int maxPhotos;
  final VoidCallback? onTap;

  const LocationPhotoGrid({
    Key? key,
    required this.photoUrls,
    this.maxHeight = 200,
    this.maxPhotos = 4,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox();

    final displayPhotos = photoUrls.take(maxPhotos).toList();
    final remainingPhotos = photoUrls.length - displayPhotos.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: displayPhotos.length == 1
            ? _buildSinglePhoto(displayPhotos[0])
            : _buildPhotoGrid(displayPhotos, remainingPhotos),
      ),
    );
  }

  Widget _buildSinglePhoto(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.error_outline,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildPhotoGrid(List<String> photos, int remaining) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: [
        ...photos.map((url) => _buildGridPhoto(url)),
        if (remaining > 0)
          Container(
            color: Colors.black45,
            child: Center(
              child: Text(
                '+$remaining more',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGridPhoto(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.error_outline,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
