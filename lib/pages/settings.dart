import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

import '../common/hexcolor.dart';

class Settings extends StatelessWidget {
  TextEditingController _urlTextFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
  var photorismModel = Provider.of<PhotoprismModel>(context);

 return Column(
   mainAxisAlignment: MainAxisAlignment.start,
   children: <Widget>[
     ListTile(
       title: Text("Photoprism URL"),
       subtitle: Text(photorismModel.photoprismUrl),
       onTap: () {
         _settingsDisplayUrlDialog(context);
       },
     ),
     ListTile(
       title: Text("Empty cache"),
       onTap: () {
         emptyCache();
       },
     )
   ],
 );
}

  _settingsDisplayUrlDialog(BuildContext context) async {
    var photorismModel = Provider.of<PhotoprismModel>(context);
    _urlTextFieldController.text = photorismModel.photoprismUrl;

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Photoprism URL'),
            content: TextField(
              key: ValueKey("photoprismUrlTextField"),
              controller: _urlTextFieldController,
              cursorColor: HexColor(photorismModel.applicationColor),
              decoration:
              InputDecoration(hintText: "https://demo.photoprism.org"),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                textColor: HexColor(photorismModel.applicationColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                textColor: HexColor(photorismModel.applicationColor),
                onPressed: () {
                  setNewPhotoprismUrl(context, _urlTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  void setNewPhotoprismUrl(context, url) async {
    Navigator.of(context).pop();
    await Provider.of<PhotoprismModel>(context).setPhotoprismUrl(url);
    await Provider.of<PhotoprismModel>(context).loadApplicationColor();
    await emptyCache();
    //await refreshPhotosPull();
    //await refreshAlbumsPull();
  }

  void emptyCache() async {
    await DefaultCacheManager().emptyCache();
  }
}

