import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

final uploader = FlutterUploader();

void main() => runApp(MyApp());

class Photo {
  final String fileHash;

  Photo({this.fileHash});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      fileHash: json['FileHash'] as String,
    );
  }
}

class Album {
  final String id;
  final String name;

  Album({this.id, this.name});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['AlbumUUID'] as String,
      name: json['AlbumName'] as String,
    );
  }
}

class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photoprism',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MainPage(title: 'Photoprism Home'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _counter = 0;
  List<Widget> imageList = new List();
  List<Widget> albumList = new List();
  File _image;
  String _ordner = "";
  String _datei = "";
  PageController _myPage;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    _myPage.jumpToPage(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  void loadPhotos() async {
    http.Response response =
        await http.get('https://demo.photoprism.org/api/v1/photos?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    List<Photo> photoList =
        parsed.map<Photo>((json) => Photo.fromJson(json)).toList();

    List<Widget> photos = new List();
    for (Photo photo in photoList) {
      photos.add(Center(
          child: Image.network(
        'https://demo.photoprism.org/api/v1/thumbnails/' +
            photo.fileHash +
            '/tile_224',
      )));
    }

    setState(() {
      imageList = photos;
    });
  }

  Future loadAlbums() async {
    http.Response response =
        await http.get('https://demo.photoprism.org/api/v1/albums?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    List<Album> albums =
        parsed.map<Album>((json) => Album.fromJson(json)).toList();

    List<Widget> newAlbums = new List();
    for (Album album in albums) {
      newAlbums.add(GridTile(
        child: Image.network(
          'https://demo.photoprism.org/api/v1/albums/' +
              album.id +
              '/thumbnail/tile_224',
        ),
        footer: GestureDetector(
          child: GridTileBar(
            backgroundColor: Colors.black45,
            title: _GridTitleText(album.name),
          ),
        ),
        // Center(
        // child: Image.network(
        //   'https://demo.photoprism.org/api/v1/albums/' + album.id + '/thumbnail/tile_224',
        // )
        //)
      ));
    }

    setState(() {
      albumList = newAlbums;
    });
  }

  void uploadImage() async {
    Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);

    var savedDir = "/sdcard/DCIM/Camera/";
    var filename = "PANO_20190611_122500.jpg";
    final taskId = await uploader.enqueue(
        url: "http://10.0.2.40:2342/api/v1/upload/test",
        //required: url to upload to
        files: [
          FileItem(filename: _datei, savedDir: _ordner, fieldname: "files")
        ],
        // required: list of files that you want to upload
        method: UploadMethod.POST,
        // HTTP method  (POST or PUT or PATCH)
        showNotification: false,
        // send local notification (android only) for upload status
        tag: "upload 1"); // unique tag for upload taskS
    final subscription = uploader.result.listen((result) async {
      var response =
          await http.post("http://10.0.2.40:2342/api/v1/import/upload/test");
    }, onError: (ex, stacktrace) {});
  }

  Future getImage() async {
//    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
      _datei = p.basename(image.path);
      _ordner = p.dirname(image.path);
    });
  }

  Future _incrementCounter() async {
    Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    Map<PermissionGroup, PermissionStatus> permissions_photos =
        await PermissionHandler().requestPermissions([PermissionGroup.photos]);

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    _myPage = PageController(initialPage: 0);
    _selectedIndex = 0;
    loadAlbums();
    loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _myPage,
        children: <Widget>[
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: imageList,
          ),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: albumList,
            padding: const EdgeInsets.all(10),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.display1,
                ),
                Center(
                  child: _image == null
                      ? Text('No image selected.')
                      : Text("Ordner: $_ordner, Datei: $_datei"),
//                  : Image.file(_image),
                ),
                RaisedButton(
                  child: const Text('Select image', semanticsLabel: ''),
                  onPressed: getImage,
                ),
                RaisedButton(
                  child: const Text('Upload image', semanticsLabel: ''),
                  onPressed: uploadImage,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            title: Text('Photos'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            title: Text('Albums'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadAlbums,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
