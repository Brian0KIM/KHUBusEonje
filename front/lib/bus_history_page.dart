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

  @override
  void initState() {
    super.initState();
    fetchBusHistory();
  }

  Future<void> fetchBusHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final today = DateTime.now();
      final formattedDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        Uri.parse('http://localhost:8081/bus/history/byBus?routeId=${widget.routeId}&stationId=${widget.stationId}&date=$formattedDate'),
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
                Text(
                  "${widget.stationName}(${widget.busNumber})",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '버스 도착 예측 시간',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
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
                              padding: EdgeInsets.zero,
                              itemCount: entry.value.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.check),
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