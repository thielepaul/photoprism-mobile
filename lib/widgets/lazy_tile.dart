import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class LazyTile extends StatefulWidget {
  final int index;
  final String albumId;

  LazyTile({Key key, this.index, this.albumId}) : super(key: key);

  _LazyTileState createState() => _LazyTileState();
}

class _LazyTileState extends State<LazyTile> {
  bool isLoading = false;
  bool disposed = false;

  Future<void> loadImageUrl(BuildContext context) async {
    if (isLoading) {
      return;
    }
    isLoading = true;
    await PhotoManager.loadPhoto(context, widget.index, widget.albumId);
    if (disposed) {
      return;
    }
    setState(() {
      isLoading = false;
    });
  }

  String getImageUrl(BuildContext context) {
    if (PhotoManager.getPhotos(context, widget.albumId)[widget.index] == null) {
      return null;
    }
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    String filehash =
        PhotoManager.getPhotos(context, widget.albumId)[widget.index].fileHash;
    return model.photoprismUrl + '/api/v1/thumbnails/' + filehash + '/tile_224';
  }

  Widget displayImageIfUrlLoaded(BuildContext context) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    String imageUrl = getImageUrl(context);
    if (imageUrl == null) {
      loadImageUrl(context);
      return Container(
        color: Colors.grey[300],
      );
    }
    return CachedNetworkImage(
      httpHeaders: model.photoprismHttpBasicAuth.getAuthHeader(),
      alignment: Alignment.center,
      fit: BoxFit.contain,
      imageUrl: imageUrl,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return displayImageIfUrlLoaded(context);
  }
}
