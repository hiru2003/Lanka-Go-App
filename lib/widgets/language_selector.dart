import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  final bool isCompact;

  const LanguageSelector({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final activeLanguage = languageProvider.currentLanguage;

    final List<Map<String, dynamic>> items = [
      {
        'lang': AppLanguage.english,
        'label': 'English',
        'code': 'EN',
      },
      {
        'lang': AppLanguage.sinhala,
        'label': 'සිංහල',
        'code': 'SI',
      },
      {
        'lang': AppLanguage.tamil,
        'label': 'தமிழ்',
        'code': 'TA',
      },
    ];

    if (isCompact) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppLanguage>(
            value: activeLanguage,
            dropdownColor: const Color(0xFF1E293B), // Slate dark dropdown
            icon: const Icon(Icons.language, color: Colors.white70, size: 18),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            onChanged: (lang) {
              if (lang != null) languageProvider.changeLanguage(lang);
            },
            items: items.map((item) {
              return DropdownMenuItem<AppLanguage>(
                value: item['lang'] as AppLanguage,
                child: Text(item['code'] as String),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            languageProvider.translate('languageLabel'),
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: items.map((item) {
              final isSelected = activeLanguage == item['lang'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => languageProvider.changeLanguage(item['lang'] as AppLanguage),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00F2FE).withAlpha(40)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF00F2FE).withAlpha(100), width: 1)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00F2FE) : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
