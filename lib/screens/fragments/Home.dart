import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttercredittransferapp/layouts/RowForHome.dart';
import 'package:fluttercredittransferapp/screens/models/ModelForUser.dart';
import 'package:provider/provider.dart';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<ModelForUser> users = [];

  @override
  Widget build(BuildContext context) {

    final usersData = Provider.of<QuerySnapshot>(context);
    final currentUser = Provider.of<FirebaseUser>(context);

    if(usersData == null) {
      return Center(child: CircularProgressIndicator());
    }

    users.clear();
    for(var doc in usersData.documents) {
      if(doc.data['uid'] != currentUser.uid) {
        users.add(ModelForUser(uid: doc.data['uid'], name: doc.data['name'], email: doc.data['email'],
                                gender: doc.data['gender'], credit: doc.data['credit'], image: doc.data['image']));
      }
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return RowForHome(user: users[index]);
      },
    );
  }
}
