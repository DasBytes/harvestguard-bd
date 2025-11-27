import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AnimatedCarousel extends StatelessWidget {
  final List<String> imageUrls = const [
    'https://picsum.photos/id/1018/800/1200',
    'https://picsum.photos/id/1025/800/1200',
    'https://picsum.photos/id/1015/800/1200',
  ];

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index, realIndex) {
        return Container(
          width: MediaQuery.of(context).size.width,

          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 900),
            child: Image.network(
              imageUrls[index],
              key: ValueKey(index),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: MediaQuery.of(context).size.height,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 8),
        enlargeCenterPage: false,
        scrollDirection: Axis.horizontal,
        onPageChanged: (index, reason) {},
      ),
    );
  }
}
