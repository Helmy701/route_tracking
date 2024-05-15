// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:route_tracking/helper/google_map_places_service.dart';
import 'package:route_tracking/helper/map_services.dart';
import 'package:route_tracking/models/place_details_model/place_details_model.dart';
import 'package:route_tracking/models/places_autocomplete_model/places_autocomplete_model.dart';

class CustomListView extends StatelessWidget {
  const CustomListView({
    Key? key,
    required this.places,
    required this.mapServices,
    required this.onPlaceSelect,
  }) : super(key: key);

  final List<PlacesAutocompleteModel> places;
  final MapServices mapServices;
  final void Function(PlaceDetailsModel) onPlaceSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(places[index].description!),
            leading: const Icon(FontAwesomeIcons.mapLocationDot),
            trailing: IconButton(
                onPressed: () async {
                  var placeDetails = await mapServices.getPlaceDetails(
                      placeId: places[index].placeId!);
                  onPlaceSelect(placeDetails);
                },
                icon: const Icon(Icons.arrow_right_alt_rounded)),
          );
        },
        separatorBuilder: (context, index) {
          return const Divider(
            height: 0,
          );
        },
        itemCount: places.length,
      ),
    );
  }
}
