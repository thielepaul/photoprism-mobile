import 'dart:convert';
import 'dart:ffi';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Photos {
  static Future loadPhotosFromNetworkOrCache(
      BuildContext context, String photoprismUrl, String albumId) async {
    print("loadPhotosFromNetworkOrCache: AlbumID:" + albumId);
    var key = 'photosList';
    key += albumId;
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey(key)) {
      final parsed =
          json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
      List<Photo> photoList =
          parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
      Provider.of<PhotoprismModel>(context).setPhotoList(photoList);
      if (albumId == "") {
        Provider.of<PhotoprismModel>(context).setPhotoList(photoList);
      } else {
        Provider.of<PhotoprismModel>(context)
            .setPhotoListOfAlbum(photoList, albumId);
      }
      return;
    }
    await loadPhotos(context, photoprismUrl, albumId);
  }

  static Future loadMorePhotos(
      BuildContext context, String photoprismUrl, String albumId) async {
    if (Provider.of<PhotoprismModel>(context, listen: false).isLoading) {
      return;
    }
    Provider.of<PhotoprismModel>(context).isLoading = true;
    print("loading more photos");
    List<Photo> photoList;
    if (albumId == "") {
      photoList =
          Provider.of<PhotoprismModel>(context, listen: false).photoList;
    } else {
      photoList = Provider.of<PhotoprismModel>(context, listen: false)
          .albums[albumId]
          .photoList;
    }

    var url = photoprismUrl +
        '/api/v1/photos?count=100&offset=' +
        photoList.length.toString();
    if (albumId != "") {
      url += "&album=" + albumId;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
    photoList
        .addAll(parsed.map<Photo>((json) => Photo.fromJson(json)).toList());

    if (albumId == "") {
      Provider.of<PhotoprismModel>(context).setPhotoList(photoList);
    } else {
      Provider.of<PhotoprismModel>(context)
          .setPhotoListOfAlbum(photoList, albumId);
    }
    Provider.of<PhotoprismModel>(context).isLoading = false;
  }

  static Future loadPhotos(
      BuildContext context, String photoprismUrl, String albumId) async {
    var url = photoprismUrl + '/api/v1/photos?count=100';
    if (albumId != "") {
      url += "&album=" + albumId;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
    List<Photo> photoList =
        parsed.map<Photo>((json) => Photo.fromJson(json)).toList();

    if (albumId == "") {
      Provider.of<PhotoprismModel>(context).setPhotoList(photoList);
    } else {
      Provider.of<PhotoprismModel>(context)
          .setPhotoListOfAlbum(photoList, albumId);
    }
  }

  static Color selectedColor(BuildContext context, bool selected) {
    if (selected) {
      return HexColor(Provider.of<PhotoprismModel>(context).applicationColor);
    }
    return Color(0x00000000);
  }

  static List<Photo> getPhotoList(context, String albumId) {
    List<Photo> photoList;
    if (albumId == "") {
      photoList =
          Provider.of<PhotoprismModel>(context, listen: false).photoList;
    } else {
      photoList = Provider.of<PhotoprismModel>(context, listen: false)
          .albums[albumId]
          .photoList;
    }
    return photoList;
  }

  static Consumer<PhotoprismModel> getGridView(BuildContext context,
      String photoprismUrl, ScrollController scrollController, String albumId) {
    return Consumer<PhotoprismModel>(
      builder: (context, photoprismModel, child) {
        print("getGridView: AlbumID:" + albumId);
        final DragSelectGridViewController gridController =
            DragSelectGridViewController();
        if (Photos.getPhotoList(context, albumId) == null) {
          return Text("loading");
        }
        return DragSelectGridView(
            key: ValueKey('photosGridView'),
            // controller: scrollController,
            gridController: gridController,
            gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: Photos.getPhotoList(context, albumId).length,
            itemBuilder: (context, index, selected) {
              return Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PhotoView(
                              index,
                              Photos.getPhotoList(context, albumId),
                              photoprismUrl)),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: photoprismUrl +
                        '/api/v1/thumbnails/' +
                        Photos.getPhotoList(context, albumId)[index].fileHash +
                        '/tile_224',
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    color: selectedColor(context, selected),
                    colorBlendMode: BlendMode.hardLight,
                  ),
                ),
              );
            });
      },
    );
  }
}
