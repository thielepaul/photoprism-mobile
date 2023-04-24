import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class SelectableTile extends StatefulWidget {
  const SelectableTile(
      {Key? key,
      this.child,
      this.index,
      this.selected,
      Function? onTap,
      this.context,
      this.gridController})
      : onTapCallback = onTap,
        super(key: key);

  @override
  _SelectableTileState createState() => _SelectableTileState();
  final Widget? child;
  final int? index;
  final bool? selected;
  final Function? onTapCallback;
  final BuildContext? context;
  final DragSelectGridViewController? gridController;
}

class _SelectableTileState extends State<SelectableTile>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  bool? wasSelected;
  bool? initialState;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    if (widget.selected!) {
      animation = Tween<double>(begin: 17, end: 0).animate(controller);
    } else {
      animation = Tween<double>(begin: 0, end: 17).animate(controller);
    }
    initialState = widget.selected;
    wasSelected = widget.selected;
  }

  void onTap() {
    final Selection selection = widget.gridController!.value;
    if (selection.isSelecting) {
      final Set<int> selectedIndexes = selection.selectedIndexes.toSet();
      if (selectedIndexes.contains(widget.index)) {
        selectedIndexes.remove(widget.index);
      } else {
        selectedIndexes.add(widget.index!);
      }
      widget.gridController!.value = Selection(selectedIndexes);
      return;
    }
    widget.onTapCallback!();
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
  const _AnimatedSelectableTile(
      {Key? key,
      required Animation<double> animation,
      this.child,
      this.selected})
      : super(key: key, listenable: animation);

  final Widget? child;
  final bool? selected;

  Widget getIcon(BuildContext context) {
    if (selected!) {
      return Positioned(
        left: 3.0,
        top: 3.0,
        child: Icon(
          Icons.check_circle,
          color: Theme.of(context).iconTheme.color,
        ),
      );
    } else if (Provider.of<PhotoprismModel>(context)
        .gridController
        .value
        .isSelecting) {
      return Positioned(
        left: 3.0,
        top: 3.0,
        child: Icon(
          Icons.radio_button_unchecked,
          color: Theme.of(context).iconTheme.color,
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return Stack(
      children: <Widget>[
        Container(
          color: Theme.of(context).colorScheme.background,
          padding: EdgeInsets.all(animation.value),
          child: child,
        ),
        getIcon(context)
      ],
    );
  }
}
