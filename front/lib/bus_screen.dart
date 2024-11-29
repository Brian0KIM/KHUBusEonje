import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class BusScreen extends StatelessWidget {
  const BusScreen({super.key});

  // 버스 노선별 색상 지정
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('버스 정보'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildBusRouteCard(
                routeNumber: "9",
                operationTime: "기점 평일 06:30~22:50, 주말 06:30~22:50",
                routeInfo: "사색의광장<->금곡LG1단지.와이씨티6단지)",
              ),
              const SizedBox(height: 10),
              _buildBusRouteCard(
                routeNumber: "1112",
                operationTime: "기점 평일 04:40~22:30, 주말 04:40~22:30",
                routeInfo: "사색의광장<->테크노마트앞.강변역(C)",
              ),
              const SizedBox(height: 10),
              _buildBusRouteCard(
                routeNumber: "5100",
                operationTime: "기점 평일 05:30~00:10, 주말 05:30~23:20",
                routeInfo: "사색의광장<->신분당선강남역(중)",
              ),
              const SizedBox(height: 10),
              _buildBusRouteCard(
                routeNumber: "7000",
                operationTime: "기점 평일 05:30~00:00, 주말 05:30~23:30",
                routeInfo: "사색의광장<->사당역4번출구",
              ),
              const SizedBox(height: 10),
              _buildBusRouteCard(
                routeNumber: "M5107",
                operationTime: "기점 평일 05:00~23:00, 주말 05:00~23:00",
                routeInfo: "경희대학교<->서울역버스환승센터(6번승강장)(중)",
              ),
              const SizedBox(height: 10),
              _buildBusRouteCard(
                routeNumber: "1560A",
                operationTime: "기점 평일 05:30~11:30, 주말 05:00~11:20",
                routeInfo: "경희대학교<->신분당선강남역(중)",
              ),
              _buildBusRouteCard(
                routeNumber: "1560B",
                operationTime: "기점 평일 11:50~22:30, 주말 11:50~22:30",
                routeInfo: "경희대학교<->신분당선강남역(중)",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusRouteCard({
    required String routeNumber,
    required String operationTime,
    required String routeInfo,
  }) {
    return Card(
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
                Icon(
                  Icons.directions_bus,
                  size: 24,
                  color: getBusColor(routeNumber), // 노선별 색상 적용
                ),
                const SizedBox(width: 8),
                Text(
                  routeNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: getBusColor(routeNumber), // 노선 번호도 같은 색상 적용
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    operationTime,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routeInfo,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    side: const BorderSide(color: Colors.lightBlue),
                  ),
                  onPressed: () {
                    // 버스 시간표 조회 기능 구현
                  },
                  child: const Text('버스 시간표 조회'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // 버스 도착 정보 조회 기능 구현
                  },
                  child: const Text('버스 도착 정보 조회'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}