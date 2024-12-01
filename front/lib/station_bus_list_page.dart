import 'package:flutter/material.dart';
import 'station_bus_info_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StationBusListPage extends StatefulWidget {
  final String stationId;
  final String stationName;

  const StationBusListPage({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<StationBusListPage> createState() => _StationBusListPageState();
}

class _StationBusListPageState extends State<StationBusListPage> {
  Set<String> segments = {'버스별', '시간순'};
  String currentSegment = '버스별';
  final List<String> busOrder = ['9', '1112', '1560A', '1560B', '5100', '7000', 'M5107'];
  List<Map<String, dynamic>> timeBasedData = [];
    bool isLoading = false;
    final Map<String, String> routeIdToNumber = {
      '200000103': '9',
      '234000016': '1112',
      '234000884': '1560A',
      '228000433': '1560B',
      '200000115': '5100',
      '200000112': '7000',
      '234001243': 'M5107',
    };
 final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    fetchTimeBasedData();
  }

   Future<void> fetchTimeBasedData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final today = DateTime.now();
      final formattedDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        //Uri.parse('http://10.0.2.2:8081/bus/history/byTime?stationId=${widget.stationId}&date=$formattedDate'),
        Uri.parse('http://localhost:8081/bus/history/byTime?stationId=${widget.stationId}&date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final List<dynamic> rawData = data['data'];
          setState(() {
            timeBasedData = rawData.map<Map<String, dynamic>>((item) {
              final arrivalDateTime = DateTime.parse(item['RArrivalDate']);
              return {
                'time': "${arrivalDateTime.hour.toString().padLeft(2, '0')}:${arrivalDateTime.minute.toString().padLeft(2, '0')}",
                'routeNumber': routeIdToNumber[item['routeId'].toString()] ?? '알 수 없음',
                'date': "${arrivalDateTime.month}월 ${arrivalDateTime.day}일",
                'fullDateTime': arrivalDateTime,
              };
            }).toList();

            // 데이터 로드 후 현재 시간과 가장 가까운 인덱스 찾기
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentTime();
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

  void _scrollToCurrentTime() {
    if (timeBasedData.isEmpty) return;

    final now = DateTime.now();
    final currentTimeMinutes = now.hour * 60 + now.minute;
    
    // 현재 시간과 가장 가까운 인덱스 찾기
    int closestIndex = 0;
    int minDifference = double.maxFinite.toInt();

    for (int i = 0; i < timeBasedData.length; i++) {
      final itemDateTime = timeBasedData[i]['fullDateTime'] as DateTime;
      final itemMinutes = itemDateTime.hour * 60 + itemDateTime.minute;
      
      final difference = (itemMinutes - currentTimeMinutes).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }

    // 찾은 인덱스로 스크롤
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        closestIndex * 56.0, // ListTile의 대략적인 높이
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }


   Widget _buildTimeBasedList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${widget.stationName}(${timeBasedData.isNotEmpty ? timeBasedData[0]['date'] : ''}) 기준",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: timeBasedData.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = timeBasedData[index];
                return ListTile(
                  leading: Icon(
                    Icons.directions_bus,
                    color: getBusColor(item['routeNumber']),
                  ),
                  title: Text(
                    item['time'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${item['routeNumber']}번",
                    style: TextStyle(
                      color: getBusColor(item['routeNumber']),
                      fontWeight: FontWeight.bold,
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
   Widget _buildBusList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          busOrder.length,
          (index) {
            final busNumber = busOrder[index];
            return Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.directions_bus,
                    color: getBusColor(busNumber),
                  ),
                  title: Text(
                    busNumber,
                    style: TextStyle(
                      color: getBusColor(busNumber),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StationBusInfoPage(
                          stationId: widget.stationId,
                          stationName: widget.stationName,
                        ),
                      ),
                    );
                  },
                ),
                if (index < busOrder.length - 1)
                  const Divider(height: 1),
              ],
            );
          },
        ),
      ),
    );
  }
  @override
    void dispose() {
      _scrollController.dispose();
      super.dispose();
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
                Text(
                  widget.stationName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '버스 과거 도착 시간',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'ⓘ 시간순 조회는 7일전 도착 시간 기록입니다.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(
                  value: '버스별',
                  label: Text(
                    "버스별",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                ButtonSegment<String>(
                  value: '시간순',
                  label: Text(
                    "시간순",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
              selected: {currentSegment},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  currentSegment = newSelection.first;
                });
              },
              style: ButtonStyle(
                      side: WidgetStateProperty.all(
                        const BorderSide(color: Colors.blue),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
           Expanded(
            child: currentSegment == '버스별' ? _buildBusList() : _buildTimeBasedList(),
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
