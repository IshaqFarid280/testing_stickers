import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testing_sticker/stickr_pack_screen.dart';
import 'package:testing_sticker/upload_stickers.dart';

class AllStickersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          color: Colors.grey,
        ),



        onPressed: (){
          Navigator.of(context).push(CupertinoPageRoute(builder: (ctx)=> UploadStickerScreen()));
        },
      ),
      appBar: AppBar(
        title: Text('All Sticker Packs'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('packs').snapshots(),
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
                      builder: (context) => StickerPackScreen(packId: pack.id,packName: pack['name'],),
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
