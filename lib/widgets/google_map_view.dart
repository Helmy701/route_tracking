import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_tracking/helper/location_service.dart';
import 'package:route_tracking/helper/map_services.dart';
import 'package:route_tracking/models/places_autocomplete_model/places_autocomplete_model.dart';
import 'package:route_tracking/widgets/custom_list_view.dart';
import 'package:route_tracking/widgets/custom_text_field.dart';
import 'package:uuid/uuid.dart';

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({super.key});

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  late MapServices mapServices;
  late CameraPosition initialCameraPosition;
  late GoogleMapController googleMapController;
  late TextEditingController textEditingController;
  String? sessionToken;
  late Uuid uuid;
  late LatLng destinationLocation;
  Set<Marker> markers = {};
  Set<Polyline> polyLines = {};
  List<PlacesAutocompleteModel> places = [];
  List<LatLng> polylineCoordinates = [];
  Timer? debounce;

  @override
  void initState() {
    uuid = const Uuid();
    textEditingController = TextEditingController();
    fetchPrediction();
    initialCameraPosition =
        const CameraPosition(target: LatLng(30.89856, -6.904988));
    mapServices = MapServices();
    super.initState();
  }

  void fetchPrediction() {
    textEditingController.addListener(
      () async {
        if (debounce?.isActive ?? false) {
          debounce?.cancel();
        }
        debounce = Timer(
          const Duration(milliseconds: 100),
          () async {
            sessionToken ??= uuid.v4();
            await mapServices.getPredictions(
                sessionToken: sessionToken!,
                input: textEditingController.text,
                places: places);
            setState(() {});
          },
        );
      },
    );
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
            mapServices.updatecurrentLocation(
                onUpdateCurrentLocation: () => setState(() {}),
                googleMapController: googleMapController,
                markers: markers);
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
                mapServices: mapServices,
                onPlaceSelect: (placeDetailsModel) async {
                  textEditingController.clear();
                  places.clear();
                  sessionToken = null;
                  setState(() {});
                  destinationLocation = LatLng(
                      placeDetailsModel.geometry!.location!.lat!,
                      placeDetailsModel.geometry!.location!.lng!);
                  await mapServices.getRoute(
                      destinationLocation: destinationLocation,
                      polylineCoordinates: polylineCoordinates);
                  mapServices.displayRoute(
                      polylineCoordinates: polylineCoordinates,
                      polyLines: polyLines,
                      googleMapController: googleMapController);
                  setState(() {});

                  // displayRoute(points);
                },
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    googleMapController.dispose();
    textEditingController.dispose();
    debounce?.cancel();
    super.dispose();
  }
}
