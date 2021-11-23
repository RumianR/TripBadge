import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trip_badge/models/user.dart';
import 'package:trip_badge/pages/activity_feed.dart';
import 'package:trip_badge/pages/create_account.dart';
import 'package:trip_badge/pages/profile.dart';
import 'package:trip_badge/pages/search.dart';
import 'package:trip_badge/pages/timeline.dart';
import 'package:trip_badge/pages/upload.dart';

final GoogleSignIn googleSignin = GoogleSignIn();
final Reference storageReference = FirebaseStorage.instance.ref();

final CollectionReference usersRef =
    FirebaseFirestore.instance.collection('users');
final CollectionReference postsRef =
    FirebaseFirestore.instance.collection('posts');
final CollectionReference commentsRef =
    FirebaseFirestore.instance.collection('comments');
final CollectionReference activityFeedRef =
    FirebaseFirestore.instance.collection('feed');
final CollectionReference followersRef =
    FirebaseFirestore.instance.collection('followers');
final CollectionReference followingRef =
    FirebaseFirestore.instance.collection('following');
final CollectionReference timelineRef =
    FirebaseFirestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
User? currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  late PageController pageController;
  int pageIndex = 0;
  bool handlingSignIn = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    // Detects when user is signed in
    googleSignin.onCurrentUserChanged.listen((account) async {
      await handleSignIn(account);

      ;
    }, onError: (err) {
      print('Error signing in: $err');
    });
    // Reauth user when app is opened
    googleSignin.signInSilently(suppressErrors: false).then((account) async {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  handleSignIn(account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    // 1) check if user exists in users collection in database (according to their id)

    final GoogleSignInAccount? user = googleSignin.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user!.id).get();

    // 2) if user don't exist, take them to user create account page

    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      // 3) get username from create account, use it to make new user document in users collection
      usersRef.doc(user.id).set({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      await followersRef
        ..doc(user.id).collection('userFollowers').doc(user.id).set({});
      doc = await usersRef.doc(user.id).get();
    }

    currentUser = User.fromDocument(doc);
    print(currentUser?.username);
  }

  login() {
    googleSignin.signIn();
  }

  logout() {
    googleSignin.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTapBottomNav(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: [
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(
            currentUser: currentUser,
          ),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTapBottomNav,
        activeColor: getActiveColor(pageIndex),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.notifications_active,
          )),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.map,
            size: 35.0,
          )),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.search,
          )),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.account_circle,
          ))
        ],
      ),
    );
    // return ElevatedButton(onPressed: logout, child: Text('Logout'));
  }

  getActiveColor(pageIndex) {
    if (pageIndex == 0) {
      return Theme.of(context).primaryColor;
    } else if (pageIndex == 1) {
      return Colors.yellow[800];
    } else if (pageIndex == 2) {
      return Colors.green;
    } else if (pageIndex == 3) {
      return Colors.blue;
    } else if (pageIndex == 4) {
      return Colors.pink;
    }
  }

  // Widget buildAuthScreen() {
  //   return Text("Authenticated");
  // }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary
              ]),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'TripBadge',
                style: TextStyle(
                  fontFamily: "Signatra",
                  fontSize: 90.0,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
