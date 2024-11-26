import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  _LoginScreenState createState() => _LoginScreenState();
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
      final Uri url = Uri.parse('http://localhost:8081/user/login'); // 로그인 API 주소
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
    required this.userId, required this.cookie,
  });

  @override
  _NavigationBarScreenState createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int _currentIndex = 3;

  late final List<Widget> _pages;


  @override
  void initState() {
    super.initState();
    _pages = [
      const Center(child: Text('홈 화면')),
      const Center(child: Text('버스 화면')),
      const Center(child: Text('지도 화면')),
      UserInfoScreen(userName: widget.userName, userId: widget.userId, cookie: widget.cookie,),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: '버스',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도',
          ),
          BottomNavigationBarItem(
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
      final Uri url = Uri.parse('http://localhost:8081/user/logout'); // 로그아웃 API 주소
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookie.join('; '),
        },
        body: json.encode({'id': userId}),
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

