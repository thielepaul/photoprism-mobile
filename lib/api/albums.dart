import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/model/album.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/albumview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Albums extends StatelessWidget {
  final String photoprismUrl;

  const Albums({Key key, this.photoprismUrl}) : super(key: key);

  static Future loadAlbumsFromNetworkOrCache(
      PhotoprismModel model, String photoprismUrl) async {
    var key = 'albumList';
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey(key)) {
      final parsed =
          json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
      List<Album> albumList =
          parsed.map<Album>((json) => Album.fromJson(json)).toList();
      model.setAlbumList(albumList);
      return;
    }
    await loadAlbums(model, photoprismUrl);
  }

  static Future loadAlbums(PhotoprismModel model, String photoprismUrl) async {
    http.Response response =
        await http.get(photoprismUrl + '/api/v1/albums?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    List<Album> albumList =
        parsed.map<Album>((json) => Album.fromJson(json)).toList();

    model.setAlbumList(albumList);
  }

  static List<Album> getAlbumList(context) {
    Map<String, Album> albums =
        Provider.of<PhotoprismModel>(context, listen: false).albums;
    if (albums == null) {
      return null;
    }
    return albums.entries.map((e) => e.value).toList();
  }

  String getAlbumPreviewUrl(context, index) {
    if (Albums.getAlbumList(context)[index].imageCount <= 0) {
      return "https://raw.githubusercontent.com/photoprism/photoprism-mobile/master/assets/emptyAlbum.jpg";
    }
    else {
      return photoprismUrl +
          '/api/v1/albums/' +
          Albums.getAlbumList(context)[index].id +
          '/thumbnail/tile_500';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Albums.getAlbumList(context) == null) {
      return Text("loading", key: ValueKey("albumsGridView"));
    }
    return GridView.builder(
        key: ValueKey('albumsGridView'),
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: Albums.getAlbumList(context).length,
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
                print(Albums.getAlbumList(context)[index].photoList);
                Photos.loadPhotosFromNetworkOrCache(
                    Provider.of<PhotoprismModel>(context),
                    photoprismUrl,
                    Albums.getAlbumList(context)[index].id);
                Photos.loadPhotos(Provider.of<PhotoprismModel>(context),
                    Provider.of<PhotoprismModel>(context).photoprismUrl, Albums.getAlbumList(context)[index].id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AlbumView(context,
                          Albums.getAlbumList(context)[index], photoprismUrl)),
                );
              },
              child: GridTile(
                child: CachedNetworkImage(
                  imageUrl: getAlbumPreviewUrl(context, index),
                  placeholder: (context, url) => Container(color: Colors.grey),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
                footer: GestureDetector(
                  child: GridTileBar(
                    backgroundColor: Colors.black45,
                    title: _GridTitleText(
                        Albums.getAlbumList(context)[index].name),
                  ),
                ),
              ));
        });
  }
}

class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}
