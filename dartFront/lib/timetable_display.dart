class TimeTableDisplay {
  static void displaySchedule(Map<String, dynamic> scheduleData) {
    final updateDate = scheduleData['update_date'];
    final company = scheduleData['company'];
    final contact = scheduleData['contact'];

    print('\n수원 9번 운행시각표 ($updateDate 기준)');
    print('교통상황에 따라 변동될 수 있습니다. / 문의전화 ($company 서부영업소): $contact\n');

    // 평일 시간표 출력
    _displayDaySchedule(scheduleData['schedules']['weekday'], '평일');
    print('');
    
    // 토요일 시간표 출력
    _displayDaySchedule(scheduleData['schedules']['saturday'], '토요일');
    print('');
    
    // 휴일 시간표 출력
    _displayDaySchedule(scheduleData['schedules']['holiday'], '휴일');
    print('');

    // 정류소 정보 출력
    _displayStops(scheduleData['stops']);
  }

  static void _displayDaySchedule(Map<String, dynamic> daySchedule, String dayType) {
    final trips = daySchedule['trips'];
    final interval = daySchedule['interval'];

    print('$dayType ${trips}회 운행');
    print('배차간격: $interval');
    
    print('┌──────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐');
    print('│ 순번 │금곡동출발│경희대출발│경희대도착│경희대출발│경희대도착│경희대출발│금곡동도착│');
    print('├──────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤');

    for (var time in daySchedule['times']) {
      print('│ ${time['trip'].toString().padRight(4)} │'
          ' ${time['depart_from'].padRight(7)}│'
          ' ${time['arrive_at'].padRight(7)}│'
          ' ${time['khu_depart'].padRight(7)}│'
          ' ${time['khu_arrive'].padRight(7)}│'
          ' ${time['khu_depart2'].padRight(7)}│'
          ' ${time['khu_arrive2'].padRight(7)}│'
          ' ${time['last_stop'].padRight(7)}│');
    }
    
    print('└──────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘');
  }

  static void _displayStops(List<dynamic> stops) {
    print('\n정류소 통과시각:');
    for (var i = 0; i < stops.length; i += 3) {
      var line = '';
      for (var j = 0; j < 3 && i + j < stops.length; j++) {
        final stop = stops[i + j];
        line += '${stop['name']} +${stop['offset']}분    ';
      }
      print(line.trim());
    }
  }
}