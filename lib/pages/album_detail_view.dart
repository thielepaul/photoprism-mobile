import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/pages/photos_page.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumDetailView extends StatelessWidget {
  final PhotoprismModel _model;
  final Album _album;
  final int _albumId;
  final TextEditingController _renameAlbumTextFieldController;

  AlbumDetailView(this._album, this._albumId, context)
      : _renameAlbumTextFieldController = new TextEditingController(),
        _model = Provider.of<PhotoprismModel>(context);

  void _renameAlbum(BuildContext context) async {
    await _model.photoprismLoadingScreen.showLoadingScreen("Renaming album...");

    // rename remote album
    var status = await Api.renameAlbum(
        _album.id, _renameAlbumTextFieldController.text, _model);

    await AlbumManager.loadAlbums(context, 0, forceReload: true);

    await _model.photoprismLoadingScreen.hideLoadingScreen();
    // close rename dialog
    Navigator.pop(context);

    // check renaming success
    if (status != 0) {
      _model.photoprismMessage.showMessage("Renaming album failed.");
    }
  }

  void _deleteAlbum(BuildContext context) async {
    await _model.photoprismLoadingScreen.showLoadingScreen("Deleting album...");

    // delete remote album
    var status = await Api.deleteAlbum(_album.id, _model);

    await _model.photoprismLoadingScreen.hideLoadingScreen();

    // close delete dialog
    Navigator.pop(context);
    // check if successful
    if (status != 0) {
      _model.photoprismMessage.showMessage("Deleting album failed.");
    } else {
      // go back to albums view
      await AlbumManager.loadAlbums(context, 0, forceReload: true);
      Navigator.pop(context);
    }
  }

  void _removePhotosFromAlbum(BuildContext context) async {
    _model.photoprismLoadingScreen.showLoadingScreen("Removing photos...");

    // save all selected photos in list
    List<String> selectedPhotos = [];
    _model.gridController.selection.selectedIndexes.forEach((element) {
      selectedPhotos
          .add(PhotoManager.getPhotos(context, _albumId)[element].photoUUID);
    });

    // remove remote photos from album
    var status =
        await Api.removePhotosFromAlbum(_album.id, selectedPhotos, _model);

    // check if successful
    if (status != 0) {
      _model.photoprismMessage
          .showMessage("Removing photos from album failed.");
    } else {
      AlbumManager.loadAlbums(context, 0,
          forceReload: true, loadPhotosForAlbumId: _albumId);
    }
    // deselect selected photos
    _model.gridController.clear();
    _model.photoprismLoadingScreen.hideLoadingScreen();
  }

  @override
  Widget build(BuildContext context) {
    int _selectedPhotosCount =
        _model.gridController.selection.selectedIndexes.length;
    return Scaffold(
      appBar: AppBar(
        title: _selectedPhotosCount > 0
            ? Text(_selectedPhotosCount.toString())
            : Text(_album.name),
        centerTitle: _selectedPhotosCount > 0 ? false : null,
        leading: _selectedPhotosCount > 0
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _model.gridController.selection = Selection({});
                },
              )
            : null,
        actions: _selectedPhotosCount > 0
            ? <Widget>[
                PopupMenuButton<int>(
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 2,
                      child: Text("Remove from album"),
                    ),
                  ],
                  onSelected: (choice) {
                    _removePhotosFromAlbum(context);
                  },
                ),
              ]
            : <Widget>[
                // overflow menu
                PopupMenuButton<int>(
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Text("Rename album"),
                    ),
                    PopupMenuItem(
                      value: 1,
                      child: Text("Delete album"),
                    ),
                  ],
                  onSelected: (choice) {
                    if (choice == 0) {
                      _showRenameAlbumDialog(context);
                    } else if (choice == 1) {
                      _showDeleteAlbumDialog(context);
                    }
                  },
                ),
              ],
      ),
      body: PhotosPage(albumId: _albumId),
    );
  }

  _showRenameAlbumDialog(BuildContext context) async {
    _renameAlbumTextFieldController.text = _album.name;
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Rename album'),
            content: TextField(
              controller: _renameAlbumTextFieldController,
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('Rename album'),
                onPressed: () {
                  _renameAlbum(context);
                },
              )
            ],
          );
        });
  }

  _showDeleteAlbumDialog(BuildContext albumContext) async {
    return showDialog(
        context: albumContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete album?'),
            content: Text(
                'Are you sure you want to delete this album? Your photos will not be deleted.'),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('Delete album'),
                onPressed: () {
                  _deleteAlbum(albumContext);
                },
              )
            ],
          );
        });
  }
}
