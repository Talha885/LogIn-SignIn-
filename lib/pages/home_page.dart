import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sigin/pages/text_box.dart';

import 'googlemaps.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  final userCollection = FirebaseFirestore.instance.collection("Users");
  String? _profilePictureURL;

  double? lat;

  double? long;

  String address = "";

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      throw 'Location services are disabled.';
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw 'Location permissions are permanently denied, we cannot request permissions.';
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  getLatLong() async {
    try {
      Position value = await _determinePosition();
      print("value $value");
      setState(() {
        lat = value.latitude;
        long = value.longitude;
      });

      getAddress(value.latitude, value.longitude);
    } catch (error) {
      print("Error $error");
    }
  }

  getAddress(double lat, double long) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
    setState(() {
      address = placemarks[0].street! + " " + placemarks[0].country!;
    });

    for (int i = 0; i < placemarks.length; i++) {
      print("INDEX $i ${placemarks[i]}");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePictureURL();
  }

  Future<void> _loadProfilePictureURL() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user!.email)
        .get();

    if (snapshot.exists) {
      final userData = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _profilePictureURL = userData['profilePictureURL'];
      });
    }
  }

  Future<void> _editField(BuildContext context, String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(newValue),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (newValue.trim().length > 0) {
      await userCollection.doc(user!.email).update({field: newValue});
    }
  }

  void _signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: _signUserOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .doc(user!.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;

            return ListView(
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_profilePictureURL ??
                      'https://about.canva.com/wp-content/uploads/sites/8/2019/03/gray.png'),
                ),
                const SizedBox(height: 10),
                Text(
                  "LOGGED IN AS: ${user?.email ?? 'Unknown'}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Text(
                    'My Details',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                MyTextBox(
                  text: userData?['username'] ?? '',
                  selectionName: 'username',
                  onPressed: () => _editField(context, 'username'),
                ),
                MyTextBox(
                  text: userData?['bio'] ?? '',
                  selectionName: 'bio',
                  onPressed: () => _editField(context, 'bio'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Text("Lat : $lat"),
                      const SizedBox(height: 5),
                      Text("Long : $long"),
                      const SizedBox(height: 5),
                      Text("Address : $address "),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: getLatLong,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 36, 36, 36),
                        ),
                        child: const Text("Get Location"),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoogleMapsPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 36, 36, 36),
                        ),
                        child: const Text("Open Google Maps"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
