import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/transparent_route.dart';
import 'package:photoprism/model/photo.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:photoprism/widgets/selectable_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Photos extends StatelessWidget {
  final ScrollController _scrollController;
  final BuildContext context;
  final String albumId;

  Photos({Key key, this.context, this.albumId})
      : _scrollController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    DragSelectGridViewController gridController =
        Provider.of<PhotoprismModel>(context)
            .photoprismCommonHelper
            .getGridController();

    _scrollController.addListener(_scrollListener);

    if (Photos.getPhotoList(context, albumId) == null) {
      return Text("", key: ValueKey("photosGridView"));
    }
    //if (Photos.getPhotoList(context, albumId).length == 0) {
    //  return IconButton(onPressed: () => {}, icon: Icon(Icons.add));
    //}
    return OrientationBuilder(builder: (context, orientation) {
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
            itemCount: Photos.getPhotoList(context, albumId).length,
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
                        .setPhotoViewScaleState(PhotoViewScaleState.initial);
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
                      imageUrl:
                          Provider.of<PhotoprismModel>(context).photoprismUrl +
                              '/api/v1/thumbnails/' +
                              Photos.getPhotoList(context, albumId)[index]
                                  .fileHash +
                              '/tile_224',
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ));
            }),
      );
    });
  }
}
