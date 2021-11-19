const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
        console.log("Follower created", snapshot.id);
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // 1) Create followed user posts ref
        const followedUserPostsRef =
            admin.firestore()
                .collection("posts")
                .doc(userId)
                .collection("userPosts");

        // 2) Create following user's timeline ref
        const timelinePostsRef =
            admin.firestore()
                .collection("timeline")
                .doc(followerId)
                .collection("timelinePosts");

        // 3) Get the followed users posts
        const querySnapshot = await followedUserPostsRef.get();

        // 4) Add each user post to the following user"s timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                timelinePostsRef.doc(postId).set(postData);
            }
        });

    });


exports.onDeleteFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot, context) => {
        console.log("Follower removed", snapshot.id);
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // 1) Get ref for all posts from person (userId) that we are unfollowing
        const timelinePostsRef =
            admin.firestore()
                .collection("timeline")
                .doc(followerId)
                .collection("timelinePosts")
                .where("ownerId", "==", userId);

        const querySnapshot = await timelinePostsRef.get();

        // 4) Remove each user post from the following user"s timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    });

// When a post is created, we want to add a post to the timeline of each follower (of post owner)
exports.onCreatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onCreate(async (snapshot, context) => {
        console.log("Post created", snapshot.id);

        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        // 1) Get all the followers of the user who made the post
        const userFollowersRef =
            admin.firestore()
                .collection("followers")
                .doc(userId)
                .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        // 2) Add new post to each follower's timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;
            admin.firestore()
                .collection("timeline")
                .doc(followerId)
                .collection("timelinePosts")
                .doc(postId)
                .set(postCreated);
        });

    });

// When a post is edited, we want to edit the post to the timeline of each follower (of post owner)
exports.onUpdatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onUpdate(async (change, context) => {


        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        // 1) Get all the followers of the user who updated the post
        const userFollowersRef =
            admin.firestore()
                .collection("followers")
                .doc(userId)
                .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        // 2) Update each post to each follower's timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;
            admin.firestore()
                .collection("timeline")
                .doc(followerId)
                .collection("timelinePosts")
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.update(postUpdated);
                    }
                }
                );
        });

    });


// When a post is deleted, we want to delete the post to the timeline of each follower (of post owner)
exports.onDeletePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onDelete(async (snapshot, context) => {
        const userId = context.params.userId;
        const postId = context.params.postId;

        // 1) Get all the followers of the user who updated the post
        const userFollowersRef =
            admin.firestore()
                .collection("followers")
                .doc(userId)
                .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        // 2) Delete each post to each follower's timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;
            admin.firestore()
                .collection("timeline")
                .doc(followerId)
                .collection("timelinePosts")
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                }
                );
        });

    });
