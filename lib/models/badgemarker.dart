import 'dart:io';
import 'dart:typed_data';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trip_badge/models/user.dart';
import 'package:trip_badge/pages/home.dart';
import 'package:trip_badge/widgets/post.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class BadgeMarker {
  getUserProfileIcon(String ownerId) {
    usersRef.doc(ownerId).get().then((doc) async {
      User user = User.fromDocument(doc);
      final File markerImageFile =
          await DefaultCacheManager().getSingleFile(user.photoUrl);
      final Uint8List markerImageBytes = await markerImageFile.readAsBytes();
      return BitmapDescriptor.fromBytes(markerImageBytes);
    });
  }

  Marker getMarker(Post post) {
    return Marker(
        markerId: MarkerId(post.postId!),
        position: LatLng(post.lat!, post.long!),
        icon: getUserProfileIcon(post.ownerId!),
        infoWindow:
            InfoWindow(title: post.location, snippet: post.description));
  }
}
