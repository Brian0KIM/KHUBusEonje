//버스 시간표 페이지
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BusTimeTablePage extends StatelessWidget {
  final String routeNumber;

  const BusTimeTablePage({
    super.key,
    required this.routeNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('버스 시간표 조회'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus,
                  size: 32,
                  color: getBusColor(routeNumber),
                ),  
                const SizedBox(width: 8),
                Text(
                  routeNumber,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: getBusColor(routeNumber),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildTimeTableImage(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTableImage(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: const BorderSide(color: Colors.blue, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                'assets/timetables/$routeNumber.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$routeNumber번 버스의\n시간표 정보가 없습니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
          ),
        ),
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