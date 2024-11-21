const Map<String, String> busRouteMap = {
  "9": "200000103",
  "1112": "234000016",
  "5100": "200000115",
  "7000": "200000112",
  "M5107": "234001243",
  "1560A": "234000884",
  "1560B": "228000433"
};

const Map<String, String> stationMap = {
  "사색의광장(정문행)": "228001174",
  "생명과학대.산업대학(정문행)": "228000704",
  "경희대체육대학.외대(정문행)": "228000703",
  "경희대학교(정문행)": "203000125",
  "경희대정문(사색행)": "228000723",
  "외국어대학(사색행)": "228000710",
  "생명과학대(사색행)": "228000709",
  "사색의광장(사색행)": "228000708",
  "경희대차고지(1)": "228000361",
  "경희대차고지(2)": "228000362"
};

const Map<String, String> pathMap = {
  "1": "203000125",  // 경희대학교(정문행)
  "2": "228000723"   // 경희대정문(사색행)
};

String? getRouteName(String routeId) {
  return busRouteMap.entries
      .firstWhere((entry) => entry.value == routeId,
          orElse: () => MapEntry(routeId, routeId))
      .key;
}

String? getStationName(String stationId) {
  return stationMap.entries
      .firstWhere((entry) => entry.value == stationId,
          orElse: () => MapEntry(stationId, stationId))
      .key;
}

String? getRouteId(String routeName) {
  return busRouteMap[routeName];
}

String? getStationId(String stationName) {
  return stationMap[stationName];
}