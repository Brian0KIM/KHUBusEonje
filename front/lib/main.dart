import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bus_company.dart';
import "bus_info.dart";
import "passed_bus_page.dart";
import "bus_screen.dart";
import "station_screen.dart";
import "map_screen.dart";
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로그인 화면',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  Future<void> _login() async {
    final String id = _idController.text.trim();
    final String password = _passwordController.text.trim();
    if (id.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')),
        );
      }
      return;
    }

    try {
      final Uri url = Uri.parse('http://10.0.2.2:8081/user/login');
      //final Uri url = Uri.parse('http://localhost:8081/user/login');// 로그인 API 주소
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'pw': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['ok'] == true) {
          final String userName = responseData['name'];
          final String userId = responseData['id'];
          final List<dynamic> cookie = responseData['cookie'];
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NavigationBarScreen(
                  userName: userName,
                  userId: userId,
                  cookie: cookie,
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그인 실패')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 실패: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50), // 추가 여백
                const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ⓘ 인포21 아이디와 비밀번호로 로그인해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: '아이디',
                    hintText: 'exampleID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '************',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      const StationScreen(), // 정류장 화면
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



class UserInfoScreen extends StatelessWidget {
  final String userName;
  final String userId;
  final List<dynamic> cookie;

  const UserInfoScreen({
    super.key,
    required this.userName,
    required this.userId,
    required this.cookie,
  });

  Future<void> _logout(BuildContext context) async {
    try {
      //final Uri url = Uri.parse('http://10.0.2.2:8081/user/logout'); // 로그아웃 API 주소
      final Uri url = Uri.parse('http://localhost:8081/user/logout');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'id': userId,
          'cookie': cookie.join('; ')}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['ok'] == true) {
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그아웃 실패')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.black54),
            const SizedBox(height: 20),
            Text(
              userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '학번: $userId',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        side: const BorderSide(color: Colors.lightBlue, width: 2), // 하늘색 테두리
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
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 5),
                Text(
                  phone1,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 5),
                Text(
                  phone2,
                  style: const TextStyle(fontSize: 14),
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
                    // 회사 정보 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyInfoPage(
                          companyId: getCompanyId(button1Text),
                        ),
                      ),
                    );
                  },
                  child: Text(button1Text),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    side: const BorderSide(color: Colors.lightBlue),
                  ),
                  onPressed: () {
                    // 두 번째 버튼 동작
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyInfoPage(
                          companyId: getCompanyId(button2Text),
                        ),
                      ),
                    );
                  },
                  child: Text(button2Text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class CompanyInfoPage extends StatelessWidget {
  final String companyId;

  const CompanyInfoPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final company = companyData[companyId];
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${company['name']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '회사 정보',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(company),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> company) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.link,
            title: '웹사이트 주소',
            content: company['url'] ?? 'none',
          ),
          _buildDivider(),
          _buildInfoItem(
            icon: Icons.phone,
            title: '전화번호',
            content: _formatPhones(company['phones']),
          ),
          if (company['address'] != null) ...[
            _buildDivider(),
            _buildInfoItem(
              icon: Icons.home,
              title: '주소',
              content: company['address'],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }

  String _formatPhones(Map<String, dynamic> phones) {
    return phones.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }
}