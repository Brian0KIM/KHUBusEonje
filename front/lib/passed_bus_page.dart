//방금 지나간 버스 페이지
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PassedBusPage extends StatefulWidget {
  final String? companyId; // nullable로 선언 (기본 화면에서는 null)
  
  const PassedBusPage({super.key, this.companyId});

  @override
  State<PassedBusPage> createState() => _PassedBusPageState();
}

class _PassedBusPageState extends State<PassedBusPage> {
  String currentStationId = "228000723"; // 기본값: 사색방향
  final Map<String, List<String>> companyRoutes = {
    "1": ["9", "5100", "7000"],         // 용남고속
    "2": ["1112", "1560A", "1560B"],    // 대원고속
    "3": ["M5107"],                      // 경기고속
  };
  List<dynamic> busData = [];
  bool isLoading = false;
  Timer? _timer;
  List<dynamic> getFilteredBusData() {
      if (widget.companyId == null) {
        return busData; // companyId가 없으면 모든 데이터 반환
      }
      
      final companyBusRoutes = companyRoutes[widget.companyId];
      if (companyBusRoutes == null) {
        return busData;
      }

      return busData.where((bus) => 
        companyBusRoutes.contains(bus['routeName'])
      ).toList();
    }
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

  Future<void> fetchBusData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        //Uri.parse('http://localhost:8081/complain/$currentStationId/passedby'),
        Uri.parse('http://10.0.2.2:8081/complain/$currentStationId/passedby'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          setState(() {
            busData = data['data'];
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
        title: const Text('방금 지나간 버스'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ⓘ 정문, 정건 정류장 기준 도착이 임박한 버스를',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  '    현재 시간으로부터 10분 전까지 조회가능합니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: "228000723",
                          label: Text("사색방향"),
                        ),
                        ButtonSegment<String>(
                          value: "203000125",
                          label: Text("정문방향"),
                        ),
                      ],
                      selected: {currentStationId},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          currentStationId = newSelection.first;
                        });
                        fetchBusData();
                      },
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(
                          const BorderSide(color: Colors.grey),
                        ),
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
                          foregroundColor: Colors.grey,
                          padding: const EdgeInsets.all(8),
                            ),
                          ),
                      ),
                    ],
                  ),
               ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : getFilteredBusData().isEmpty // busData 대신 getFilteredBusData() 사용
                    ? Card(
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
                                '최근 지나간 버스가 없습니다',
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
                        itemCount: getFilteredBusData().length,
                        itemBuilder: (context, index) {
                          final bus = getFilteredBusData()[index];
                          final expectedArrival = DateTime.parse(bus['expectedArrival']);
                          final formattedTime =
                              '${expectedArrival.hour.toString().padLeft(2, '0')}:${expectedArrival.minute.toString().padLeft(2, '0')}';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ListTile(
                              leading: Icon(Icons.directions_bus,
                                  color: getBusColor(bus['routeName'])),
                              title: Text(
                                bus['routeName'],
                                style: TextStyle(fontWeight: FontWeight.bold,color: getBusColor(bus['routeName'])),
                              ),
                              subtitle: Text(
                                '${bus['plateNo']}\n$formattedTime 도착 예정',
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