// import 'dart:convert';

// import 'package:route_tracking/models/location_info/location_info.dart';
// import 'package:route_tracking/models/routes_model/routes_model.dart';
// import 'package:http/http.dart' as http;
// import 'package:route_tracking/models/routes_modifires.dart';

// class RoutesService {
//   final String baseUrl =
//       'https://routes.googleapis.com/directions/v2:computeRoutes';
//   final String apiKey = 'AIzaSyBVofSHmm5fYuCQFYHlNSltQJhVjAi1H80';
//   fetchRoutes(
//       {required LocationInfoModel origin,
//       required LocationInfoModel destination,
//       RoutesModifires? routesModifires}) async {
//     Uri url = Uri.parse(baseUrl);
//     Map<String, String> headers = {
//       'Content-Type': 'application/json',
//       'X-Goog-Api-Key': apiKey,
//       'X-Goog-FieldMask':
//           'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
//     };
//     Map<String, dynamic> body = {
//       "origin": origin.toJson(),
//       "destination": destination.toJson(),
//       "travelMode": "DRIVE",
//       "routingPreference": "TRAFFIC_AWARE",
//       "computeAlternativeRoutes": false,
//       "routeModifiers": routesModifires?.toJson() ?? RoutesModifires().toJson(),
//       "languageCode": "en-US",
//       "units": "IMPERIAL"
//     };
//     var response = await http.post(
//       url,
//       headers: headers,
//       body: jsonEncode(body),
//     );
//     if (response.statusCode == 200) {
//       return RoutesModel.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('No routes found');
//     }
//   }
// }
