import 'package:flutter/material.dart';
import 'company_info_page.dart';
import 'passed_bus_page.dart';

class ComplaintServiceScreen extends StatelessWidget {
  const ComplaintServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 뒤로가기 동작
          },
        ),
        title: const Text('민원 도우미 서비스'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildBusInfoCard(
                companyName: "용남고속",
                routes: "9 | 5100 | 7000",
                stopInfo: "교내 정류장 존재",
                phone: "031-273-8335",
                context: context,
              ),
              const SizedBox(height: 10),
              _buildBusInfoCard(
                companyName: "대원고속",
                routes: "1112 | 1560(A,B)",
                stopInfo: "1112: 교내 정류장 존재\n1560: 교내 정류장 없음",
                phone: "031-204-6657",
                context: context,
              ),
              const SizedBox(height: 10),
              _buildBusInfoCard(
                companyName: "경기고속",
                routes: "M5107",
                stopInfo: "교내 정류장 없음",
                phone: "031-206-1570",
                context: context,
              ),
              const SizedBox(height: 10),
              _buildGeneralInfoCard(
                title: "경기도 버스 민원",
                phone1: "031-120",
                phone2: "031-246-4211",
                button1Text: "경기도청-버스불편신고",
                button2Text: "경기도버스운송조합",
                context: context,
              ),
              const SizedBox(height: 10),
              _buildGeneralInfoCard(
                title: "경희대학교",
                phone1: "031-201-2004",
                phone2: "031-201-3051~4",
                button1Text: "경희옴부즈민원",
                button2Text: "학생지원센터",
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusInfoCard({
    required String companyName,
    required String routes,
    required String stopInfo,
    required String phone,
    required BuildContext context,
  }) {
    String getCompanyId() {
    switch (companyName) {
      case "용남고속":
        return "1";
      case "대원고속":
        return "2";
      case "경기고속":
        return "3";
      default:
        return "1";
    }
    }
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Colors.lightBlue, width: 2), // 하늘색 테두리
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.directions_bus, size: 18),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.black),
                    const SizedBox(width: 5),
                    Text(
                      phone,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              routes,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    stopInfo,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    side: const BorderSide(color: Colors.lightBlue),
                  ),
                  onPressed: () {
                    // 회사 정보 보기 버튼 동작
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyInfoPage(
                          companyId: getCompanyId(),
                        ),
                      ),
                    );
                  },
                  child: const Text('회사 정보 보기'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // 버튼 배경색
                    foregroundColor: Colors.white, // 버튼 텍스트 색상
                  ),
                  onPressed: () {
                    // 방금 지나간 버스 버튼 동작
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PassedBusPage(),
                      ),
                    );
                  },
                  child: const Text('방금 지나간 버스'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard({
    required String title,
    required String phone1,
    required String phone2,
    required String button1Text,
    required String button2Text,
    required BuildContext context,
  }) {
    String getCompanyId(String buttonText) {
    switch (buttonText) {
      case "경기도청-버스불편신고":
        return "4";
      case "경기도버스운송조합":
        return "5";
      case "경희옴부즈민원":
        return "6";
      case "학생지원센터":
        return "7";
      default:
        return "4";
    }
    }
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          phone1,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          phone2,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlue,
                      side: const BorderSide(color: Colors.lightBlue),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyInfoPage(
                            companyId: getCompanyId(button1Text),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      button1Text,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                      
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlue,
                      side: const BorderSide(color: Colors.lightBlue),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyInfoPage(
                            companyId: getCompanyId(button2Text),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      button2Text,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}