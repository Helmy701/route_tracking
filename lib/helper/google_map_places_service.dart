import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:route_tracking/models/place_details_model/place_details_model.dart';
import 'package:route_tracking/models/places_autocomplete_model/places_autocomplete_model.dart';

class GoogleMapsPlacesService {
  final String baseUrl = 'https://maps.googleapis.com/maps/api/place/';
  final String apiKey = "AIzaSyBVofSHmm5fYuCQFYHlNSltQJhVjAi1H80";
  Future<List<PlacesAutocompleteModel>> getPredictions(
      {required String input, required String sessionToken}) async {
    http.Response response = await http.get(Uri.parse(
        "${baseUrl}autocomplete/json?key=$apiKey&input=$input&sessiontoken=$sessionToken"));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['predictions'];
      List<PlacesAutocompleteModel> places = [];
      for (var item in data) {
        places.add(PlacesAutocompleteModel.fromJson(item));
      }
      return places;
    } else {
      throw Exception();
    }
  }

  Future<PlaceDetailsModel> getPlaceDetails({required String placeId}) async {
    http.Response response = await http
        .get(Uri.parse("${baseUrl}details/json?place_id=$placeId&key=$apiKey"));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['result'];

      return PlaceDetailsModel.fromJson(data);
    } else {
      throw Exception();
    }
  }
}
