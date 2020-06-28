import 'package:cached_network_image/cached_network_image.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/model/photo.dart';
import 'package:provider/provider.dart';

import '../model/photoprism_model.dart';

class FullscreenPhotoGallery extends StatefulWidget {
  const FullscreenPhotoGallery(this.currentPhotoIndex, this.albumId);

  final int albumId;
  final int currentPhotoIndex;

  @override
  _FullscreenPhotoGalleryState createState() => _FullscreenPhotoGalleryState();
}

class _FullscreenPhotoGalleryState extends State<FullscreenPhotoGallery>
    with TickerProviderStateMixin {
  PageController pageController;
  int currentPhotoIndex;
  String photoprismUrl;
  Map<int, Photo> photos;
  bool photoViewIsScrolling = false;
  bool showAppBar = true;
  bool dragging = false;
  Key globalKeyPhotoView = GlobalKey();
  int photoViewTouchCount = 0;
  AnimationController animationController;
  AnimationController backgroundAnimationController;
  Animation<double> animation;
  Animation<double> backgroundAnimation;
  GlobalKey previewKey = GlobalKey();
  Offset photoPosition = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
    pageController = PageController(
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
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        animationController.forward();
        backgroundAnimationController.forward();
      });
    });
  }

  bool isZoomed(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    return model.photoViewScaleState != PhotoViewScaleState.initial ||
        (photoViewTouchCount > 1 && !photoViewIsScrolling);
  }

  void toggleAppBar(BuildContext context) {
    setState(() {
      if (showAppBar == false) {
        showAppBar = true;
      } else {
        showAppBar = false;
      }
    });
  }

  void setTouchCount(int multiTouch) {
    setState(() {
      photoViewTouchCount = multiTouch;
    });
  }

  void setDragging(bool value) {
    setState(() {
      dragging = value;
    });
  }

  Widget photoview(int index) {
    currentPhotoIndex = index;
    if (photos[index].aspectRatio >= 1) {
      if (MediaQuery.of(context).size.width <=
          MediaQuery.of(context).size.height) {
        animation = Tween<double>(begin: 1 / photos[index].aspectRatio, end: 1)
            .animate(animationController);
      } else {
        final double screenRatio = MediaQuery.of(context).size.height /
            MediaQuery.of(context).size.width;
        animation = Tween<double>(begin: screenRatio, end: 1)
            .animate(animationController);
      }
    } else {
      if (MediaQuery.of(context).size.width >=
          MediaQuery.of(context).size.height) {
        animation = Tween<double>(begin: photos[index].aspectRatio, end: 1)
            .animate(animationController);
      } else {
        final double screenRatio = MediaQuery.of(context).size.width /
            MediaQuery.of(context).size.height;
        animation = Tween<double>(begin: screenRatio, end: 1)
            .animate(animationController);
      }
    }
    return _AnimatedFullScreenPhoto(
        orientation: photos[index].aspectRatio >= 1
            ? Orientation.landscape
            : Orientation.portrait,
        animation: animation,
        child: PhotoView(
          filterQuality: FilterQuality.medium,
          imageProvider: CachedNetworkImageProvider(
            photoprismUrl +
                '/api/v1/t/' +
                photos[index].hash +
                '/public/fit_1920',
            headers: Provider.of<PhotoprismModel>(context)
                .photoprismAuth
                .getAuthHeaders(),
          ),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.contained * 2,
          scaleStateChangedCallback: (PhotoViewScaleState scaleState) {
            Provider.of<PhotoprismModel>(context)
                .photoprismCommonHelper
                .setPhotoViewScaleState(scaleState);
          },
          backgroundDecoration: BoxDecoration(color: Colors.transparent),
        ));
  }

  Widget getPreview(int index) {
    final String imageUrl =
        PhotoManager.getPhotoThumbnailUrl(context, index, widget.albumId);
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Center(
            child: Hero(
                tag: index.toString(),
                createRectTween: (Rect begin, Rect end) {
                  return RectTween(begin: begin, end: end);
                },
                child: CachedNetworkImage(
                  httpHeaders: Provider.of<PhotoprismModel>(context)
                      .photoprismAuth
                      .getAuthHeaders(),
                  width: MediaQuery.of(context).size.height *
                      photos[index].aspectRatio,
                  height: MediaQuery.of(context).size.width /
                      photos[index].aspectRatio,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  imageUrl: imageUrl,
                ))));
  }

  Widget pageview() => Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: PageView.builder(
        physics: isZoomed(context)
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          if (PhotoManager.getPhotos(context, widget.albumId)[index] == null) {
            PhotoManager.loadPhoto(context, index, widget.albumId);
            return Container();
          }

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
        itemCount: PhotoManager.getPhotosCount(context, widget.albumId),
        controller: pageController,
      ));

  Widget scrollNotificationListener(Widget child) =>
      NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            photoViewIsScrolling = true;
          } else if (scrollNotification is ScrollEndNotification) {
            photoViewIsScrolling = false;
          }
          return true;
        },
        child: child,
      );

  Future<void> animateAndPop(BuildContext context) async {
    await animationController.reverse();
    Navigator.of(context).pop();
  }

  Widget dismissibleIfNotZoomed(Widget child) {
    if (!isZoomed(context)) {
      return Draggable<Widget>(
        onDragStarted: () {
          setDragging(true);
          backgroundAnimationController.reverse();
        },
        onDragEnd: (DraggableDetails details) {
          if (details.offset.dy.abs() >
              MediaQuery.of(context).size.height / 4) {
            setState(() {
              photoPosition = details.offset;
            });
            animateAndPop(context);
          } else {
            setDragging(false);
            backgroundAnimationController.forward();
          }
        },
        key: const ValueKey<String>('photoViewDismissible'),
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
        setTouchCount(photoViewTouchCount + 1);
      },
      onPointerUp: (PointerUpEvent e) {
        setTouchCount(photoViewTouchCount - 1);
      },
      child: child);
  @override
  Widget build(BuildContext context) {
    photoprismUrl = Provider.of<PhotoprismModel>(context).photoprismUrl;
    photos = PhotoManager.getPhotos(context, widget.albumId);
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
                      key: const ValueKey<String>('PhotoView'),
                      child: scrollNotificationListener(pageview()),
                    ),
                    onTap: () => toggleAppBar(context)),
              )),
              if (showAppBar && !dragging)
                Positioned(
                    top: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: AppBar(
                      title: const Text(''),
                      actions: <Widget>[
                        /*IconButton(
                            icon: const Icon(Icons.archive),
                            tooltip: 'Archive photo',
                            onPressed: () {

                            },
                          ),*/
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Share photo',
                          onPressed: () {
                            sharePhoto(currentPhotoIndex, context);
                          },
                        )
                      ],
                      backgroundColor: Colors.transparent,
                    ))
              else
                Container(),
            ])));
  }

  Future<void> sharePhoto(int index, BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final List<int> photoBytes =
        await Api.downloadPhoto(model, photos[index].hash);

    if (photoBytes != null) {
      await Share.file('Photoprism Photo', photos[index].hash + '.jpg',
          photoBytes, 'image/jpg');
    }
  }
}

class _AnimatedFullScreenPhoto extends AnimatedWidget {
  const _AnimatedFullScreenPhoto(
      {Key key, Animation<double> animation, this.child, this.orientation})
      : super(key: key, listenable: animation);

  final Widget child;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
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
  const _AnimatedBackground(
      {Key key, Animation<double> animation, this.child, this.orientation})
      : super(key: key, listenable: animation);

  final Widget child;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return Container(
      color: Color.fromRGBO(0, 0, 0, animation.value),
      child: child,
    );
  }
}
