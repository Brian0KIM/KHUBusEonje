// 네비게이션 바
import 'package:flutter/material.dart';
import 'bus_screen.dart';
import 'station_screen.dart';
import 'map_screen.dart';
import 'compliant_service_screen.dart';
import 'user_info_screen.dart';


class NavigationBarScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final List<dynamic> cookie;

  const NavigationBarScreen({
    super.key,
    required this.userName,
    required this.userId,
    required this.cookie,
  });

  @override
  State<NavigationBarScreen> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int currentPageIndex = 4; // "내 정보" 화면이 기본 활성화 상태

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ComplaintServiceScreen(), // 민원 화면
      const BusScreen(), // 버스 화면
      const MapScreen(), // 지도 화면
      const StationScreen(stationName: "정류장"), // 정류장 화면
      UserInfoScreen(
        userName: widget.userName,
        userId: widget.userId,
        cookie: widget.cookie,
      ), // 내 정보 화면
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[currentPageIndex], // 현재 활성화된 화면
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.warning_amber_rounded),
            label: '민원',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus),
            label: '버스',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: '지도',
          ),
          NavigationDestination(
            icon: Icon(Icons.stop_circle_outlined),
            label: '정류장',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}