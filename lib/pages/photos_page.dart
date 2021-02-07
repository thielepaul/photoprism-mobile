import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/transparent_route.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:photoprism/widgets/filter_photos_dialog.dart';
import 'package:photoprism/widgets/selectable_tile.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class PhotosPage extends StatelessWidget {
  const PhotosPage({Key key, this.albumId}) : super(key: key);

  final int albumId;

  static Future<void> archiveSelectedPhotos(BuildContext context) async {
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    final List<String> selectedPhotos = model
        .gridController.value.selectedIndexes
        .map<String>((int element) => model.photos[element].photo.uid)
        .toList();

    PhotoManager.archivePhotos(context, selectedPhotos);
  }

  static void _selectAlbumBottomSheet(BuildContext context) {
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    if (model.albums == null) {
      Api.updateDb(model);
    }

    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext bc) {
          return ListView.builder(
              itemCount: model.albums == null ? 0 : model.albums.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return ListTile(
                  title: Text(model.albums[index].title),
                  onTap: () {
                    addPhotosToAlbum(index, context);
                  },
                );
              });
        });
  }

  static Future<void> _sharePhotos(BuildContext context) async {
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    final Map<String, List<int>> photos = <String, List<int>>{};
    model.photoprismLoadingScreen
        .showLoadingScreen('Preparing photos for sharing...');
    for (final int index in model.gridController.value.selectedIndexes) {
      final List<int> bytes =
          await Api.downloadPhoto(model, model.photos[index].file.hash);
      if (bytes == null) {
        model.photoprismLoadingScreen.hideLoadingScreen();
        return;
      }
      photos[model.photos[index].file.hash + '.jpg'] = bytes;
    }
    model.photoprismLoadingScreen.hideLoadingScreen();
    Share.files('Photoprism Photos', photos, 'image/jpg');
  }

  static Future<void> addPhotosToAlbum(
      int albumId, BuildContext context) async {
    Navigator.pop(context);

    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);
    final List<String> selectedPhotos = model
        .gridController.value.selectedIndexes
        .map<String>((int element) => model.photos[element].photo.uid)
        .toList();

    model.gridController.clear();
    AlbumManager.addPhotosToAlbum(context, albumId, selectedPhotos);
  }

  Text getMonthFromOffset(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final DateTime takenAt = model
        .photos[PhotoManager.getPhotoIndexInScrollView(context)].photo.takenAt;
    return Text('${takenAt.month}/${takenAt.year}');
  }

  Widget displayPhotoIfUrlLoaded(BuildContext context, int index) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (!(index < model.photos.length)) {
      return Container(
        color: Colors.grey[300],
      );
    }
    final String imageUrl =
        PhotoManager.getPhotoThumbnailUrl(context, index, albumId);
    if (imageUrl == null) {
      return Container(
        color: Colors.grey[300],
      );
    }
    return CachedNetworkImage(
      httpHeaders: model.photoprismAuth.getAuthHeaders(),
      alignment: Alignment.center,
      fit: BoxFit.contain,
      imageUrl: imageUrl,
      placeholder: (BuildContext context, String url) => Container(
        color: Colors.grey[300],
      ),
      errorWidget: (BuildContext context, String url, Object error) =>
          const Icon(Icons.error),
    );
  }

  static AppBar appBar(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    return AppBar(
      title: model.gridController.value.selectedIndexes.isNotEmpty
          ? Text(model.gridController.value.selectedIndexes.length.toString())
          : const Text('PhotoPrism'),
      backgroundColor: HexColor(model.applicationColor),
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
                  archiveSelectedPhotos(context);
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
                    value: 1,
                    child: const Text('filter_and_sort').tr(),
                  )
                ],
                onSelected: (int choice) {
                  if (choice == 0) {
                    model.photoprismUploader.selectPhotoAndUpload(context);
                  } else if (choice == 1) {
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

    final int tileCount = model.photos != null ? model.photos.length : 0;

    return RefreshIndicator(child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
      if (model.config == null) {
        Api.loadConfig(model);
      }
      if (model.dbTimestamps.isEmpty) {
        Api.updateDb(model);
        return const Text('', key: ValueKey<String>('photosGridView'));
      }

      return DraggableScrollbar.semicircle(
        labelTextBuilder: (double offset) => getMonthFromOffset(context),
        heightScrollThumb: 50.0,
        controller: _scrollController,
        child: DragSelectGridView(
            padding: const EdgeInsets.only(top: 0),
            key: const ValueKey<String>('photosGridView'),
            scrollController: _scrollController,
            gridController: gridController,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: orientation == Orientation.portrait ? 3 : 6,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: tileCount,
            itemBuilder: (BuildContext context, int index, bool selected) {
              return SelectableTile(
                  key: const ValueKey<String>('PhotoTile'),
                  index: index,
                  context: context,
                  gridController: gridController,
                  selected: selected,
                  onTap: () {
                    Provider.of<PhotoprismModel>(context, listen: false)
                        .photoprismCommonHelper
                        .setPhotoViewScaleState(PhotoViewScaleState.initial);
                    Navigator.push(
                        context,
                        TransparentRoute(
                          builder: (BuildContext context) =>
                              FullscreenPhotoGallery(index, albumId),
                        ));
                  },
                  child: Hero(
                    tag: index.toString(),
                    createRectTween: (Rect begin, Rect end) {
                      return RectTween(begin: begin, end: end);
                    },
                    child: displayPhotoIfUrlLoaded(context, index),
                  ));
            }),
      );
    }), onRefresh: () async {
      await Api.loadConfig(model);
      await Api.updateDb(model);
    });
  }
}
