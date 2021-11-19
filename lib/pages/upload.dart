import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trip_badge/helpers/map_helper.dart';
import 'dart:typed_data';
import 'dart:ui';
import 'package:trip_badge/models/user.dart';
import 'package:trip_badge/pages/home.dart';
import 'package:trip_badge/widgets/badgemap.dart';
import 'package:trip_badge/widgets/post.dart';
import 'package:trip_badge/widgets/progress.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class Upload extends StatefulWidget {
  final User? currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();

  File? file;
  bool isUploading = false;
  String? postId;

  double lat = -1.1;
  double long = -1.1;
  Set<Marker> markers = {};

  @override
  void initState() {
    getMarkers();
    super.initState();
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    XFile? xfile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxHeight: 675,
        maxWidth: 960,
        imageQuality: 50);

    setState(() {
      this.file = File(xfile!.path);
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    XFile? xfile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxHeight: 675,
        maxWidth: 960,
        imageQuality: 50);

    setState(() {
      this.file = File(xfile!.path);
    });
  }

  Future<String> uploadImage(imageFile) async {
    firebase_storage.UploadTask uploadTask =
        storageReference.child("post_$postId.jpg").putFile(imageFile);

    firebase_storage.TaskSnapshot storageSnap =
        await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {required String mediaUrl,
      required String location,
      required String description}) {
    postsRef
        .doc(widget.currentUser!.id)
        .collection("userPosts")
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": widget.currentUser!.id,
      "username": widget.currentUser!.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "lat": lat,
      "long": long,
      "timestamp": DateTime.now(),
      "likes": {}
    });
  }

  handleSubmit() async {
    postId = Uuid().v4();
    setState(() {
      isUploading = true;
    });
    // await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
        mediaUrl: mediaUrl,
        location: locationController.text,
        description: captionController.text);

    captionController.clear();
    locationController.clear();

    setState(() {
      file = null;
      isUploading = false;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(await file!.readAsBytes());
    final compressedImageFile = await File('$path/img_$postId.jpg')
        .writeAsBytes(Im.encodeJpg(imageFile!, quality: 85));

    setState(() {
      file = compressedImageFile;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Create Post"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Photo with Camera"),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery,
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  getMarkers() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser!.id)
        .collection('timelinePosts')
        .get();

    Set<Marker> loadedMarkers = {};
    snapshot.docs.forEach((doc) async {
      Marker marker = await getMarker(Post.fromDocument(doc));
      loadedMarkers.add(marker);
    });

    setState(() {
      this.markers = loadedMarkers;
    });
  }

  Future<BitmapDescriptor> getUserProfileIcon(String ownerId) async {
    DocumentSnapshot doc = await usersRef.doc(ownerId).get();
    User user = User.fromDocument(doc);
    final int targetWidth = 60;
    final BitmapDescriptor markerImage = await MapHelper.getMarkerImageFromUrl(
        user.photoUrl,
        targetWidth: targetWidth);

    // final File markerImageFile =
    //     await DefaultCacheManager().getSingleFile(user.photoUrl);
    // final Uint8List markerImageBytes = await markerImageFile.readAsBytes();
    // BitmapDescriptor bitMap = BitmapDescriptor.fromBytes(markerImageBytes);
    return markerImage;
  }

  Future<Marker> getMarker(Post post) async {
    BitmapDescriptor descriptor = await getUserProfileIcon(post.ownerId!);

    return Marker(
        markerId: MarkerId(post.postId!),
        position: LatLng(post.lat!, post.long!),
        icon: descriptor,
        infoWindow:
            InfoWindow(title: post.location, snippet: post.description));
  }

  // FutureBuilder buildMarkersToDraw() {
  //   return FutureBuilder(
  //       future: getMarkers(),
  //       builder: (context, snapshot) {
  //         if (!snapshot.hasData) {
  //           return BadgeMap(markers: markers);
  //         }
  //         return BadgeMap(markers: markers);
  //       });
  // }

  late GoogleMapController mapController;

  final LatLng _center = const LatLng(45.5017, -73.5673);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Container buildSplashScreen() {
    return Container(
      // color: Theme.of(context).primaryColor.withOpacity(0.2),
      child: Stack(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // SvgPicture.asset(
          //   'assets/images/upload.svg',
          //   height: 260.0,
          // ),
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: markers,
          ),

          Padding(
            padding: EdgeInsets.only(bottom: 20.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 35.0,
                ),
                onPressed: () => selectImage(context),
              ),
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    lat = position.latitude;
    long = position.longitude;

    List<Placemark> placemarks =
        await GeocodingPlatform.instance.placemarkFromCoordinates(lat, long);

    Placemark placemark = placemarks[0];

    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: clearImage,
        ),
        title: Center(
          child: Text(
            "Caption Post",
            style: TextStyle(color: Colors.black),
          ),
        ),
        actions: [
          TextButton(
              onPressed: handleSubmit,
              child: Text(
                "Post",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0),
              ))
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(
                        File(file!.path),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser!.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: "Write a caption...", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop, color: Colors.orange, size: 35.0),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                    hintText: "Where was this photo taken?",
                    border: InputBorder.none),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100,
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                "Use Current Location",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
