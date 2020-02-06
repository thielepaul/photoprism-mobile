import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/widgets/http_auth_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/photoprism_model.dart';
import 'auto_upload_queue.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController _urlTextFieldController = TextEditingController();
  final TextEditingController _uploadFolderTextFieldController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text('PhotoPrism'),
        ),
        body: Container(
            //width: double.maxFinite,
            child: ListView(
          children: <Widget>[
            ListTile(
              title: const Text('Photoprism URL'),
              subtitle: Text(model.photoprismUrl),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.public),
              ),
              onTap: () {
                _settingsDisplayUrlDialog(context);
              },
            ),
            ListTile(
              title: const Text('HTTP Basic authentication'),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.vpn_key),
              ),
              onTap: () => showDialog<void>(
                  context: context,
                  builder: (BuildContext context) => HttpAuthDialog(
                        context: context,
                      )),
            ),
            ListTile(
              title: const Text('Empty cache'),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.delete),
              ),
              onTap: () {
                emptyCache(context);
              },
            ),
            SwitchListTile(
              title: const Text('Auto Upload'),
              secondary: const Icon(Icons.cloud_upload),
              value: model.autoUploadEnabled,
              onChanged: (bool newState) async {
                final PermissionHandler _permissionHandler =
                    PermissionHandler();
                final Map<PermissionGroup, PermissionStatus> result =
                    await _permissionHandler.requestPermissions(
                        <PermissionGroup>[PermissionGroup.storage]);

                if (result[PermissionGroup.storage] ==
                    PermissionStatus.granted) {
                  print(newState);
                  model.photoprismUploader.setAutoUpload(newState);
                } else {
                  print('Not authorized.');
                }
              },
            ),
            ListTile(
              title: const Text('Upload folder'),
              subtitle: Text(model.autoUploadFolder),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.folder),
              ),
              onTap: () {
                getUploadFolder(context);
              },
            ),
            ListTile(
              title: const Text('Last time checked for photos to be uploaded'),
              subtitle: Text(model.autoUploadLastTimeCheckedForPhotos),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.sync),
              ),
            ),
            ListTile(
              title: const Text('Delete already uploaded photos info'),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.delete_sweep),
              ),
              onTap: () {
                deleteUploadInfo(context);
              },
            ),
            ListTile(
              title: const Text('Show upload queue'),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.sort),
              ),
              trailing: Text(model.photosToUpload.length.toString()),
              onTap: () {
                model.photoprismUploader.getPhotosToUpload();
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                      builder: (BuildContext ctx) => FileList(
                          files: model.photosToUpload,
                          title: 'Auto upload queue')),
                );
              },
            ),
            ListTile(
              title: const Text('Show uploaded photos list'),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.sort),
              ),
              trailing: Text(model.alreadyUploadedPhotos.length.toString()),
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                      builder: (BuildContext ctx) => FileList(
                          files: model.alreadyUploadedPhotos,
                          title: 'Uploaded photos list')),
                );
              },
            ),
            const ListTile(
              title: Text(
                  'Warning: Auto upload is still under development. It only works under Android at this moment. Not fully working.'),
            ),
          ],
        )));
  }

  Future<void> deleteUploadInfo(BuildContext context) async {
    await PhotoprismUploader.saveAndSetAlreadyUploadedPhotos(
        Provider.of<PhotoprismModel>(context), <String>[]);
  }

  Future<void> getUploadFolder(BuildContext context) async {
    _settingsDisplayUploadFolderDialog(context);
  }

  Future<void> _settingsDisplayUrlDialog(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    _urlTextFieldController.text = model.photoprismUrl;

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Photoprism URL'),
            content: TextField(
              key: const ValueKey<String>('photoprismUrlTextField'),
              controller: _urlTextFieldController,
              decoration: const InputDecoration(
                  hintText: 'https://demo.photoprism.org'),
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: const Text('Save'),
                onPressed: () {
                  setNewPhotoprismUrl(context, _urlTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  Future<void> _settingsDisplayUploadFolderDialog(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    _uploadFolderTextFieldController.text = model.autoUploadFolder;

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter upload folder path'),
            content: TextField(
              controller: _uploadFolderTextFieldController,
              decoration: const InputDecoration(
                  hintText: '/storage/emulated/0/DCIM/Camera'),
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: const Text('Save'),
                onPressed: () {
                  setNewUploadFolder(
                      context, _uploadFolderTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  Future<void> setNewPhotoprismUrl(BuildContext context, String url) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    Navigator.of(context).pop();
    await model.photoprismCommonHelper.setPhotoprismUrl(url);
    model.photoprismRemoteConfigLoader.loadApplicationColor();
    emptyCache(context);
  }

  Future<void> setNewUploadFolder(BuildContext context, String path) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    Navigator.of(context).pop();
    await model.photoprismUploader.setUploadFolder(path);
  }

  static Future<void> emptyCache(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.remove('momentsTime');
    sp.remove('photos');
    sp.remove('albums');
    if (model.albums != null) {
      for (final int albumId in model.albums.keys) {
        sp.remove('photos' + albumId.toString());
      }
    }
    model.photos = null;
    model.momentsTime = null;
    model.albums = null;
    await DefaultCacheManager().emptyCache();
  }
}
