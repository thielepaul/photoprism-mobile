import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/transparent_route.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:photoprism/widgets/selectable_tile.dart';
import 'package:provider/provider.dart';

class PhotosPage extends StatelessWidget {
  final int albumId;

  PhotosPage({Key key, this.albumId});

  archiveSelectedPhotos(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    List<String> selectedPhotos = [];

    model.gridController.selection.selectedIndexes.forEach((element) {
      selectedPhotos
          .add(PhotoManager.getPhotos(context, null)[element].photoUUID);
    });

    PhotoManager.archivePhotos(context, selectedPhotos, albumId);
  }

  void _selectAlbumBottomSheet(context) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return ListView.builder(
              itemCount: model.albums == null ? 0 : model.albums.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return ListTile(
                  title: Text(model.albums[index].name),
                  onTap: () {
                    addPhotosToAlbum(index, context);
                  },
                );
              });
        });
  }

  addPhotosToAlbum(int albumId, BuildContext context) async {
    Navigator.pop(context);

    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    List<String> selectedPhotos = [];

    model.gridController.selection.selectedIndexes.forEach((element) {
      selectedPhotos
          .add(PhotoManager.getPhotos(context, null)[element].photoUUID);
    });

    model.gridController.clear();
    AlbumManager.addPhotosToAlbum(context, albumId, selectedPhotos);
  }

  Text getMonthFromOffset(
      BuildContext context, ScrollController scrollController) {
    for (MomentsTime m in PhotoManager.getCummulativeMonthCount(context)) {
      if (m.count >= PhotoManager.getPhotoIndexInScrollView(context, albumId)) {
        return Text("${m.month}/${m.year}");
      }
    }
    return Text("");
  }

  Widget displayPhotoIfUrlLoaded(BuildContext context, int index) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    String imageUrl =
        PhotoManager.getPhotoThumbnailUrl(context, index, albumId);
    if (imageUrl == null) {
      PhotoManager.loadPhoto(context, index, albumId);
      return Container(
        color: Colors.grey[300],
      );
    }
    return CachedNetworkImage(
      httpHeaders: model.photoprismHttpBasicAuth.getAuthHeader(),
      alignment: Alignment.center,
      fit: BoxFit.contain,
      imageUrl: imageUrl,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final ScrollController _scrollController = model.scrollController;

    DragSelectGridViewController gridController =
        Provider.of<PhotoprismModel>(context)
            .photoprismCommonHelper
            .getGridController();

    int tileCount = PhotoManager.getPhotosCount(context, albumId);

    //if (Photos.getPhotoList(context, albumId).length == 0) {
    //  return IconButton(onPressed: () => {}, icon: Icon(Icons.add));
    //}
    return Scaffold(
        appBar: albumId == null
            ? AppBar(
                title: model.gridController.selection.selectedIndexes.length > 0
                    ? Text(model.gridController.selection.selectedIndexes.length
                        .toString())
                    : Text("PhotoPrism"),
                backgroundColor: HexColor(model.applicationColor),
                leading:
                    model.gridController.selection.selectedIndexes.length > 0
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              model.gridController.selection = Selection({});
                            },
                          )
                        : null,
                actions:
                    model.gridController.selection.selectedIndexes.length > 0
                        ? <Widget>[
                            IconButton(
                              icon: const Icon(Icons.archive),
                              tooltip: 'Archive photos',
                              onPressed: () {
                                archiveSelectedPhotos(context);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Add to album',
                              onPressed: () {
                                _selectAlbumBottomSheet(context);
                              },
                            ),
                          ]
                        : <Widget>[
                            PopupMenuButton<int>(
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem(
                                  value: 0,
                                  child: Text('Upload photo'),
                                )
                              ],
                              onSelected: (choice) {
                                if (choice == 0) {
                                  model.photoprismUploader
                                      .selectPhotoAndUpload(context);
                                }
                              },
                            ),
                          ],
              )
            : null,
        body: RefreshIndicator(
            child: OrientationBuilder(builder: (context, orientation) {
          if (albumId == null && model.momentsTime == null) {
            PhotoManager.loadMomentsTime(context);
            return Text("", key: ValueKey("photosGridView"));
          }

          return DraggableScrollbar.semicircle(
            labelTextBuilder: albumId == null
                ? (double offset) =>
                    getMonthFromOffset(context, _scrollController)
                : null,
            heightScrollThumb: 50.0,
            controller: _scrollController,
            child: DragSelectGridView(
                key: ValueKey('photosGridView'),
                scrollController: _scrollController,
                gridController: gridController,
                physics: AlwaysScrollableScrollPhysics(),
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: orientation == Orientation.portrait ? 3 : 6,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: tileCount,
                itemBuilder: (context, index, selected) {
                  return SelectableTile(
                      key: ValueKey("PhotoTile"),
                      index: index,
                      context: context,
                      gridController: gridController,
                      selected: selected,
                      onTap: () {
                        Provider.of<PhotoprismModel>(context)
                            .photoprismCommonHelper
                            .setPhotoViewScaleState(
                                PhotoViewScaleState.initial);
                        Navigator.push(
                            context,
                            TransparentRoute(
                              builder: (context) =>
                                  FullscreenPhotoGallery(index, albumId),
                            ));
                      },
                      child: Hero(
                        tag: index.toString(),
                        createRectTween: (begin, end) {
                          return RectTween(begin: begin, end: end);
                        },
                        child: displayPhotoIfUrlLoaded(
                          context,
                          index,
                        ),
                      ));
                }),
          );
        }), onRefresh: () async {
          if (albumId == null) {
            return await PhotoManager.loadMomentsTime(context,
                forceReload: true);
          } else {
            await AlbumManager.loadAlbums(context, 0,
                forceReload: true, loadPhotosForAlbumId: albumId);
          }
        }));
  }
}
