import 'package:flutter/material.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/pages/photos_page.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumDetailView extends StatelessWidget {
  AlbumDetailView(this._album, this._albumId, BuildContext context)
      : _renameAlbumTextFieldController = TextEditingController(),
        _model = Provider.of<PhotoprismModel>(context);

  final PhotoprismModel _model;
  final Album _album;
  final int _albumId;
  final TextEditingController _renameAlbumTextFieldController;

  Future<void> _renameAlbum(BuildContext context) async {
    _model.photoprismLoadingScreen.showLoadingScreen('Renaming album...');

    // rename remote album
    final int status = await Api.renameAlbum(
        _album.uid, _renameAlbumTextFieldController.text, _model);

    await Api.updateDb(_model);

    await _model.photoprismLoadingScreen.hideLoadingScreen();
    // close rename dialog
    Navigator.pop(context);

    // check renaming success
    if (status != 0) {
      _model.photoprismMessage.showMessage('Renaming album failed.');
    }
  }

  Future<void> _deleteAlbum(BuildContext context) async {
    _model.photoprismLoadingScreen.showLoadingScreen('Deleting album...');

    // delete remote album
    final int status = await Api.deleteAlbum(_album.uid, _model);

    await _model.photoprismLoadingScreen.hideLoadingScreen();

    // close delete dialog
    Navigator.pop(context);
    // check if successful
    if (status != 0) {
      _model.photoprismMessage.showMessage('Deleting album failed.');
    } else {
      // go back to albums view
      Navigator.pop(context);
      await Api.updateDb(_model);
    }
  }

  Future<void> _removePhotosFromAlbum(BuildContext context) async {
    _model.photoprismLoadingScreen.showLoadingScreen('Removing photos...');

    // save all selected photos in list
    final List<String> selectedPhotos = <String>[];
    for (final int photoId in _model.gridController.value.selectedIndexes) {
      selectedPhotos.add(_model.photos[photoId].photo.uid);
    }

    // remove remote photos from album
    final int status =
        await Api.removePhotosFromAlbum(_album.uid, selectedPhotos, _model);

    // check if successful
    if (status != 0) {
      _model.photoprismMessage
          .showMessage('Removing photos from album failed.');
    } else {
      await Api.updateDb(_model);
    }
    // deselect selected photos
    _model.gridController.clear();
    _model.photoprismLoadingScreen.hideLoadingScreen();
  }

  @override
  Widget build(BuildContext context) {
    final int _selectedPhotosCount =
        _model.gridController.value.selectedIndexes.length;
    return NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: _selectedPhotosCount > 0
                    ? Text(_selectedPhotosCount.toString())
                    : Text(_album.title),
                centerTitle: _selectedPhotosCount > 0 ? false : null,
              ),
              leading: _selectedPhotosCount > 0
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _model.gridController.clear();
                      },
                    )
                  : null,
              actions: _selectedPhotosCount > 0
                  ? <Widget>[
                      PopupMenuButton<int>(
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<int>>[
                          const PopupMenuItem<int>(
                            value: 2,
                            child: Text('Remove from album'),
                          ),
                        ],
                        onSelected: (int choice) {
                          _removePhotosFromAlbum(context);
                        },
                      ),
                    ]
                  : <Widget>[
                      // overflow menu
                      PopupMenuButton<int>(
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<int>>[
                          const PopupMenuItem<int>(
                            value: 0,
                            child: Text('Rename album'),
                          ),
                          const PopupMenuItem<int>(
                            value: 1,
                            child: Text('Delete album'),
                          ),
                        ],
                        onSelected: (int choice) {
                          if (choice == 0) {
                            _showRenameAlbumDialog(context);
                          } else if (choice == 1) {
                            _showDeleteAlbumDialog(context);
                          }
                        },
                      ),
                    ],
            ),
          ];
        },
        body: Container(
            color: Colors.white, child: PhotosPage(albumId: _albumId)));
  }

  Future<void> _showRenameAlbumDialog(BuildContext context) async {
    _renameAlbumTextFieldController.text = _album.title;
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Rename album'),
            content: TextField(
              controller: _renameAlbumTextFieldController,
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: const Text('Rename album'),
                onPressed: () {
                  _renameAlbum(context);
                },
              )
            ],
          );
        });
  }

  Future<void> _showDeleteAlbumDialog(BuildContext albumContext) async {
    return showDialog(
        context: albumContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete album?'),
            content: const Text(
                'Are you sure you want to delete this album? Your photos will not be deleted.'),
            actions: <Widget>[
              FlatButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: const Text('Delete album'),
                onPressed: () {
                  _deleteAlbum(albumContext);
                },
              )
            ],
          );
        });
  }
}
