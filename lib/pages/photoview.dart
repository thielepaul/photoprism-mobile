import 'dart:io' as io;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:share/share.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:easy_localization/easy_localization.dart';

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
  VideoPlayerController videoController;

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

    pageController.addListener(() {
      if (videoController != null) {
        videoController.pause();
      }
    });
  }

  @override
  void dispose() {
    if (videoController != null) {
      videoController.dispose();
    }
    super.dispose();
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
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    currentPhotoIndex = index;
    return FutureBuilder<PhotoWithFile>(
        future: model.photos[currentPhotoIndex],
        builder: (BuildContext context, AsyncSnapshot<PhotoWithFile> snapshot) {
          if (snapshot.data == null) {
            return Container();
          }
          final PhotoWithFile photo = snapshot.data;
          if (photo.file.aspectRatio >= 1) {
            if (MediaQuery.of(context).size.width <=
                MediaQuery.of(context).size.height) {
              animation =
                  Tween<double>(begin: 1 / photo.file.aspectRatio, end: 1)
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
              animation = Tween<double>(begin: photo.file.aspectRatio, end: 1)
                  .animate(animationController);
            } else {
              final double screenRatio = MediaQuery.of(context).size.width /
                  MediaQuery.of(context).size.height;
              animation = Tween<double>(begin: screenRatio, end: 1)
                  .animate(animationController);
            }
          }

          final Widget photoChild = PhotoView(
            loadingBuilder: (BuildContext context, ImageChunkEvent event) =>
                CachedNetworkImage(
              httpHeaders: Provider.of<PhotoprismModel>(context)
                  .photoprismAuth
                  .getAuthHeaders(),
              width:
                  MediaQuery.of(context).size.height * photo.file.aspectRatio,
              height:
                  MediaQuery.of(context).size.width / photo.file.aspectRatio,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              cacheKey: photo.file.hash + 'tile_224',
              imageUrl: PhotoManager.getPhotoThumbnailUrl(context, photo),
            ),
            filterQuality: FilterQuality.medium,
            imageProvider: CachedNetworkImageProvider(
              photoprismUrl +
                  '/api/v1/t/' +
                  photo.file.hash +
                  '/' +
                  model.config.previewToken +
                  '/fit_1920',
              cacheKey: photo.file.hash + 'fit_1920',
              headers: model.photoprismAuth.getAuthHeaders(),
            ),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.contained * 2,
            scaleStateChangedCallback: (PhotoViewScaleState scaleState) {
              model.photoprismCommonHelper.setPhotoViewScaleState(scaleState);
            },
            backgroundDecoration:
                const BoxDecoration(color: Colors.transparent),
          );

          final Widget videoChild =
              (videoController != null && videoController.value.isInitialized)
                  ? AspectRatio(
                      aspectRatio: videoController.value.aspectRatio,
                      child: VideoPlayer(videoController),
                    )
                  : Container();

          return _AnimatedFullScreenPhoto(
            orientation: photo.file.aspectRatio >= 1
                ? Orientation.landscape
                : Orientation.portrait,
            animation: animation,
            child: FutureBuilder<String>(
                future: Api.getVideoUrl(model, model.photos[currentPhotoIndex]),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.data == null) {
                    return Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Center(
                          child: photoChild,
                        ));
                  } else {
                    return Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Center(
                          child: videoController != null &&
                                  videoController.value.isPlaying &&
                                  videoController.dataSource == snapshot.data
                              ? videoChild
                              : photoChild,
                        ),
                        floatingActionButton: FloatingActionButton(
                          onPressed: () {
                            if (videoController == null ||
                                videoController.dataSource != snapshot.data) {
                              if (videoController != null) {
                                videoController.dispose();
                              }
                              model.photoprismLoadingScreen
                                  .showLoadingScreen('loading video');
                              videoController =
                                  VideoPlayerController.network(snapshot.data)
                                    ..initialize().then((_) {
                                      model.photoprismLoadingScreen
                                          .hideLoadingScreen();
                                      videoController.setLooping(true);
                                      setState(() {
                                        videoController.play();
                                      });
                                    });
                            } else {
                              setState(() {
                                if (videoController.value.isPlaying) {
                                  videoController.pause();
                                } else {
                                  videoController.seekTo(const Duration());
                                  videoController.play();
                                }
                              });
                            }
                          },
                          child: Icon(
                            videoController != null &&
                                    videoController.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ));
                  }
                }),
          );
        });
  }

  Widget getPreview(int index) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    return FutureBuilder<PhotoWithFile>(
        future: model.photos[index],
        builder: (BuildContext context, AsyncSnapshot<PhotoWithFile> snapshot) {
          if (snapshot.data == null) {
            return Container();
          }
          final PhotoWithFile photo = snapshot.data;
          final String imageUrl =
              PhotoManager.getPhotoThumbnailUrl(context, photo);
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
                        cacheKey: photo.file.hash + 'tile_224',
                        httpHeaders: Provider.of<PhotoprismModel>(context)
                            .photoprismAuth
                            .getAuthHeaders(),
                        width: MediaQuery.of(context).size.height *
                            photo.file.aspectRatio,
                        height: MediaQuery.of(context).size.width /
                            photo.file.aspectRatio,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        imageUrl: imageUrl,
                      ))));
        });
  }

  Widget pageview() => Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: PageView.builder(
        physics: isZoomed(context)
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
          if (model.photos == null) {
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
        itemCount: Provider.of<PhotoprismModel>(context).photos.length,
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
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    photoprismUrl = model.photoprismUrl;
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
                        ),
                      ],
                      backgroundColor: Colors.transparent,
                    ))
              else
                Container(),
            ])));
  }

  Future<void> sharePhoto(int index, BuildContext context) async {
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);

    final String videoUrl = await Api.getVideoUrl(model, model.photos[index]);

    if (videoUrl != null) {
      return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('share_photo_or_video').tr(),
              actions: <Widget>[
                TextButton(
                  child: const Text('video').tr(),
                  onPressed: () {
                    shareVideoFile(index, model);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('photo').tr(),
                  onPressed: () {
                    sharePhotoFile(index, model);
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    }

    return sharePhotoFile(index, model);
  }

  Future<void> sharePhotoFile(int index, PhotoprismModel model) async {
    final io.File photoFile =
        await Api.downloadPhoto(model, (await model.photos[index]).file.hash);

    if (photoFile != null) {
      await Share.shareFiles(<String>[photoFile.path],
          mimeTypes: <String>['image/jpg']);
    }
  }

  Future<void> shareVideoFile(int index, PhotoprismModel model) async {
    final io.File videoFile =
        await Api.downloadVideo(model, model.photos[index]);

    if (videoFile != null) {
      await Share.shareFiles(<String>[videoFile.path],
          mimeTypes: <String>['video/mp4']);
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
