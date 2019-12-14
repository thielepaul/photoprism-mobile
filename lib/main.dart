import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

class PhotoView extends StatelessWidget {
  int currentPhotoIndex;
  List<Photo> photos;
  String photoprismURL;
  PageController pageController;

  PhotoView(int currentPhotoIndex, List<Photo> photos, String photoprismURL) {
    this.currentPhotoIndex = currentPhotoIndex;
    this.photos = photos;
    this.photoprismURL = photoprismURL;
    this.pageController = PageController(initialPage: this.currentPhotoIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: GestureDetector(
      child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(photoprismURL +
                "/api/v1/thumbnails/" +
                this.photos[index].fileHash +
                "/fit_1920"),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 1.5,
          );
        },
        itemCount: photos.length,
        pageController: pageController,
      ),
      onTap: () {
        Navigator.pop(context);
      },
    ));
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
      theme: ThemeData(),
      home: MainPage(title: 'Photoprism'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);
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
  String photoprismURL = "";
  PageController _myPage;
  int _selectedIndex = 0;
  TextEditingController _textFieldController = TextEditingController();

  _displayDialog(BuildContext context) async {
    _textFieldController.text = photoprismURL;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Photoprism URL'),
            content: TextField(
              controller: _textFieldController,
              decoration:
                  InputDecoration(hintText: "https://demo.photoprism.org"),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                onPressed: () {
                  setURL(_textFieldController.text);
                  refreshPhotos();
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void _onItemTapped(int index) {
    _myPage.jumpToPage(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  Future setURL(String _url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("url", _url);
    setState(() {
      photoprismURL = _url;
    });
  }

  Future getURL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _url = prefs.getString("url");
    setState(() {
      photoprismURL = _url;
    });
  }

  void loadPhotos() async {
    http.Response response =
        await http.get(photoprismURL + '/api/v1/photos?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    List<Photo> photoList =
        parsed.map<Photo>((json) => Photo.fromJson(json)).toList();

    List<Widget> photos = new List();
    int i = 0;
    for (Photo photo in photoList) {
      int currentPhotoIndex = i;
      photos.add(Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PhotoView(currentPhotoIndex, photoList, photoprismURL)),
            );
          },
          child: Image.network(
            photoprismURL +
                '/api/v1/thumbnails/' +
                photo.fileHash +
                '/tile_224',
          ),
        ),
      ));
      i++;
    }

    setState(() {
      imageList = photos;
    });
  }

  Future loadAlbums() async {
    http.Response response =
        await http.get(photoprismURL + '/api/v1/albums?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    List<Album> albums =
        parsed.map<Album>((json) => Album.fromJson(json)).toList();

    List<Widget> newAlbums = new List();
    for (Album album in albums) {
      newAlbums.add(GridTile(
        child: Image.network(
          photoprismURL + '/api/v1/albums/' + album.id + '/thumbnail/tile_224',
        ),
        footer: GestureDetector(
          child: GridTileBar(
            backgroundColor: Colors.black45,
            title: _GridTitleText(album.name),
          ),
        ),
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
        url: photoprismURL + "/api/v1/upload/test",
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
          await http.post(photoprismURL + "/api/v1/import/upload/test");
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

  void refreshPhotos() async {
    await getURL();
    loadAlbums();
    loadPhotos();
  }

  @override
  void initState() {
    super.initState();
    _myPage = PageController(initialPage: 0);
    _selectedIndex = 0;
    refreshPhotos();
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
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              ListTile(
                title: Text("Photoprism URL"),
                subtitle: Text(photoprismURL),
                onTap: () {
                  _displayDialog(context);
                },
              ),
//                Center(
//                  child: _image == null
//                      ? Text('No image selected.')
//                      : Text("Ordner: $_ordner, Datei: $_datei"),
//                ),
//                RaisedButton(
//                  child: const Text('Select image', semanticsLabel: ''),
//                  onPressed: getImage,
//                ),
//                RaisedButton(
//                  child: const Text('Upload image', semanticsLabel: ''),
//                  onPressed: uploadImage,
//                ),
            ],
          )
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
        onPressed: refreshPhotos,
        tooltip: 'Increment',
        child: Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
