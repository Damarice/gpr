import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as LocationPackage;
import 'package:share/share.dart';

void main() {
  runApp(GpsToAddressApp());
}

class GpsToAddressApp extends StatefulWidget {
  @override
  _GpsToAddressAppState createState() => _GpsToAddressAppState();
}

class _GpsToAddressAppState extends State<GpsToAddressApp> {
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  String address = '';
  String coordinates = '';
  GoogleMapController? mapController;
  LocationPackage.LocationData? currentLocation;
  List<String> recentSearches = [];

  void convertCoordinatesToAddress() async {
    final double? latitude = double.tryParse(latitudeController.text);
    final double? longitude = double.tryParse(longitudeController.text);

    if (latitude != null && longitude != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          setState(() {
            address = placemarks[0].name!;
            coordinates = 'Coordinates: $latitude, $longitude';
            recentSearches.add('$latitude, $longitude - $address');
          });
        } else {
          setState(() {
            address = 'No address found';
            coordinates = '';
          });
        }
      } catch (e) {
        setState(() {
          address = 'Error occurred: $e';
          coordinates = '';
        });
      }
    } else {
      setState(() {
        address = 'Invalid coordinates';
        coordinates = '';
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _getCurrentLocation() async {
    LocationPackage.Location location = LocationPackage.Location();
    currentLocation = await location.getLocation();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Widget _buildAddressDisplay() {
    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: latitudeController,
                  keyboardType: TextInputType.number,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  placeholder: 'Latitude',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CupertinoTextField(
                  controller: longitudeController,
                  keyboardType: TextInputType.number,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  placeholder: 'Longitude',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          CupertinoButton(
            onPressed: convertCoordinatesToAddress,
            color: Colors.purple,
            child: Text('Convert'),
          ),
          SizedBox(height: 16),
          Text(
            'Address:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            address,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            coordinates,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: address.isNotEmpty
                ? () {
                    Share.share('Address: $address\nCoordinates: $coordinates');
                  }
                : null,
            child: Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS to Address Converter',
      theme: ThemeData(
        primaryColor: Colors.purple,
        hintColor: Colors.purpleAccent,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('GPS to Address Converter'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/white.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAddressDisplay(),
              SizedBox(height: 16),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentLocation?.latitude ?? 0,
                        currentLocation?.longitude ?? 0,
                      ),
                      zoom: 15,
                    ),
                    markers: Set<Marker>.from([
                      Marker(
                        markerId: MarkerId('currentLocation'),
                        position: LatLng(
                          currentLocation?.latitude ?? 0,
                          currentLocation?.longitude ?? 0,
                        ),
                        icon: BitmapDescriptor.defaultMarker,
                        infoWindow: InfoWindow(title: 'Current Location'),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
