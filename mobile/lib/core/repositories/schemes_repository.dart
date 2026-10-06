import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scheme_model.dart';

class SchemesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Real-time stream of schemes from Firestore
  Stream<List<SchemeModel>> streamSchemes({
    required String role, // 'FARMER' or 'MACHINE_OWNER' or 'ALL'
    required String lang, // 'ta', 'te', 'hi', 'en'
    String? category,
  }) {
    Query query = _firestore.collection('schemes').where('isActive', isEqualTo: true);

    final normalizedRole = role.toUpperCase();
    if (normalizedRole != 'ALL') {
      query = query.where('targetRole', whereIn: [normalizedRole, 'BOTH']);
    }

    if (category != null && category.isNotEmpty && category != 'ALL') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getFallbackSchemes(role, lang, category);
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SchemeModel.fromFirestore(data, lang);
      }).toList();
    }).handleError((_) {
      // In case of any Firestore permission/connectivity issues, return fallback
      return _getFallbackSchemes(role, lang, category);
    });
  }

  /// One-time fetch of schemes
  Future<List<SchemeModel>> getSchemesOnce({
    required String role,
    required String lang,
    String? category,
  }) async {
    try {
      Query query = _firestore.collection('schemes').where('isActive', isEqualTo: true);
      final normalizedRole = role.toUpperCase();
      if (normalizedRole != 'ALL') {
        query = query.where('targetRole', whereIn: [normalizedRole, 'BOTH']);
      }
      if (category != null && category.isNotEmpty && category != 'ALL') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return _getFallbackSchemes(role, lang, category);
      }
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SchemeModel.fromFirestore(data, lang);
      }).toList();
    } catch (_) {
      return _getFallbackSchemes(role, lang, category);
    }
  }

  /// Built-in fallback dataset ensuring 100% offline availability
  List<SchemeModel> _getFallbackSchemes(String role, String lang, String? category) {
    final all = _fallbackRawData.map((d) => SchemeModel.fromFirestore(d, lang)).toList();
    final normRole = role.toUpperCase();

    return all.where((s) {
      final matchesRole = normRole == 'ALL' || s.targetRole == normRole || s.targetRole == 'BOTH';
      final matchesCat = category == null || category == 'ALL' || s.category == category;
      return matchesRole && matchesCat;
    }).toList();
  }

  static final List<Map<String, dynamic>> _fallbackRawData = [
    {
      'id': 'smam-machinery-subsidy',
      'targetRole': 'MACHINE_OWNER',
      'category': 'MACHINERY_SUBSIDY',
      'subsidyBadge': {
        'ta': '40% - 50% மானியம்',
        'te': '40% - 50% రాయితీ',
        'hi': '40% - 50% सब्सिडी',
        'en': '40% - 50% Subsidy',
      },
      'title': {
        'ta': 'வேளாண் இயந்திரமயமாக்கல் திட்டம் (SMAM)',
        'te': 'వ్యవసాయ యాంత్రీకరణ సబ్-మిషన్ (SMAM)',
        'hi': 'कृषि यंत्रीकरण उप-मिशन (SMAM)',
        'en': 'Sub-Mission on Agricultural Mechanization (SMAM)',
      },
      'shortDesc': {
        'ta': 'புதிய டிராக்டர், பவர் டில்லர், அறுவடை இயந்திரம் வாங்க 40% முதல் 50% வரை அரசு மானியம்.',
        'te': 'కొత్త ట్రాక్టర్లు, పవర్ టిల్లర్లు, హార్వెస్టర్ల కొనుగోలుకు 40% నుండి 50% వరకు ప్రభుత్వ రాయితీ.',
        'hi': 'नए ट्रैक्टर, पावर टिलर और हार्वेस्टर खरीदने पर 40% से 50% तक सरकारी सब्सिडी।',
        'en': 'Get 40% to 50% subsidy on purchase of new tractors, power tillers, rotavators, and harvesters.',
      },
      'overview': {
        'ta': 'மத்திய அரசு மற்றும் தமிழக வேளாண் பொறியியல் துறை இணைந்து விவசாயிகளுக்கும் இயந்திர உரிமையாளர்களுக்கும் நவீன வேளாண் இயந்திரங்களை வாங்க நிதி உதவி வழங்கும் முதன்மை திட்டம்.',
        'te': 'కేంద్ర ప్రభుత్వం మరియు రాష్ట్ర వ్యవసాయ శాఖ ఆధ్వర్యంలో రైతులకు, యంత్ర యజమానులకు ఇచ్చే ప్రధాన పథకం.',
        'hi': 'किसानों और मशीन मालिकों को आधुनिक कृषि उपकरण खरीदने के लिए सरकारी वित्तीय सहायता योजना।',
        'en': 'Flagship scheme offering capital subsidy for purchasing farm machines and establishing Custom Hiring Centres.',
      },
      'benefits': {
        'ta': [
          'டிராக்டர் மற்றும் கருவிகளுக்கு 40% முதல் 50% வரை மானியம் (ரூ. 5 லட்சம் வரை)',
          'வாடகை மையம் (Custom Hiring Centre) அமைக்க 40% முதல் 80% வரை நிதி உதவி',
          'நேரடி வங்கி பரிமாற்றம் (DBT) மூலம் மானிய தொகை வழங்கப்படும்'
        ],
        'te': [
          'ట్రాక్టర్లపై 40% నుండి 50% రాయితీ',
          'కస్టమ్ హైరింగ్ సెంటర్ల ఏర్పాటుకు 80% వరకు సబ్సిడీ'
        ],
        'hi': [
          'ट्रैक्टर व उपकरणों पर 40% से 50% सब्सिडी',
          'कस्टम हायरिंग सेंटर हेतु 80% तक सहायता'
        ],
        'en': [
          '40% to 50% subsidy on tractors and implements (up to ₹5 Lakhs)',
          'Up to 80% subsidy for setting up Custom Hiring Centres (CHC)',
          'Direct Benefit Transfer (DBT) to bank account'
        ],
      },
      'eligibility': {
        'ta': ['விவசாயிகள் அல்லது இயந்திர வாடகை தொழில் தொடங்குவோர்', 'சொந்த நிலம் அல்லது குத்தகை உரிமை'],
        'te': ['రైతులు లేదా అద్దె వ్యాపారులు', 'భూమి వివరాలు ఉన్నవారు'],
        'hi': ['किसान अथवा ग्रामीण मशीनरी उद्यमी', 'वैध भूमि दस्तावेज'],
        'en': ['Farmers or custom hiring entrepreneurs', 'Valid land or business records'],
      },
      'documentsRequired': {
        'ta': ['ஆதார் அட்டை', 'பட்டா / சிட்டா நகல்', 'டீலரிடம் இருந்து கொட்டேஷன்', 'வங்கி பாஸ்புக்'],
        'te': ['ఆధార్ కార్డు', 'పట్టాదారు పాస్ బుక్', 'డీలర్ కొటేషన్', 'బ్యాంక్ పాస్‌బుక్'],
        'hi': ['आधार कार्ड', 'खसरा/खतौनी', 'डीलर कोटेशन', 'बैंक पासबुक'],
        'en': ['Aadhaar Card', 'Land Patta/Chitta', 'Dealer Quotation', 'Bank Passbook'],
      },
      'howToApply': {
        'ta': 'agrimachinery.nic.in இணையதளத்தில் பதிவு செய்து விண்ணப்பிக்கலாம்.',
        'te': 'agrimachinery.nic.in లో ఆన్‌లైన్‌లో దరఖాస్తు చేసుకోవచ్చు.',
        'hi': 'agrimachinery.nic.in पर सीधे ऑनलाइन आवेदन करें।',
        'en': 'Apply online at agrimachinery.nic.in or visit Agricultural Engineering Office.',
      },
      'applyUrl': 'https://agrimachinery.nic.in',
      'helpline': '1800-180-1551',
      'state': 'All India',
      'isActive': true,
    },
    {
      'id': 'aif-custom-hiring-loan',
      'targetRole': 'MACHINE_OWNER',
      'category': 'LOAN_CREDIT',
      'subsidyBadge': {
        'ta': '3% வட்டி தள்ளுபடி',
        'te': '3% వడ్డీ రాయితీ',
        'hi': '3% ब्याज छूट',
        'en': '3% Interest Subvention',
      },
      'title': {
        'ta': 'வேளாண் உள்கட்டமைப்பு நிதி (AIF)',
        'te': 'వ్యవసాయ మౌలిక సదుపాయాల నిధి (AIF)',
        'hi': 'कृषि अवसंरचना कोष (AIF ऋण)',
        'en': 'Agriculture Infrastructure Fund (AIF)',
      },
      'shortDesc': {
        'ta': 'வாடகை இயந்திர மையம் மற்றும் கிடங்கு அமைக்க ₹2 கோடி வரை 3% குறைந்த வட்டியில் வங்கிக் கடன்.',
        'te': 'కస్టమ్ హైరింగ్ సెంటర్ల ఏర్పాటుకు ₹2 కోట్ల వరకు 3% వడ్డీ రాయితీ రుణాలు.',
        'hi': 'कस्टम हायरिंग हब स्थापित करने हेतु ₹2 करोड़ तक के लोन पर 3% ब्याज छूट।',
        'en': '3% interest subvention on loans up to ₹2 Crores to establish machinery hubs.',
      },
      'overview': {
        'ta': 'இயந்திர மையம், குளிர்பதன கிடங்கு அமைக்க ₹2 கோடி வரை கடன் மற்றும் 3% வட்டி தள்ளுபடி.',
        'te': 'యంత్ర కేంద్రాలు మరియు గోదాముల ఏర్పాటుకు బ్యాంక్ రుణాలు.',
        'hi': 'एग्री इन्फ्रास्ट्रक्चर और मशीनरी हब हेतु बैंक ऋण पर ब्याज सहायता।',
        'en': 'Long-term debt financing with 3% interest subvention up to 7 years.',
      },
      'benefits': {
        'ta': ['3% வட்டி மானியம்', 'ரூ. 2 கோடி வரை கடன் வசதி', 'CGTMSE அரசு கடன் பிணையம்'],
        'te': ['3% వడ్డీ రాయితీ', 'రూ. 2 కోట్ల వరకు రుణం'],
        'hi': ['3% ब्याज छूट', '₹2 करोड़ तक ऋण'],
        'en': ['3% interest subvention', 'Up to ₹2 Crore loan cover', 'CGTMSE guarantee'],
      },
      'eligibility': {
        'ta': ['இயந்திர உரிமையாளர்கள், உழவர் உற்பத்தியாளர் குழுக்கள் (FPO)'],
        'te': ['యంత్ర యజమానులు, FPOలు'],
        'hi': ['मशीन मालिक, एफपीओ (FPO)'],
        'en': ['Machine owners, Agri-entrepreneurs, FPOs'],
      },
      'documentsRequired': {
        'ta': ['திட்ட அறிக்கை (Project DPR)', 'பான் மற்றும் ஆதார் அட்டை', 'வங்கி அறிக்கை'],
        'te': ['DPR ప్రాజెక్ట్ రిపోర్ట్', 'పాన్ & ఆధార్ కార్డు'],
        'hi': ['प्रोजेक्ट रिपोर्ट (DPR)', 'पैन एवं आधार कार्ड'],
        'en': ['Detailed Project Report (DPR)', 'PAN and Aadhaar', 'Bank statement'],
      },
      'howToApply': {
        'ta': 'agriinfra.dac.gov.in தளத்தில் விண்ணப்பிக்கவும்.',
        'te': 'agriinfra.dac.gov.in ద్వారా దరఖాస్తు చేయండి.',
        'hi': 'agriinfra.dac.gov.in पर ऑनलाइन आवेदन करें।',
        'en': 'Apply online at agriinfra.dac.gov.in.',
      },
      'applyUrl': 'https://agriinfra.dac.gov.in',
      'helpline': '011-23382012',
      'state': 'All India',
      'isActive': true,
    },
    {
      'id': 'pm-kisan-samman',
      'targetRole': 'FARMER',
      'category': 'DIRECT_BENEFIT',
      'subsidyBadge': {
        'ta': '₹6,000 / ஆண்டு',
        'te': '₹6,000 / ఏటా',
        'hi': '₹6,000 / वर्ष',
        'en': '₹6,000 / Year',
      },
      'title': {
        'ta': 'பிரதமர் கிசான் சம்மான் நிதி (PM-KISAN)',
        'te': 'పీఎం కిసాన్ సమ్మాన్ నిధి',
        'hi': 'प्रधानमंत्री किसान सम्मान निधि (PM-KISAN)',
        'en': 'PM-KISAN Samman Nidhi',
      },
      'shortDesc': {
        'ta': 'அனைத்து விவசாயிகளுக்கும் ஆண்டுக்கு ₹6,000 நேரடி பண உதவி (4 மாதத்திற்கு ஒருமுறை ₹2,000).',
        'te': 'రైతులకు ప్రతి సంవత్సరం ₹6,000 నేరుగా బ్యాంక్ ఖాతాలో జమ (₹2,000 వంతున 3 సార్లు).',
        'hi': 'सभी किसान परिवारों को प्रति वर्ष ₹6,000 की सीधी नकद सहायता।',
        'en': 'Direct income support of ₹6,000 per year in 3 installments of ₹2,000.',
      },
      'overview': {
        'ta': 'விவசாய செலவுகளுக்காக மத்திய அரசு வழங்கும் நேரடி வங்கி பண உதவி திட்டம்.',
        'te': 'రైతు పెట్టుబడి సహాయం కోసం కేంద్ర ప్రభుత్వం ఇచ్చే నగదు బదిలీ.',
        'hi': 'किसानों को आर्थिक सहायता हेतु प्रति वर्ष ₹6,000 की प्रत्यक्ष सहायता।',
        'en': 'Income support scheme transferring ₹6,000 annually into farmer bank accounts.',
      },
      'benefits': {
        'ta': ['ஆண்டுக்கு ₹6,000 நேரடி வரவு', 'இடைத்தரகர் இல்லாமல் வங்கிக்கு பணம்'],
        'te': ['ఏటా ₹6,000 నేరుగా జమ', 'మధ్యవర్తులు లేరు'],
        'hi': ['₹6,000 सीधे बैंक खाते में', 'शत-प्रतिशत केंद्रीय योजना'],
        'en': ['₹6,000 per year direct credit', '100% centrally sponsored'],
      },
      'eligibility': {
        'ta': ['விவசாய நிலம் வைத்துள்ள விவசாயிகள் (e-KYC கட்டாயம்)'],
        'te': ['వ్యవసాయ భూమి ఉన్న రైతులు'],
        'hi': ['खेतीहर भूमि स्वामी किसान परिवार'],
        'en': ['All cultivable landholding farmer families'],
      },
      'documentsRequired': {
        'ta': ['ஆதார் அட்டை', 'பட்டா / சிட்டா', 'ஆதார் இணைக்கப்பட்ட வங்கி கணக்கு'],
        'te': ['ఆధార్ కార్డు', 'పట్టాదారు పాస్ బుక్', 'బ్యాంక్ పాస్‌బుక్'],
        'hi': ['आधार कार्ड', 'खतौनी', 'आधार लिंक बैंक खाता'],
        'en': ['Aadhaar Card', 'Land Patta', 'Aadhaar-linked Bank Account'],
      },
      'howToApply': {
        'ta': 'pmkisan.gov.in அல்லது இ-சேவை மையம் மூலம் பதிவு செய்யலாம்.',
        'te': 'pmkisan.gov.in లో లేదా మీ-సేవ కేంద్రంలో నమోదు చేసుకోండి.',
        'hi': 'pmkisan.gov.in पोर्टल अथवा CSC सेंटर से आवेदन करें।',
        'en': 'Apply online at pmkisan.gov.in or through nearest CSC / e-Seva centre.',
      },
      'applyUrl': 'https://pmkisan.gov.in',
      'helpline': '155261',
      'state': 'All India',
      'isActive': true,
    },
    {
      'id': 'pmfby-crop-insurance',
      'targetRole': 'FARMER',
      'category': 'INSURANCE',
      'subsidyBadge': {
        'ta': '1.5% - 2% பிரீமியம்',
        'te': '1.5% - 2% ప్రీమియం',
        'hi': '1.5% - 2% प्रीमियम',
        'en': '1.5% - 2% Premium',
      },
      'title': {
        'ta': 'பிரதம மந்திரி பயிர் காப்பீட்டுத் திட்டம் (PMFBY)',
        'te': 'ప్రధాన మంత్రి ఫసల్ బీమా యోజన (PMFBY)',
        'hi': 'प्रधानमंत्री फसल बीमा योजना (PMFBY)',
        'en': 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      },
      'shortDesc': {
        'ta': 'வறட்சி, பெருமழை, பூச்சி தாக்குதலால் ஏற்படும் பயிர் சேதத்திற்கு முழு காப்பீட்டு இழப்பீடு.',
        'te': 'కరువు, వరదలు, తెగుళ్ల వల్ల కలిగే పంట నష్టానికి పూర్తి బీమా పరిహారం.',
        'hi': 'प्राकृतिक आपदा व कीट प्रकोप से फसल नुकसान पर व्यापक बीमा सुरक्षा।',
        'en': 'Comprehensive crop insurance against drought, floods, and natural hazards.',
      },
      'overview': {
        'ta': 'மிகக்குறைந்த பிரீமியத்தில் பயிர்களுக்கு முழு நிதி பாதுகாப்பு வழங்கும் காப்பீடு.',
        'te': 'రైతులకు నష్టపరిహారం అందించే తక్కువ ప్రీమియం పంట బీమా పథకం.',
        'hi': 'किसानों के लिए न्यूनतम प्रीमियम पर व्यापक फसल बीमा सुरक्षा।',
        'en': 'Lowest premium crop insurance protection across all seasonal notified crops.',
      },
      'benefits': {
        'ta': ['முழு சாகுபடி செலவிற்கும் இழப்பீடு', 'அறுவடைக்கு பிந்தைய சேதத்திற்கும் பாதுகாப்பு'],
        'te': ['పూర్తి పెట్టుబడికి రక్షణ', 'కోత తర్వాత కూడా వర్తింపు'],
        'hi': ['पूरी लागत का बीमा', 'कटाई उपरांत नुकसान भी शामिल'],
        'en': ['Covers full sum insured', 'Post-harvest losses covered up to 14 days'],
      },
      'eligibility': {
        'ta': ['அறிவிக்கப்பட்ட பயிர்களை பயிரிடும் நில உரிமையாளர்கள் மற்றும் குத்தகை விவசாயிகள்'],
        'te': ['నోటిఫై చేసిన పంటలు సాగుచేసే రైతులు'],
        'hi': ['अधिसूचित फसलें उगाने वाले सभी किसान व काश्तकार'],
        'en': ['All farmers cultivating notified crops in notified areas'],
      },
      'documentsRequired': {
        'ta': ['சாகுபடி அடங்கல் (VAO)', 'ஆதார் அட்டை', 'வங்கி பாஸ்புக்', 'பட்டா'],
        'te': ['సాగు పత్రం (VAO)', 'ఆధార్ కార్డు', 'బ్యాంక్ పాస్‌బుక్'],
        'hi': ['बुवाई प्रमाण पत्र', 'आधार कार्ड', 'बैंक पासबुक'],
        'en': ['Sowing Certificate (VAO/Village Officer)', 'Aadhaar Card', 'Bank Passbook'],
      },
      'howToApply': {
        'ta': 'pmfby.gov.in அல்லது தொடக்க கூட்டுறவு சங்கத்தில் (PACCS) பதிவு செய்ய வேண்டும்.',
        'te': 'pmfby.gov.in లేదా ప్రాథమిక వ్యవసాయ సహకార సంఘంలో నమోదు చేయండి.',
        'hi': 'pmfby.gov.in या नजदीकी प्राथमिक सहकारी समिति (PACS) से संपर्क करें।',
        'en': 'Enroll via pmfby.gov.in or Primary Agricultural Credit Society (PACS).',
      },
      'applyUrl': 'https://pmfby.gov.in',
      'helpline': '14447',
      'state': 'All India',
      'isActive': true,
    },
    {
      'id': 'micro-irrigation-subsidy',
      'targetRole': 'FARMER',
      'category': 'IRRIGATION',
      'subsidyBadge': {
        'ta': '100% இலவச மானியம்',
        'te': '100% ఉచిత రాయితీ',
        'hi': '100% तक अनुदान',
        'en': 'Up to 100% Subsidy',
      },
      'title': {
        'ta': 'சொட்டு நீர் பாசன மானியம் (Micro Irrigation)',
        'te': 'డ్రిప్ & స్ప్రింక్లర్ సబ్సిడీ',
        'hi': 'ड्रिप एवं स्प्रिंकलर सूक्ष्म सिंचाई अनुदान',
        'en': 'Micro Irrigation Scheme (Drip & Sprinkler)',
      },
      'shortDesc': {
        'ta': 'சிறு/குறு விவசாயிகளுக்கு 100% இலவச அரசு மானியத்தில் சொட்டு நீர் பாசனம்.',
        'te': 'చిన్న, సన్నకారు రైతులకు 100% ఉచిత రాయితీతో డ్రిప్ పరికరాలు.',
        'hi': 'लघु एवं सीमांत किसानों को 100% तक अनुदान पर ड्रिप सिस्टम।',
        'en': '100% subsidy for small and marginal farmers in TN for drip and sprinkler irrigation.',
      },
      'overview': {
        'ta': 'குறைந்த நீரில் அதிக மகசூல் பெற தமிழக அரசு 100% வரை வழங்கும் இலவச மானிய திட்டம்.',
        'te': 'నీటి ఆదా మరియు అధిక దిగుబడి కోసం సూక్ష్మ సేద్య పథకం.',
        'hi': 'जल संरक्षण और अधिक उपज के लिए सूक्ष्म सिंचाई अनुदान योजना।',
        'en': 'Precision micro irrigation scheme providing 100% subsidy for small farmers.',
      },
      'benefits': {
        'ta': ['100% இலவச மானியம்', '50% தண்ணீர் சேமிப்பு', 'களை கட்டுப்பாடு'],
        'te': ['100% రాయితీ', '50% నీటి ఆదా'],
        'hi': ['100% तक मुफ्त सहायता', '50% पानी की बचत'],
        'en': ['100% free subsidy for small farmers', 'Saves 50% water', 'Higher crop yields'],
      },
      'eligibility': {
        'ta': ['கிணறு அல்லது போர்வெல் பாசன நீர் ஆதாரம் உள்ள விவசாயிகள்'],
        'te': ['బోరుబావి లేదా బావి నీటి సౌకర్యం ఉన్న రైతులు'],
        'hi': ['सिंचाई का जल स्रोत रखने वाले किसान'],
        'en': ['Farmers with assured irrigation water source in Tamil Nadu'],
      },
      'documentsRequired': {
        'ta': ['சிட்டா மற்றும் அடங்கல்', 'நில வரைபடம் (FMB Sketch)', 'ஆதார் அட்டை'],
        'te': ['పట్టా పాస్ బుక్', 'FMB స్కెచ్', 'ఆధార్ కార్డు'],
        'hi': ['खतौनी', 'नक्शा (FMB)', 'आधार कार्ड'],
        'en': ['Chitta / Adangal', 'FMB Field Map', 'Aadhaar Card'],
      },
      'howToApply': {
        'ta': 'tnhorticulture.tn.gov.in அல்லது தோட்டக்கலை உதவி இயக்குநர் அலுவலகத்தை அணுகவும்.',
        'te': 'ఉద్యానవన శాఖ కార్యాలయం ద్వారా దరఖాస్తు చేసుకోండి.',
        'hi': 'राज्य उद्यानिकी विभाग पोर्टल से आवेदन करें।',
        'en': 'Apply online at tnhorticulture.tn.gov.in or contact Horticulture Office.',
      },
      'applyUrl': 'https://tnhorticulture.tn.gov.in',
      'helpline': '1800-425-4444',
      'state': 'Tamil Nadu',
      'isActive': true,
    },
    {
      'id': 'kisan-credit-card',
      'targetRole': 'FARMER',
      'category': 'LOAN_CREDIT',
      'subsidyBadge': {
        'ta': '4% குறைந்த வட்டி',
        'te': '4% స్వల్ప వడ్డీ',
        'hi': '4% ब्याज दर',
        'en': '4% Interest',
      },
      'title': {
        'ta': 'கிசான் கடன் அட்டை திட்டம் (KCC)',
        'te': 'కిసాన్ క్రెడిట్ కార్డు (KCC)',
        'hi': 'किसान क्रेडिट कार्ड (KCC)',
        'en': 'Kisan Credit Card (KCC)',
      },
      'shortDesc': {
        'ta': 'பயிர் சாகுபடிக்கு ₹3 லட்சம் வரை வெறும் 4% குறைந்த வட்டியில் கடன் வசதி.',
        'te': 'సాగు ఖర్చుల కోసం ₹3 లక్షల వరకు కేవలం 4% తక్కువ వడ్డీతో బ్యాంక్ రుణం.',
        'hi': 'फसल की बुवाई हेतु ₹3 लाख तक का लोन मात्र 4% ब्याज पर।',
        'en': 'Short-term cultivation loan up to ₹3 Lakhs at only 4% interest rate.',
      },
      'overview': {
        'ta': 'விதை, உரம் மற்றும் சாகுபடி செலவுகளுக்காக வங்கிகள் வழங்கும் எளிய கடன் அட்டை.',
        'te': 'రైతులకు బ్యాంకుల ద్వారా లభించే స్వల్పకాలిక రుణ సదుపాయం.',
        'hi': 'समय पर कृषि लागत जुटाने के लिए रियायती ब्याज दर पर बैंक लोन।',
        'en': 'Flexible credit facility for farm inputs at 4% effective interest rate.',
      },
      'benefits': {
        'ta': ['ATM மூலம் எப்போது வேண்டுமானாலும் பணம் எடுக்கலாம்', 'வட்டி வெறும் 4% மட்டுமே'],
        'te': ['ATM ద్వారా నగదు ఉపసంహరణ', 'కేవలం 4% వడ్డీ'],
        'hi': ['ATM कार्ड की सुविधा', 'मात्र 4% ब्याज दर'],
        'en': ['ATM-enabled card', 'Effective 4% interest with prompt repayment'],
      },
      'eligibility': {
        'ta': ['விவசாயிகள், குத்தகை விவசாயிகள், கால்நடை வளர்ப்போர்'],
        'te': ['రైతులు, కౌలుదారులు, పశుపోషకులు'],
        'hi': ['किसान, बटाईदार व पशुपालक'],
        'en': ['All farmers, tenant farmers, and dairy keepers'],
      },
      'documentsRequired': {
        'ta': ['ஆதார் அட்டை & பான் கார்டு', 'பட்டா / சிட்டா', 'சாகுபடி விவரம்'],
        'te': ['ఆధార్ & పాన్ కార్డు', 'పట్టాదారు పాస్ బుక్'],
        'hi': ['आधार एवं पैन कार्ड', 'खतौनी'],
        'en': ['Aadhaar and PAN Card', 'Land record', 'Crop details'],
      },
      'howToApply': {
        'ta': 'உங்கள் வங்கி அல்லது தொடக்க கூட்டுறவு சங்கத்தில் படிவம் கொடுத்து பெறலாம்.',
        'te': 'స్థానిక బ్యాంకు లేదా ప్రాథమిక సహకార సంఘంలో దరఖాస్తు చేయండి.',
        'hi': 'नजदीकी बैंक या सहकारी समिति में आवेदन करें।',
        'en': 'Apply at any bank branch or Cooperative Credit Society.',
      },
      'applyUrl': 'https://www.myscheme.gov.in/schemes/kcc',
      'helpline': '1800-180-1551',
      'state': 'All India',
      'isActive': true,
    },
  ];
}
