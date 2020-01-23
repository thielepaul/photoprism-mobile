import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class LazyTile extends StatefulWidget {
  final int index;
  final String albumId;
  final BuildContext context;

  LazyTile({Key key, this.index, this.albumId, this.context}) : super(key: key);

  _LazyTileState createState() => _LazyTileState(context);
}

class _LazyTileState extends State<LazyTile> {
  PhotoprismModel model;
  BuildContext context;
  bool isLoading = false;
  bool disposed = false;

  _LazyTileState(BuildContext context) {
    model = Provider.of<PhotoprismModel>(context);
  }

  Future<void> loadImageUrl() async {
    if (isLoading) {
      return;
    }
    isLoading = true;
    await model.photoprismPhotoManager
        .loadPhoto(widget.index, widget.albumId, model);
    if (disposed) {
      return;
    }
    setState(() {
      isLoading = false;
    });
  }

  String getImageUrl() {
    String filehash;
    if (widget.albumId == "") {
      if (model.photoprismPhotoManager.photos[widget.index] == null) {
        return null;
      }
      filehash = model.photoprismPhotoManager.photos[widget.index].fileHash;
    } else {
      if (model.photoprismPhotoManager.albumPhotos[widget.albumId] == null ||
          model.photoprismPhotoManager.albumPhotos[widget.albumId]
                  [widget.index] ==
              null) {
        return null;
      }
      filehash = model.photoprismPhotoManager
          .albumPhotos[widget.albumId][widget.index].fileHash;
    }
    return model.photoprismUrl + '/api/v1/thumbnails/' + filehash + '/tile_224';
  }

  Widget displayImageIfUrlLoaded() {
    String imageUrl = getImageUrl();
    if (imageUrl == null) {
      loadImageUrl();
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
    return displayImageIfUrlLoaded();
  }
}
