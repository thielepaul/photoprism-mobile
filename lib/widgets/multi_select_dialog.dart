import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MultiSelectDialog extends StatefulWidget {
  const MultiSelectDialog({Key key, this.items, this.selected})
      : super(key: key);
  final List<String> items;
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
        title: const Text('Select albums for auto-upload'),
        content: Container(
            width: double.maxFinite,
            child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (BuildContext context, int position) =>
                    CheckboxListTile(
                        title: Text(widget.items[position]),
                        onChanged: (bool value) {
                          setState(() {
                            if (value) {
                              selected.add(widget.items[position]);
                            } else {
                              selected.remove(widget.items[position]);
                            }
                          });
                        },
                        value: selected.contains(widget.items[position])))),
        actions: <Widget>[
          FlatButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(widget.selected.toSet()),
          ),
          FlatButton(
            child: const Text('Save'),
            onPressed: () => Navigator.of(context).pop(selected),
          )
        ],
      );
}
