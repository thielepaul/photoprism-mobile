import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/album_detail_view.dart';
import 'package:provider/provider.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({Key key}) : super(key: key);

  // static Future loadAlbumsFromNetworkOrCache(
  //     PhotoprismModel model, String photoprismUrl) async {
  //   var key = 'albumList';
  //   SharedPreferences sp = await SharedPreferences.getInstance();
  //   if (sp.containsKey(key)) {
  //     final parsed =
  //         json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
  //     List<Album> albumList =
  //         parsed.map<Album>((json) => Album.fromJson(json)).toList();
  //     model.photoprismAlbumManager.setAlbumList(albumList);
  //     return;
  //   }
  //   await loadAlbums(model, photoprismUrl);
  // }

  // static List<Album> getAlbumList(context) {
  //   Map<String, Album> albums =
  //       Provider.of<PhotoprismModel>(context, listen: false).albums;
  //   if (albums == null) {
  //     return null;
  //   }
  //   return albums.entries.map((e) => e.value).toList();
  // }

  static String getAlbumPreviewUrl(context, int index) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (model.albums[index].imageCount <= 0) {
      return "https://raw.githubusercontent.com/photoprism/photoprism-mobile/master/assets/emptyAlbum.jpg";
    } else {
      return model.photoprismUrl +
          '/api/v1/albums/' +
          model.albums[index].id +
          '/thumbnail/tile_500';
    }
  }

  // Future<int> refreshAlbumsPull(BuildContext context) async {
  //   print('refreshing albums..');
  //   final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
  //   await AlbumsPage.loadAlbums(model, model.photoprismUrl);
  //   await AlbumsPage.loadAlbumsFromNetworkOrCache(model, model.photoprismUrl);
  //   return 0;
  // }

  void createAlbum(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    var uuid = await Api.createAlbum("New album", model);

    if (uuid == "-1") {
      model.photoprismMessage.showMessage("Creating album failed.");
    } else {
      await AlbumManager.resetAlbums(context);

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //       builder: (ctx) => AlbumDetailView(
      //           AlbumsPage.getAlbumList(context)[length], context)),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (model.albums.length == 0) {
      AlbumManager.loadAlbums(context, 0);
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
              itemCount: model.albums.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => AlbumDetailView(
                                  model.albums[index], index, context)));
                    },
                    child: ClipRRect(
                        borderRadius: new BorderRadius.circular(8.0),
                        child: GridTile(
                          child: CachedNetworkImage(
                            httpHeaders:
                                model.photoprismHttpBasicAuth.getAuthHeader(),
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
                                model.albums[index].imageCount.toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                              title: _GridTitleText(model.albums[index].name),
                            ),
                          ),
                        )));
              });
        }), onRefresh: () async {
          return AlbumManager.resetAlbums(context);
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
