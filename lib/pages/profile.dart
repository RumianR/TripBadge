import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trip_badge/models/user.dart';
import 'package:trip_badge/pages/edit_profile.dart';
import 'package:trip_badge/pages/home.dart';
import 'package:trip_badge/widgets/header.dart';
import 'package:trip_badge/widgets/post.dart';
import 'package:trip_badge/widgets/post_tile.dart';
import 'package:trip_badge/widgets/profile_map.dart';
import 'package:trip_badge/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String? profileId;
  final bool? removeBackArrowFromAppbar;

  Profile({this.profileId, this.removeBackArrowFromAppbar = true});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String? currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isLoading = false;
  bool isFollowing = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  refresh() {
    getProfilePosts();
    setState(() {});
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    // Make auth user follower of THAT user (update THEIR followers collection)
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .set({});
    // Put THAT user on YOUR following collection (update your following collection)
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .set({});
    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser!.username,
      "userId": currentUserId,
      "userProfileImg": currentUser!.photoUrl,
      "timestamp": timestamp,
      "mediaUrl": "",
      "commentData": "",
      "postId": ""
    });
    followerCount++;
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // remove following
    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    followerCount--;
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
      followerCount = snapshot.docs.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs
          .map((doc) => Post.fromDocument(doc, notifyParent: refresh))
          .toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w400,
                fontSize: 15.0),
          ),
        )
      ],
    );
  }

  editProfile() {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    EditProfile(currentUserId: currentUserId!)))
        .then((value) => setState(() {
              // refresh state of Page1
            }));
  }

  buildProfileButton() {
    // viewing our own profile -  we should show the edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else if (isFollowing) {
      return buildButton(
        text: "Unfollow",
        function: handleUnfollowUser,
      );
    } else if (!isFollowing) {
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 260.0,
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      return Expanded(child: MyHomePage());
      //   List<GridTile> gridTiles = [];
      //   posts.forEach((post) {
      //     gridTiles.add(GridTile(
      //       child: PostTile(post: post),
      //     ));
      //   });

      //   return GridView.count(
      //     crossAxisCount: 3,
      //     childAspectRatio: 1.0,
      //     mainAxisSpacing: 1.5,
      //     crossAxisSpacing: 1.5,
      //     shrinkWrap: true,
      //     physics: NeverScrollableScrollPhysics(),
      //     children: gridTiles,
      //   );
    } else if (postOrientation == "list") {
      return Expanded(
          child: ListView(
        children: posts,
      ));
    }
  }

  Container buildButton({required String text, required Function() function}) {
    return Container(
      height: 30,
      // padding: EdgeInsets.symmetric(vertical: 1, horizontal: 1),
      child: TextButton(
        child: Text(text,
            style: TextStyle(
                color: isFollowing ? Colors.black : Colors.blue, fontSize: 12)),
        onPressed: function,
      ),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10)),
    );
  }

  FutureBuilder buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followerCount),
                            buildCountColumn("following", followingCount)
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [buildProfileButton()],
                        )
                      ],
                    ),
                  )
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(user.bio),
              ),
            ],
          ),
        );
      },
    );
  }

  FutureBuilder buildProfileHeader2() {
    return FutureBuilder(
        future: usersRef.doc(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);

          return Column(
            children: [
              // profile photo
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(user.photoUrl),
                  ),
                ),
              ),
              // username
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Text(
                  user.username,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),
              ),

              // bio
              Text(
                user.bio,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 15),
              // number of following, followers, likes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Column(
                        children: [
                          Text(
                            followingCount.toString(),
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Following',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: Column(
                        children: [
                          Text(
                            followerCount.toString(),
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Followers',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [
                          Text(
                            postCount.toString(),
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            '  Pins  ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // buttons -> edit profile, insta links, bookmark
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildProfileButton(),
                ],
              ),

              SizedBox(height: 10),
            ],
          );
        });
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
            onPressed: () => setPostOrientation("grid"),
            icon: Icon(Icons.public),
            color: postOrientation == "grid"
                ? Theme.of(context).primaryColor
                : Colors.grey),
        IconButton(
            onPressed: () => setPostOrientation("list"),
            icon: Icon(Icons.list),
            color: postOrientation == "list"
                ? Theme.of(context).primaryColor
                : Colors.grey),
      ],
    );
  }

  FutureBuilder buildProfileAppBar() {
    return FutureBuilder(
        future: usersRef.doc(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return profileAppBar(context, editProfile,
                username: "",
                removeBackButton: widget.removeBackArrowFromAppbar);
          }
          User user = User.fromDocument(snapshot.data);
          return profileAppBar(context, editProfile,
              username: user.displayName,
              removeBackButton: widget.removeBackArrowFromAppbar);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: buildProfileAppBar(),
        ),
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              buildProfileHeader2(),
              Divider(
                height: 0.0,
              ),
              buildTogglePostOrientation(),
              Divider(
                height: 0.0,
              ),
              Container(
                height: 300,
                child: buildProfilePosts(),
              ),
            ],
          ),
        ));
  }
}
