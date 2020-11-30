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
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:photoprism/widgets/selectable_tile.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class PhotosPage extends StatelessWidget {
  const PhotosPage({Key key, this.albumId, this.videosPage = false})
      : super(key: key);

  final int albumId;
  final bool videosPage;

  static Future<void> archiveSelectedPhotos(
      BuildContext context, bool videosPage) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final List<String> selectedPhotos = model
        .gridController.selection.selectedIndexes
        .map<String>((int element) =>
            PhotoManager.getPhotos(context, null, videosPage)[element].uid)
        .toList();

    PhotoManager.archivePhotos(context, selectedPhotos);
  }

  static void _selectAlbumBottomSheet(BuildContext context, bool videosPage) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (model.albums == null) {
      AlbumManager.loadAlbums(context, 0);
    }

    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext bc) {
          return ListView.builder(
              itemCount: model.albums == null ? 0 : model.albums.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return ListTile(
                  title: Text(model.albums[index].name),
                  onTap: () {
                    addPhotosToAlbum(index, context, videosPage);
                  },
                );
              });
        });
  }

  static Future<void> _sharePhotos(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final Map<String, List<int>> photos = <String, List<int>>{};
    model.photoprismLoadingScreen
        .showLoadingScreen('Preparing photos for sharing...');
    for (final int index in model.gridController.selection.selectedIndexes) {
      final List<int> bytes =
          await Api.downloadPhoto(model, model.photos[index].hash);
      if (bytes == null) {
        model.photoprismLoadingScreen.hideLoadingScreen();
        return;
      }
      photos[model.photos[index].hash + '.jpg'] = bytes;
    }
    model.photoprismLoadingScreen.hideLoadingScreen();
    Share.files('Photoprism Photos', photos, 'image/jpg');
  }

  static Future<void> addPhotosToAlbum(
      int albumId, BuildContext context, bool videosPage) async {
    Navigator.pop(context);

    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final List<String> selectedPhotos = model
        .gridController.selection.selectedIndexes
        .map<String>((int element) =>
            PhotoManager.getPhotos(context, null, videosPage)[element].uid)
        .toList();

    model.gridController.clear();
    AlbumManager.addPhotosToAlbum(context, albumId, selectedPhotos);
  }

  Text getMonthFromOffset(
      BuildContext context, ScrollController scrollController) {
    for (final MomentsTime m
        in PhotoManager.getCummulativeMonthCount(context)) {
      if (m.count >= PhotoManager.getPhotoIndexInScrollView(context, albumId)) {
        return Text('${m.month}/${m.year}');
      }
    }
    return const Text('');
  }

  Widget displayPhotoIfUrlLoaded(BuildContext context, int index) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final String imageUrl =
        PhotoManager.getPhotoThumbnailUrl(context, index, albumId, videosPage);
    if (imageUrl == null) {
      PhotoManager.loadPhoto(context, index, albumId, videosPage);
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

  static AppBar appBar(BuildContext context, bool videosPage) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    return AppBar(
      title: model.gridController.selection.selectedIndexes.isNotEmpty
          ? Text(
              model.gridController.selection.selectedIndexes.length.toString())
          : const Text('PhotoPrism'),
      backgroundColor: HexColor(model.applicationColor),
      leading: model.gridController.selection.selectedIndexes.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                model.gridController.clear();
              },
            )
          : null,
      actions: model.gridController.selection.selectedIndexes.isNotEmpty
          ? <Widget>[
              IconButton(
                icon: const Icon(Icons.archive),
                tooltip: 'archive_photos'.tr(),
                onPressed: () {
                  archiveSelectedPhotos(context, videosPage);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'add_to_album'.tr(),
                onPressed: () {
                  _selectAlbumBottomSheet(context, videosPage);
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
                  )
                ],
                onSelected: (int choice) {
                  if (choice == 0) {
                    model.photoprismUploader.selectPhotoAndUpload(context);
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

    final int tileCount =
        PhotoManager.getPhotosCount(context, albumId, videosPage);

    //if (Photos.getPhotoList(context, albumId).length == 0) {
    //  return IconButton(onPressed: () => {}, icon: Icon(Icons.add));
    //}
    return RefreshIndicator(child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
      if (videosPage && model.config == null) {
        Api.loadConfig(model);
        return const Text('', key: ValueKey<String>('videosGridView'));
      }
      if (albumId == null && model.momentsTime == null) {
        PhotoManager.loadMomentsTime(context);
        return const Text('', key: ValueKey<String>('photosGridView'));
      }

      return DraggableScrollbar.semicircle(
        labelTextBuilder: albumId == null
            ? (double offset) => getMonthFromOffset(context, _scrollController)
            : null,
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
                    Provider.of<PhotoprismModel>(context)
                        .photoprismCommonHelper
                        .setPhotoViewScaleState(PhotoViewScaleState.initial);
                    Navigator.push(
                        context,
                        TransparentRoute(
                          builder: (BuildContext context) =>
                              FullscreenPhotoGallery(
                                  index, albumId, videosPage),
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
      if (albumId != null) {
        await AlbumManager.loadAlbums(context, 0,
            forceReload: true, loadPhotosForAlbumId: albumId);
      } else if (videosPage) {
        PhotoManager.saveAndSetPhotos(context, <int, Photo>{}, null, true);
        await Api.loadConfig(model);
      } else {
        return await PhotoManager.loadMomentsTime(context, forceReload: true);
      }
    });
  }
}
