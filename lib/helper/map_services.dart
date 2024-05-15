import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracking/helper/google_map_places_service.dart';
import 'package:route_tracking/helper/location_service.dart';
import 'package:route_tracking/models/place_details_model/place_details_model.dart';
import 'package:route_tracking/models/places_autocomplete_model/places_autocomplete_model.dart';

class MapServices {
  LocationService locationService = LocationService();
  PlacesService placesService = PlacesService();
  Future<void> getPredictions({
    required String sessionToken,
    required String input,
    required List<PlacesAutocompleteModel> places,
  }) async {
    if (input.isNotEmpty) {
      var result = await placesService.getPredictions(
          sessionToken: sessionToken, input: input);
      places.clear();
      places.addAll(result);
    } else {
      places.clear();
    }
  }

  Future<void> getRoute(
      {required LatLng currentLocation,
      required LatLng destinationLocation,
      required List<LatLng> polylineCoordinates}) async {
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
  }

  void displayRoute(
      {required List<LatLng> polylineCoordinates,
      required Set<Polyline> polyLines,
      required GoogleMapController googleMapController}) {
    Polyline route = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: polylineCoordinates,
    );
    polyLines.add(route);
    LatLngBounds bounds = getLatLungBounds(polylineCoordinates);

    googleMapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
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

  Future<LatLng> updatecurrentLocation(
      {required GoogleMapController googleMapController,
      required Set<Marker> markers}) async {
    var locationData = await locationService.getLocation();
    var currentLocation =
        LatLng(locationData.latitude!, locationData.longitude!);
    CameraPosition myCurrentCameraPosition =
        CameraPosition(target: currentLocation, zoom: 15);
    var myMarkers = Marker(
      markerId: const MarkerId('my_location_marker'),
      position: currentLocation,
    );
    markers.add(myMarkers);
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(myCurrentCameraPosition));
    return currentLocation;
  }

  Future<PlaceDetailsModel> getPlaceDetails({required String placeId}) async {
    return await placesService.getPlaceDetails(placeId: placeId);
  }
}
