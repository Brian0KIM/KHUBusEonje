import 'dart:io';
import './bus_client.dart'; 
String readPassword() {
  // 현재 터미널 설정 저장
  final stdin = IoUtils.stdin;
  final prevEchoMode = stdin.echoMode;
  final prevLineMode = stdin.lineMode;

  // 에코 모드 비활성화 (입력 문자 숨기기)
  stdin.echoMode = false;
  stdin.lineMode = false;

  StringBuffer password = StringBuffer();
  while (true) {
    int input = stdin.readByteSync();
    // Enter 키 감지
    if (input == 10 || input == 13) {
      break;
    }
    // Backspace 키 감지
    else if (input == 127 || input == 8) {
      if (password.length > 0) {
        password.write('\b \b');
      }
    }
    // 일반 문자 입력
    else {
      password.writeCharCode(input);
    }
  }

  // 터미널 설정 복원
  stdin.echoMode = prevEchoMode;
  stdin.lineMode = prevLineMode;

  print(''); // 새 줄로 이동
  return password.toString();
}
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
        stdout.write('아이디: ');
        final id = stdin.readLineSync();
        stdout.write('비밀번호: ');
        final pw = readPassword();  // 수정된 부분
        if (id != null && pw.isNotEmpty) {
          await client.login(id, pw);
        }
        break;
      case '2':
        await client.logout();
        break;
      case '3':
        await client.checkStatus();
        break;
      case '4':
        stdout.write('노선 ID를 입력하세요: ');
        final routeId = stdin.readLineSync();
        if (routeId != null) {
          await client.startBusEtaPolling(routeId);
        }
        break;
      case '5':
        stdout.write('정류장 ID를 입력하세요: ');
        final stationId = stdin.readLineSync();
        if (stationId != null) {
          await client.startStopEtaPolling(stationId);
        }
        break;
      case '6':
        stdout.write('정류장 ID를 입력하세요: ');
        final stationId = stdin.readLineSync();
        if (stationId != null) {
          await client.startPassedByPolling(stationId);
        }
        break;
      case '7':
        stdout.write('노선 ID를 입력하세요: ');
        final routeId = stdin.readLineSync();
        stdout.write('정류장 ID를 입력하세요: ');
        final stationId = stdin.readLineSync();
        stdout.write('날짜를 입력하세요 (YYYY-MM-DD): ');
        final date = stdin.readLineSync();
        if (routeId != null && stationId != null && date != null) {
          await client.getBusHistory(routeId, stationId, date);
        }
        break;
      case '8':
        stdout.write('정류장 ID를 입력하세요: ');
        final stationId = stdin.readLineSync();
        stdout.write('날짜를 입력하세요 (YYYY-MM-DD): ');
        final date = stdin.readLineSync();
        if (stationId != null && date != null) {
          await client.getTimeHistory(stationId, date);
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