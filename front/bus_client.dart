import 'dart:async';  // Timer 클래스용
import 'dart:convert';  // jsonDecode, JsonEncoder용
import 'dart:io';  // stdin용
import 'package:http/http.dart' as http;  // http 요청용

const String baseUrl = 'http://localhost:8081';  // baseUrl 상수 정의

class BusClient {
  Timer? _busTimer;
  Timer? _stopTimer;
  Timer? _passedByTimer;
  
  Future<void> startBusEtaPolling(String routeId) async {
    // 기존 타이머 취소
    _busTimer?.cancel();
    
    // 즉시 첫 번째 데이터 가져오기
    await _fetchBusEta(routeId);
    
    // 15초마다 새로고침
    _busTimer = Timer.periodic(Duration(seconds: 15), (_) async {
      await _fetchBusEta(routeId);
    });
    
    print('\n종료하려면 아무 키나 누르세요...');
    stdin.readLineSync();
    _busTimer?.cancel();
  }
  
  Future<void> startStopEtaPolling(String stationId) async {
    _stopTimer?.cancel();
    
    await _fetchStopEta(stationId);
    
    _stopTimer = Timer.periodic(Duration(seconds: 15), (_) async {
      await _fetchStopEta(stationId);
    });
    
    print('\n종료하려면 아무 키나 누르세요...');
    stdin.readLineSync();
    _stopTimer?.cancel();
  }
  
  Future<void> startPassedByPolling(String stationId) async {
    _passedByTimer?.cancel();
    
    await _fetchPassedBy(stationId);
    
    _passedByTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      await _fetchPassedBy(stationId);
    });
    
    print('\n종료하려면 아무 키나 누르세요...');
    stdin.readLineSync();
    _passedByTimer?.cancel();
  }
  
  Future<void> _fetchBusEta(String routeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/bus/$routeId/eta'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('\x1B[2J\x1B[0;0H'); // 화면 클리어
        print('버스 도착 정보 (노선 ID: $routeId)');
        print(JsonEncoder.withIndent('  ').convert(data));
      } else {
        print('오류: ${response.statusCode}');
      }
    } catch (e) {
      print('요청 실패: $e');
    }
  }
  
  Future<void> _fetchStopEta(String stationId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stop/$stationId/eta'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('\x1B[2J\x1B[0;0H');
        print('정류장 도착 정보 (정류장 ID: $stationId)');
        print(JsonEncoder.withIndent('  ').convert(data));
      } else {
        print('오류: ${response.statusCode}');
      }
    } catch (e) {
      print('요청 실패: $e');
    }
  }
  
  Future<void> _fetchPassedBy(String stationId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/complain/$stationId/passedby'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('\x1B[2J\x1B[0;0H');
        print('무정차 기록 (정류장 ID: $stationId)');
        print(JsonEncoder.withIndent('  ').convert(data));
      } else {
        print('오류: ${response.statusCode}');
      }
    } catch (e) {
      print('요청 실패: $e');
    }
  }
}