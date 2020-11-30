import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class LogView extends StatelessWidget {
  LogView(BuildContext context)
      : _model = Provider.of<PhotoprismModel>(context);

  final PhotoprismModel _model;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Log'), actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'clear_log'.trim(),
            onPressed: () {
              _model.clearLog();
            },
          ),
        ]),
        body: ListView.builder(
          itemCount: _model.log.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(
                _model.log[index],
                style: DefaultTextStyle.of(context)
                    .style
                    .apply(fontSizeFactor: 0.8),
              ),
            );
          },
        ));
  }
}
