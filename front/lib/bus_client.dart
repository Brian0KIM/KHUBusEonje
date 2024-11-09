import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'utils.dart';
import 'timetable_display.dart';
const String baseUrl = 'http://localhost:8081';

class BusClient {
  late final Dio _dio;
  Timer? _busTimer;
  Timer? _stopTimer;
  Timer? _passedByTimer;
  String? _currentUserId;
  String? _currentCookie;

 final _keyController = StreamController<String>.broadcast();
  bool _isListening = false;
  BusClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
    ));
     if (!_isListening) {
      stdin.transform(utf8.decoder).listen((input) {
        _keyController.add(input);
      });
      _isListening = true;
    }
  }
  
  Future<void> startBusEtaPolling(String routeId) async {
  _busTimer?.cancel();

  // 첫 번째 데이터 fetch
  await _fetchBusEta(routeId);

  bool isRunning = true;
  print('\n폴링을 중단하고 메인 메뉴로 돌아가려면 Enter 키를 누르세요...');

  // 비동기 입력 모니터링을 설정하여 Enter 키 감지
 var subscription = _keyController.stream.listen((input) {
      if (input.trim().isEmpty) {
        isRunning = false;
        print('\n메인 메뉴로 돌아갑니다...');
      }
    });
    
    while (isRunning) {
      await Future.delayed(Duration(seconds: 5));
      if (isRunning) {
        await _fetchBusEta(routeId);
      }
    }
    
    subscription.cancel();
}


Future<void> startStopEtaPolling(String stationId) async {
  _stopTimer?.cancel();
  await _fetchStopEta(stationId);

  bool isRunning = true;
  print('\n폴링을 중단하고 메인 메뉴로 돌아가려면 Enter 키를 누르세요...');

  // 비동기 입력 모니터링을 설정하여 Enter 키 감지
  var subscription = _keyController.stream.listen((input) {
      if (input.trim().isEmpty) {
        isRunning = false;
        print('\n메인 메뉴로 돌아갑니다...');
      }
    });
    
    while (isRunning) {
      await Future.delayed(Duration(seconds: 5));
      if (isRunning) {
        await _fetchStopEta(stationId);
      }
    }
    
    subscription.cancel();
}
  Future<void> startPassedByPolling(String stationId) async {
  _passedByTimer?.cancel();
  await _fetchPassedBy(stationId);

  bool isRunning = true;
  print('\n폴링을 중단하고 메인 메뉴로 돌아가려면 Enter 키를 누르세요...');

  // 비동기 입력 모니터링을 설정하여 Enter 키 감지
  var subscription = _keyController.stream.listen((input) {
      if (input.trim().isEmpty) {
        isRunning = false;
        print('\n메인 메뉴로 돌아갑니다...');
      }
    });
    
    while (isRunning) {
      await Future.delayed(Duration(seconds: 30));
      if (isRunning) {
        await _fetchPassedBy(stationId);
      }
    }
    
    subscription.cancel();
}
  
  
  
  Future<void> _fetchBusEta(String routeId) async {
    try {
      final response = await _dio.get('/bus/$routeId/eta');
      print('\x1B[2J\x1B[0;0H'); // 화면 클리어
      print('버스 도착 정보 (노선 ID: $routeId)');
      print('마지막 업데이트: ${DateTime.now().toString()}');
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
      print('정차 기록 (정류장 이름: ${getStationName(stationId)})');
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
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
      )
    );
    
    if (response.data['ok']) {
      _currentUserId = response.data['id'];
      // cookie가 리스트인 경우 첫 번째 값을 사용
      _currentCookie = (response.data['cookie'] as List).first.toString();
      print('로그인 성공! 환영합니다, ${response.data['name']}님');
    } else {
      print('로그인 실패: ${response.data['err']}');
    }
  } on DioException catch (e) {
    if (e.response != null) {
      print('로그인 실패: ${e.response?.data['err']}');
      print('상태 코드: ${e.response?.statusCode}');
      print('응답 데이터: ${e.response?.data}');
    } else {
      print('로그인 요청 실패: ${e.message}');
      print('에러 타입: ${e.type}');
    }
  } catch (e) {
    print('예상치 못한 에러 발생: $e');
    // 디버깅을 위한 스택 트레이스 출력
    print(StackTrace.current);
  }
}

