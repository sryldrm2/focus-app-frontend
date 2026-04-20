import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFE85D04);
    const secondaryPeach = Color(0xFFFFE5D5);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Çalışma Raporum',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet Bilgi Kartları (Toplam Süre ve Oturum)
            Row(
              children: [
                _buildSummaryCard(
                  title: 'Toplam Süre',
                  value: '18s 45dk', // Örnek veri, API entegrasyonu yapılacak.
                  icon: Icons.timer_outlined,
                  color: primaryOrange,
                  subtitle: 'Bu hafta',
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  title: 'Toplam Oturum',
                  value: '36 Oturum', // Örnek veri, API entegrasyonu yapılacak.
                  icon: Icons.local_fire_department_outlined,
                  color: Colors.orangeAccent,
                  subtitle: 'Pomodoro',
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Haftalık Performans Grafiği Bölümü
            const Text(
              'Günlük Çalışma Süreleri (Saat)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
            ),
            const SizedBox(height: 15),
            Container(
              height: 280,
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)}s',
                          const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt() % 7], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  // Grafik Verileri (Şu an için manuel, dinamik hale getirilecek)
                  barGroups: [
                    _makeGroupData(0, 4.5, primaryOrange),
                    _makeGroupData(1, 6.2, primaryOrange),
                    _makeGroupData(2, 3.8, primaryOrange),
                    _makeGroupData(3, 8.5, primaryOrange),
                    _makeGroupData(4, 5.0, primaryOrange),
                    _makeGroupData(5, 2.5, Colors.grey.shade300),
                    _makeGroupData(6, 1.8, Colors.grey.shade300),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Ders Bazlı Dağılım Bölümü
            const Text(
              'Derslere Göre Dağılım',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
            ),
            const SizedBox(height: 15),
            // Statik ders verileri, lise müfredatına göre düzenlendi.
            _buildSubjectRow('Matematik', '6s 20dk', 0.85, primaryOrange),
            _buildSubjectRow('Fizik', '4s 15dk', 0.60, Colors.blueAccent),
            _buildSubjectRow('Kimya', '3s 10dk', 0.45, Colors.teal),
            _buildSubjectRow('Biyoloji', '2s 40dk', 0.35, Colors.green),
            _buildSubjectRow('İngilizce', '1s 50dk', 0.20, Colors.purpleAccent),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Özet kartlarını oluşturan yardımcı widget
  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color, required String subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Ders ilerleme satırlarını oluşturan yardımcı widget
  Widget _buildSubjectRow(String name, String time, double progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(time, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // Grafik çubuklarını oluşturan yardımcı fonksiyon
  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: const Color(0xFFF1F1F1),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }
}