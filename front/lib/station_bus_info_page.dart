import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bus_info.dart';
import 'dart:async';


class StationBusInfoPage extends StatefulWidget {
  final String stationId;
  final String stationName;

  const StationBusInfoPage({
    super.key,
    required this.stationId,
    required this.stationName,
  });


  @override
  State<StationBusInfoPage> createState() => _StationBusInfoPageState();
}

class _StationBusInfoPageState extends State<StationBusInfoPage> {
  List<dynamic> busData = [];
  bool isLoading = false;
  Timer? _timer;
  final Map<String, int> busPriority = {
    "9": 0,
    "1112": 1,
    "1560A": 2,
    "1560B": 3,
    "5100": 4,
    "7000": 5,
    "M5107": 6,
  };
  Set<String> availableRoutes = {}; //
  @override
  void initState() {
    super.initState();
    fetchBusData();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchBusData();
    });
  }
  @override
  void dispose() {
    _timer?.cancel(); // 페이지 dispose 시 타이머 취소
    super.dispose();
  }
  int calculateRemaining(String? totalStr, String? locationStr) {
  if (totalStr == null || locationStr == null) return 0;
    try {
      final total = int.parse(totalStr);
      final location = int.parse(locationStr);
      return total - location;
    } catch (e) {
      return 0;
    }
  }

  Future<void> fetchBusData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        //Uri.parse('http://localhost:8081/stop/${widget.stationId}/eta'),
        Uri.parse('http://10.0.2.2:8081/stop/${widget.stationId}/eta'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          final List<dynamic> rawData = data['data'];
          setState(() {
            // 도착 예정 정보가 있는 노선 저장
            availableRoutes = rawData
                .where((bus) => bus['predictTime1'] != null)
                .map<String>((bus) => bus['routeName'] as String)
                .toSet();
            
            // 데이터 정렬
            busData = rawData..sort((a, b) {
              bool aHasInfo = a['predictTime1'] != null;
              bool bHasInfo = b['predictTime1'] != null;
              
              if (aHasInfo && !bHasInfo) return -1;
              if (!aHasInfo && bHasInfo) return 1;
              
              return (busPriority[a['routeName']] ?? 999)
                  .compareTo(busPriority[b['routeName']] ?? 999);
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
        title: const Text('버스 도착 정보 조회'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.stationName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          size: 28,
                        ),
                        onPressed: isLoading ? null : () => fetchBusData(),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  '버스 도착 정보 조회',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'ⓘ M5107과 1560은 교내 버스 이동 시간을 고려하여 보정된 버스 도착 정보를 제공합니다.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : busData.isEmpty || !availableRoutes.any((route) => busPriority.containsKey(route))
                      ?  Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey[800]!,
                            width: 2,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                '도착 예정 정보 없음',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: busData.length,
                        itemBuilder: (context, index) {
                          final bus = busData[index];
                          final routeId = bus['routeId'];
                          final stationId = bus['stationId'];
                          
                          // 남은 정류장 수 계산
                          final totalStations = stationOrder[stationId]?[routeId];
                          final remaining1 = calculateRemaining(totalStations, bus['locationNo1']);
                          final remaining2 = bus['locationNo2'] != null ? 
                              calculateRemaining(totalStations, bus['locationNo2']) : null;
                          return Card(
                            margin: const EdgeInsets.symmetric( 
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_bus,
                                        color: getBusColor(bus['routeName']),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        bus['routeName'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: getBusColor(bus['routeName']),
                                        ),
                                      ),
                                      if (bus['isCalculated'] == true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '보정됨',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (bus['predictTime1'] != null) RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${bus['predictTime1']}',
                                          style: TextStyle(fontWeight: FontWeight.bold,
                                          color: getBusColor(bus['routeName']),
                                        ),
                                        ),
                                        const TextSpan(text: '분 후 도착 ('),
                                        TextSpan(
                                          text: '$remaining1',
                                          style: const TextStyle(fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                        ),
                                        const TextSpan(text: ' 정류장 전)'),
                                        if (bus['remainSeatCnt1'] != '-1') ...[
                                          const TextSpan(text: ' 잔여: '),
                                          TextSpan(
                                            text: '${bus['remainSeatCnt1']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                          ),
                                          const TextSpan(text: '석'),
                                        ],
                                      ],
                                    ),
                                  ) else const Text(
                                    '도착 예정 정보 없음',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (bus['predictTime2'] != null) RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${bus['predictTime2']}',
                                          style: TextStyle(fontWeight: FontWeight.bold,
                                          color: getBusColor(bus['routeName']),
                                        ),
                                        ),
                                        const TextSpan(text: '분 후 도착 ('),
                                        TextSpan(
                                          text: '$remaining2',
                                          style: const TextStyle(fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                        ),
                                        const TextSpan(text: ' 정류장 전)'),
                                        if (bus['remainSeatCnt2'] != '-1') ...[
                                          const TextSpan(text: ' 잔여: '),
                                          TextSpan(
                                            text: '${bus['remainSeatCnt2']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                          ),
                                          const TextSpan(text: '석'),
                                        ],
                                      ],
                                    ),
                                  ) else const Text(
                                    '도착 예정 정보 없음',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey, 
                                    ),
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