void dispose() {
    _keyController.close();
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
          'routeId': routeId.toString(),
          'stationId': stationId.toString(),
          'date': date,
        }
      );
      
      if (response.data['ok']) {
      print('\n버스 운행 기록:');
      print('노선: ${getRouteName(routeId)}');
      print('정류장: ${getStationName(stationId)}');
      print('날짜: $date');
      print('-------------------');
      
      final data = response.data['data'] as List;
      if (data.isEmpty) {
        print('해당 날짜의 운행 기록이 없습니다.');
      } else {
        for (var record in data) {
          try {
            String routeIdStr = (record['routeId'] ?? '').toString();
            String stationIdStr = (record['stationId'] ?? '').toString();
            
            print('도착 시간: ${record['RArrivalDate']}');
            print('노선: ${getRouteName(routeIdStr)}');
            print('정류장: ${getStationName(stationIdStr)}');
            print('-------------------');
          } catch (e) {
            print('레코드 처리 중 오류: $e');
            print('원본 레코드: $record');
            print('-------------------');
          }
        }
      }
    }
  } on DioException catch (e) {
    if (e.response != null) {
      print('기록 조회 실패: ${e.response?.data['error']}');
      print('응답 데이터: ${e.response?.data}');
    } else {
      print('기록 조회 요청 실패: ${e.message}');
    }
  } catch (e) {
    print('예상치 못한 오류: $e');
  }
  }

  Future<void> getTimeHistory(String stationId, String date) async {
   try {
    final response = await _dio.get('/bus/history/byTime',
      queryParameters: {
        'stationId': stationId.toString(),
        'date': date,
      }
    );
    
    if (response.data['ok']) {
      print('\n시간별 운행 기록:');
      print('정류장: ${getStationName(stationId)}');
      print('날짜: $date');
      print('-------------------');
      
      final data = response.data['data'] as List;
      if (data.isEmpty) {
        print('해당 날짜의 운행 기록이 없습니다.');
      } else {
        for (var record in data) {
          try {
            String routeIdStr = (record['routeId'] ?? '').toString();
            String stationIdStr = (record['stationId'] ?? '').toString();
            
            print('도착 시간: ${record['RArrivalDate']}');
            print('노선: ${getRouteName(routeIdStr)}');
            print('정류장: ${getStationName(stationIdStr)}');
            print('-------------------');
          } catch (e) {
            print('레코드 처리 중 오류: $e');
            print('원본 레코드: $record');
            print('-------------------');
          }
        }
      }
    }
  } on DioException catch (e) {
    if (e.response != null) {
      print('기록 조회 실패: ${e.response?.data['error']}');
      print('응답 데이터: ${e.response?.data}');
    } else {
      print('기록 조회 요청 실패: ${e.message}');
    }
  } catch (e) {
    print('예상치 못한 오류: $e');
  }
}
Future<void> displayCompanyInfo(Map<String, dynamic> companyData) async {
    print('\n회사 정보:');
    print('회사명: ${companyData['name']}');
    
    if (companyData['phones'] != null) {
      print('\n연락처:');
      (companyData['phones'] as Map<String, dynamic>).forEach((key, value) {
        print('$key: $value');
      });
    }
    
    if (companyData['address'] != null) {
      print('\n주소: ${companyData['address']}');
    }
    
    if (companyData['buses'] != null) {
      print('\n운행 노선:');
      final buses = companyData['buses'] as List;
      buses.forEach((bus) => print('- $bus'));
    }
    
    if (companyData['url'] != null && companyData['url'] != 'none') {
      print('\n웹사이트: ${companyData['url']}');
    }
  }
    Future<void> displayBusTimeTable(String routeName) async {
    try {
      final file = File('./assets/data/bus_schedules.json');
      if (!await file.exists()) {
        print('시간표 데이터 파일을 찾을 수 없습니다.');
        return;
      }

      final jsonString = await file.readAsString();
      final schedules = json.decode(jsonString);

      if (!schedules.containsKey(routeName)) {
        print('해당 버스의 시간표 정보가 없습니다.');
        return;
      }

      switch(routeName) {
        case '9':
          TimeTableDisplay.displaySchedule(schedules[routeName]);
          break;
        default:
          print('지원하지 않는 버스 노선입니다.');
      }
    } catch (e) {
      print('시간표 로딩 중 오류 발생: $e');
    }
  }
}