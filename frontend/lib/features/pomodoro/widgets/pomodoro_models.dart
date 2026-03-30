import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  const Subject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}

final mockSubjects = [
  Subject(id: '1', name: 'Matematik', emoji: '📐', color: Color(0xFFE74C3C)),
  Subject(id: '2', name: 'Fizik', emoji: '⚡', color: Color(0xFF3498DB)),
  Subject(id: '3', name: 'İngilizce', emoji: '📖', color: Color(0xFF2ECC71)),
  Subject(id: '4', name: 'Kimya', emoji: '🧪', color: Color(0xFF9B59B6)),
  Subject(id: '5', name: 'Biyoloji', emoji: '🌿', color: Color(0xFF1ABC9C)),
];

enum TimerStatus { idle, running, paused, breakTime, completed }