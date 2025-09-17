import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final String description;
  final Color color;
  final String icon;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    this.description = '',
    this.color = Colors.green,
    this.icon = 'category',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.value,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: Color(map['color'] ?? Colors.green.value),
      icon: map['icon'] ?? 'category',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
