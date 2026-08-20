import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class QuestionType {
  static const int singleChoice = 0;
  static const int reading = 1;
  static const int matching = 2;
  static const int multipleChoice = 3;
  static const int trueFalse = 4;
  static const int fillInBlank = 5;
  static const int tfng = 6;
  static const int ordering = 7;
  static const int shortAnswer = 8;
  static const int dropdown = 9;
  static const int highlighting = 10;

  static String getLabel(BuildContext context, int type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case singleChoice:
        return l10n.questionTypeSingleChoice;
      case reading:
        return l10n.questionTypeReading;
      case matching:
        return l10n.questionTypeMatching;
      case multipleChoice:
        return l10n.questionTypeMultipleChoice;
      case trueFalse:
        return l10n.questionTypeTrueFalse;
      case fillInBlank:
        return l10n.questionTypeFillInBlank;
      case tfng:
        return l10n.questionTypeTfng;
      case ordering:
        return l10n.questionTypeOrdering;
      case shortAnswer:
        return l10n.questionTypeShortAnswer;
      case dropdown:
        return l10n.questionTypeDropdown;
      case highlighting:
        return l10n.questionTypeHighlighting;
      default:
        return l10n.questionTypeDefault;
    }
  }

  static Color getBadgeBgColor(int type) {
    switch (type) {
      case singleChoice:
        return const Color(0xFFE0F2FE);
      case reading:
        return const Color(0xFFFEF3C7);
      case matching:
        return const Color(0xFFD1FAE5);
      case multipleChoice:
        return const Color(0xFFEDE9FE);
      case trueFalse:
        return const Color(0xFFFCE7F3);
      case fillInBlank:
        return const Color(0xFFFFEDD5);
      case tfng:
        return const Color(0xFFF0FDF4);
      case ordering:
        return const Color(0xFFFEFCE8);
      case shortAnswer:
        return const Color(0xFFF1F5F9);
      case dropdown:
        return const Color(0xFFEEF2FF);
      case highlighting:
        return const Color(0xFFFAE8FF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  static Color getBadgeTextColor(int type) {
    switch (type) {
      case singleChoice:
        return const Color(0xFF0369A1);
      case reading:
        return const Color(0xFF92400E);
      case matching:
        return const Color(0xFF065F46);
      case multipleChoice:
        return const Color(0xFF5B21B6);
      case trueFalse:
        return const Color(0xFF9D174D);
      case fillInBlank:
        return const Color(0xFF9A3412);
      case tfng:
        return const Color(0xFF166534);
      case ordering:
        return const Color(0xFF854D0E);
      case shortAnswer:
        return const Color(0xFF334155);
      case dropdown:
        return const Color(0xFF4338CA);
      case highlighting:
        return const Color(0xFFA21CAF);
      default:
        return const Color(0xFF475569);
    }
  }
}
