import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bus_info.dart';

class BusArrivalPage extends StatefulWidget {
  final String routeNumber;
  
  const BusArrivalPage({
    super.key,
    required this.routeNumber,
  });

  @override
  State<BusArrivalPage> createState() => _BusArrivalPageState();
}

class _BusArrivalPageState extends State<BusArrivalPage> {
  List<dynamic> busData = [];
  bool isLoading = false;
  bool isAscending = true; // true: 정문방향(오름차순), false: 사색방향(내림차순)

  @override
  void initState() {
    super.initState();
    fetchBusData();
  }

  Future<void> fetchBusData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final routeId = busRouteMap[widget.routeNumber];
      final response = await http.get(
        Uri.parse('http://localhost:8081/bus/$routeId/eta'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          setState(() {
            busData = List.from(data['data'])
              ..sort((a, b) => isAscending
                  ? int.parse(a['stationSeq']).compareTo(int.parse(b['stationSeq']))
                  : int.parse(b['stationSeq']).compareTo(int.parse(a['stationSeq'])));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('버스 도착 정보'),
      ),
      body: Column(
        children: [
          Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus,
                size: 32,
                color: getBusColor(widget.routeNumber),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.routeNumber}번',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: getBusColor(widget.routeNumber),
                ),
              ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text("정문 방향"),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text("사색 방향"),
                ),
              ],
              selected: {isAscending},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  isAscending = newSelection.first;
                  busData.sort((a, b) => isAscending
                      ? int.parse(a['stationSeq']).compareTo(int.parse(b['stationSeq']))
                      : int.parse(b['stationSeq']).compareTo(int.parse(a['stationSeq'])));
                });
              },
              style: ButtonStyle(
                side: WidgetStateProperty.all(
                  const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : busData.isEmpty
                    ? const Center(
                        child: Text('운행 중인 버스가 없습니다.'),
                      )
                    : ListView.builder(
                        itemCount: busData.length,
                        itemBuilder: (context, index) {
                          final bus = busData[index];
                          final totalStations = int.parse(stationRouteOrder[widget.routeNumber] ?? "0");
                          final currentStation = int.parse(bus['stationSeq']);
                          final remainingStations = totalStations - currentStation;
                          
                          // 잔여 좌석 텍스트 조건부 생성
                          String remainingSeatText = '';
                          if (bus['remainSeatCnt'] != '-1') {
                            remainingSeatText = '잔여: ${bus['remainSeatCnt']} 석';
                          } else {
                            remainingSeatText = '잔여: 정보없음';
                          }
    
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: const BorderSide(color: Colors.blue),
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
                                        color: getBusColor(widget.routeNumber),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${bus['stationName']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${bus['plateNo']}\n',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(text: '기점에서 '),
                                        TextSpan(
                                          text: '${bus['stationSeq']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(text: '째 정류장\n'),
                                        const TextSpan(
                                          text: '사색의광장',
                                        ),
                                        const TextSpan(text: '까지: '),
                                        TextSpan(
                                          text: '$remainingStations',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(text: ' 전\n'),
                                        if (bus['remainSeatCnt'] != '-1') ...[
                                          const TextSpan(text: '잔여: '),
                                          TextSpan(
                                            text: '${bus['remainSeatCnt']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(text: ' 석'),
                                        ] else
                                          const TextSpan(text: '잔여: 정보없음'),
                                      ],
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