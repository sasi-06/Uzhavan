/// Uzhavan — AI Agent Script
/// Full multi-language prompt & response scripts for every conversation step.
/// Supports Tamil (ta), Telugu (te), Hindi (hi), English (en).

class AgentScript {
  AgentScript._();

  // ── Greeting ─────────────────────────────────────────────────────────────────

  static String greeting(String lang) => _pick(lang, {
    'ta': 'வணக்கம்! நான் உங்கள் உழவன் உதவியாளர். என்ன வேண்டும்?',
    'te': 'నమస్కారం! నేను మీ ఉఝవన్ సహాయకుడిని. మీకు ఏమి కావాలి?',
    'hi': 'नमस्ते! मैं आपका उझवन सहायक हूं। आपको क्या चाहिए?',
    'en': 'Hello! I am your Uzhavan assistant. What do you need?',
  });

  // ── Machine Type Prompt ───────────────────────────────────────────────────────

  static String askMachineType(String lang) => _pick(lang, {
    'ta': 'எந்த எந்திரம் வேண்டும்?',
    'te': 'మీకు ఏ యంత్రం కావాలి?',
    'hi': 'आपको कौन सी मशीन चाहिए?',
    'en': 'Which machine do you need?',
  });

  static List<String> machineTypeOptions(String lang) => _pickList(lang, {
    'ta': ['🚜 டிராக்டர்', '🌾 அறுவடை', '💧 தெளிப்பான்', '🌱 விதைப்பான்', '🔄 ரோட்டவேட்டர்'],
    'te': ['🚜 ట్రాక్టర్', '🌾 హార్వెస్టర్', '💧 స్ప్రేయర్', '🌱 సీడర్', '🔄 రోటావేటర్'],
    'hi': ['🚜 ट्रैक्टर', '🌾 हार्वेस्टर', '💧 स्प्रेयर', '🌱 सीडर', '🔄 रोटावेटर'],
    'en': ['🚜 Tractor', '🌾 Harvester', '💧 Sprayer', '🌱 Seeder', '🔄 Rotavator'],
  });

  // ── Area Prompt ───────────────────────────────────────────────────────────────

  static String askArea(String lang, String machineDisplay) => _pick(lang, {
    'ta': '$machineDisplay-க்கு எத்தனை ஏக்கர்?',
    'te': '$machineDisplay కోసం ఎన్ని ఎకరాలు?',
    'hi': '$machineDisplay के लिए कितने एकड़?',
    'en': 'How many acres for the $machineDisplay?',
  });

  static List<String> areaOptions(String lang) => _pickList(lang, {
    'ta': ['1 ஏக்கர்', '2 ஏக்கர்', '3 ஏக்கர்', '5 ஏக்கர்', '10 ஏக்கர்'],
    'te': ['1 ఎకరం', '2 ఎకరాలు', '3 ఎకరాలు', '5 ఎకరాలు', '10 ఎకరాలు'],
    'hi': ['1 एकड़', '2 एकड़', '3 एकड़', '5 एकड़', '10 एकड़'],
    'en': ['1 acre', '2 acres', '3 acres', '5 acres', '10 acres'],
  });

  // ── Date Prompt ───────────────────────────────────────────────────────────────

  static String askDate(String lang) => _pick(lang, {
    'ta': 'எந்த தேதி வேண்டும்?',
    'te': 'మీకు ఏ తేదీ కావాలి?',
    'hi': 'कौन सी तारीख चाहिए?',
    'en': 'Which date do you need it?',
  });

  static List<String> dateOptions(String lang) => _pickList(lang, {
    'ta': ['இன்று', 'நாளை', '2 நாள் பிறகு', 'இந்த வாரம்'],
    'te': ['ఈ రోజు', 'రేపు', '2 రోజుల తర్వాత', 'ఈ వారం'],
    'hi': ['आज', 'कल', '2 दिन बाद', 'इस हफ्ते'],
    'en': ['Today', 'Tomorrow', 'In 2 days', 'This week'],
  });

  // ── Searching ─────────────────────────────────────────────────────────────────

  static String searching(String lang) => _pick(lang, {
    'ta': 'உங்கள் அருகில் கிடைக்கும் எந்திரங்களை தேடுகிறேன்...',
    'te': 'మీ సమీపంలో అందుబాటులో ఉన్న యంత్రాలను వెతుకుతున్నాను...',
    'hi': 'आपके पास उपलब्ध मशीनें खोज रहा हूं...',
    'en': 'Searching for available machines near you...',
  });

  // ── Owner Found ───────────────────────────────────────────────────────────────

  static String ownersFound(String lang, int count, String machineDisplay) => _pick(lang, {
    'ta': 'உங்கள் அருகில் $count $machineDisplay கிடைக்கிறது! யாரை தேர்ந்தெடுக்கட்டுமா?',
    'te': 'మీ సమీపంలో $count $machineDisplay అందుబాటులో ఉంది! ఎవరిని ఎంచుకోనా?',
    'hi': 'आपके पास $count $machineDisplay उपलब्ध है! किसे चुनना है?',
    'en': '$count $machineDisplay found near you! Which one shall I contact?',
  });

