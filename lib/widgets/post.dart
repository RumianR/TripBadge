import 'dart:async';
import 'dart:ffi';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trip_badge/models/user.dart';
import 'package:trip_badge/pages/comments.dart';
import 'package:trip_badge/pages/home.dart';
import 'package:trip_badge/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Post extends StatefulWidget {
  final Function()? notifyParent;
  final String? postId;
  final String? ownerId;
  final String? username;
  final String? location;
  final String? description;
  final String? mediaUrl;
  final double? lat;
  final double? long;
  final dynamic likes;
  final Timestamp? timeStamp;

  Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.lat,
      this.long,
      this.timeStamp,
      this.notifyParent});

  factory Post.fromDocument(DocumentSnapshot doc,
      {Function()? notifyParent = null}) {
    return Post(
        postId: doc['postId'],
        ownerId: doc['ownerId'],
        username: doc['username'],
        location: doc['location'],
        description: doc['description'],
        mediaUrl: doc['mediaUrl'],
        likes: doc['likes'],
        lat: doc['lat'],
        long: doc['long'],
        timeStamp: doc['timestamp'],
        notifyParent: notifyParent);
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _Post createState() => _Post(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
        timeStamp: this.timeStamp,
      );
}

class _Post extends State<Post> {
  final String? currentUserId = currentUser?.id;
  final String? postId;
  final String? ownerId;
  final String? username;
  final String? location;
  final String? description;
  final String? mediaUrl;
  final Timestamp? timeStamp;
  int? likeCount;
  Map? likes;
  bool? isLiked;
  bool showHeart = false;

