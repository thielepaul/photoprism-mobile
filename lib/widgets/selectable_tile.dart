import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class SelectableTile extends StatelessWidget {
  final Widget child;
  final int index;
  final bool selected;
  final Function onTapCallback;
  final BuildContext context;
  final DragSelectGridViewController gridController;

  const SelectableTile(
      {Key key,
      this.child,
      this.index,
      this.selected,
      Function onTap,
      this.context,
      this.gridController})
      : this.onTapCallback = onTap,
        super(key: key);

  bool isSelected() {
    Selection selection = Provider.of<PhotoprismModel>(context).selection;
    return selection.selectedIndexes.contains(index);
  }

  void onTap() {
    Selection selection = Provider.of<PhotoprismModel>(context).selection;
    print(selection);
    if (selection.isSelecting) {
      Set<int> selectedIndexes = selection.selectedIndexes;
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
      } else {
        selectedIndexes.add(index);
      }
      Navigator.of(context).maybePop();
      gridController.selection = Selection(selectedIndexes);
      return;
    }
    onTapCallback();
  }

  getSelectedTile(context) => (Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(16.0),
            child: child,
          ),
          Positioned(
            left: 3.0,
            top: 3.0,
            child: new Icon(
              Icons.check_circle,
              color: HexColor(
                  Provider.of<PhotoprismModel>(context).applicationColor),
            ),
          ),
        ],
      ));

  @override
  Widget build(BuildContext context) {
    if (isSelected()) {
      return GestureDetector(
        child: getSelectedTile(context),
        onTap: onTap,
      );
    }
    return GestureDetector(
      child: child,
      onTap: onTap,
    );
  }
}
