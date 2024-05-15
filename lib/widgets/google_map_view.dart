import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracking/helper/google_map_places_service.dart';
import 'package:route_tracking/helper/location_service.dart';
import 'package:route_tracking/models/places_autocomplete_model/places_autocomplete_model.dart';
import 'package:route_tracking/models/routes_model/routes_model.dart';
import 'package:route_tracking/widgets/custom_list_view.dart';
import 'package:route_tracking/widgets/custom_text_field.dart';
import 'package:uuid/uuid.dart';

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({super.key});

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  late CameraPosition initialCameraPosition;
  late GoogleMapsPlacesService googleMapsPlacesService;
  late GoogleMapController googleMapController;
  late LocationService locationService;
  late TextEditingController textEditingController;
  String? sessionToken;
  late Uuid uuid;
  late LatLng currentLocation;
  late LatLng destinationLocation;
  Set<Marker> markers = {};
  Set<Polyline> polyLines = {};
  List<PlacesAutocompleteModel> places = [];
  List<LatLng> polylineCoordinates = [];

  @override
  void initState() {
    uuid = const Uuid();
    textEditingController = TextEditingController();
    googleMapsPlacesService = GoogleMapsPlacesService();
    fetchPrediction();
    initialCameraPosition =
        const CameraPosition(target: LatLng(30.89856, -6.904988));
    locationService = LocationService();
    super.initState();
  }

  void fetchPrediction() {
    sessionToken ??= uuid.v4();
    textEditingController.addListener(() async {
      if (textEditingController.text.isNotEmpty) {
        var result = await googleMapsPlacesService.getPredictions(
            sessionToken: sessionToken!, input: textEditingController.text);
        places.clear();
        places.addAll(result);
        setState(() {});
      } else {
        places.clear();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          polylines: polyLines,
          markers: markers,
          onMapCreated: (controller) {
            googleMapController = controller;
            updatecurrentLocation();
          },
          initialCameraPosition: initialCameraPosition,
          zoomControlsEnabled: false,
        ),
        Positioned(
          top: 16,
          right: 16,
          left: 16,
          child: Column(
            children: [
              CustomTextField(
                controller: textEditingController,
              ),
              const SizedBox(
                height: 10,
              ),
              CustomListView(
                places: places,
                googleMapsPlacesService: googleMapsPlacesService,
                onPlaceSelect: (placeDetailsModel) async {
                  textEditingController.clear();
                  places.clear();
                  sessionToken = null;
                  setState(() {});
                  destinationLocation = LatLng(
                      placeDetailsModel.geometry!.location!.lat!,
                      placeDetailsModel.geometry!.location!.lng!);
                  await getRoute();

                  // displayRoute(points);
                },
              )
            ],
          ),
        )
      ],
    );
  }

  Future<void> getRoute() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyBVofSHmm5fYuCQFYHlNSltQJhVjAi1H80',
      PointLatLng(currentLocation.latitude, currentLocation.longitude),
      PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    displayRoute();
  }

  void myMarkers(LatLng latLng) async {
    var myMarkers = Marker(
      markerId: const MarkerId('my_location_marker'),
      position: latLng,
    );
    markers.add(myMarkers);
    setState(() {});
  }

  void updatecurrentLocation() async {
    try {
      var locationData = await locationService.getLocation();
      currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      CameraPosition myCurrentCameraPosition =
          CameraPosition(target: currentLocation, zoom: 15);
      myMarkers(currentLocation);
      googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(myCurrentCameraPosition));
    } on LocationServiceException catch (e) {
      // todo
    } on LocationPermissionException catch (e) {
      // todo
    } catch (e) {
      //todo
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    googleMapController.dispose();
    textEditingController;
    super.dispose();
  }

  void displayRoute() {
    Polyline route = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: polylineCoordinates,
    );
    polyLines.add(route);
    LatLngBounds bounds = getLatLungBounds(polylineCoordinates);

    googleMapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
    setState(() {});
  }

  LatLngBounds getLatLungBounds(List<LatLng> points) {
    var southWestLatitude = points.first.latitude;
    var southWestLongtude = points.first.longitude;
    var northEastLatitude = points.first.latitude;
    var northEastLongtude = points.first.longitude;
    for (var point in points) {
      southWestLatitude = min(southWestLatitude, point.latitude);
      southWestLongtude = min(southWestLongtude, point.longitude);
      northEastLatitude = max(northEastLatitude, point.longitude);
      northEastLongtude = max(northEastLongtude, point.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(southWestLatitude, southWestLongtude),
      northeast: LatLng(northEastLatitude, northEastLongtude),
    );
  }
}
