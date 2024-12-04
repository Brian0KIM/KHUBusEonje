//정류장 페이지
import 'package:flutter/material.dart';
import 'station_bus_info_page.dart';
import 'bus_info.dart';
import 'station_bus_list_page.dart';

class StationScreen extends StatefulWidget {
  final String stationName;  // stationName 매개변수 추가

  const StationScreen({
    super.key,
    required this.stationName,  // required로 필수 매개변수로 지정
  });
  

  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen> {
  bool isAscending = false; // false: 사색 방향(default), true: 정문 방향

  // 정류장 데이터
  final Map<String, List<Map<String, String>>> stationData = {
    'ascending': [ // 정문 방향
      {'name': '사색의광장(정문행)', 'description': 'ⓘ 정문 방향(29059)'},
      {'name': '생명과학대.산업대학(정문행)', 'description': 'ⓘ 정문 방향(29050)'},
      {'name': '경희대체육대학.외대(정문행)', 'description': 'ⓘ 정문 방향(29044)'},
      {'name': '경희대학교(정문행)', 'description': 'ⓘ 정문 방향(04241)'},
    ],
    'descending': [ // 사색 방향
      {'name': '경희대정문(사색행)', 'description': 'ⓘ 사색 방향(29038)'},
      {'name': '외국어대학(사색행)', 'description': 'ⓘ 사색 방향(29040)'},
      {'name': '생명과학대(사색행)', 'description': 'ⓘ 사색 방향(29049)'},
      {'name': '사색의광장(사색행)', 'description': 'ⓘ 사색 방향(29057)'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stationName),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '정류장별 버스 도착 정보 조회',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ⓘ M5107과 1560은 교내 버스 이동 시간을 고려하여',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                  '    보정된 버스 도착 정보를 제공합니다.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text("정문 방향",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text("사색 방향",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                    selected: {isAscending},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        isAscending = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(
                        const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: stationData[isAscending ? 'ascending' : 'descending']!.length,
              itemBuilder: (context, index) {
                final station = stationData[isAscending ? 'ascending' : 'descending']![index];
                return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: const BorderSide(color: Colors.lightBlue, width: 2),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.directions_bus,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          station['name']!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (station['description']!.isNotEmpty)
                                          Text(
                                            station['description']!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.lightBlue,
                                        side: const BorderSide(color: Colors.lightBlue),
                                      ),
                                      onPressed: () {
                                        //과거 도착 시간 기능 구현
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => StationBusListPage(
                                              stationId: stationMap[station['name']]!,
                                              stationName: station['name']!,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('과거 도착 시간'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        //버스 도착 정보 조회 기능 구현
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => StationBusInfoPage(
                                              stationId: stationMap[station['name']]!,
                                              stationName: station['name']!,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('버스 도착 정보 조회'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}