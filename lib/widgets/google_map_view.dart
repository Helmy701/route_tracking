import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracking/helper/google_map_places_service.dart';
import 'package:route_tracking/helper/location_service.dart';
import 'package:route_tracking/helper/routes_service.dart';
import 'package:route_tracking/models/location_info/lat_lng.dart';
import 'package:route_tracking/models/location_info/location.dart';
import 'package:route_tracking/models/location_info/location_info.dart';
import 'package:route_tracking/models/place_details_model/place_details_model.dart';
import 'package:route_tracking/models/places_autocomplete_model/places_autocomplete_model.dart';
import 'package:route_tracking/models/routes_model/route.dart';
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
  late RoutesService routesService;
  String? sessionToken;
  late Uuid uuid;
  late LatLng currentLocation;
  late LatLng destinationLocation;
  Set<Marker> markers = {};
  Set<Polyline> polyLines = {};
  List<PlacesAutocompleteModel> places = [];

  @override
  void initState() {
    uuid = const Uuid();
    textEditingController = TextEditingController();
    googleMapsPlacesService = GoogleMapsPlacesService();
    fetchPrediction();
    routesService = RoutesService();
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
                  var points = await getRouteData();
                  displayRoute(points);
                },
              )
            ],
          ),
        )
      ],
    );
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

  Future<List<LatLng>> getRouteData() async {
    LocationInfoModel origin = LocationInfoModel(
      location: LocationModel(
        latLng: LatLngModel(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        ),
      ),
    );
    LocationInfoModel destination = LocationInfoModel(
      location: LocationModel(
        latLng: LatLngModel(
          latitude: destinationLocation.latitude,
          longitude: destinationLocation.longitude,
        ),
      ),
    );
    RoutesModel routes = await routesService.fetchRoutes(
        origin: origin, destination: destination);
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> points = getDencodedRoute(polylinePoints, routes);
    return points;
  }

  List<LatLng> getDencodedRoute(
      PolylinePoints polylinePoints, RoutesModel routes) {
    List<PointLatLng> result = polylinePoints
        .decodePolyline(routes.routes!.first.polyline!.encodedPolyline!);
    List<LatLng> points =
        result.map((e) => LatLng(e.latitude, e.longitude)).toList();
    return points;
  }

  void displayRoute(List<LatLng> points) {
    Polyline route = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: points,
    );
    polyLines.add(route);
    setState(() {});
  }
}
