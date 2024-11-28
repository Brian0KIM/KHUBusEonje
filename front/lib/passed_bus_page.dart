import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PassedBusPage extends StatefulWidget {
  const PassedBusPage({super.key});

  @override
  State<PassedBusPage> createState() => _PassedBusPageState();
}

class _PassedBusPageState extends State<PassedBusPage> {
  String currentStationId = "228000723"; // 기본값: 사색방향
  List<dynamic> busData = [];
  bool isLoading = false;

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
      final response = await http.get(
        Uri.parse('http://localhost:8081/complain/$currentStationId/passedby'),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: busData.length,
                    itemBuilder: (context, index) {
                      final bus = busData[index];
                      final expectedArrival = DateTime.parse(bus['expectedArrival']).toLocal();
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: const Icon(Icons.check, color: Colors.blue),
                          title: Text(
                            bus['routeName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${bus['plateNo']}\n${expectedArrival.hour}:${expectedArrival.minute.toString().padLeft(2, '0')} 도착 예정',
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