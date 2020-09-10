import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
// import 'package:permission/permission.dart';

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  GoogleMapController googleMapController;
  static LatLng _initialPosition;
  TextEditingController locationController = TextEditingController();
  String startPoint;
  TextEditingController destinationController = TextEditingController();
  //  List<Address> address;
  LatLng _lastPosition = _initialPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> routeCoords;
  GoogleMapPolyline googlePolyline =
      new GoogleMapPolyline(apiKey: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
  // for my custom marker pins
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  LocationData currentLocation;
// a reference to the destination location
  LocationData destinationLocation;
// wrapper around the location API
  Location location;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    location = new Location();
    location.onLocationChanged.listen((LocationData cLoc) {
      currentLocation = cLoc;
      updatePinOnMap();
    });
    // set custom marker pins
    setSourceAndDestinationIcons();
    _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initialPosition == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _initialPosition, zoom: 15),
                  mapType: MapType.normal,
                  onMapCreated: onCreated,
                  myLocationEnabled: true,
                  compassEnabled: true,
                  markers: _markers,
                  onCameraMove: _onCameraMoved,
                  polylines: _polylines,
                ),

                Positioned(
                  top: 50.0,
                  right: 15.0,
                  left: 15.0,
                  child: Container(
                    height: 50.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey,
                            offset: Offset(1.0, 5.0),
                            blurRadius: 10,
                            spreadRadius: 3)
                      ],
                    ),
                    child: TextField(
                      cursorColor: Colors.black,
                      controller: destinationController,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (value) {
                        sendRequest(value);
                      },
                      decoration: InputDecoration(
                        icon: Container(
                          margin: EdgeInsets.only(left: 20, top: 5),
                          width: 10,
                          height: 10,
                          child: Icon(
                            Icons.local_taxi,
                            color: Colors.deepPurple,
                          ),
                        ),
                        hintText: " enter destination?",
                        labelText: "destination",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(left: 15.0, top: 16.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void onCreated(GoogleMapController controller) {
    setState(() {
      googleMapController = controller;
    });
  }

  void _onCameraMoved(CameraPosition position) {
    setState(() {
      _lastPosition = position.target;
    });
  }

  void _addMarker(LatLng location, String address, BitmapDescriptor data) {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(data==sourceIcon?"sourceid":"destinationid"),
          position: location,
          infoWindow: InfoWindow(title: address),
          icon: data));
    });
  }

  void createRoute(List<LatLng> routeCoords) {
    setState(() {

      _polylines.add(Polyline(
          polylineId: PolylineId(_lastPosition.toString()),
          width: 2,
          visible: true,
          points: routeCoords,
          color: Colors.black,
          startCap: Cap.squareCap,
          endCap: Cap.buttCap));
    });
  }

  void _getUserLocation() async {
    currentLocation = await location.getLocation();
    // final coordinates = new Coordinates(18.6694,73.8154);
    final coordinates =new Coordinates(currentLocation.latitude, currentLocation.longitude);
    var addresses =await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    print("${first.featureName} : ${first.addressLine}");
    setState(() {
      // _initialPosition = LatLng(18.6694,73.8154);
      _initialPosition = LatLng(currentLocation.latitude, currentLocation.longitude);
     
      startPoint=first.addressLine;
    });
  }

  void sendRequest(String intendedLocation) async {
    final query = intendedLocation;
    var addresses = await Geocoder.local.findAddressesFromQuery(query);
    var first = addresses.first;
    print("${first.featureName} : ${first.coordinates}");

    LatLng destination =
        LatLng(first.coordinates.latitude, first.coordinates.longitude);
    _addMarker(destination, intendedLocation, destinationIcon);
    _addMarker(LatLng(currentLocation.latitude, currentLocation.longitude), startPoint, sourceIcon);
    // String route=await googleMapServices.getRoutCordinates(_initialPosition, destination);
    // createRoute(route);
    routeCoords = await googlePolyline.getCoordinatesWithLocation(
        origin: _initialPosition,
        destination: destination,
        mode: RouteMode.driving);
    createRoute(routeCoords);
  }

  void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.0), 'assets/driving_pin.png')
        .then((onValue) {
      sourceIcon = onValue;
    });

    BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.0),
            'assets/destination_map_marker.png')
        .then((onValue) {
      destinationIcon = onValue;
    });
  }

  void updatePinOnMap() async {
    CameraPosition cameraPosition = CameraPosition(
        zoom: 16,
        target: LatLng(currentLocation.latitude, currentLocation.longitude));
        googleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        setState(() {
          var pinPosition =LatLng(currentLocation.latitude, currentLocation.longitude);
          _markers.removeWhere((m) => m.markerId.value == "sourceid");
          _markers.add(Marker(
          markerId: MarkerId('sourceid'),
          position: pinPosition, // updated position
          icon: sourceIcon));
        });
  }
}
