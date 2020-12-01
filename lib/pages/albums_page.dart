import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/album_detail_view.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({Key key}) : super(key: key);

  static String getAlbumPreviewUrl(BuildContext context, int index) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (model.albums != null &&
        model.albums[index] != null &&
        model.albums[index].imageCount > 0) {
      return model.photoprismUrl +
          '/api/v1/albums/' +
          model.albums[index].id +
          '/t/public/tile_500';
    } else {
      return 'https://raw.githubusercontent.com/photoprism/photoprism-mobile/master/assets/emptyAlbum.jpg';
    }
  }

  Future<void> createAlbum(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    model.photoprismLoadingScreen
        .showLoadingScreen('create_album'.tr() + '...');
    final String uuid = await Api.createAlbum('New album', model);

    if (uuid == '-1') {
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage('Creating album failed.');
    } else {
      await AlbumManager.loadAlbums(context, 0, forceReload: true);
      await model.photoprismLoadingScreen.hideLoadingScreen();

      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
            builder: (BuildContext ctx) => AlbumDetailView(
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
          title: const Text('PhotoPrism'),
          backgroundColor: HexColor(model.applicationColor),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'create_album'.tr(),
              onPressed: () {
                //model.photoprismAlbumManager.createAlbum();
                createAlbum(context);
              },
            ),
          ],
        ),
        body: RefreshIndicator(child: OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
          if (model.albums == null) {
            AlbumManager.loadAlbums(context, 0);
            return const Text('', key: ValueKey<String>('albumsGridView'));
          }
          return GridView.builder(
              key: const ValueKey<String>('albumsGridView'),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              padding: const EdgeInsets.all(10),
              itemCount: model.albums.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                              builder: (BuildContext ctx) => AlbumDetailView(
                                  model.albums[index], index, context)));
                    },
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: GridTile(
                          child: CachedNetworkImage(
                            httpHeaders: model.photoprismAuth.getAuthHeaders(),
                            imageUrl: getAlbumPreviewUrl(context, index),
                            placeholder: (BuildContext context, String url) =>
                                Container(color: Colors.grey),
                            errorWidget: (BuildContext context, String url,
                                    Object error) =>
                                const Icon(Icons.error),
                          ),
                          footer: GestureDetector(
                            child: GridTileBar(
                              backgroundColor: Colors.black45,
                              trailing: Text(
                                model.albums[index].imageCount.toString(),
                                style: const TextStyle(color: Colors.white),
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
