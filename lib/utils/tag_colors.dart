import 'package:flutter/material.dart';

class TagColors {
  static const List<Color> _baseColors = [
    Color(0xFF6B4E71),  // Roxo suave (cor primária)
    Color(0xFF4CAF50),  // Verde
    Color(0xFF2196F3),  // Azul
    Color(0xFFF44336),  // Vermelho
    Color(0xFF9C27B0),  // Roxo
    Color(0xFF009688),  // Verde-azulado
    Color(0xFFFF9800),  // Laranja
    Color(0xFF795548),  // Marrom
    Color(0xFF607D8B),  // Azul-acinzentado
    Color(0xFFE91E63),  // Rosa
    Color(0xFF3F51B5),  // Índigo
    Color(0xFF00BCD4),  // Ciano
  ];

  static Color getColorForTag(String tagName) {
    if (tagName.isEmpty) return _baseColors[0];
    
    // Usa a soma dos códigos ASCII das letras para gerar um índice consistente
    int sum = 0;
    for (int i = 0; i < tagName.length; i++) {
      sum += tagName.codeUnitAt(i);
    }
    
    return _baseColors[sum % _baseColors.length];
  }

  static Color getBackgroundColorForTag(String tagName) {
    final baseColor = getColorForTag(tagName);
    return baseColor.withOpacity(0.12);
  }

  static Color getTextColorForTag(String tagName) {
    final baseColor = getColorForTag(tagName);
    return baseColor;
  }
}
