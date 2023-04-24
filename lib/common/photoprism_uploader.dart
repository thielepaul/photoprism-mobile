import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:background_fetch/background_fetch.dart';
import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart' as photolib;
import 'package:photo_manager/photo_manager.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/api/db_api.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/common/localfile.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismUploader {
  PhotoprismUploader(this.model) {
    initialize();
  }

  PhotoprismModel model;
  late Completer<int> manualUploadFinishedCompleter;
  Map<String?, Album> deviceAlbums = <String, Album>{};
  late Isar isar;
  int currentlyIndexingCounter = 0;
  int maxIndexingCounter = 10;
  bool autoUploadIsRunning = false;

  Future<void> initialize() async {
    await loadPreferences();
    if (!model.autoUploadEnabled) {
      print('photo upload disabled');
      return;
    }
    initPlatformState();

    BackgroundFetch.start().then((int status) {
      print('[BackgroundFetch] start success: $status');
    }).catchError((Object e) {
      print('[BackgroundFetch] start FAILURE: $e');
    });

    final io.Directory dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(<CollectionSchema<LocalFile>>[LocalFileSchema],
        directory: dir.path);
    updatePhotoSets();
  }

  Future<void> resetState() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
    await getPhotosToUpload();
  }

  Future<void> setAutoUpload(bool autoUploadEnabledNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoUploadEnabled', autoUploadEnabledNew);
    model.autoUploadEnabled = autoUploadEnabledNew;
    model.notify();
    getPhotosToUpload();
  }

  Future<void> setAutoUploadWifiOnly(bool autoUploadWifiOnlyNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoUploadWifiOnly', autoUploadWifiOnlyNew);
    model.autoUploadWifiOnly = autoUploadWifiOnlyNew;
    model.notify();
  }

  Future<void> setAutoUploadLastTimeActive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // get current date and time
    final DateTime now = DateTime.now();
    final String currentTime = DateFormat('dd.MM.yyyy – HH:mm').format(now);

    prefs.setString('autoUploadLastTimeActive', currentTime.toString());
    model.autoUploadLastTimeCheckedForPhotos = currentTime.toString();
    model.notify();
  }

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    model.autoUploadEnabled = prefs.getBool('autoUploadEnabled') ?? false;
    model.autoUploadLastTimeCheckedForPhotos =
        prefs.getString('autoUploadLastTimeActive') ?? 'Never';
    model.notify();
  }

  /// Starts image file picker, uploads photo(s) and imports them.
  Future<void> selectPhotoAndUpload(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.media, allowMultiple: true);

    if (result == null) {
      return;
    }

    model.photoprismLoadingScreen.showLoadingScreen('Starting upload...');

    final void Function(String step, int count) showStatus = (String step,
            int count) =>
        model.photoprismLoadingScreen.updateLoadingScreen(
            '$step photo${result.count > 1 ? 's' : ''}... ($count/${result.count})');

    for (int idx = 0; idx < result.files.length; idx++) {
      final PlatformFile file = result.files[idx];
      final Random rng = Random.secure();
      String event = '';
      for (int i = 0; i < 12; i++) {
        event += rng.nextInt(9).toString();
      }

      final String? path = file.path;
      if (path == null) {
        return;
      }
      showStatus('Uploading', idx + 1);
      final bool status =
          await apiUpload(model, event, file.name, io.File(path), <String>[]);
      if (status) {
        print('Manual upload successful for ${file.name}.');
      } else {
        print('Manual upload failed for ${file.name}.');
        model.photoprismMessage
            .showMessage('Uploading photo "${file.name}" failed!');
      }
    }
    await model.photoprismLoadingScreen.hideLoadingScreen();
    await apiUpdateDb(model);
  }

  Future<void> getPhotosToUpload() async {
    if (!model.autoUploadEnabled) {
      return;
    }

    final String deviceName = await getNameOfCurrentDevice(model);
    await getRemoteAlbumsWithDeviceName(deviceName);

    if ((await photolib.PhotoManager.requestPermissionExtend()).isAuth) {
      final List<photolib.AssetPathEntity> albums =
          await photolib.PhotoManager.getAssetPathList();
      for (final photolib.AssetPathEntity album in albums) {
        if (model.albumsToUpload.contains(album.id)) {
          model.addLogEntry('AutoUploader',
              "start checking album '${album.name}' for changes");
          const int pageSize = 100;
          int page = 0;
          List<photolib.AssetEntity> entries;
          do {
            entries = await album.getAssetListPaged(page: page, size: pageSize);
            final List<LocalFile?> files = await isar.localFiles.getAll(entries
                .map((photolib.AssetEntity e) => fastHash(e.id))
                .toList());
            for (int i = 0; i < entries.length; i++) {
              final photolib.AssetEntity entry = entries[i];
              final LocalFile? file = files[i];
              if (file != null) {
                if (file.uploadStatus == UploadStatus.none) {
                  await isar.writeTxn(() async {
                    file.uploadStatus = UploadStatus.planned;
                    await isar.localFiles.put(file);
                  });
                }
                continue;
              }
              final String filename = await entry.titleAsync;
              await isar.writeTxn(() async {
                await isar.localFiles.put(LocalFile()
                  ..id = entry.id
                  ..filename = filename
                  ..localAlbumId = album.id
                  ..albumName = '$deviceName – ${album.name}');
              });
            }
            page++;
          } while (entries.length == pageSize);
          model.addLogEntry('AutoUploader',
              "finished checking album '${album.name}' for changes");
        }
      }
    }

    final List<LocalFile> plannedButNotSelectedAnymore = await isar.localFiles
        .filter()
        .uploadStatusEqualTo(UploadStatus.planned)
        .and()
        .allOf<String, LocalFile>(
            model.albumsToUpload,
            (QueryBuilder<LocalFile, LocalFile, QFilterCondition> q,
                    String albumId) =>
                q.not().localAlbumIdEqualTo(albumId))
        .findAll();
    for (final LocalFile file in plannedButNotSelectedAnymore) {
      await isar.writeTxn(() async {
        final LocalFile? dbfile = await isar.localFiles.get(file.isarId);
        if (dbfile == null) {
          return;
        }
        dbfile.uploadStatus = UploadStatus.none;
        await isar.localFiles.put(dbfile);
      });
    }

    await updatePhotoSets();
  }

  Future<void> updatePhotoSets() async {
    await _updatePhotosToUpload();
    await _updateAlreadyUploadedPhotos();
    await _updateFailedUploads();
  }

  Future<void> _updatePhotosToUpload() async {
    model.photosToUpload = (await isar.localFiles
            .filter()
            .uploadStatusEqualTo(UploadStatus.planned)
            .findAll())
        .map((LocalFile e) => e.id)
        .toSet();
  }

  Future<void> _updateAlreadyUploadedPhotos() async {
    model.alreadyUploadedPhotos = (await isar.localFiles
            .filter()
            .uploadStatusEqualTo(UploadStatus.uploaded)
            .findAll())
        .map((LocalFile e) => e.id)
        .toSet();
  }

  Future<void> _updateFailedUploads() async {
    model.photosUploadFailed = (await isar.localFiles
            .filter()
            .uploadStatusEqualTo(UploadStatus.failed)
            .findAll())
        .map((LocalFile e) => e.id)
        .toSet();
  }

  Future<void> initPlatformState() async {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: false,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      try {
        runAutoUploadBackgroundRoutine(taskId);
      } finally {
        BackgroundFetch.finish(taskId);
      }
    }).then((int status) {
      model.addLogEntry(
          'AutoUploader',
          'Configuration of auto uploader successful. Status: ' +
              status.toString());
    }).catchError((Object e) {
      model.addLogEntry(
          'AutoUploader', 'ERROR: Configuration of auto uploader failed.');
    });
  }

  Future<void> runAutoUploadBackgroundRoutine(String taskId) async {
    if (autoUploadIsRunning) {
      model.addLogEntry(
          'AutoUploader', 'Autoupload routine is already running');
      return;
    }
    autoUploadIsRunning = true;

    model.addLogEntry(
        'AutoUploader', 'Starting autoupload routine. Task ID: ' + taskId);

    if (!model.autoUploadEnabled) {
      model.addLogEntry(
          'AutoUploader', 'Auto upload disabled. Stopping autoupload routine.');
      autoUploadIsRunning = false;
      return;
    }

    if (model.autoUploadWifiOnly) {
      final ConnectivityResult connectivityResult =
          await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) {
        model.addLogEntry('AutoUploader',
            'Auto upload requires Wi-Fi. Stopping autoupload routine.');
        autoUploadIsRunning = false;
        return;
      }
    }

    if (model.photoprismUrl == 'https://demo.photoprism.org' ||
        model.photoprismUrl == 'https://photoprism.p4u1.de' ||
        model.photoprismUrl == 'https://photoprism.herokuapp.com') {
      model.addLogEntry('AutoUploader',
          'Auto upload disabled for demo page. Stopping autoupload routine.');
      autoUploadIsRunning = false;
      return;
    }

    // Set date and time when background routine was run last time.
    setAutoUploadLastTimeActive();

    await getPhotosToUpload();

    final List<photolib.AssetPathEntity> albumList =
        await photolib.PhotoManager.getAssetPathList();

    String albumsString = '';
    int albumsCount = 0;
    for (final photolib.AssetPathEntity album in albumList) {
      if (albumsString == '') {
        albumsString += "'";
        albumsString += album.name;
        albumsString += "'";
      } else {
        albumsString += ', ';
        albumsString += "'";
        albumsString += album.name;
        albumsString += "'";
      }
      albumsCount++;
    }

    model.addLogEntry(
        'AutoUploader',
        'Found ' +
            albumsCount.toString() +
            ' albums on device: ' +
            albumsString);

    model.addLogEntry('AutoUploader', 'Next, uploading all new photos.');
    await Future.wait(<Future<void>>[prepareForUpload(), uploadPhotos()]);

    model.addLogEntry('AutoUploader', 'Next, checking album assignments.');
    await fixAlbumAssignments();

    model.addLogEntry('AutoUploader', 'Autoupload routine finished.');
    autoUploadIsRunning = false;
  }

  static Future<String> getHash(io.File value) {
    return compute(
        (io.File value) async =>
            (await sha1.bind(value.openRead()).first).toString(),
        value);
  }

  Future<void> prepareForUpload() async {
    final List<LocalFile> files = await isar.localFiles
        .filter()
        .uploadStatusEqualTo(UploadStatus.planned)
        .and()
        .hashIsNull()
        .findAll();
    for (final LocalFile file in files) {
      if (!model.autoUploadEnabled) {
        model.addLogEntry(
            'AutoUploader', 'Automatic photo upload was disabled, stopping.');
        break;
      }

      final photolib.AssetEntity? asset = await AssetEntity.fromId(file.id);
      if (asset == null) {
        model.addLogEntry('AutoUploader',
            "ERROR: Photo which should be uploaded with ID '${file.id}' was not found on the phone.");
        continue;
      }

      final io.File? imageFile = await asset.originFile;
      if (imageFile == null) {
        model.addLogEntry('AutoUploader',
            "ERROR: Original file for photo which should be uploaded with ID '${file.id}' was not found on the phone.");
        continue;
      }

      while (currentlyIndexingCounter >= maxIndexingCounter) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      indexPhoto(imageFile, file);
    }
    while (currentlyIndexingCounter > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> indexPhoto(io.File imageFile, LocalFile file) async {
    currentlyIndexingCounter += 1;

    final String filehash = await getHash(imageFile);

    final bool alreadyUploaded = model.database != null &&
        (await model.database!.getFileFromHash(filehash)).isNotEmpty;

    await isar.writeTxn(() async {
      final LocalFile? dbfile = await isar.localFiles.get(file.isarId);
      if (dbfile == null) {
        return;
      }
      dbfile.hash = filehash;
      if (alreadyUploaded) {
        dbfile.uploadStatus = UploadStatus.uploaded;
      }
      await isar.localFiles.put(dbfile);
    });

    await updatePhotoSets();

    model.addLogEntry('AutoUploader',
        "Photo with ID '${file.id}' was indexed${alreadyUploaded ? ' (and already found on server)' : ''}.");

    currentlyIndexingCounter -= 1;
  }

  Future<void> uploadPhotos() async {
    while (model.photosToUpload.isNotEmpty) {
      if (!model.autoUploadEnabled) {
        model.addLogEntry(
            'AutoUploader', 'Automatic photo upload was disabled, stopping.');
        break;
      }
      final LocalFile? file = await isar.localFiles
          .filter()
          .uploadStatusEqualTo(UploadStatus.planned)
          .and()
          .hashIsNotNull()
          .findFirst();
      if (file == null) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      await autoUploadPhoto(file);
    }
  }

  Future<void> autoUploadPhoto(LocalFile file) async {
    final Future<void> Function(String reason) failUpload =
        (String reason) async {
      model.addLogEntry(
          'AutoUploader', "Uploading photo '${file.filename}' failed: $reason");
      await isar.writeTxn(() async {
        final LocalFile? dbfile = await isar.localFiles.get(file.isarId);
        if (dbfile == null) {
          return;
        }
        dbfile.uploadStatus = UploadStatus.failed;
        await isar.localFiles.put(dbfile);
      });
      updatePhotoSets();
    };

    final String? fileHash = file.hash;
    if (fileHash == null) {
      await failUpload('has no hash entry.');
      return;
    }

    final photolib.AssetEntity? asset = await AssetEntity.fromId(file.id);
    if (asset == null) {
      await failUpload('was not found on the phone.');
      return;
    }

    model.addLogEntry('AutoUploader',
        "Uploading photo '${file.filename}' to album '${file.albumName}'.");
    final io.File? imageFile = await asset.originFile;
    if (imageFile == null) {
      await failUpload('original file could not be accessed.');
      return;
    }

    final String serverAlbumId =
        deviceAlbums[file.albumName]?.uid ?? file.albumName;
    final bool status = await apiUpload(
        model, fileHash, file.filename, imageFile, <String>[serverAlbumId]);
    if (status) {
      model.addLogEntry('AutoUploader',
          "Uploading photo ${file.filename} successful to album '$serverAlbumId'.");
    } else {
      await failUpload('backend returned error.');
      return;
    }

    await apiUpdateDb(model);
    final bool notYetUploaded = model.database == null ||
        (await model.database!.getFileFromHash(fileHash)).isEmpty;

    if (notYetUploaded) {
      await failUpload('not found on server after upload.');
      return;
    }

    await isar.writeTxn(() async {
      final LocalFile? dbfile = await isar.localFiles.get(file.isarId);
      if (dbfile == null) {
        return;
      }
      dbfile.uploadStatus = UploadStatus.uploaded;
      await isar.localFiles.put(dbfile);
    });

    await updatePhotoSets();
  }

  Future<void> retryFailedUploads(PhotoprismModel model) async {
    await isar.writeTxn(() async {
      final List<LocalFile> dbfiles = await isar.localFiles
          .filter()
          .uploadStatusEqualTo(UploadStatus.failed)
          .findAll();
      for (final LocalFile file in dbfiles) {
        file.uploadStatus = UploadStatus.planned;
      }
      await isar.localFiles.putAll(dbfiles);
    });
    await updatePhotoSets();
  }

  Future<void> getRemoteAlbumsWithDeviceName(String deviceName) async {
    // Get list of albums from server which name contains the device name of the smartphone.
    await apiUpdateDb(model);
    final List<Album> deviceAlbumList = model.albums!
        .where((Album album) => album.title!.contains(deviceName))
        .toList();

    deviceAlbums = Map<String?, Album>.fromEntries(deviceAlbumList
        .map((Album album) => MapEntry<String?, Album>(album.title, album)));
  }

  static Future<void> saveAndSetAlbumsToUpload(
      PhotoprismModel model, Set<String> albumsToUpload) async {
    model.albumsToUpload = albumsToUpload;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('albumsToUpload', albumsToUpload.toList());
    await model.photoprismUploader.getPhotosToUpload();
  }

  Future<void> fixAlbumAssignments() async {
    final Map<String, List<String>> albumAssignments = <String, List<String>>{};
    final List<LocalFile> dbfiles = await isar.localFiles
        .filter()
        .uploadStatusEqualTo(UploadStatus.uploaded)
        .findAll();
    for (final LocalFile dbfile in dbfiles) {
      final String? hash = dbfile.hash;
      if (hash == null) {
        model.addLogEntry('AutoUploader',
            'ERROR: photo is marked as uploaded, but hash is null.');
        continue;
      }
      final List<File> file = await model.database!.getFileFromHash(hash);
      if (file.isEmpty) {
        model.addLogEntry('AutoUploader',
            'ERROR: photo is marked as uploaded, but found no file in database.');
        continue;
      }
      String? serverAlbumId = deviceAlbums[dbfile.albumName]?.uid;
      if (serverAlbumId == null) {
        serverAlbumId = await apiCreateAlbum(dbfile.albumName, model);
        if (serverAlbumId == '-1') {
          model.addLogEntry('AutoUploader', 'ERROR: creating album failed.');
          continue;
        }
        await apiUpdateDb(model);
        final String deviceName = await getNameOfCurrentDevice(model);
        await getRemoteAlbumsWithDeviceName(deviceName);
      }
      if (await model.database!.isPhotoAlbum(file[0].photoUID, serverAlbumId)) {
        continue;
      }
      if (!albumAssignments.containsKey(serverAlbumId)) {
        albumAssignments[serverAlbumId] = <String>[];
      }
      albumAssignments[serverAlbumId]!.add(file[0].photoUID);
    }
    for (final MapEntry<String, List<String>> entry
        in albumAssignments.entries) {
      model.addLogEntry('AutoUploader',
          'INFO: adding ${entry.value.length} photos to album ${entry.key}.');
      const int batchSize = 100;
      for (int i = 0; i < entry.value.length; i += batchSize) {
        final int result = await apiAddPhotosToAlbum(
            entry.key,
            entry.value.sublist(i, min(i + batchSize, entry.value.length)),
            model);
        if (result != 0) {
          model.addLogEntry(
              'AutoUploader', 'ERROR: adding photos to album failed.');
          return;
        }
      }
    }
  }

  // Returns the device name of the current device (smartphone).
  static Future<String> getNameOfCurrentDevice(PhotoprismModel model) async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (io.Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (io.Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    model.addLogEntry(
        'AutoUploader', 'ERROR: Failed to get name of this device.');
    return '';
  }
}
