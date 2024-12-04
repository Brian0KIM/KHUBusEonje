//과거 버스 도착 정보(버스별) 페이지
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BusHistoryPage extends StatefulWidget {
  final String routeId;
  final String stationId;
  final String stationName;
  final String busNumber;

  const BusHistoryPage({
    super.key,
    required this.routeId,
    required this.stationId,
    required this.stationName,
    required this.busNumber,
  });

  @override
  State<BusHistoryPage> createState() => _BusHistoryPageState();
}

class _BusHistoryPageState extends State<BusHistoryPage> {
  bool isLoading = false;
  Map<int, List<String>> groupedData = {};
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    fetchBusHistory();
  }
  @override
  void dispose() {
    // ScrollController 해제
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
 void _scrollToCurrentTime(int daysAgo, List<String> times) {
    if (times.isEmpty) return;

    final now = DateTime.now();
    final currentTimeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    // 현재 시간과 가장 가까운 인덱스 찾기
    int closestIndex = 0;
    int minDifference = double.maxFinite.toInt();

    for (int i = 0; i < times.length; i++) {
      final difference = _getTimeDifference(currentTimeString, times[i]);
      if (difference.abs() < minDifference) {
        minDifference = difference.abs();
        closestIndex = i;
      }
    }

    // ScrollController가 없으면 생성
    if (!_scrollControllers.containsKey(daysAgo)) {
      _scrollControllers[daysAgo] = ScrollController();
    }

    // 스크롤 위치 조정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollControllers[daysAgo]!.hasClients) {
        _scrollControllers[daysAgo]!.animateTo(
          closestIndex * 56.0, // ListTile의 대략적인 높이
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  int _getTimeDifference(String time1, String time2) {
    final t1Parts = time1.split(':');
    final t2Parts = time2.split(':');
    
    final t1Minutes = int.parse(t1Parts[0]) * 60 + int.parse(t1Parts[1]);
    final t2Minutes = int.parse(t2Parts[0]) * 60 + int.parse(t2Parts[1]);
    
    return t2Minutes - t1Minutes;
  }
  Future<void> fetchBusHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final today = DateTime.now();
      final formattedDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        //Uri.parse('http://localhost:8081/bus/history/byBus?routeId=${widget.routeId}&stationId=${widget.stationId}&date=$formattedDate'),
        Uri.parse('http://10.0.2.2:8081/bus/history/byBus?routeId=${widget.routeId}&stationId=${widget.stationId}&date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final List<dynamic> rawData = data['data'];
          
          // 데이터를 daysAgo별로 그룹화
          final Map<int, List<String>> tempGroupedData = {};
          
          for (var item in rawData) {
            final arrivalDateTime = DateTime.parse(item['RArrivalDate']);
            final time = "${arrivalDateTime.hour.toString().padLeft(2, '0')}:${arrivalDateTime.minute.toString().padLeft(2, '0')}";
            final daysAgo = item['daysAgo'] as int;
            
            if (!tempGroupedData.containsKey(daysAgo)) {
              tempGroupedData[daysAgo] = [];
            }
            tempGroupedData[daysAgo]!.add(time);
          }

          setState(() {
            groupedData = tempGroupedData;
            groupedData.forEach((daysAgo, times) {
              _scrollToCurrentTime(daysAgo, times);
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정류장별 버스 정보'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // 기본 텍스트 색상
                    ),
                    children: [
                      TextSpan(text: widget.stationName),
                      TextSpan(
                        text: "  ${widget.busNumber}",
                        style: TextStyle(
                          color: getBusColor(widget.busNumber),
                        ),
                      ),
                      const TextSpan(text: "번 버스"),
                    ],
                  ),
                ),
                const Text(
                  '버스 도착 예측 시간',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                _getDateMessage(),  // 요일별 안내 메시지 추가
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Row(
                children: groupedData.entries.map((entry) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${entry.key}일전',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              controller: _scrollControllers[entry.key],
                              padding: EdgeInsets.zero,
                              itemCount: entry.value.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Icon(Icons.directions_bus, color: getBusColor(widget.busNumber)),
                                  title: Text(
                                    entry.value[index],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}


Color getBusColor(String routeNumber) {
  switch (routeNumber) {
    case "9":
      return const Color(0xff33CC99); // 지선버스
    case "1112":
      return const Color(0xffE60012); // 지선버스
    case "5100":
      return const Color(0xffE60012); // 광역버스
    case "7000":
      return const Color(0xffE60012); // 광역버스
    case "M5107":
      return const Color(0xff006896); // M버스
    case "1560A":
      return const Color(0xffE60012); // 지선버스
    case "1560B":
      return const Color(0xffE60012); // 지선버스
    default:
      return Colors.black;
  }
}
String _getDateMessage() {
  final today = DateTime.now();
  final weekday = today.weekday; // 1 = 월요일, 7 = 일요일
  
  switch (weekday) {
    case 1: // 월요일
      return 'ⓘ 월요일: 3일전, 7일전 도착 기록을 제공합니다.';
    case 2: // 화요일
      return 'ⓘ 화요일: 1일전, 7일전 도착 기록을 제공합니다.';
    case 3: // 수요일
    case 4: // 목요일
    case 5: // 금요일
      return 'ⓘ 수요일, 목요일, 금요일: 1일전, 2일전, 7일전 도착 기록을 제공합니다.';
    case 6: // 토요일
    case 7: // 일요일
      return 'ⓘ 토요일, 일요일: 7일전 도착 기록을 제공합니다.';
    default:
      return 'ⓘ 7일전 도착 기록을 제공합니다.';
  }
}