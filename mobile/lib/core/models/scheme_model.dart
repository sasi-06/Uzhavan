class SchemeModel {
  final String id;
  final String targetRole; // FARMER, MACHINE_OWNER, BOTH
  final String category;
  final String subsidyBadge;
  final String title;
  final String shortDesc;
  final String overview;
  final List<String> benefits;
  final List<String> eligibility;
  final List<String> documentsRequired;
  final String howToApply;
  final String applyUrl;
  final String helpline;
  final String state;
  final String currentLang;

  SchemeModel({
    required this.id,
    required this.targetRole,
    required this.category,
    required this.subsidyBadge,
    required this.title,
    required this.shortDesc,
    required this.overview,
    required this.benefits,
    required this.eligibility,
    required this.documentsRequired,
    required this.howToApply,
    required this.applyUrl,
    required this.helpline,
    required this.state,
    required this.currentLang,
  });

  factory SchemeModel.fromFirestore(Map<String, dynamic> data, String lang) {
    String getLocalized(dynamic mapOrString, String l, [String fallback = '']) {
      if (mapOrString == null) return fallback;
      if (mapOrString is String) return mapOrString;
      if (mapOrString is Map) {
        return (mapOrString[l] ?? mapOrString['ta'] ?? mapOrString['en'] ?? fallback).toString();
      }
      return fallback;
    }

    List<String> getLocalizedList(dynamic listOrMap, String l) {
      if (listOrMap == null) return [];
      if (listOrMap is List) {
        return listOrMap.map((e) => e.toString()).toList();
      }
      if (listOrMap is Map) {
        final list = listOrMap[l] ?? listOrMap['ta'] ?? listOrMap['en'];
        if (list is List) {
          return list.map((e) => e.toString()).toList();
        }
      }
      return [];
    }

    return SchemeModel(
      id: (data['id'] ?? '').toString(),
      targetRole: (data['targetRole'] ?? 'BOTH').toString().toUpperCase(),
      category: (data['category'] ?? 'SUBSIDY').toString().toUpperCase(),
      subsidyBadge: getLocalized(data['subsidyBadge'], lang, 'அரசு உதவி'),
      title: getLocalized(data['title'], lang, 'அரசு திட்டம்'),
      shortDesc: getLocalized(data['shortDesc'], lang, ''),
      overview: getLocalized(data['overview'], lang, ''),
      benefits: getLocalizedList(data['benefits'], lang),
      eligibility: getLocalizedList(data['eligibility'], lang),
      documentsRequired: getLocalizedList(data['documentsRequired'], lang),
      howToApply: getLocalized(data['howToApply'], lang, ''),
      applyUrl: (data['applyUrl'] ?? '').toString(),
      helpline: (data['helpline'] ?? '').toString(),
      state: (data['state'] ?? 'All India').toString(),
      currentLang: lang,
    );
  }

  /// Voice-friendly spoken text summary for audio playback
  String toSpeechText() {
    final buffer = StringBuffer();
    buffer.write('$title. ');
    if (subsidyBadge.isNotEmpty) {
      buffer.write('$subsidyBadge. ');
    }
    buffer.write(shortDesc);
    return buffer.toString();
  }
}
