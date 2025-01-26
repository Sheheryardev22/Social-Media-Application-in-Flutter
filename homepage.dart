import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:madproject/text_field.dart';
import 'package:madproject/wall_post.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  //post text controller

  final textController = TextEditingController();

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  //post message

  void postMessage() {
    if (textController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection("User Posts").add({
        'UserEmail': currentUser.email,
        'Message': textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes' : [],
      });
    }
    setState(() {
      textController.clear();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          title: Text("Your Wall"),
          backgroundColor: Colors.grey[900],
          actions: [
            IconButton(
              onPressed: signOut,
              icon: Icon(Icons.logout),
            )
          ]),
      body: Center(
        child: Column(
          children: [
            //the wall
            // post message
            Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("User Posts")
                      .orderBy(
                    "TimeStamp",
                    descending: false,
                  ).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          // get the message

                          final post = snapshot.data!.docs[index];
                          return WallPost(message: post['Message'],
                              user: post['UserEmail'],
                            postId: post.id,
                            likes: List<String>.from(post['Likes'] ?? []),
                          );
                          },
                      );
                    }
                    else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error.toString()}'),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                )),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Row(
                //textfield

                children: [
                  Expanded(
                      child: MyTextField(
                        controller: textController,
                        hintText: "What's on your mind?",
                        obscureText: false,
                      )),

                  //post button

                  IconButton(
                      onPressed: postMessage,
                      icon: const Icon(Icons.arrow_circle_up))
                ],
              ),
            ),
            //logged in as (username)
            Text("Logged in as: " + currentUser.email!),
          ],
        ),
      ),
    );
  }
}
