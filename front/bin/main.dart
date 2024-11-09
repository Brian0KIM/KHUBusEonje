import 'dart:io';
import 'package:bus_client/bus_client.dart';
import 'package:bus_client/config.dart';
import 'dart:convert';
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
  "경희대차고지(1)": "228000706",
  "경희대차고지(2)": "228000707"
};
const Map<String, String> pathMap = {
  "1": "203000125",
  "2": "228000723"
};
String? getRouteId(String routeName) => busRouteMap[routeName];
String? getStationId(String stationName) => stationMap[stationName];
late final Map<String, dynamic> busCompanyData;
void main() async {
  final client = BusClient();
  final file = File('./assets/data/bus_company.json');
  busCompanyData = json.decode(await file.readAsString());
  while (true) {
    print('\n버스 정보 시스템');
    print('1. 로그인');
    print('2. 로그아웃');
    print('3. 사용자 상태 확인');
    print('4. 버스 도착 정보');
    print('5. 정류장 도착 정보');
    print('6. 민원/정차 기록 확인');
    print('7. 버스별 운행 기록');
    print('8. 시간별 운행 기록');
    print('9. 민원 정보');
    print('0. 종료');
    
    stdout.write('선택하세요: ');
    final choice = stdin.readLineSync();
    
    switch (choice) {
      case '1':
        case '1':
        await client.login(Config.KHU_ID, Config.KHU_PW);
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
        var stationList = stationMap.keys.toList();
        for (var i = 0; i < stationList.length; i++) {
            print('${i + 1}. ${stationList[i]}');
        }
    
        stdout.write('\n정류장 번호를 입력하세요 (1-${stationList.length}): ');
        final input = stdin.readLineSync()?.trim();
        if (input != null) {
        final index = int.tryParse(input);
        if (index != null && index >= 1 && index <= stationList.length) {
            final stationName = stationList[index - 1];
            final stationId = getStationId(stationName);
            if (stationId != null) {
                await client.startStopEtaPolling(stationId);
            }
        } else {
            print('올바른 번호를 입력해주세요 (1-${stationList.length}).');
          }
        }
        break;
      case '6':
         print('\n사용 가능한 방향:');
        print('1. 경희대학교(정문행)');
        print('2. 경희대정문(사색행)');
        
        stdout.write('\n방향 번호를 입력하세요 (1-2): ');
        final input = stdin.readLineSync()?.trim();
        
        if (input != null) {
            final index = int.tryParse(input);
            if (index != null && index >= 1 && index <= 2) {
                final pathId = pathMap[index.toString()];  // index를 문자열로 변환
                if (pathId != null) {
                    await client.startPassedByPolling(pathId);
                } else {
                    print('경로 ID를 찾을 수 없습니다.');
                }
            } else {
                print('올바른 번호를 입력해주세요 (1-2).');
            }
        }
        break;
      case '7':
        print('\n사용 가능한 버스 노선:');
        var routeList = busRouteMap.keys.toList();
        for (var i = 0; i < routeList.length; i++) {
            print('${i + 1}. ${routeList[i]}');
        }
        stdout.write('\n버스 노선 번호를 입력하세요 (1-${routeList.length}): ');
        final routeInput = stdin.readLineSync()?.trim();
        
        print('\n사용 가능한 정류장:');
        var stationList = stationMap.keys.toList();
        for (var i = 0; i < stationList.length; i++) {
            print('${i + 1}. ${stationList[i]}');
        }
        stdout.write('\n정류장 번호를 입력하세요 (1-${stationList.length}): ');
        final stationInput = stdin.readLineSync()?.trim();
        
        stdout.write('날짜를 입력하세요 (YYYY-MM-DD): ');
        final date = stdin.readLineSync()?.trim();
        
        if (routeInput != null && stationInput != null && date != null) {
            final routeIndex = int.tryParse(routeInput);
            final stationIndex = int.tryParse(stationInput);
            
            if (routeIndex != null && routeIndex >= 1 && routeIndex <= routeList.length &&
                stationIndex != null && stationIndex >= 1 && stationIndex <= stationList.length) {
                final routeName = routeList[routeIndex - 1];
                final stationName = stationList[stationIndex - 1];
                final routeId = getRouteId(routeName);
                final stationId = getStationId(stationName);
                
                if (routeId != null && stationId != null) {
                    await client.getBusHistory(routeId, stationId, date);
                }
            } else {
                print('올바른 번호를 입력해주세요.');
            }
        }
        break;
      case '8':
         print('\n사용 가능한 정류장:');
        var stationList = stationMap.keys.toList();
        for (var i = 0; i < stationList.length; i++) {
            print('${i + 1}. ${stationList[i]}');
        }
        stdout.write('\n정류장 번호를 입력하세요 (1-${stationList.length}): ');
        final input = stdin.readLineSync()?.trim();
        
        stdout.write('날짜를 입력하세요 (YYYY-MM-DD): ');
        final date = stdin.readLineSync()?.trim();
        
        if (input != null && date != null) {
            final index = int.tryParse(input);
            if (index != null && index >= 1 && index <= stationList.length) {
                final stationName = stationList[index - 1];
                final stationId = getStationId(stationName);
                if (stationId != null) {
                    await client.getTimeHistory(stationId, date);
                }
            } else {
                print('올바른 번호를 입력해주세요 (1-${stationList.length}).');
            }
        }
        break;
      case '9':
        print('\n민원 가능한 버스 회사/기관:');
        busCompanyData.forEach((key, value) {
          print('$key. ${value['name']}');
        });
        
        stdout.write('\n회사/기관 번호를 입력하세요 (1-${busCompanyData.length}): ');
        final input = stdin.readLineSync()?.trim();
        
        if (input != null) {
          final companyInfo = busCompanyData[input];
          if (companyInfo != null) {
            await client.displayCompanyInfo(companyInfo);
          } else {
            print('올바른 번호를 입력해주세요 (1-${busCompanyData.length}).');
          }
        }
        break;
      case '0':
        exit(0);
      default:
        print('잘못된 선택입니다.');
    }
  }
}
class IoUtils {
  static Stdin get stdin => stdin;
}