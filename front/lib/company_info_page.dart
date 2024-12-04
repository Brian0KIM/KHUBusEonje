//회사 정보 페이지
import 'package:flutter/material.dart';
import 'bus_company.dart';


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