  static String noOwnersFound(String lang) => _pick(lang, {
    'ta': 'மன்னிக்கவும்! இப்போது அருகில் எந்திரம் கிடைக்கவில்லை. நாளை மீண்டும் முயற்சிக்கவும்.',
    'te': 'క్షమించండి! ఇప్పుడు సమీపంలో యంత్రం అందుబాటులో లేదు. రేపు మళ్ళీ ప్రయత్నించండి.',
    'hi': 'माफ करें! अभी पास में कोई मशीन उपलब्ध नहीं है। कल फिर कोशिश करें।',
    'en': 'Sorry! No machines available nearby right now. Please try again tomorrow.',
  });

  // ── Owner Announcement ────────────────────────────────────────────────────────

  static String announceOwner(String lang, int index, String ownerName, double? distKm, String? price) {
    final dist = distKm != null ? '${distKm.toStringAsFixed(1)} கி.மீ.' : '';
    final priceStr = price ?? '';
    return _pick(lang, {
      'ta': 'விருப்பம் $index: $ownerName — $dist — $priceStr',
      'te': 'ఎంపిక $index: $ownerName — $dist — $priceStr',
      'hi': 'विकल्प $index: $ownerName — $dist — $priceStr',
      'en': 'Option $index: $ownerName — $dist — $priceStr',
    });
  }

  // ── Confirm ───────────────────────────────────────────────────────────────────

  static String confirm(String lang, String ownerName, String machineDisplay, double? area, DateTime? date) {
    final areaStr = area != null ? '${area.toStringAsFixed(0)} ஏக்கர்' : '';
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '';
    return _pick(lang, {
      'ta': '$ownerName-க்கு $machineDisplay முன்பதிவு — $areaStr — $dateStr. அனுப்பட்டுமா?',
      'te': '$ownerName కి $machineDisplay బుకింగ్ — $areaStr — $dateStr. పంపనా?',
      'hi': '$ownerName को $machineDisplay बुकिंग — $areaStr — $dateStr. भेजूं?',
      'en': 'Send $machineDisplay booking to $ownerName — $areaStr — $dateStr?',
    });
  }

  static List<String> confirmOptions(String lang) => _pickList(lang, {
    'ta': ['✅ ஆம், அனுப்பு', '❌ வேண்டாம்'],
    'te': ['✅ అవును, పంపు', '❌ వద్దు'],
    'hi': ['✅ हाँ, भेजो', '❌ नहीं'],
    'en': ['✅ Yes, send it', '❌ No, cancel'],
  });

  // ── Done ─────────────────────────────────────────────────────────────────────

  static String done(String lang, String ownerName) => _pick(lang, {
    'ta': 'முன்பதிவு $ownerName-க்கு அனுப்பப்பட்டது! ✅ அவர் ஏற்றுக்கொண்டால் உங்களுக்கு தெரிவிக்கப்படும்.',
    'te': 'బుకింగ్ $ownerName కి పంపబడింది! ✅ వారు స్వీకరిస్తే మీకు తెలియజేస్తాం.',
    'hi': 'बुकिंग $ownerName को भेज दी गई! ✅ जब वे स्वीकार करें, आपको सूचित किया जाएगा।',
    'en': 'Booking sent to $ownerName! ✅ You will be notified when they accept.',
  });

  static String cancelled(String lang) => _pick(lang, {
    'ta': 'சரி! முன்பதிவு ரத்து செய்யப்பட்டது. மீண்டும் முயற்சிக்கவும்.',
    'te': 'సరే! బుకింగ్ రద్దు చేయబడింది. మళ్ళీ ప్రయత్నించండి.',
    'hi': 'ठीक है! बुकिंग रद्द कर दी गई। फिर कोशिश करें।',
    'en': 'Okay! Booking cancelled. Try again anytime.',
  });

  // ── Clarification ─────────────────────────────────────────────────────────────

  static String clarify(String lang) => _pick(lang, {
    'ta': 'மன்னிக்கவும், புரியவில்லை. மீண்டும் சொல்லுங்கள் அல்லது கீழே உள்ள பொத்தானை அழுத்துங்கள்.',
    'te': 'క్షమించండి, అర్థం కాలేదు. మళ్ళీ చెప్పండి లేదా కింద బటన్ నొక్కండి.',
    'hi': 'माफ करें, समझ नहीं आया। फिर से बोलें या नीचे का बटन दबाएं।',
    'en': 'Sorry, I did not understand. Please speak again or tap a button below.',
  });

  // ── Helpers ───────────────────────────────────────────────────────────────────

  static String _pick(String lang, Map<String, String> map) =>
      map[lang] ?? map['en'] ?? map.values.first;

  static List<String> _pickList(String lang, Map<String, List<String>> map) =>
      map[lang] ?? map['en'] ?? map.values.first;
}