  _Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.likeCount,
      this.timeStamp});

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    deletePost();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          );
        });
  }

  // Note: To delete post, ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePost() async {
    // delete post itself
    postsRef.doc(ownerId).collection('userPosts').doc(postId).get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image for thep ost
    storageReference.child("post_$postId.jpg").delete();
    // then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // then delete all comments
    QuerySnapshot commentsSnapshot =
        await commentsRef.doc(postId).collection('comments').get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    widget.notifyParent!();
  }

  addLikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef.doc(ownerId).collection("feedItems").doc(postId).set({
        "type": "like",
        "username": currentUser!.username,
        "userId": currentUser!.id,
        "userProfileImg": currentUser!.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "commentData": "",
        "timestamp": timestamp,
        "ownerId": ownerId,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  handleLikePost() {
    bool _isLiked = likes![currentUserId] == true;

    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount = likeCount! - 1;
        isLiked = false;
        likes![currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount = likeCount! + 1;
        isLiked = true;
        likes![currentUserId] = true;
        showHeart = true;
      });

      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  FutureBuilder buildPostHeader() {
    return FutureBuilder(
        future: usersRef.doc(ownerId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          bool isPostOwner = currentUserId == ownerId;

          return ListTile(
            contentPadding: const EdgeInsets.all(0),
            leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.grey),
            title: Text(user.username,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
            subtitle: Text(
                timeago.format(this.timeStamp!.toDate(), allowFromNow: true),
                style: Theme.of(context).textTheme.bodyText2!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey)),
            trailing: isPostOwner
                ? IconButton(
                    onPressed: () => handleDeletePost(context),
                    icon: Icon(
                      Icons.more_horiz,
                      color: Theme.of(context).iconTheme.color,
                    ))
                : Text(''),
          );

          // return ListTile(
          //   leading: CircleAvatar(
          //       backgroundImage: CachedNetworkImageProvider(user.photoUrl),
          //       backgroundColor: Colors.grey),
          //   title: GestureDetector(
          //     onTap: () => print('showing profile'),
          //     child: Text(
          //       user.username,
          //       style:
          //           TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          //     ),
          //   ),
          //   subtitle: Text(
          //     location!,
          //   ),
          //   trailing: isPostOwner
          //       ? IconButton(
          //           onPressed: () => handleDeletePost(context),
          //           icon: Icon(Icons.more_vert),
          //         )
          //       : Text(''),
          // );
        });
  }

  buildDescription() {
    return description!.isEmpty
        ? const SizedBox.shrink()
        : Text(
            description!,
            textAlign: TextAlign.left,
          );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: mediaUrl!,
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Padding(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                    padding: EdgeInsets.all(10),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                )),
          ),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, AnimatorState anim, wid) =>
                      Transform.scale(
                          scale: anim.value,
                          child: Icon(
                            Icons.star,
                            size: 80.0,
                            color: Colors.yellow,
                          )),
                )
              : Text(""),
        ],
      ),
    );

    // return GestureDetector(
    //   onDoubleTap: handleLikePost,
    //   child: Stack(
    //     alignment: Alignment.center,
    //     children: <Widget>[
    //       cachedNetworkImage(mediaUrl!),
    //       showHeart
    //           ? Animator(
    //               duration: Duration(milliseconds: 300),
    //               tween: Tween(begin: 0.8, end: 1.4),
    //               curve: Curves.elasticOut,
    //               cycles: 0,
    //               builder: (context, AnimatorState anim, wid) =>
    //                   Transform.scale(
    //                       scale: anim.value,
    //                       child: Icon(
    //                         Icons.favorite,
    //                         size: 80.0,
    //                         color: Colors.pink,
    //                       )),
    //             )
    //           : Text(""),
    //     ],
    //   ),
    // );
  }

  buildPostFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
                onTap: handleLikePost,
                child: Icon(isLiked! ? Icons.star : Icons.star_border,
                    size: 28.0,
                    color: !isLiked!
                        ? Theme.of(context).iconTheme.color
                        : Colors.yellow[700])),
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: GestureDetector(
                  onTap: () => showComments(
                        context,
                        postId: postId,
                        ownerId: ownerId,
                        mediaUrl: mediaUrl,
                      ),
                  child: Icon(Icons.comment, color: Colors.teal)),
            )
          ],
        ),
        Row(
          children: [
            GestureDetector(
                onTap: null,
                child: Text(location!,
                    style: Theme.of(context).textTheme.bodyText2!.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey))),
            GestureDetector(
                onTap: null,
                child: IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.place,
                      color: Theme.of(context).primaryColor,
                    ))),
          ],
        )
      ],
    );

    // return Column(
    //   children: <Widget>[
    //     Row(
    //       mainAxisAlignment: MainAxisAlignment.start,
    //       children: <Widget>[
    //         Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
    //         GestureDetector(
    //           onTap: handleLikePost,
    //           child: Icon(
    //             isLiked! ? Icons.favorite : Icons.favorite_border,
    //             size: 28.0,
    //             color: Colors.pink,
    //           ),
    //         ),
    //         Padding(
    //           padding: EdgeInsets.only(right: 20.0),
    //         ),
    //         GestureDetector(
    //           onTap: () => showComments(
    //             context,
    //             postId: postId,
    //             ownerId: ownerId,
    //             mediaUrl: mediaUrl,
    //           ),
    //           child: Icon(
    //             Icons.chat,
    //             size: 28.0,
    //             color: Colors.blue[900],
    //           ),
    //         ),
    //       ],
    //     ),
    //     Row(
    //       children: <Widget>[
    //         Container(
    //           margin: EdgeInsets.only(left: 20.0),
    //           child: Text(
    //             "$likeCount likes",
    //             style: TextStyle(
    //               color: Colors.black,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         )
    //       ],
    //     ),
    //     Row(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: <Widget>[
    //         Container(
    //           margin: EdgeInsets.only(left: 20.0),
    //           child: Text(
    //             "$username ",
    //             style: TextStyle(
    //               color: Colors.black,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ),
    //         Expanded(
    //           child: Text(description!),
    //         ),
    //       ],
    //     )
    //   ],
    // );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes![currentUserId] == true);

    return Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        margin: const EdgeInsets.all(16),
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              buildPostHeader(),
              buildDescription(),
              buildPostImage(),
              buildPostFooter(),
            ])));
    // return Column(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     buildPostHeader(),
    //     buildDescription(),
    //     buildPostImage(),
    //     buildPostFooter(),
    //   ],
    // );
  }
}

showComments(BuildContext context,
    {String? postId, String? ownerId, String? mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}
