import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/model/photo.dart';
import 'package:provider/provider.dart';

import '../model/photoprism_model.dart';

class FullscreenPhotoGallery extends StatefulWidget {
  final String albumId;
  final int currentPhotoIndex;

  FullscreenPhotoGallery(this.currentPhotoIndex, this.albumId);

  _FullscreenPhotoGalleryState createState() => _FullscreenPhotoGalleryState();
}

class _FullscreenPhotoGalleryState extends State<FullscreenPhotoGallery>
    with TickerProviderStateMixin {
  PageController pageController;
  int currentPhotoIndex;
  String photoprismUrl;
  List<Photo> photos;
  bool photoViewIsScrolling = false;
  bool showAppBar = true;
  Key globalKeyPhotoView = GlobalKey();
  bool photoViewMultiTouch = false;
  AnimationController animationController;
  AnimationController backgroundAnimationController;
  Animation<double> animation;
  Animation<double> backgroundAnimation;
  GlobalKey previewKey = GlobalKey();
  Offset photoPosition = Offset(0, 0);

  @override
  void initState() {
    super.initState();
    this.pageController = PageController(
      initialPage: widget.currentPhotoIndex,
      viewportFraction: 1.06,
    );
    animationController = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);

    backgroundAnimationController = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    backgroundAnimation =
        Tween<double>(begin: 0, end: 1).animate(backgroundAnimationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        animationController.forward();
        backgroundAnimationController.forward();
      });
    });
  }

  bool isZoomed(BuildContext context) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    return (model.photoViewScaleState == PhotoViewScaleState.initial &&
        !photoViewMultiTouch);
  }

  void toggleAppBar(context) {
    setState(() {
      if (showAppBar == false) {
        showAppBar = true;
      } else {
        showAppBar = false;
      }
    });
  }

  void setPhotoViewMultiTouch(bool multiTouch) {
    setState(() {
      photoViewMultiTouch = multiTouch;
    });
  }

  Widget photoview(index) {
    this.currentPhotoIndex = index;
    if (this.photos[index].aspectRatio >= 1) {
      if (MediaQuery.of(context).size.width <=
          MediaQuery.of(context).size.height) {
        animation =
            Tween<double>(begin: 1 / this.photos[index].aspectRatio, end: 1)
                .animate(animationController);
      } else {
        double screenRatio = MediaQuery.of(context).size.height /
            MediaQuery.of(context).size.width;
        animation = Tween<double>(begin: screenRatio, end: 1)
            .animate(animationController);
      }
    } else {
      if (MediaQuery.of(context).size.width >=
          MediaQuery.of(context).size.height) {
        animation = Tween<double>(begin: this.photos[index].aspectRatio, end: 1)
            .animate(animationController);
      } else {
        double screenRatio = MediaQuery.of(context).size.width /
            MediaQuery.of(context).size.height;
        animation = Tween<double>(begin: screenRatio, end: 1)
            .animate(animationController);
      }
    }
    return _AnimatedFullScreenPhoto(
        orientation: this.photos[index].aspectRatio >= 1
            ? Orientation.landscape
            : Orientation.portrait,
        animation: animation,
        child: PhotoView(
          // filterQuality: FilterQuality.medium,
          imageProvider: CachedNetworkImageProvider(photoprismUrl +
              "/api/v1/thumbnails/" +
              photos[index].fileHash +
              "/fit_1920"),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.contained * 2,
          scaleStateChangedCallback: (scaleState) {
            Provider.of<PhotoprismModel>(context)
                .setPhotoViewScaleState(scaleState);
            if (scaleState == PhotoViewScaleState.zoomedOut) {
              backgroundAnimationController.reverse();
            } else {
              backgroundAnimationController.forward();
            }
          },
          backgroundDecoration: BoxDecoration(color: Colors.transparent),
        ));
  }

  Widget getPreview(index) {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Center(
            child: Hero(
                tag: index.toString(),
                createRectTween: (begin, end) {
                  return RectTween(begin: begin, end: end);
                },
                child: CachedNetworkImage(
                  width: MediaQuery.of(context).size.height *
                      this.photos[index].aspectRatio,
                  height: MediaQuery.of(context).size.width /
                      this.photos[index].aspectRatio,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  imageUrl: photoprismUrl +
                      '/api/v1/thumbnails/' +
                      photos[index].fileHash +
                      '/tile_224',
                ))));
  }

  Widget pageview() => Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: PageView.builder(
        physics: isZoomed(context)
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03),
              child: Stack(children: <Widget>[
                Positioned(
                    left: photoPosition.dx,
                    top: photoPosition.dy,
                    child: (Provider.of<PhotoprismModel>(context)
                                .photoViewScaleState !=
                            PhotoViewScaleState.zoomedOut)
                        ? getPreview(index)
                        : Container()),
                Positioned(
                    left: photoPosition.dx,
                    top: photoPosition.dy,
                    child: photoview(index)),
              ]));
        },
        itemCount: photos.length,
        controller: pageController,
      ));

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

  void animateAndPop(BuildContext context) async {
    await animationController.reverse();
    Navigator.of(context).pop();
  }

  Widget dismissibleIfNotZoomed(Widget child) {
    if (isZoomed(context)) {
      return Draggable(
        onDragStarted: () {
          backgroundAnimationController.reverse();
        },
        onDragEnd: (details) {
          if (details.offset.dy.abs() >
              MediaQuery.of(context).size.height / 4) {
            setState(() {
              photoPosition = details.offset;
            });
            animateAndPop(context);
          } else {
            backgroundAnimationController.forward();
          }
        },
        key: ValueKey("photoViewDismissible"),
        child: child,
        childWhenDragging: Container(),
        affinity: Axis.vertical,
        feedback: child,
      );
    }
    return child;
  }

  Widget multiTouchListener(Widget child) => Listener(
      onPointerDown: (PointerDownEvent e) {
        if (e.device == 1 && !photoViewIsScrolling) {
          setPhotoViewMultiTouch(true);
        }
      },
      onPointerUp: (PointerUpEvent e) {
        if (e.device == 1 && !photoViewIsScrolling) {
          setPhotoViewMultiTouch(false);
        }
      },
      child: child);
  @override
  Widget build(BuildContext context) {
    photoprismUrl = Provider.of<PhotoprismModel>(context).photoprismUrl;
    photos = Photos.getPhotoList(context, widget.albumId);
    currentPhotoIndex = widget.currentPhotoIndex;

    return WillPopScope(
        onWillPop: () async {
          backgroundAnimationController.reverse();
          await animationController.reverse();
          return true;
        },
        child: _AnimatedBackground(
            animation: backgroundAnimation,
            child: Stack(children: <Widget>[
              multiTouchListener(dismissibleIfNotZoomed(
                GestureDetector(
                    key: globalKeyPhotoView,
                    child: Container(
                      key: ValueKey("PhotoView"),
                      child: scrollNotificationListener(pageview()),
                    ),
                    onTap: () => toggleAppBar(context)),
              )),
              showAppBar
                  ? Positioned(
                      top: 0.0,
                      left: 0.0,
                      right: 0.0,
                      child: AppBar(
                        title: Text(""),
                        actions: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.share),
                            tooltip: 'Share photo',
                            onPressed: () {
                              sharePhoto(this.currentPhotoIndex);
                            },
                          )
                        ],
                        backgroundColor: Colors.transparent,
                      ))
                  : Container(),
            ])));
  }

  sharePhoto(index) async {
    var request = await HttpClient().getUrl(Uri.parse(
        photoprismUrl + "/api/v1/download/" + photos[index].fileHash));
    var response = await request.close();
    print(response.statusCode);

    if (response.statusCode == 200) {
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      await Share.file('Photoprism Photo', photos[index].fileHash + '.jpg',
          bytes, 'image/jpg');
    } else {
      Provider.of<PhotoprismModel>(context)
          .photoprismMessage
          .showMessage("Error while sharing: No connection to server!");
    }
  }
}

class _AnimatedFullScreenPhoto extends AnimatedWidget {
  final Widget child;
  final Orientation orientation;

  const _AnimatedFullScreenPhoto(
      {Key key, Animation<double> animation, this.child, this.orientation})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Visibility(
        visible: animation.status != AnimationStatus.dismissed,
        child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
                child: ClipRect(
                    child: Align(
              widthFactor:
                  orientation == Orientation.landscape ? animation.value : 1,
              heightFactor:
                  orientation == Orientation.portrait ? animation.value : 1,
              child: child,
            )))));
  }
}

class _AnimatedBackground extends AnimatedWidget {
  final Widget child;
  final Orientation orientation;

  const _AnimatedBackground(
      {Key key, Animation<double> animation, this.child, this.orientation})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Container(
      color: Color.fromRGBO(0, 0, 0, animation.value),
      child: child,
    );
  }
}
