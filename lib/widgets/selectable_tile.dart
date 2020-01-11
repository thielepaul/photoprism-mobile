import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class SelectableTile extends StatefulWidget {
  final Widget child;
  final int index;
  final bool selected;
  final Function onTapCallback;
  final BuildContext context;
  final DragSelectGridViewController gridController;

  SelectableTile(
      {Key key,
      this.child,
      this.index,
      this.selected,
      Function onTap,
      this.context,
      this.gridController})
      : this.onTapCallback = onTap,
        super(key: key);

  _SelectableTileState createState() => _SelectableTileState();
}

class _SelectableTileState extends State<SelectableTile>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  bool wasSelected;
  bool initialState;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    if (widget.selected) {
      animation = Tween<double>(begin: 17, end: 0).animate(controller);
    } else {
      animation = Tween<double>(begin: 0, end: 17).animate(controller);
    }
    initialState = widget.selected;
    wasSelected = widget.selected;
  }

  void onTap() {
    Selection selection = widget.gridController.selection;
    if (selection.isSelecting) {
      Set<int> selectedIndexes = selection.selectedIndexes;
      if (selectedIndexes.contains(widget.index)) {
        selectedIndexes.remove(widget.index);
      } else {
        selectedIndexes.add(widget.index);
      }
      widget.gridController.selection = Selection(selectedIndexes);
      return;
    }
    widget.onTapCallback();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selected != wasSelected) {
      wasSelected = widget.selected;
      if (widget.selected != initialState) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
    return GestureDetector(
        onTap: onTap,
        child: _AnimatedSelectableTile(
          animation: animation,
          child: widget.child,
          selected: widget.selected,
        ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _AnimatedSelectableTile extends AnimatedWidget {
  final Widget child;
  final bool selected;

  const _AnimatedSelectableTile(
      {Key key, Animation<double> animation, this.child, this.selected})
      : super(key: key, listenable: animation);

  Widget getIcon(context) {
    if (selected) {
      return Positioned(
        left: 3.0,
        top: 3.0,
        child: new Icon(
          Icons.check_circle,
          color: HexColor(Provider.of<PhotoprismModel>(context)
              .photoprismConfig
              .applicationColor),
        ),
      );
    } else if (Provider.of<PhotoprismModel>(context)
        .getGridController()
        .selection
        .isSelecting) {
      return Positioned(
        left: 3.0,
        top: 3.0,
        child: new Icon(
          Icons.radio_button_unchecked,
          color: HexColor(Provider.of<PhotoprismModel>(context)
              .photoprismConfig
              .applicationColor),
        ),
      );
    }
    return Container();
  }

  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Stack(
      children: <Widget>[
        Container(
          color: Color(0xffeeeeee),
          padding: EdgeInsets.all(animation.value),
          child: child,
        ),
        getIcon(context)
      ],
    );
  }
}
