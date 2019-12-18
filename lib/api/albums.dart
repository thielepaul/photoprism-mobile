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

class Albums {
  List<Album> albumList;

  Future loadAlbumsFromNetworkOrCache(
      BuildContext context, String photoprismUrl) async {
    var key = 'albumList';
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey(key)) {
      final parsed =
          json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
      albumList = parsed.map<Album>((json) => Album.fromJson(json)).toList();
      return;
    }
    await loadAlbums(context, photoprismUrl);
  }

  Future loadAlbums(BuildContext context, String photoprismUrl) async {
    http.Response response =
        await http.get(photoprismUrl + '/api/v1/albums?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    albumList = parsed.map<Album>((json) => Album.fromJson(json)).toList();

    Provider.of<PhotoprismModel>(context).setAlbumList(albumList);
  }

  GridView getGridView(String photoprismUrl) {
    GridView photosGridView = GridView.builder(
        key: ValueKey('albumsGridView'),
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: albumList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
                Photos.loadPhotosFromNetworkOrCache(
                    context, photoprismUrl, albumList[index].id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AlbumView(context, albumList[index], photoprismUrl)),
                );
              },
              child: GridTile(
                child: CachedNetworkImage(
                  imageUrl: photoprismUrl +
                      '/api/v1/albums/' +
                      albumList[index].id +
                      '/thumbnail/tile_500',
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
                footer: GestureDetector(
                  child: GridTileBar(
                    backgroundColor: Colors.black45,
                    title: _GridTitleText(albumList[index].name),
                  ),
                ),
              ));
        });

    return photosGridView;
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
