import 'package:flutter/material.dart';
import 'package:trip_badge/pages/home.dart';
import 'package:trip_badge/widgets/header.dart';
import 'package:trip_badge/widgets/post.dart';
import 'package:trip_badge/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String? userId;
  final String? postId;

  PostScreen({this.userId, this.postId});

  @override
  FutureBuilder build(BuildContext context) {
    return FutureBuilder(
      future: postsRef.doc(userId).collection('userPosts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header2(context, titleText: post.description!),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
