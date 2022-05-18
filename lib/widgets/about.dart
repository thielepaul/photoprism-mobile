import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextTheme theme = Theme.of(context).textTheme;
    return AboutListTile(
      aboutBoxChildren: <Widget>[
        RichText(
          text: TextSpan(
            children: <InlineSpan>[
              TextSpan(
                  style: theme.bodyText1,
                  text:
                      'This PhotoPrism Flutter App is a community-maintained application to browse the photos on your PhotoPrism server.\n\nThe source code of the app is licensed under the GPLv3. The source code of the app can be found here: '),
              TextSpan(
                text: 'https://github.com/photoprism/photoprism-mobile',
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launch('https://github.com/photoprism/photoprism-mobile');
                  },
              ),
              TextSpan(
                  style: theme.headline6,
                  text: '\n\nTrademarks'),
              TextSpan(
                  style: theme.bodyText1,
                  text:
                      '\n\nPhotoPrism® is a registered trademark of Michael Mayer. You may use it as required to describe our software, run your server, for educational purposes, but not for offering commercial goods, products, or services without prior written permission.\n\nFeel free to reach out if you have questions:\n'),
              TextSpan(
                text: 'https://photoprism.app/contact',
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launch('https://photoprism.app/contact');
                  },
              ),
            ],
          ),
        )
      ],
    );
  }
}
