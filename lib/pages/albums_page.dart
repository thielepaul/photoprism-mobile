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

  static String getAlbumPreviewUrl(context, int index) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (model.albums != null &&
        model.albums[index] != null &&
        model.albums[index].imageCount > 0) {
      return model.photoprismUrl +
          '/api/v1/albums/' +
          model.albums[index].id +
          '/thumbnail/tile_500';
    } else {
      return "https://raw.githubusercontent.com/photoprism/photoprism-mobile/master/assets/emptyAlbum.jpg";
    }
  }

  void createAlbum(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await model.photoprismLoadingScreen.showLoadingScreen("Creating album...");
    var uuid = await Api.createAlbum("New album", model);

    if (uuid == "-1") {
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage("Creating album failed.");
    } else {
      await AlbumManager.loadAlbums(context, 0, forceReload: true);
      await model.photoprismLoadingScreen.hideLoadingScreen();

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => AlbumDetailView(
                model.albums[model.albums.length - 1],
                model.albums.length - 1,
                context)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
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
          if (model.albums == null) {
            AlbumManager.loadAlbums(context, 0);
            return Text("", key: ValueKey("albumsGridView"));
          }
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
          return AlbumManager.loadAlbums(context, 0, forceReload: true);
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
