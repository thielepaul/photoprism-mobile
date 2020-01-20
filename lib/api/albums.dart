import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/album.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/album_detail_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({Key key}) : super(key: key);

  static Future loadAlbumsFromNetworkOrCache(
      PhotoprismModel model, String photoprismUrl) async {
    var key = 'albumList';
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey(key)) {
      final parsed =
          json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
      List<Album> albumList =
          parsed.map<Album>((json) => Album.fromJson(json)).toList();
      model.photoprismAlbumManager.setAlbumList(albumList);
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

    model.photoprismAlbumManager.setAlbumList(albumList);
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
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (AlbumsPage.getAlbumList(context)[index].imageCount <= 0) {
      return "https://raw.githubusercontent.com/photoprism/photoprism-mobile/master/assets/emptyAlbum.jpg";
    } else {
      return model.photoprismUrl +
          '/api/v1/albums/' +
          AlbumsPage.getAlbumList(context)[index].id +
          '/thumbnail/tile_500';
    }
  }

  Future<int> refreshAlbumsPull(BuildContext context) async {
    print('refreshing albums..');
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await AlbumsPage.loadAlbums(model, model.photoprismUrl);
    await AlbumsPage.loadAlbumsFromNetworkOrCache(model, model.photoprismUrl);
    return 0;
  }

  void createAlbum(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    var uuid = await Api.createAlbum("New album", model.photoprismUrl);

    if (uuid == "-1") {
      model.photoprismMessage.showMessage("Creating album failed.");
    } else {
      List<Album> albums = AlbumsPage.getAlbumList(context);

      int length = 0;
      if (albums != null) {
        length = albums.length;
      }

      albums.add(Album(id: uuid, name: "New album", imageCount: 0));
      model.photoprismAlbumManager.setAlbumList(albums);

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => AlbumDetailView(
                AlbumsPage.getAlbumList(context)[length], context)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (AlbumsPage.getAlbumList(context) == null) {
      return Text("loading", key: ValueKey("albumsGridView"));
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("PhotoPrism"),
          backgroundColor: HexColor(model.applicationColor),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create album',
              onPressed: () {
                //model.photoprismAlbumManager.createAlbum();
                createAlbum(context);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
            child: OrientationBuilder(builder: (context, orientation) {
          return GridView.builder(
              key: ValueKey('albumsGridView'),
              gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: const EdgeInsets.all(10),
              itemCount: AlbumsPage.getAlbumList(context).length,
              itemBuilder: (context, index) {
                return GestureDetector(
                    onTap: () {
                      PhotosPage.loadPhotosFromNetworkOrCache(
                          Provider.of<PhotoprismModel>(context),
                          model.photoprismUrl,
                          AlbumsPage.getAlbumList(context)[index].id);
                      PhotosPage.loadPhotos(
                          Provider.of<PhotoprismModel>(context),
                          Provider.of<PhotoprismModel>(context).photoprismUrl,
                          AlbumsPage.getAlbumList(context)[index].id);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => AlbumDetailView(
                                  AlbumsPage.getAlbumList(context)[index],
                                  context)));
                    },
                    child: ClipRRect(
                        borderRadius: new BorderRadius.circular(8.0),
                        child: GridTile(
                          child: CachedNetworkImage(
                            imageUrl: getAlbumPreviewUrl(context, index),
                            placeholder: (context, url) =>
                                Container(color: Colors.grey),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          footer: GestureDetector(
                            child: GridTileBar(
                              backgroundColor: Colors.black45,
                              trailing: Text(
                                AlbumsPage.getAlbumList(context)[index]
                                    .imageCount
                                    .toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                              title: _GridTitleText(
                                  AlbumsPage.getAlbumList(context)[index].name),
                            ),
                          ),
                        )));
              });
        }), onRefresh: () async {
          return await refreshAlbumsPull(context);
        }));
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
