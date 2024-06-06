import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testing_sticker/stickr_pack_screen.dart';

class UserPacksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Sticker Packs'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('packs')
            .where('user_id', isEqualTo: userId).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var packs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: packs.length,
            itemBuilder: (context, index) {
              var pack = packs[index];
              return ListTile(
                title: Text(pack['name']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StickerPackScreen(
                        packId: pack.id,
                        packName: pack['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
