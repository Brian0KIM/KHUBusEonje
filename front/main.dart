import 'dart:io';
import './bus_client.dart'; 
const String baseUrl = 'http://localhost:8081';

void main() async {
  final client = BusClient();
  
  while (true) {
    print('\n버스 정보 시스템');
    print('1. 버스 도착 정보');
    print('2. 정류장 도착 정보');
    print('3. 무정차 기록 확인');
    print('4. 종료');
    
    stdout.write('선택하세요: ');
    final choice = stdin.readLineSync();
    
    switch (choice) {
      case '1':
        stdout.write('노선 ID를 입력하세요: ');
        final routeId = stdin.readLineSync();
        if (routeId != null) {
          await client.startBusEtaPolling(routeId);
        }
        break;
      case '2':
        stdout.write('정류장 ID를 입력하세요: ');
        final stationId = stdin.readLineSync();
        if (stationId != null) {
          await client.startStopEtaPolling(stationId);
        }
        break;
      case '3':
        stdout.write('정류장 ID를 입력하세요: ');
        final stationId = stdin.readLineSync();
        if (stationId != null) {
          await client.startPassedByPolling(stationId);
        }
        break;
      case '4':
        exit(0);
      default:
        print('잘못된 선택입니다.');
    }
  }
}