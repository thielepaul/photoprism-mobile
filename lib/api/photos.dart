import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/common/transparent_route.dart';
import 'package:photoprism/model/photo.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:photoprism/widgets/selectable_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'albums.dart';

class PhotosPage extends StatelessWidget {
  final ScrollController _scrollController;
  final String albumId;

  PhotosPage({Key key, this.albumId}) : _scrollController = ScrollController();

  static Future loadPhotosFromNetworkOrCache(
      PhotoprismModel model, String photoprismUrl, String albumId) async {
    print("loadPhotosFromNetworkOrCache: AlbumID:" + albumId);
    var key = 'photosList';
    key += albumId;
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey(key)) {
      final parsed =
          json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
      List<Photo> photoList =
          parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
      if (albumId == "") {
        model.photoprismPhotoManager.setPhotoList(photoList);
      } else {
        model.photoprismAlbumManager.setPhotoListOfAlbum(photoList, albumId);
      }
      return;
    }
    await loadPhotos(model, photoprismUrl, albumId);
  }

  static Future<int> loadMorePhotos(
      PhotoprismModel model, String photoprismUrl, String albumId) async {
    if (model.isLoading) {
      return 0;
    }
    model.isLoading = true;
    print("loading more photos");
    List<Photo> photoList;
    if (albumId == "") {
      photoList = model.photoList;
    } else {
      photoList = model.albums[albumId].photoList;
    }

    var url = photoprismUrl +
        '/api/v1/photos?count=1000&offset=' +
        photoList.length.toString();
    if (albumId != "") {
      url += "&album=" + albumId;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
    photoList
        .addAll(parsed.map<Photo>((json) => Photo.fromJson(json)).toList());

    if (albumId == "") {
      model.photoprismPhotoManager.setPhotoList(photoList);
    } else {
      model.photoprismAlbumManager.setPhotoListOfAlbum(photoList, albumId);
    }
    model.isLoading = false;
    return (parsed.map<Photo>((json) => Photo.fromJson(json)).toList().length);
  }

  static Future loadPhotos(
      PhotoprismModel model, String photoprismUrl, String albumId) async {
    var url = photoprismUrl + '/api/v1/photos?count=1000';
    if (albumId != "") {
      url += "&album=" + albumId;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
    List<Photo> photoList =
        parsed.map<Photo>((json) => Photo.fromJson(json)).toList();

    if (albumId == "") {
      model.photoprismPhotoManager.setPhotoList(photoList);
    } else {
      model.photoprismAlbumManager.setPhotoListOfAlbum(photoList, albumId);
    }
    print("Loading more photos");
    int morePhotosCount = await loadMorePhotos(model, photoprismUrl, albumId);
    while (morePhotosCount > 0) {
      print("Loading more photos");
      morePhotosCount = await loadMorePhotos(model, photoprismUrl, albumId);
    }
  }

  static List<Photo> getPhotoList(context, String albumId) {
    List<Photo> photoList;
    if (albumId == "") {
      photoList =
          Provider.of<PhotoprismModel>(context, listen: false).photoList;
    } else {
      if (Provider.of<PhotoprismModel>(context, listen: false)
              .albums[albumId] !=
          null) {
        photoList = Provider.of<PhotoprismModel>(context, listen: false)
            .albums[albumId]
            .photoList;
      }
    }
    return photoList;
  }

  void _scrollListener() async {
    if (_scrollController.position.extentAfter < 500) {
      //await Photos.loadMorePhotos(
      //    Provider.of<PhotoprismModel>(context), photoprismUrl, albumId);
    }
  }

  Future<void> refreshPhotosPull(BuildContext context) async {
    print('refreshing photos..');
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await PhotosPage.loadPhotos(model, model.photoprismUrl, "");
    await PhotosPage.loadPhotosFromNetworkOrCache(
        model, model.photoprismUrl, "");
  }

  archiveSelectedPhotos(BuildContext context) async {
    List<String> selectedPhotos = [];
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    model.gridController.selection.selectedIndexes.forEach((element) {
      selectedPhotos
          .add(PhotosPage.getPhotoList(context, "")[element].photoUUID);
    });
    model.photoprismPhotoManager.archivePhotos(selectedPhotos);
  }

  _selectAlbumDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select album'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                  itemCount: AlbumsPage.getAlbumList(context).length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return GestureDetector(
                        onTap: () {
                          addPhotosToAlbum(
                              AlbumsPage.getAlbumList(context)[index].id,
                              context);
                        },
                        child: Card(
                            child: ListTile(
                                title: Text(
                                    AlbumsPage.getAlbumList(context)[index]
                                        .name))));
                  }),
            ),
          );
        });
  }

  addPhotosToAlbum(albumId, context) async {
    Navigator.pop(context);

    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    List<String> selectedPhotos = [];

    model.gridController.selection.selectedIndexes.forEach((element) {
      selectedPhotos
          .add(PhotosPage.getPhotoList(context, "")[element].photoUUID);
    });

    model.gridController.clear();
    model.photoprismAlbumManager.addPhotosToAlbum(albumId, selectedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    DragSelectGridViewController gridController =
        Provider.of<PhotoprismModel>(context)
            .photoprismCommonHelper
            .getGridController();

    _scrollController.addListener(_scrollListener);

    if (PhotosPage.getPhotoList(context, albumId) == null) {
      return Text("", key: ValueKey("photosGridView"));
    }
    //if (Photos.getPhotoList(context, albumId).length == 0) {
    //  return IconButton(onPressed: () => {}, icon: Icon(Icons.add));
    //}
    return Scaffold(
        appBar: albumId == ""
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
                                _selectAlbumDialog(context);
                              },
                            ),
                          ]
                        : <Widget>[
                            IconButton(
                              icon: const Icon(Icons.cloud_upload),
                              tooltip: 'Upload photo',
                              onPressed: () {
                                model.photoprismUploader.selectPhotoAndUpload();
                              },
                            )
                          ],
              )
            : null,
        body: RefreshIndicator(
            child: OrientationBuilder(builder: (context, orientation) {
          return DraggableScrollbar.semicircle(
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
                itemCount: PhotosPage.getPhotoList(context, albumId).length,
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
                        child: CachedNetworkImage(
                          alignment: Alignment.center,
                          fit: BoxFit.contain,
                          imageUrl: Provider.of<PhotoprismModel>(context)
                                  .photoprismUrl +
                              '/api/v1/thumbnails/' +
                              PhotosPage.getPhotoList(context, albumId)[index]
                                  .fileHash +
                              '/tile_224',
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      ));
                }),
          );
        }), onRefresh: () {
          refreshPhotosPull(context);
        }));
  }
}
