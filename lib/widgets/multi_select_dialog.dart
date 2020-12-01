import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class MultiSelectDialog extends StatefulWidget {
  const MultiSelectDialog(
      {Key key, this.titles, this.subtitles, this.ids, this.selected})
      : super(key: key);
  final List<String> titles;
  final List<String> subtitles;
  final List<String> ids;
  final List<String> selected;

  @override
  _MultiSelectDialogState createState() =>
      _MultiSelectDialogState(selected.toSet());
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  _MultiSelectDialogState(this.selected);
  Set<String> selected;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('select_albums_for_auto_upload'.tr()),
        content: Container(
            width: double.maxFinite,
            child: ListView.builder(
                itemCount: widget.ids.length,
                itemBuilder: (BuildContext context, int position) =>
                    CheckboxListTile(
                        title: Text(widget.titles[position]),
                        subtitle: Text(widget.subtitles[position]),
                        onChanged: (bool value) {
                          setState(() {
                            if (value) {
                              selected.add(widget.ids[position]);
                            } else {
                              selected.remove(widget.ids[position]);
                            }
                          });
                        },
                        value: selected.contains(widget.ids[position])))),
        actions: <Widget>[
          FlatButton(
            child: Text('cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(widget.selected.toSet()),
          ),
          FlatButton(
            child: Text('save'.tr()),
            onPressed: () => Navigator.of(context).pop(selected),
          )
        ],
      );
}
