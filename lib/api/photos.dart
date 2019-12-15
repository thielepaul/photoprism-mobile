import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/pages/photoview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Photos {
  List<Photo> photoList;
  bool isLoading = false;
  Album album;

  Photos();

  Photos.withAlbum(Album album) {
    this.album = album;
  }

  Future loadPhotosFromNetworkOrCache(String photoprismUrl) async {
    var key = 'photosList';
    if (this.album != null) {
      key += album.id;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
      if (sp.containsKey(key)) {
        final parsed =
            json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
        photoList = parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
        return;
      }
    await loadPhotos(photoprismUrl);
  }

  Future savePhotoListToSharedPrefs() async {
    var key = 'photosList';
    if (this.album != null) {
      key += album.id;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(photoList));
  }

  Future loadMorePhotos(String photoprismUrl) async {
    if (isLoading) {
      return;
    }
    isLoading = true;
    print("loading more photos");
    var url = photoprismUrl +
        '/api/v1/photos?count=100&offset=' +
        photoList.length.toString();
    if (this.album != null) {
      url += "&album=" + this.album.id;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
    photoList
        .addAll(parsed.map<Photo>((json) => Photo.fromJson(json)).toList());
    await savePhotoListToSharedPrefs();
    isLoading = false;
  }

  Future loadPhotos(String photoprismUrl) async {
    var url = photoprismUrl + '/api/v1/photos?count=100';
    if (this.album != null) {
      url += "&album=" + this.album.id;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    photoList = parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
    await savePhotoListToSharedPrefs();
  }

  GridView getGridView(
      String photoprismUrl, ScrollController scrollController) {
    GridView photosGridView = GridView.builder(
        controller: scrollController,
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: photoList.length,
        itemBuilder: (context, index) {
          return Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PhotoView(index, photoList, photoprismUrl)),
                );
              },
              child: CachedNetworkImage(
                imageUrl: photoprismUrl +
                    '/api/v1/thumbnails/' +
                    photoList[index].fileHash +
                    '/tile_224',
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          );
        });

    return photosGridView;
  }
}
