import 'on_device_nlp_engine.dart';

/// Closed taxonomy I = {I1, I2, ..., I22} of 22 operational intents:
/// Î = arg max_{Ik ∈ I} P(Ik | ASR(S), L, R)
enum VoiceIntentType {
  openAiAgent,        // AI Conversational Multi-turn Agent
  searchMachine,      // I1
  voiceBook,          // I2: natural language booking e.g. "tractor 2 acres"
  bookMachine,        // I3
  checkBookingStatus, // I4
  cancelBooking,      // I5
  contactOwner,       // I6
  rateOwner,          // I7
  listMyMachine,      // I8
  checkEarnings,      // I9
  acceptBooking,      // I10
  declineBooking,     // I11
  switchRole,         // I12: contextual role switch R
  navigateHome,       // I13
  navigateSearch,     // I14
  navigateBookings,   // I15
  navigateProfile,    // I16
  readPage,           // I17
  registerUser,       // I18
  confirmAction,      // I19
  rejectAction,       // I20
  unknown,            // I21
}

class VoiceIntentResult {
  const VoiceIntentResult({
    required this.intent,
    required this.originalSpeech,
    this.extractedQuery,
    this.targetRole,
    required this.feedbackMessage,
    this.confidence = 0.88, // CNLU confidence score (Formula 1 & 2)
  });

  final VoiceIntentType intent;
  final String originalSpeech;
  final String? extractedQuery;
  final String? targetRole; // 'farmer' or 'owner' (Contextual metadata R)
  final String feedbackMessage;
  final double confidence; // CNLU score
}

class VoiceAssistantService {
  /// Core intent classification: Î = arg max_{Ik ∈ I} P(Ik | ASR(S), L, R)
  /// Parses natural language spoken commands across Tamil, Tanglish, Telugu, Hindi, and English.
  static VoiceIntentResult parseCommand(String speechText, String langCode, {String? currentRole}) {
    final text = speechText.toLowerCase().trim();
    if (text.isEmpty) {
      return VoiceIntentResult(
        intent: VoiceIntentType.unknown,
        originalSpeech: speechText,
        confidence: 0.0, // CNLU < 0.70 triggers k increment
        feedbackMessage: _getFeedback(langCode, 'unknown'),
      );
    }

    // 0. AI Agent & Natural Voice Booking (Powered by On-Device AI Model)
    if (_matches(text, [
      'agent', 'ai agent', 'ai assistant', 'assistant', 'bot', 'robot',
      'உதவியாளர்', 'உழவன் உதவியாளர்', 'உதவி', 'ஏஜென்ட்', 'ஏஜன்ட்', 'ரோபோ',
      'டிராக்டர் வேண்டும்', 'ஹார்வெஸ்டர் வேண்டும்', 'எந்திரம் வேண்டும்',
      'புக் பண்ணனும்', 'புக் செய்', 'முன்பதிவு செய்', 'முன்பதிவு செய்ய',
      'வாடகைக்கு வேண்டும்', 'வாடகைக்கு எடுக்க',
      'సహాయకుడు', 'ఏజెంట్', 'బుక్ చేయండి',
      'सहायक', 'एजेंट', 'बुक करें'
    ])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.openAiAgent,
        originalSpeech: speechText,
        extractedQuery: speechText,
        confidence: 0.98,
        feedbackMessage: _getFeedback(langCode, 'open_agent'),
      );
    }

    final isSearchQuery = text.contains('search') ||
        text.contains('தேடு') ||
        text.contains('find') ||
        text.contains('खोज') ||
        text.contains('శోధ');

    if (!isSearchQuery) {
      final nlp = OnDeviceNlpEngine.instance.predict(speechText);
      final hasBookIntent = nlp.confidence >= 0.65 && nlp.intent.startsWith('book_');
      final hasNeedOrBook = text.contains('வேண்டும்') ||
          text.contains('தேவை') ||
          text.contains('want') ||
          text.contains('need') ||
          text.contains('book');
      if (hasBookIntent || (nlp.machineType != null && hasNeedOrBook)) {
        return VoiceIntentResult(
          intent: VoiceIntentType.openAiAgent,
          originalSpeech: speechText,
          extractedQuery: speechText,
          confidence: nlp.confidence,
          feedbackMessage: _getFeedback(langCode, 'open_agent'),
        );
      }
    }

