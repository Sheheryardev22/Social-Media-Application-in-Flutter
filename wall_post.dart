import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madproject/commentButton.dart';
import 'package:madproject/deleteButton.dart';
import 'package:madproject/like_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madproject/comments.dart';

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  final String postId;
  final List<String> likes;

  const WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.postId,
    required this.likes,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;

  //comment text controller

  final commentTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentUser.email);
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    //Access the document in Firebase

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('User Posts').doc(widget.postId);

    if (isLiked) {
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentUser.email]),
      });
    } else {
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentUser.email]),
      });
    }
  }

  void addComment(String commentText) {
    FirebaseFirestore.instance
        .collection('User Posts')
        .doc(widget.postId)
        .collection('Comments')
        .add({
      "CommentText": commentText,
      "CommentedBy": currentUser.email,
      "CommentTime": Timestamp.now(),
    });
  }

  void showCommentDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Add Comment"),
              content: TextField(
                controller: commentTextController,
                decoration: InputDecoration(hintText: "Write a comment..."),
              ),
              actions: [
                //save button

                TextButton(
                    onPressed: () {
                      addComment(commentTextController.text);
                      commentTextController.clear();
                    },
                    child: Text("Post")),

                //cancel button
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);

                      //clear controller

                      commentTextController.clear();
                    },
                    child: Text("Cancel")),
              ],
            ));
  }

  void deletePost() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Delete Post"),
                content:
                    const Text("Are you sure you want to delete this post?"),
                actions: [
                  //Cancel
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel")),

                  // Delete button

                  TextButton(
                      onPressed: () async {
                        final commentDocs = await FirebaseFirestore.instance
                            .collection('User Posts')
                            .doc(widget.postId)
                            .collection("Comments")
                            .get();
                        //deleting the comments
                        for (var doc in commentDocs.docs) {
                          await FirebaseFirestore.instance
                              .collection("User Posts")
                              .doc(widget.postId)
                              .collection("Comments")
                              .doc(doc.id)
                              .delete();
                        }

                        //deleting the comment
                        FirebaseFirestore.instance
                            .collection("User Posts")
                            .doc(widget.postId)
                            .delete().then((value) => print("Post Deleted")).catchError((error) => print("Failed: $error" ));

                        Navigator.pop(context);
                        },
                      child: const Text("Delete")),
                ]));
  }

  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.only(top: 25, left: 25, right: 25),
        padding: EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user,
                        style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 10),
                    Text(widget.message),
                  ],
                ),
                //delete button
                if (widget.user == currentUser.email)
                  DeleteButton(
                    onTap: deletePost,
                  )
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    LikeButton(isLiked: isLiked, onTap: toggleLike),
                    const SizedBox(
                      height: 5,
                    ),

                    //likes count
                    Text(widget.likes.length.toString()),
                  ],
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  children: [
                    CommentButton(onTap: showCommentDialog),
                    const SizedBox(
                      height: 5,
                    ),

                    //likes count
                  ],
                ),
              ],
            ),

            //comments
            SizedBox(
              height: 10,
            ),
            StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('User Posts')
                    .doc(widget.postId)
                    .collection('Comments')
                    .orderBy("CommentTime", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: snapshot.data!.docs.map((doc) {
                      final commentData = doc.data() as Map<String, dynamic>;

                      return Comment(
                          text: commentData['CommentText'],
                          user: commentData['CommentedBy']);
                    }).toList(),
                  );
                })
          ],
        ));
  }
}
