import 'package:easy_localization/easy_localization.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:moor/moor.dart' as moor;
import 'package:photoprism/model/filter_photos.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

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

  List<Widget> _sortOptions(BuildContext context) {
    final List<Widget> sort = PhotoSort.values
        .map((PhotoSort e) => RadioListTile<PhotoSort>(
              title: Text(EnumToString.convertToString(e).tr()),
              dense: true,
              value: e,
              groupValue: filter.sort,
              onChanged: (PhotoSort value) => setState(() {
                filter.sort = value;
              }),
            ))
        .toList();

    final List<Widget> order = moor.OrderingMode.values
        .map((moor.OrderingMode e) => RadioListTile<moor.OrderingMode>(
            title: Text(EnumToString.convertToString(e).tr()),
            dense: true,
            value: e,
            groupValue: filter.order,
            onChanged: (moor.OrderingMode value) => setState(() {
                  filter.order = value;
                })))
        .toList();
    return <Widget>[
      _dialogHeading('sort'.tr()),
      ...sort,
      _dialogHeading('sort_order'.tr()),
      ...order
    ];
  }

  List<Widget> _filterOptions(BuildContext context) {
    return <Widget>[
      _dialogHeading('filter'.tr()),
      ...PhotoType.values
          .map((PhotoType e) => CheckboxListTile(
              title: Text(EnumToString.convertToString(e)),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 25),
              onChanged: (bool value) {
                setState(() {
                  if (value) {
                    filter.types.add(e);
                  } else {
                    filter.types.remove(e);
                  }
                });
              },
              value: filter.types.contains(e)))
          .toList()
    ];
  }

  Widget _dialogHeading(String title) {
    return Container(
        margin: const EdgeInsets.fromLTRB(25, 25, 10, 10), child: Text(title));
  }

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
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          ..._sortOptions(context),
          ..._filterOptions(context)
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      )),
      actions: <Widget>[
        TextButton(
          child: const Text('cancel').tr(),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('set_as_default').tr(),
          onPressed: () => saveAndPop(asDefault: true),
        ),
        TextButton(
          child: const Text('apply').tr(),
          onPressed: () => saveAndPop(asDefault: false),
        ),
      ],
    );
  }
}
