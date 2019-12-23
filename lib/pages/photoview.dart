import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/model/photo.dart';
import 'package:provider/provider.dart';

import '../common/hexcolor.dart';
import '../model/photoprism_model.dart';

class FullscreenPhotoGallery extends StatelessWidget {
  final int currentPhotoIndex;
  final List<Photo> photos;
  final String photoprismURL;
  final PageController pageController;

  FullscreenPhotoGallery(
      this.currentPhotoIndex, this.photos, this.photoprismURL)
      : this.pageController = PageController(
          initialPage: currentPhotoIndex,
          viewportFraction: 1.06,
        );

  static bool isZoomed(BuildContext context) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    return (model.photoViewScaleState == PhotoViewScaleState.initial &&
        !model.photoViewMultiTouch);
  }

  static void toggleAppBar(context) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (model.showAppBar == false) {
      model.setShowAppBar(true);
    } else {
      model.setShowAppBar(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool photoViewIsScrolling = false;

    Widget photoview(index) => PhotoView(
          // filterQuality: FilterQuality.medium,
          imageProvider: CachedNetworkImageProvider(photoprismURL +
              "/api/v1/thumbnails/" +
              this.photos[index].fileHash +
              "/fit_1920"),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 1.5,
          scaleStateChangedCallback: (scaleState) {
            Provider.of<PhotoprismModel>(context)
                .setPhotoViewScaleState(scaleState);
          },
        );

    Widget pageview() => PageView.builder(
          physics: isZoomed(context)
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.03),
                child: photoview(index));
          },
          itemCount: photos.length,
          controller: pageController,
        );

    Widget scrollNotificationListener(child) =>
        NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollStartNotification) {
              photoViewIsScrolling = true;
            } else if (scrollNotification is ScrollEndNotification) {
              photoViewIsScrolling = false;
            }
            return true;
          },
          child: child,
        );

    Widget dismissibleIfNotZoomed(Widget child) {
      if (isZoomed(context)) {
        return Dismissible(
          key: ValueKey("photoViewDismissible"),
          child: child,
          direction: DismissDirection.down,
          onDismissed: (direction) {
            Navigator.of(context).pop();
          },
        );
      }
      return child;
    }

    Widget multiTouchListener(Widget child) => Listener(
        onPointerDown: (PointerDownEvent e) {
          if (e.device == 1 && !photoViewIsScrolling) {
            Provider.of<PhotoprismModel>(context).setPhotoViewMultiTouch(true);
          }
        },
        onPointerUp: (PointerUpEvent e) {
          if (e.device == 1 && !photoViewIsScrolling) {
            Provider.of<PhotoprismModel>(context).setPhotoViewMultiTouch(false);
          }
        },
        child: child);

    return Scaffold(
        appBar: Provider.of<PhotoprismModel>(context).showAppBar
            ? AppBar(
                title: Text(""),
                backgroundColor: HexColor(
                    Provider.of<PhotoprismModel>(context).applicationColor),
              )
            : null,
        backgroundColor: Colors.black,
        body: multiTouchListener(dismissibleIfNotZoomed(
          GestureDetector(
              key: Provider.of<PhotoprismModel>(context).globalKeyPhotoView,
              child: Container(
                color: Colors.black,
                key: ValueKey("PhotoView"),
                child: scrollNotificationListener(pageview()),
              ),
              onTap: () => toggleAppBar(context)),
        )));
  }
}