    // 1. Role Switch commands
    if (_matches(text, ['my machines', 'owner mode', 'உரிமையாளர்', 'எந்திர உரிமையாளர்', 'என் எந்திரங்கள்', 'மாம்பக்கம்', 'ஓனர்', ' switch to owner', 'to owner'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.switchRole,
        originalSpeech: speechText,
        targetRole: 'owner',
        confidence: 0.95,
        feedbackMessage: _getFeedback(langCode, 'switch_owner'),
      );
    }
    if (_matches(text, ['renting', 'farmer mode', 'வாடகைக்கு', 'வாடகை', 'விவசாயி', 'விவசாயி முறை', ' switch to farmer', 'to farmer'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.switchRole,
        originalSpeech: speechText,
        targetRole: 'farmer',
        confidence: 0.95,
        feedbackMessage: _getFeedback(langCode, 'switch_farmer'),
      );
    }

    // 2. Earnings check intent
    if (_matches(text, ['earnings', 'income', 'வருமானம்', 'பணம்', 'வருமானம் பார்க்க', 'कमाई', 'ఆదాయం'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.checkEarnings,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'earnings'),
      );
    }

    // 3. List / Add Machine intent
    if (_matches(text, ['add machine', 'list machine', 'புதிய எந்திரம்', 'சேர்', 'எந்திரம் சேர்க்க', 'எந்திரம் பதிவு', 'मशीन जोड़ें', 'యంత్రం జోడించు'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.listMyMachine,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'list_machine'),
      );
    }

    // 4. Accept / Decline incoming booking requests
    if (_matches(text, ['accept booking', 'ஏற்றுக்கொள்', 'சரி செய்', 'स्वीकार करें', 'அంగీకరించు'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.acceptBooking,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'accept_booking'),
      );
    }
    if (_matches(text, ['decline booking', 'நிராகரி', 'அस्वीकार करें', 'తిరస్కరించు'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.declineBooking,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'decline_booking'),
      );
    }

    // 5. Contact Owner intent
    if (_matches(text, ['call owner', 'contact owner', 'அழை', 'உரிமையாளரை அழை', 'கால் செய்', 'कॉल करें', 'కాల్ చేయండి'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.contactOwner,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'contact_owner'),
      );
    }

    // 6. Rate Owner intent
    if (_matches(text, ['rate owner', 'rating', 'மதிப்பீடு', 'ஸ்டார் கொடு', 'ரேட்டிங்', 'रेटिंग', 'రేటింగ్'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.rateOwner,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'rate_owner'),
      );
    }

    // 7a. Smart Voice Booking — "I want a tractor for 2 acres" style natural sentence
    //     Must contain a machine keyword AND an area/need keyword
    final machineKeywords = [
      'tractor', 'டிராக்டர்', 'ट्रैक्टर', 'ట్రాక్టర్',
      'harvester', 'அறுவடை', 'हार्वेस्टर', 'హార్వెస்టర్',
      'rotavator', 'ரோட்டவேட்டர்', 'रोटावेटर',
      'plough', 'plow', 'கலப்பை', 'ஏர்', 'हल',
      'seeder', 'விதைப்பான்', 'sprayer', 'தெளிப்பான்',
      'cultivator', 'உழவு',
    ];
    final needKeywords = [
      'வேண்டும்', 'வேண்டும்', 'தேவை', 'வேண்டுமானால்',
      'acre', 'ஏக்கர்', 'ఎకరం', 'एकड़',
      'ஒன்று', 'இரண்டு', 'மூன்று', 'நான்கு', 'ஐந்து',
      'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
      'want', 'need', 'book for', 'rent',
      'plough', 'ploughing', 'harvest', 'sow', 'spray',
      'உழவு', 'அறுவடை', 'விதைப்பு',
    ];
    final hasMachine = machineKeywords.any((k) => text.contains(k));
    final hasNeed = needKeywords.any((k) => text.contains(k));
    if (hasMachine && hasNeed) {
      return VoiceIntentResult(
        intent: VoiceIntentType.voiceBook,
        originalSpeech: speechText,
        extractedQuery: speechText, // raw text for VoiceBookingParser
        feedbackMessage: _getFeedback(langCode, 'voice_book'),
      );
    }

    // 7b. Book Machine intent (legacy explicit command)
    if (_matches(text, ['book machine', 'book tractor', 'முன்பதிவு செய்', 'முன்பதிவு செய்ய வேண்டும்', 'புக்கிங் செய்', 'எந்திரம் முன்பதிவு', 'டிராக்டர் முன்பதிவு', 'बुक करें', 'బుక్ చేయండి'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.bookMachine,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'book_machine'),
      );
    }

    // 8. Cancel Booking intent
    if (_matches(text, ['cancel booking', 'முன்பதிவு ரத்து', 'ரத்து செய்', 'ரத்து', 'बुकिंग रद्द करें', 'బుకింగ్ రద్దు'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.cancelBooking,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'cancel_booking'),
      );
    }

    // 9. Check Booking Status intent
    if (_matches(text, ['check status', 'status', 'நிலை', 'முன்பதிவு நிலை', 'நிலைமை', 'முன்பதிவு என்ன ஆச்சு', 'स्थिति', 'స్థితి'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.checkBookingStatus,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'check_status'),
      );
    }

    // 10. Explicit Affirmation / Rejection (for Voice Confirmation Modal)
    if (_matches(text, ['yes', 'உறுதி', 'ஆமாம்', 'சரி', 'हां', 'அవును', 'confirm', 'ok', 'okay', 'accept'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.confirmAction,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'confirm'),
      );
    }
    if (_matches(text, ['no', 'வேண்டாம்', 'இல்லை', 'नहीं', 'వద్దు', 'cancel', 'decline', 'stop'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.rejectAction,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'reject'),
      );
    }

    // 11. Navigation
    if (_matches(text, ['home', 'முகப்பு', 'முகப்பு பக்கம்', 'ஹோம்', 'முதன்மை', 'முதல் பக்கம்', 'வீடு', 'முகப்புக்கு செல்', 'होम', 'హోమ్'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.navigateHome,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'home'),
      );
    }
    if (_matches(text, ['booking', 'bookings', 'முன்பதிவுகள்', 'முன்பதிவு', 'என் முன்பதிவு', 'புக்கிங்', 'बुकिंग', 'బుకింగ్‌లు'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.navigateBookings,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'bookings'),
      );
    }
    if (_matches(text, ['profile', 'account', 'சுயவிவரம்', 'புரோஃபைல்', 'கணக்கு', 'प्रोफाइल', 'ప్రొఫైల్'])) {
      return VoiceIntentResult(
        intent: VoiceIntentType.navigateProfile,
        originalSpeech: speechText,
        feedbackMessage: _getFeedback(langCode, 'profile'),
      );
    }

    // 12. Search keywords or fallback
    return VoiceIntentResult(
      intent: VoiceIntentType.searchMachine,
      originalSpeech: speechText,
      extractedQuery: speechText,
      feedbackMessage: _getFeedback(langCode, 'search', query: speechText),
    );
  }

  static bool _matches(String text, List<String> keywords) {
    final words = text.split(RegExp(r'\s+'));
    return keywords.any((kw) {
      final cleanKw = kw.trim();
      // Exact full-text match
      if (cleanKw == text) return true;
      // Exact single-word match
      if (words.contains(cleanKw)) return true;
      // Multi-word phrase match
      if (cleanKw.contains(' ') && text.contains(cleanKw)) return true;
      // Substring match — handles Tamil STT variants where extra syllables are appended
      if (text.contains(cleanKw)) return true;
      return false;
    });
  }

  static String _getFeedback(String lang, String type, {String? query}) {
    final isTa = lang.startsWith('ta');
    final isTe = lang.startsWith('te');
    final isHi = lang.startsWith('hi');

    switch (type) {
      case 'open_agent':
        if (isTa) return 'உழவன் AI உதவியாளர் திறக்கப்படுகிறது';
        if (isTe) return 'ఉఝవన్ AI సహాయకుడు తెరవబడుతోంది';
        if (isHi) return 'उझवन AI सहायक खोला जा रहा है';
        return 'Opening Uzhavan AI Assistant';
      case 'confirm':
        if (isTa) return 'செயல் உறுதி செய்யப்பட்டது';
        if (isTe) return 'చర్య ధృవీకరించబడింది';
        if (isHi) return 'कार्रवाई की पुष्टि की गई';
        return 'Action confirmed';
      case 'reject':
        if (isTa) return 'செயல் ரத்து செய்யப்பட்டது';
        if (isTe) return 'చర్య రద్దు చేయబడింది';
        if (isHi) return 'कार्रवाई रद्द की गई';
        return 'Action cancelled';
      case 'switch_owner':
        if (isTa) return 'என் எந்திரங்கள் பகுதிக்கு மாறுகிறது';
        if (isTe) return 'నా యంత్రాల విభాగానికి మారుతోంది';
        if (isHi) return 'मालिक मोड में स्विच किया जा रहा है';
        return 'Switching to Owner mode';
      case 'switch_farmer':
        if (isTa) return 'வாடகைக்கு பகுதிக்கு மாறுகிறது';
        if (isTe) return 'రైతు విభాగానికి మారుతోంది';
        if (isHi) return 'किसान मोड में स्विच किया जा रहा है';
        return 'Switching to Farmer mode';
      case 'earnings':
        if (isTa) return 'வருமான விபரங்களைத் திறக்கிறது';
        if (isTe) return 'ఆదాయ వివరాలను తెరుస్తోంది';
        if (isHi) return 'कमाई का विवरण खोला जा रहा है';
        return 'Opening earnings page';
      case 'list_machine':
        if (isTa) return 'புதிய எந்திரம் சேர்க்கும் பக்கத்தைத் திறக்கிறது';
        if (isTe) return 'కొత్త యంత్రాన్ని జోడించే పేజీని తెరుస్తోంది';
        if (isHi) return 'नई मशीन जोड़ने का पेज खोल रहे हैं';
        return 'Opening add machine form';
      case 'accept_booking':
        if (isTa) return 'முன்பதிவை ஏற்கவும்';
        if (isTe) return 'బుకింగ్ అంగీకరించు';
        if (isHi) return 'बुकिंग स्वीकार करें';
        return 'Accepting booking';
      case 'decline_booking':
        if (isTa) return 'முன்பதிவை நிராகரிக்கவும்';
        if (isTe) return 'బుకింగ్ తిరస్కరించு';
        if (isHi) return 'बुकिंग अस्वीकार करें';
        return 'Declining booking';
      case 'voice_book':
        if (isTa) return 'அருகில் உள்ள எந்திரம் தேடுகிறோம்...';
        if (isTe) return 'సమీప యంత్రాన్ని వెతుకుతోంది...';
        if (isHi) return 'पास की मशीन खोज रहे हैं...';
        return 'Finding the best matching machine near you...';
      case 'book_machine':
        if (isTa) return 'முன்பதிவு செய்யப்படுகிறது';
        if (isTe) return 'బుకింగ్ ప్రక్రియ ప్రారంభమైంది';
        if (isHi) return 'बुकिंग की जा रही है';
        return 'Initiating booking';
      case 'cancel_booking':
        if (isTa) return 'முன்பதிவை ரத்து செய்கிறது';
        if (isTe) return 'బుకిங் రద్దు చేస్తోంది';
        if (isHi) return 'बुकिंग रद्द की जा रही है';
        return 'Cancelling booking';
      case 'contact_owner':
        if (isTa) return 'உரிமையாளரைத் தொடர்பு கொள்ளுகிறது';
        if (isTe) return 'యజమానిని సంప్రదిస్తోంది';
        if (isHi) return 'मालिक से संपर्क किया जा रहा है';
        return 'Contacting owner';
      case 'rate_owner':
        if (isTa) return 'மதிப்பீட்டைப் பதிவு செய்கிறது';
        if (isTe) return 'ரேட்டிங் నమోదు చేస్తోంది';
        if (isHi) return 'रेटिंग दर्ज की जा रही है';
        return 'Opening rating dialog';
      case 'check_status':
        if (isTa) return 'முன்பதிவு நிலையைச் சரிபார்க்கிறது';
        if (isTe) return 'బుకింగ్ స్థితిని తనిఖీ చేస్తోంది';
        if (isHi) return 'बुकिंग स्थिति जांच रहे हैं';
        return 'Checking booking status';
      case 'home':
        if (isTa) return 'முகப்பு பக்கத்திற்குச் செல்கிறது';
        if (isTe) return 'హోమ్ పేజీకి வெళ్తోంది';
        if (isHi) return 'होम पेज पर जा रहे हैं';
        return 'Navigating to Home screen';
      case 'bookings':
        if (isTa) return 'உங்கள் முன்பதிவுகளைக் காட்டுகிறது';
        if (isTe) return 'మీ బుకింగ్‌లను చూపిస్తోంది';
        if (isHi) return 'आपकी बुकिंग दिखाई जा रही है';
        return 'Opening your bookings';
      case 'profile':
        if (isTa) return 'உங்கள் கணக்கு பக்கத்தைத் திறக்கிறது';
        if (isTe) return 'మీ ప్రొఫైల్ పేజీని తెరుస్తోంది';
        if (isHi) return 'प्रोफाइल पेज खोल रहे हैं';
        return 'Opening your profile';
      case 'read':
        if (isTa) return 'பக்கத்தின் விபரங்களை வாசிக்கிறது';
        if (isTe) return 'పేజీ వివరాలను చదువుతోంది';
        if (isHi) return 'पेज की जानकारी पढ़ रहे हैं';
        return 'Reading page content';
      case 'search':
        final q = query ?? '';
        if (isTa) return '$q தேடப்படுகிறது';
        if (isTe) return '$q కోసం వెతుకుతోంది';
        if (isHi) return '$q की खोज की जा रही है';
        return 'Searching for $q';
      default:
        if (isTa) return 'புரியவில்லை. மீண்டும் சொல்லுங்கள்';
        if (isTa) return 'அర్థம் కాలேது. மళ్లీ சொல்லுங்கள்';
        if (isHi) return 'समझ नहीं आया. कृपया दोबारा बोलें';
        return 'Voice command not recognized. Please try again.';
    }
  }
}
