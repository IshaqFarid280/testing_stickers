import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'BottomScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // unique ID on Android
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor; // unique ID on iOS
    }
    return null;
  }

  checkUserStatus() async {
    String? deviceId = await getDeviceId();
    if (deviceId == null) {
      // Handle the error, e.g., show an error message to the user
      return;
    }

    // Sign in anonymously to get a new UID
    UserCredential userCredential = await auth.signInAnonymously();
    String newUid = userCredential.user!.uid;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot doc = await firestore.collection('users').doc(deviceId).get();

    if (doc.exists) {
      // Device ID already registered, update the UID
      await firestore.collection('users').doc(deviceId).update({'uid': newUid});
    } else {
      // Device ID not registered, create a new document with the new UID
      await firestore.collection('users').doc(deviceId).set({'uid': newUid});
    }

    // Navigate to the main screen with the new UID
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (context) => BottomScreen(userId: newUid)),
    );

  }

  @override
  void initState() {
    super.initState();
    checkUserStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Image.asset('assets/images/splash.jpg', fit: BoxFit.cover),
      ),
    );
  }
}
