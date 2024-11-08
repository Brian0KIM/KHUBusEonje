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
  String? _currentUserId;
  String? _currentCookie;

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
  Future<void> login(String id, String pw) async {
    try {
      final response = await _dio.post('/user/login', 
        data: {
          'id': id,
          'pw': pw,
        }
      );
      
      if (response.data['ok']) {
        _currentUserId = response.data['id'];
        _currentCookie = response.data['cookie'];
        print('로그인 성공! 환영합니다, ${response.data['name']}님');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('로그인 실패: ${e.response?.data['err']}');
      } else {
        print('로그인 요청 실패: ${e.message}');
      }
    }
  }

  Future<void> logout() async {
    if (_currentUserId == null || _currentCookie == null) {
      print('먼저 로그인해주세요.');
      return;
    }

    try {
      final response = await _dio.post('/user/logout',
        data: {
          'id': _currentUserId,
          'cookie': _currentCookie,
        }
      );
      
      if (response.data['ok']) {
        print('로그아웃 성공!');
        _currentUserId = null;
        _currentCookie = null;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('로그아웃 실패: ${e.response?.data['error']}');
      } else {
        print('로그아웃 요청 실패: ${e.message}');
      }
    }
  }

  Future<void> checkStatus() async {
    if (_currentUserId == null || _currentCookie == null) {
      print('먼저 로그인해주세요.');
      return;
    }

    try {
      final response = await _dio.get('/user/status',
        queryParameters: {'id': _currentUserId},
        options: Options(
          headers: {'Authorization': _currentCookie}
        )
      );
      
      if (response.data['ok']) {
        final userData = response.data['data'];
        print('\n사용자 상태:');
        print('ID: ${userData['id']}');
        print('이름: ${userData['name']}');
        print('로그인 상태: ${userData['isLoggedIn'] ? '로그인됨' : '로그아웃됨'}');
        print('세션 유효성: ${userData['sessionValid'] ? '유효함' : '만료됨'}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('상태 확인 실패: ${e.response?.data['error']}');
      } else {
        print('상태 확인 요청 실패: ${e.message}');
      }
    }
  }

  Future<void> getBusHistory(String routeId, String stationId, String date) async {
    try {
      final response = await _dio.get('/bus/history/byBus',
        queryParameters: {
          'routeId': routeId,
          'stationId': stationId,
          'date': date,
        }
      );
      
      if (response.data['ok']) {
        print('\n버스 운행 기록:');
        print(JsonEncoder.withIndent('  ').convert(response.data));
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('기록 조회 실패: ${e.response?.data['error']}');
      } else {
        print('기록 조회 요청 실패: ${e.message}');
      }
    }
  }

  Future<void> getTimeHistory(String stationId, String date) async {
    try {
      final response = await _dio.get('/bus/history/byTime',
        queryParameters: {
          'stationId': stationId,
          'date': date,
        }
      );
      
      if (response.data['ok']) {
        print('\n시간별 운행 기록:');
        print('정류장: ${response.data['stationName']}');
        print('마지막 업데이트: ${response.data['lastUpdate']}');
        print(JsonEncoder.withIndent('  ').convert(response.data['data']));
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('기록 조회 실패: ${e.response?.data['error']}');
      } else {
        print('기록 조회 요청 실패: ${e.message}');
      }
    }
  }
}