import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:moor/moor.dart' as moor;
import 'package:photoprism/model/filter_photos.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:enum_to_string/enum_to_string.dart';

class FilterPhotosDialog extends StatefulWidget {
  const FilterPhotosDialog({Key key, this.context}) : super(key: key);
  final BuildContext context;

  static Future<Widget> show(BuildContext context) => showDialog(
      context: context,
      builder: (BuildContext context) => FilterPhotosDialog(
            context: context,
          ));

  @override
  _FilterPhotosDialogState createState() => _FilterPhotosDialogState(context);
}

class _FilterPhotosDialogState extends State<FilterPhotosDialog> {
  _FilterPhotosDialogState(BuildContext context) {
    model = Provider.of<PhotoprismModel>(context);
    filter = model.filterPhotos;
  }

  PhotoprismModel model;
  FilterPhotos filter;

  @override
  Widget build(BuildContext context) {
    Future<void> saveAndPop({bool asDefault}) async {
      model.filterPhotos = filter;
      await model.updatePhotosSubscription();
      if (asDefault) {
        filter.saveTosharedPrefs();
      }
      Navigator.of(context).pop();
    }

    return AlertDialog(
      title: const Text('filter_and_sort').tr(),
      content: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          SwitchListTile(
            title: const Text('archived').tr(),
            onChanged: (bool value) {
              setState(() {
                filter.archived = value;
              });
            },
            value: filter.archived,
          ),
          SwitchListTile(
            title: const Text('private_photos').tr(),
            onChanged: (bool value) {
              setState(() {
                filter.private = value;
              });
            },
            value: filter.private,
          ),
          DropdownButton<moor.OrderingMode>(
            value: filter.order,
            onChanged: (moor.OrderingMode newValue) {
              setState(() {
                filter.order = newValue;
              });
            },
            items: moor.OrderingMode.values
                .map<DropdownMenuItem<moor.OrderingMode>>(
                    (moor.OrderingMode value) {
              return DropdownMenuItem<moor.OrderingMode>(
                value: value,
                child: Text(EnumToString.convertToString(value)).tr(),
              );
            }).toList(),
          ),
          DropdownButton<PhotoSort>(
            value: filter.sort,
            onChanged: (PhotoSort newValue) {
              setState(() {
                filter.sort = newValue;
              });
            },
            items: PhotoSort.values
                .map<DropdownMenuItem<PhotoSort>>((PhotoSort value) {
              return DropdownMenuItem<PhotoSort>(
                value: value,
                child: Text(EnumToString.convertToString(value)),
              );
            }).toList(),
          ),
          Container(
              height: double.maxFinite,
              width: double.maxFinite,
              child: ListView.builder(
                  itemCount: PhotoType.values.length,
                  itemBuilder: (BuildContext context, int i) =>
                      CheckboxListTile(
                          title: Text(EnumToString.convertToString(
                              PhotoType.values[i])),
                          onChanged: (bool value) {
                            setState(() {
                              if (value) {
                                filter.types.add(PhotoType.values[i]);
                              } else {
                                filter.types.remove(PhotoType.values[i]);
                              }
                            });
                          },
                          value: filter.types.contains(PhotoType.values[i])))),
        ],
      )),
      actions: <Widget>[
        FlatButton(
          child: const Text('cancel').tr(),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: const Text('set_as_default').tr(),
          onPressed: () => saveAndPop(asDefault: true),
        ),
        FlatButton(
          child: const Text('apply').tr(),
          onPressed: () => saveAndPop(asDefault: false),
        ),
      ],
    );
  }
}
