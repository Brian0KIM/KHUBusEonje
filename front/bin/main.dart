import 'dart:io';
import 'package:bus_client/bus_client.dart';
const Map<String, String> busRouteMap = {
  "9": "200000103",
  "1112": "234000016",
  "5100": "200000115",
  "7000": "200000112",
  "M5107": "234001243",
  "1560A": "234000884",
  "1560B": "228000433"
};
const String KHU_ID = '';
const String KHU_PW = '';
const Map<String, String> stationMap = {
  "사색의광장(정문행)": "228001174",
  "생명과학대.산업대학(정문행)": "228000704",
  "경희대체육대학.외대(정문행)": "228000703",
  "경희대학교(정문행)": "203000125",
  "경희대정문(사색행)": "228000723",
  "외국어대학(사색행)": "228000710",
  "생명과학대(사색행)": "228000709",
  "사색의광장(사색행)": "228000708",
  "경희대차고지(1)": "228000706",
  "경희대차고지(2)": "228000707"
};
String? getRouteId(String routeName) => busRouteMap[routeName];
String? getStationId(String stationName) => stationMap[stationName];

void main() async {
  final client = BusClient();
  
  while (true) {
    print('\n버스 정보 시스템');
    print('1. 로그인');
    print('2. 로그아웃');
    print('3. 사용자 상태 확인');
    print('4. 버스 도착 정보');
    print('5. 정류장 도착 정보');
    print('6. 정차 기록 확인');
    print('7. 버스별 운행 기록');
    print('8. 시간별 운행 기록');
    print('9. 종료');
    
    stdout.write('선택하세요: ');
    final choice = stdin.readLineSync();
    
    switch (choice) {
      case '1':
        case '1':
        await client.login(KHU_ID, KHU_PW);
        break;
      case '2':
        await client.logout();
        break;
      case '3':
        await client.checkStatus();
        break;
      case '4':
         print('\n사용 가능한 버스 노선:');
        busRouteMap.keys.forEach((name) => print(name));
        stdout.write('\n노선명을 입력하세요: ');
        final routeName = stdin.readLineSync();
        if (routeName != null) {
          final routeId = getRouteId(routeName);
          if (routeId != null) {
            await client.startBusEtaPolling(routeId);
          } else {
            print('올바르지 않은 버스 노선명입니다.');
          }
        }
        break;
      case '5':
        print('\n사용 가능한 정류장:');
        stationMap.keys.forEach((name) => print(name));
        stdout.write('\n정류장명을 입력하세요: ');
        final stationName = stdin.readLineSync();
        if (stationName != null) {
          final stationId = getStationId(stationName);
          if (stationId != null) {
            await client.startStopEtaPolling(stationId);
          } else {
            print('올바르지 않은 정류장명입니다.');
          }
        }
        break;
      case '6':
        print('\n사용 가능한 정류장:');
        stationMap.keys.forEach((name) => print(name));
        stdout.write('\n정류장명을 입력하세요: ');
        final stationName = stdin.readLineSync();
        if (stationName != null) {
          final stationId = getStationId(stationName);
          if (stationId != null) {
            await client.startPassedByPolling(stationId);
          } else {
            print('올바르지 않은 정류장명입니다.');
          }
        }
        break;
      case '7':
        print('\n사용 가능한 버스 노선:');
        busRouteMap.keys.forEach((name) => print(name));
        stdout.write('\n노선명을 입력하세요: ');
        final routeName = stdin.readLineSync();
        
        print('\n사용 가능한 정류장:');
        stationMap.keys.forEach((name) => print(name));
        stdout.write('\n정류장명을 입력하세요: ');
        final stationName = stdin.readLineSync();
        
        stdout.write('날짜를 입력하세요 (YYYY-MM-DD): ');
        final date = stdin.readLineSync();
        
        if (routeName != null && stationName != null && date != null) {
          final routeId = getRouteId(routeName);
          final stationId = getStationId(stationName);
          if (routeId != null && stationId != null) {
            await client.getBusHistory(routeId, stationId, date);
          } else {
            print('올바르지 않은 버스 노선명 또는 정류장명입니다.');
          }
        }
        break;
      case '8':
        print('\n사용 가능한 정류장:');
        stationMap.keys.forEach((name) => print(name));
        stdout.write('\n정류장명을 입력하세요: ');
        final stationName = stdin.readLineSync();
        stdout.write('날짜를 입력하세요 (YYYY-MM-DD): ');
        final date = stdin.readLineSync();
        if (stationName != null && date != null) {
          final stationId = getStationId(stationName);
          if (stationId != null) {
            await client.getTimeHistory(stationId, date);
          } else {
            print('올바르지 않은 정류장명입니다.');
          }
        }
        break;
      case '9':
        exit(0);
      default:
        print('잘못된 선택입니다.');
    }
  }
}
class IoUtils {
  static Stdin get stdin => stdin;
}