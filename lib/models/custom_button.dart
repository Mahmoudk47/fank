import 'package:flutter/material.dart';

class CustomButton {
  String id;
  String label;
  int count;
  Color color;
  bool isEdited;

  CustomButton({
    required this.id,
    required this.label,
    required this.count,
    required this.color,
    this.isEdited = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'count': count,
      'color': color.value,
    };
  }

  factory CustomButton.fromJson(Map<String, dynamic> json) {
    return CustomButton(
      id: json['id'],
      label: json['label'],
      count: json['count'],
      color: Color(json['color']),
    );
  }

  CustomButton copyWith({
    String? id,
    String? label,
    int? count,
    Color? color,
    bool? isEdited,
  }) {
    return CustomButton(
      id: id ?? this.id,
      label: label ?? this.label,
      count: count ?? this.count,
      color: color ?? this.color,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}