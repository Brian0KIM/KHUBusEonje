import 'package:flutter/material.dart';
import 'station_bus_info_page.dart';

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
                  '버스 도착 예측 시간',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'ⓘ 시간순 조회는 현재 시간으로부터 도착 시간순으로 조회 가능합니다.',
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: busOrder.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final busNumber = busOrder[index];
                  return ListTile(
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
                  );
                },
              ),
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
