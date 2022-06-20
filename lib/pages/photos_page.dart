import 'dart:io' as io;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/api/db_api.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/transparent_route.dart';
import 'package:photoprism/model/filter_photos.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:photoprism/widgets/filter_photos_dialog.dart';
import 'package:photoprism/widgets/selectable_tile.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class PhotosPage extends StatelessWidget {
  const PhotosPage({Key? key, this.albumId}) : super(key: key);

  final int? albumId;

  static Future<void> _showArchiveDialog(BuildContext albumContext) async {
    return showDialog(
        context: albumContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Archive photos?'),
            content: const Text(
                'Are you sure you want to archive the selected photos?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text('Archive photos'),
                onPressed: () {
                  archiveSelectedPhotos(albumContext);
                },
              )
            ],
          );
        });
  }

  static Future<void> archiveSelectedPhotos(BuildContext context) async {
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    final List<Future<String?>> selectedPhotos = model
        .gridController.value.selectedIndexes
        .map<Future<String?>>(
            (int element) async => (await model.photos![element])!.photo.uid)
        .toList();

    PhotoManager.archivePhotos(context, await Future.wait(selectedPhotos));
  }

  static void _selectAlbumBottomSheet(BuildContext context) {
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    if (model.albums == null) {
      apiUpdateDb(model);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        builder: (_, ScrollController controller) => Column(
          children: <Widget>[
            ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: const Text(
                'Add to Album',
                style: TextStyle(fontSize: 24.0),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: model.albums?.length ?? 0,
                itemBuilder: (BuildContext ctxt, int index) {
                  return ListTile(
                    title: Text(model.albums![index].title!),
                    onTap: () {
                      addPhotosToAlbum(index, context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _sharePhotos(BuildContext context) async {
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    model.photoprismLoadingScreen
        .showLoadingScreen('Preparing photos for sharing...');
    final List<String> photoFiles = <String>[];
    final List<String> mimeTypes = <String>[];
    for (final int index in model.gridController.value.selectedIndexes) {
      final io.File? photoFile = await apiDownloadPhoto(
          model, (await model.photos![index])!.file.hash);
      if (photoFile != null) {
        photoFiles.add(photoFile.path);
        mimeTypes.add('image/jpg');
      }
    }
    model.photoprismLoadingScreen.hideLoadingScreen();
    await Share.shareFiles(photoFiles, mimeTypes: mimeTypes);
  }

  static Future<void> addPhotosToAlbum(
      int albumId, BuildContext context) async {
    Navigator.pop(context);

    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    final List<Future<String?>> selectedPhotos = model
        .gridController.value.selectedIndexes
        .map<Future<String?>>(
            (int element) async => (await model.photos![element])!.photo.uid)
        .toList();

    model.gridController.clear();
    albumManagerAddPhotosToAlbum(
        context, albumId, await Future.wait(selectedPhotos));
  }

  Text getMonthFromOffset(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final PhotoWithFile? photo =
        model.photos!.getNow(PhotoManager.getPhotoIndexInScrollView(context));
    if (photo == null) {
      return const Text('');
    }
    final DateTime takenAt = photo.photo.takenAt!;
    return Text('${takenAt.month}/${takenAt.year}');
  }

  Widget displayPhotoIfUrlLoaded(BuildContext context, int index) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (!(index < model.photos!.length)) {
      return Container(
        color: Theme.of(context).backgroundColor,
      );
    }

    return FutureBuilder<PhotoWithFile?>(
        future: model.photos![index],
        builder:
            (BuildContext context, AsyncSnapshot<PhotoWithFile?> snapshot) {
          if (snapshot.data == null) {
            return Container(
              color: Theme.of(context).backgroundColor,
            );
          }
          final PhotoWithFile? photo = snapshot.data;
          final String? imageUrl =
              PhotoManager.getPhotoThumbnailUrl(context, photo);
          if (imageUrl == null) {
            return Container(
              color: Theme.of(context).backgroundColor,
            );
          }
          return CachedNetworkImage(
            cacheKey: photo!.file.hash + 'tile_224',
            httpHeaders: model.photoprismAuth.getAuthHeaders(),
            alignment: Alignment.center,
            fit: BoxFit.contain,
            imageUrl: imageUrl,
            placeholder: (BuildContext context, String url) => Container(
              color: Theme.of(context).backgroundColor,
            ),
            errorWidget: (BuildContext context, String url, Object? error) =>
                Container(
              color: Theme.of(context).backgroundColor,
              child: const Icon(Icons.error),
              alignment: Alignment.center,
            ),
          );
        });
  }

  static AppBar appBar(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    return AppBar(
      title: model.gridController.value.selectedIndexes.isNotEmpty
          ? Text(model.gridController.value.selectedIndexes.length.toString())
          : const Text('PhotoPrism'),
      backgroundColor: HexColor(model.applicationColor!),
      leading: model.gridController.value.selectedIndexes.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                model.gridController.clear();
              },
            )
          : null,
      actions: model.gridController.value.selectedIndexes.isNotEmpty
          ? <Widget>[
              IconButton(
                icon: const Icon(Icons.archive),
                tooltip: 'archive_photos'.tr(),
                onPressed: () {
                  _showArchiveDialog(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'add_to_album'.tr(),
                onPressed: () {
                  _selectAlbumBottomSheet(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'share_photos'.tr(),
                onPressed: () {
                  _sharePhotos(context);
                },
              ),
            ]
          : <Widget>[
              PopupMenuButton<int>(
                itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(
                    value: 0,
                    child: const Text('upload_photo').tr(),
                  ),
                  PopupMenuItem<int>(
                      value: 1, child: const Text('list_default').tr()),
                  PopupMenuItem<int>(
                      value: 2, child: const Text('list_archive').tr()),
                  PopupMenuItem<int>(
                      value: 3, child: const Text('list_private').tr()),
                  PopupMenuItem<int>(
                    value: 4,
                    child: const Text('filter_and_sort').tr(),
                  )
                ],
                onSelected: (int choice) {
                  if (choice == 0) {
                    model.photoprismUploader.selectPhotoAndUpload(context);
                  } else if (choice == 1) {
                    model.filterPhotos!.list = PhotoList.Default;
                    model.updatePhotosSubscription();
                  } else if (choice == 2) {
                    model.filterPhotos!.list = PhotoList.Archive;
                    model.updatePhotosSubscription();
                  } else if (choice == 3) {
                    model.filterPhotos!.list = PhotoList.Private;
                    model.updatePhotosSubscription();
                  } else if (choice == 4) {
                    FilterPhotosDialog.show(context);
                  }
                },
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    final ScrollController _scrollController = model.scrollController;

    final DragSelectGridViewController gridController =
        Provider.of<PhotoprismModel>(context).gridController;

    final int tileCount = model.photos != null ? model.photos!.length : 0;

    return RefreshIndicator(
        child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: <PointerDeviceKind>{
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: OrientationBuilder(
                builder: (BuildContext context, Orientation orientation) {
              if (model.config == null) {
                apiLoadConfig(model);
              }
              if (model.dbTimestamps!.isEmpty) {
                apiUpdateDb(model, context: context);
                return const Text('', key: ValueKey<String>('photosGridView'));
              }

              return DraggableScrollbar.semicircle(
                backgroundColor: Theme.of(context).canvasColor,
                labelTextBuilder: (double offset) =>
                    getMonthFromOffset(context),
                heightScrollThumb: 50.0,
                controller: _scrollController,
                child: DragSelectGridView(
                    padding: const EdgeInsets.only(top: 0),
                    key: const ValueKey<String>('photosGridView'),
                    scrollController: _scrollController,
                    gridController: gridController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          orientation == Orientation.portrait ? 3 : 6,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: tileCount,
                    itemBuilder:
                        (BuildContext context, int index, bool selected) {
                      return SelectableTile(
                          key: const ValueKey<String>('PhotoTile'),
                          index: index,
                          context: context,
                          gridController: gridController,
                          selected: selected,
                          onTap: () {
                            Provider.of<PhotoprismModel>(context, listen: false)
                                .photoprismCommonHelper
                                .setPhotoViewScaleState(
                                    PhotoViewScaleState.initial);
                            Navigator.push(
                                context,
                                TransparentRoute(
                                  builder: (BuildContext context) =>
                                      FullscreenPhotoGallery(index, albumId),
                                ));
                          },
                          child: Hero(
                            tag: index.toString(),
                            createRectTween: (Rect? begin, Rect? end) {
                              return RectTween(begin: begin, end: end);
                            },
                            child: displayPhotoIfUrlLoaded(context, index),
                          ));
                    }),
              );
            })),
        onRefresh: () async {
          await apiLoadConfig(model);
          await apiUpdateDb(model);
        });
  }
}
