import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photoprism/model/photo.dart';
import 'package:provider/provider.dart';

import '../common/hexcolor.dart';
import '../model/photoprism_model.dart';

class PhotoView extends StatelessWidget {
  final int currentPhotoIndex;
  final List<Photo> photos;
  final String photoprismURL;
  final PageController pageController;

  PhotoView(this.currentPhotoIndex, this.photos, this.photoprismURL)
      : this.pageController = PageController(initialPage: currentPhotoIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Provider.of<PhotoprismModel>(context).showAppBar ? AppBar(
        title: Text(""),
        backgroundColor: HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
      ) : null,
      body: GestureDetector(
          child:Container(
            color: Colors.black,
            key: ValueKey("PhotoView"),
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(photoprismURL +
                      "/api/v1/thumbnails/" +
                      this.photos[index].fileHash +
                      "/fit_1920"),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 1.5,

                );
              },
              itemCount: photos.length,
              pageController: pageController,
            ),
          ),
          onTap: () {
            var provider = Provider.of<PhotoprismModel>(context);
            if (provider.showAppBar == false) {
              provider.setShowAppBar(true);
            }
            else {
              provider.setShowAppBar(false);
            }
          }
      ),
    );
  }
}
