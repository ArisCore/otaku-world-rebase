import 'package:flutter/material.dart';

import '../../../constants/string_constants.dart';
import '../../../graphql/__generated/graphql/character-detail/character_media.graphql.dart';
import '../../../graphql/__generated/graphql/details/characters.graphql.dart';
import '../filters/custom_dropdown.dart';

mixin LanguageSelectionMixin<T extends StatefulWidget> on State<T> {
  List<String> _availableLanguages = [];
  String? _selectedLanguage;
  int _lastItemCount = 0;

  List<String> get availableLanguages => _availableLanguages;

  String? get selectedLanguage => _selectedLanguage;

  void loadLanguagesFromVoiceActors(List<dynamic> items) {
    // Only process if items count changed
    if (items.length == _lastItemCount && _availableLanguages.isNotEmpty) {
      return;
    }

    _lastItemCount = items.length;
    final languages = _extractLanguages(items);

    // Only update if languages actually changed
    if (!_listsEqual(_availableLanguages, languages)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure setState is called after the current frame
        if (mounted) {
          setState(() {
            _availableLanguages = languages;
            if (_availableLanguages.isNotEmpty && _selectedLanguage == null) {
              if (availableLanguages
                  .contains(StringConstants.defaultLanguageDropdown)) {
                _selectedLanguage = StringConstants.defaultLanguageDropdown;
              } else {
                _selectedLanguage = availableLanguages.first;
              }
            }
          });
        }
      });
    }
  }

  List<String> _extractLanguages(List<dynamic> items) {
    final Set<String> languages = <String>{};

    for (final item in items) {
      final voiceActorRoles = _getVoiceActorRoles(item);
      if (voiceActorRoles != null) {
        for (final role in voiceActorRoles) {
          final language = role?.voiceActor?.languageV2;
          if (language != null) {
            languages.add(language);
          }
        }
      }
    }

    return languages.toList()..sort();
  }

  List<dynamic>? _getVoiceActorRoles(dynamic item) {
    // Handle different types of objects
    if (item is Query$Characters$Media$characters$edges) {
      return item.voiceActorRoles;
    } else if (item is Query$getCharacterMedia$Character$media$edges) {
      return item.voiceActorRoles;
    }
    return null;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void updateSelectedLanguage(String language) {
    if (mounted && _selectedLanguage != language) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  void resetLanguages() {
    _availableLanguages = [];
    _selectedLanguage = null;
    _lastItemCount = 0;
  }

  Widget buildLanguageDropdown() {
    if (_selectedLanguage == null ||
        _availableLanguages.isEmpty ||
        _availableLanguages.length <= 1) {
      return const SizedBox.shrink();
    }

    return CustomDropdown(
      dropdownItems: _availableLanguages,
      initialValue: _selectedLanguage!,
      onChange: updateSelectedLanguage,
    );
  }
}
