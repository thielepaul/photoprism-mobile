import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/widgets/http_auth_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'albums_page.dart';
import 'photos_page.dart';
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
          title: Text("PhotoPrism"),
        ),
        body: Container(
            //width: double.maxFinite,
            child: ListView(
          children: <Widget>[
            ListTile(
              title: Text("Photoprism URL"),
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
              title: Text("HTTP Basic authentication"),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.vpn_key),
              ),
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => HttpAuthDialog(
                        context: context,
                      )),
            ),
            ListTile(
              title: Text("Empty cache"),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.delete),
              ),
              onTap: () {
                emptyCache();
              },
            ),
            SwitchListTile(
              title: Text("Auto Upload"),
              secondary: const Icon(Icons.cloud_upload),
              value: model.autoUploadEnabled,
              onChanged: (bool newState) async {
                final PermissionHandler _permissionHandler =
                    PermissionHandler();
                var result = await _permissionHandler
                    .requestPermissions([PermissionGroup.storage]);

                if (result[PermissionGroup.storage] ==
                    PermissionStatus.granted) {
                  print(newState);
                  model.photoprismUploader.setAutoUpload(newState);
                } else {
                  print("Not authorized.");
                }
              },
            ),
            ListTile(
              title: Text("Upload folder"),
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
              title: Text("Last time checked for photos to be uploaded"),
              subtitle: Text(model.autoUploadLastTimeCheckedForPhotos),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.sync),
              ),
            ),
            ListTile(
              title: Text("Delete already uploaded photos info"),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.delete_sweep),
              ),
              onTap: () {
                deleteUploadInfo();
              },
            ),
            ListTile(
              title: Text("Show upload queue"),
              leading: Container(
                width: 10,
                alignment: Alignment.center,
                child: Icon(Icons.sort),
              ),
              onTap: () {
                model.photoprismUploader.getPhotosToUpload();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => AutoUploadQueue(model)),
                );
              },
            ),
            ListTile(
              title: Text(
                  "Warning: Auto upload is still under development. It only works under Android at this moment. Not fully working."),
            ),
          ],
        )));
  }

  void deleteUploadInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("alreadyUploadedPhotos", []);
  }

  void getUploadFolder(context) async {
    _settingsDisplayUploadFolderDialog(context);
  }

  _settingsDisplayUrlDialog(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    _urlTextFieldController.text = model.photoprismUrl;

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Photoprism URL'),
            content: TextField(
              key: ValueKey("photoprismUrlTextField"),
              controller: _urlTextFieldController,
              decoration:
                  InputDecoration(hintText: "https://demo.photoprism.org"),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                onPressed: () {
                  setNewPhotoprismUrl(context, _urlTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  _settingsDisplayUploadFolderDialog(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    _uploadFolderTextFieldController.text = model.autoUploadFolder;

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter upload folder path'),
            content: TextField(
              controller: _uploadFolderTextFieldController,
              decoration:
                  InputDecoration(hintText: "/storage/emulated/0/DCIM/Camera"),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                onPressed: () {
                  setNewUploadFolder(
                      context, _uploadFolderTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  void setNewPhotoprismUrl(context, url) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    Navigator.of(context).pop();
    await model.photoprismCommonHelper.setPhotoprismUrl(url);
    model.photoprismRemoteConfigLoader.loadApplicationColor();
    emptyCache();
    await PhotosPage.loadPhotos(model, model.photoprismUrl, "");
    await AlbumsPage.loadAlbums(model, model.photoprismUrl);
  }

  void setNewUploadFolder(context, path) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    Navigator.of(context).pop();
    await model.photoprismUploader.setUploadFolder(path);
  }

  static void emptyCache() async {
    await DefaultCacheManager().emptyCache();
  }
}
