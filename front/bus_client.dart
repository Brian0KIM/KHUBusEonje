import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

const String baseUrl = 'http://localhost:8081';

class BusClient {
  late final Dio _dio;
  Timer? _busTimer;
  Timer? _stopTimer;
  Timer? _passedByTimer;

  BusClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
    ));
  }
  
  Future<void> startBusEtaPolling(String routeId) async {
    _busTimer?.cancel();
    await _fetchBusEta(routeId);
    
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
      final response = await _dio.get('/bus/$routeId/eta');
      print('\x1B[2J\x1B[0;0H'); // 화면 클리어
      print('버스 도착 정보 (노선 ID: $routeId)');
      print(JsonEncoder.withIndent('  ').convert(response.data));
    } on DioException catch (e) {
      if (e.response != null) {
        print('오류: ${e.response?.statusCode}');
      } else {
        print('요청 실패: ${e.message}');
      }
    }
  }
  
  Future<void> _fetchStopEta(String stationId) async {
    try {
      final response = await _dio.get('/stop/$stationId/eta');
      print('\x1B[2J\x1B[0;0H');
      print('정류장 도착 정보 (정류장 ID: $stationId)');
      print(JsonEncoder.withIndent('  ').convert(response.data));
    } on DioException catch (e) {
      if (e.response != null) {
        print('오류: ${e.response?.statusCode}');
      } else {
        print('요청 실패: ${e.message}');
      }
    }
  }
  
  Future<void> _fetchPassedBy(String stationId) async {
    try {
      final response = await _dio.get('/complain/$stationId/passedby');
      print('\x1B[2J\x1B[0;0H');
      print('무정차 기록 (정류장 ID: $stationId)');
      print(JsonEncoder.withIndent('  ').convert(response.data));
    } on DioException catch (e) {
      if (e.response != null) {
        print('오류: ${e.response?.statusCode}');
      } else {
        print('요청 실패: ${e.message}');
      }
    }
  }
}