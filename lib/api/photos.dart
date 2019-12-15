import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/pages/photoview.dart';

class Photos {
  List<Photo> photoList;
  bool isLoading = false;
  Album album;

  Photos();

  Photos.withAlbum(Album album) {
    this.album = album;
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
    isLoading = false;
  }

  Future loadPhotos(String photoprismUrl) async {
    var url = photoprismUrl + '/api/v1/photos?count=100';
    if (this.album != null) {
      url += "&album=" + this.album.id;
    }
    http.Response response =
    await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    photoList = parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
  }

  GridView getGridView(String photoprismUrl, ScrollController scrollController) {
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
              child: Image.network(
                photoprismUrl +
                    '/api/v1/thumbnails/' +
                    photoList[index].fileHash +
                    '/tile_224',
              ),
            ),
          );
        });

    return photosGridView;
  }
}
