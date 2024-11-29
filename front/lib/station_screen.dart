import 'package:flutter/material.dart';

class StationScreen extends StatefulWidget {
  const StationScreen({super.key});

  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen> {
  bool isAscending = false; // false: 사색 방향(default), true: 정문 방향

  // 정류장 데이터
  final Map<String, List<Map<String, String>>> stationData = {
    'ascending': [ // 정문 방향
      {'name': '사색의 광장', 'description': ''},
      {'name': '생명과학대.산업대학', 'description': '정문행'},
      {'name': '경희대체육대학.외대', 'description': '정문행'},
      {'name': '경희대학교(정건)', 'description': '정문행'},
    ],
    'descending': [ // 사색 방향
      {'name': '경희대정문', 'description': '사색행'},
      {'name': '외국어대학', 'description': '사색행'},
      {'name': '생명과학대', 'description': '사색행'},
      {'name': '사색의광장', 'description': '사색행'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정류장별 버스 정보'),
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
                'M5107과 1560은 서울대학교 학기 시 서울 지역과 교대역 방면을 경유합니다.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                '버스 도착 정보 시간은 평균 운행 시간과 시간대별 패턴으로 예측한 결과입니다.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                                        // TODO: 버스 도착 예정 시간 기능 구현
                                      },
                                      child: const Text('버스 도착 예정 시간'),
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
                                        // TODO: 버스 도착 정보 조회 기능 구현
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