export interface LocalizedText {
  ta: string;
  te: string;
  hi: string;
  en: string;
}

export interface LocalizedList {
  ta: string[];
  te: string[];
  hi: string[];
  en: string[];
}

export interface SchemeItem {
  id: string;
  targetRole: 'FARMER' | 'MACHINE_OWNER' | 'BOTH';
  category: 'MACHINERY_SUBSIDY' | 'DIRECT_BENEFIT' | 'INSURANCE' | 'IRRIGATION' | 'LOAN_CREDIT' | 'SOIL_SEEDS';
  subsidyBadge: LocalizedText;
  title: LocalizedText;
  shortDesc: LocalizedText;
  overview: LocalizedText;
  benefits: LocalizedList;
  eligibility: LocalizedList;
  documentsRequired: LocalizedList;
  howToApply: LocalizedText;
  applyUrl: string;
  helpline: string;
  state: string;
  isActive: boolean;
}

export const MASTER_SCHEMES: SchemeItem[] = [
  // ── 1. SMAM (Sub-Mission on Agricultural Mechanization) ────────────────────
  {
    id: 'smam-machinery-subsidy',
    targetRole: 'MACHINE_OWNER',
    category: 'MACHINERY_SUBSIDY',
    subsidyBadge: {
      ta: '40% - 50% மானியம்',
      te: '40% - 50% రాయితీ',
      hi: '40% - 50% सब्सिडी',
      en: '40% - 50% Subsidy',
    },
    title: {
      ta: 'வேளாண் இயந்திரமயமாக்கல் திட்டம் (SMAM)',
      te: 'వ్యవసాయ యాంత్రీకరణ సబ్-మిషన్ (SMAM)',
      hi: 'कृषि यंत्रीकरण उप-मिशन (SMAM)',
      en: 'Sub-Mission on Agricultural Mechanization (SMAM)',
    },
    shortDesc: {
      ta: 'புதிய டிராக்டர், பவர் டில்லர், அறுவடை இயந்திரம் வாங்க 40% முதல் 50% வரை அரசு மானியம்.',
      te: 'కొత్త ట్రాక్టర్లు, పవర్ టిల్లర్లు, హార్వెస్టర్ల కొనుగోలుకు 40% నుండి 50% వరకు ప్రభుత్వ రాయితీ.',
      hi: 'नए ट्रैक्टर, पावर टिलर और हार्वेस्टर खरीदने पर 40% से 50% तक सरकारी सब्सिडी।',
      en: 'Get 40% to 50% subsidy on purchase of new tractors, power tillers, rotavators, and harvesters.',
    },
    overview: {
      ta: 'இந்திய அரசு மற்றும் தமிழக வேளாண் பொறியியல் துறை இணைந்து விவசாயிகளுக்கும் இயந்திர உரிமையாளர்களுக்கும் நவீன வேளாண் இயந்திரங்களை வாங்க நிதி உதவி வழங்கும் முதன்மை திட்டம் ஆகும். இதன் மூலம் தனிநபர்கள் மற்றும் வாடகை மையங்கள் (Custom Hiring Centres) மானியம் பெறலாம்.',
      te: 'భారత ప్రభుత్వం మరియు రాష్ట్ర వ్యవసాయ శాఖ సంయుక్తంగా రైతులు మరియు యంత్ర యజమానులకు ఆధునిక వ్యవసాయ పరికరాలు కొనుగోలు చేయడానికి ఇచ్చే ప్రధాన పథకం. దీని ద్వారా కస్టమ్ హైరింగ్ కేంద్రాలను కూడా ఏర్పాటు చేసుకోవచ్చు.',
      hi: 'भारत सरकार का यह प्रमुख मिशन किसानों और मशीन मालिकों को आधुनिक कृषि उपकरण खरीदने के लिए वित्तीय सहायता प्रदान करता है। इसके तहत कस्टम हायरिंग सेंटर (CHC) भी स्थापित किए जा सकते हैं।',
      en: 'The flagship scheme by Ministry of Agriculture offering financial support for purchasing tractors, implements, and setting up Custom Hiring Centres (CHC) to mechanize farm operations.',
    },
    benefits: {
      ta: [
        'டிராக்டர் மற்றும் கருவிகளுக்கு 40% முதல் 50% வரை மானியம் (ரூ. 5 லட்சம் வரை)',
        'வாடகை மையம் (Custom Hiring Centre) அமைக்க 40% முதல் 80% வரை நிதி உதவி',
        'பெண்கள், சிறு/குறு விவசாயிகள் மற்றும் ஆதிதிராவிடர் பிரிவினருக்கு முன்னுரிமை',
        'நேரடி வங்கி பரிமாற்றம் (DBT) மூலம் மானிய தொகை வழங்கப்படும்',
      ],
      te: [
        'ట్రాక్టర్లు మరియు పరికరాలపై 40% నుండి 50% వరకు రాయితీ (గరిష్టంగా రూ. 5 లక్షలు)',
        'కస్టమ్ హైరింగ్ సెంటర్ల (CHC) ఏర్పాటుకు 40% నుండి 80% వరకు సబ్సిడీ',
        'మహిళలు, చిన్న/సన్నకారు రైతులకు ప్రాధాన్యత',
        'నేరుగా బ్యాంక్ ఖాతాలో జమ అయ్యే రాయితీ (DBT)',
      ],
      hi: [
        'ट्रैक्टर और कृषि उपकरणों पर 40% से 50% सब्सिडी (अधिकतम ₹5 लाख तक)',
        'कस्टम हायरिंग सेंटर (CHC) स्थापित करने के लिए 40% से 80% तक सहायता',
        'महिला एवं लघु/सीमांत किसानों को अतिरिक्त वरीयता',
        'डीबीटी (DBT) के माध्यम से बैंक खाते में सीधे सब्सिडी भुगतान',
      ],
      en: [
        '40% to 50% capital subsidy on tractors and implements (up to ₹5 Lakhs)',
        '40% to 80% subsidy for establishing Custom Hiring Centres (CHC)',
        'Special preference for small, marginal, and women agri-entrepreneurs',
        'Direct Benefit Transfer (DBT) credited directly to bank account',
      ],
    },
    eligibility: {
      ta: [
        'விவசாயிகள் அல்லது வேளாண் இயந்திர வாடகை தொழில் தொடங்குவோர்',
        'சொந்த நிலம் அல்லது குத்தகை நில உரிமை ஆவணம்',
        'கடந்த 5 ஆண்டுகளில் இதே திட்டத்தில் மானியம் பெறாதவராக இருக்க வேண்டும்',
      ],
      te: [
        'రైతులు లేదా వ్యవసాయ యంత్ర అద్దె వ్యాపారం ప్రారంభించేవారు',
        'సొంత లేదా కౌలు భూమి వివరాలు కలిగి ఉండాలి',
        'గత 5 సంవత్సరాలలో ఈ పథకం కింద ప్రయోజనం పొందలేదని నిరూపించాలి',
      ],
      hi: [
        'किसान या कृषि मशीनरी कस्टम हायरिंग शुरू करने वाले ग्रामीण उद्यमी',
        'भूमि अभिलेख या कृषि कार्य प्रमाण पत्र',
        'पिछले 5 वर्षों में समान उपकरण के लिए कोई अन्य सब्सिडी न ली हो',
      ],
      en: [
        'Farmers or rural agri-entrepreneurs setting up custom hiring services',
        'Valid agricultural landholding or business registration',
        'Must not have availed subsidy on same equipment within last 5 years',
      ],
    },
    documentsRequired: {
      ta: ['ஆதார் அட்டை (Aadhaar Card)', 'பட்டா / சிட்டா நகல்', 'அங்கீகரிக்கப்பட்ட டீலரிடம் இருந்து விலைப்புள்ளி (Dealer Quotation)', 'ஆதார் இணைக்கப்பட்ட வங்கி பாஸ்புக்'],
      te: ['ఆధార్ కార్డు', 'పట్టాదారు పాస్ పుస్తకం', 'డీలర్ కొటేషన్ (Quotation)', 'బ్యాంక్ పాస్‌బుక్'],
      hi: ['आधार कार्ड', 'जमीन की खतौनी / खसरा', 'अधिकृत डीलर से कोटेशन', 'बैंक पासबुक'],
      en: ['Aadhaar Card', 'Land Record (Patta/Chitta)', 'Quotation from authorized dealer', 'Aadhaar-linked bank passbook'],
    },
    howToApply: {
      ta: 'agrimachinery.nic.in இணையதளத்தில் பதிவு செய்து, டீலர் கொட்டேஷன் மற்றும் ஆவணங்களை பதிவேற்ற வேண்டும். அல்லது உங்கள் வட்டார வேளாண்மை உதவி இயக்குநர் அலுவலகத்தை அணுகலாம்.',
      te: 'agrimachinery.nic.in వెబ్‌సైట్‌లో దరఖాస్తు చేసుకోవచ్చు లేదా మండల వ్యవసాయ అధికారి కార్యాలయాన్ని సంప్రదించవచ్చు.',
      hi: 'agrimachinery.nic.in पोर्टल पर ऑनलाइन पंजीकरण करें अथवा अपने निकटतम कृषि विज्ञान केंद्र या उप निदेशक कृषि कार्यालय से संपर्क करें।',
      en: 'Register online at agrimachinery.nic.in, upload quotation & land records, or visit the Assistant Director of Agricultural Engineering office.',
    },
    applyUrl: 'https://agrimachinery.nic.in',
    helpline: '1800-180-1551',
    state: 'All India',
    isActive: true,
  },

  // ── 2. Agriculture Infrastructure Fund (AIF) ───────────────────────────────
  {
    id: 'aif-custom-hiring-loan',
    targetRole: 'MACHINE_OWNER',
    category: 'LOAN_CREDIT',
    subsidyBadge: {
      ta: '3% வட்டி தள்ளுபடி',
      te: '3% వడ్డీ రాయితీ',
      hi: '3% ब्याज छूट',
      en: '3% Interest Subvention',
    },
    title: {
      ta: 'வேளாண் உள்கட்டமைப்பு நிதி (AIF - குறைந்த வட்டி கடன்)',
      te: 'వ్యవసాయ మౌలిక సదుపాయాల నిధి (AIF)',
      hi: 'कृषि अवसंरचना कोष (AIF ऋण योजना)',
      en: 'Agriculture Infrastructure Fund (AIF)',
    },
    shortDesc: {
      ta: 'வாடகை இயந்திர மையம் மற்றும் கிடங்கு அமைக்க ₹2 கோடி வரை 3% குறைந்த வட்டியில் வங்கிக் கடன்.',
      te: 'కస్టమ్ హైరింగ్ కేంద్రాలు మరియు గిడ్డంగుల ఏర్పాటుకు ₹2 కోట్ల వరకు 3% వడ్డీ రాయితీతో బ్యాంకు రుణాలు.',
      hi: 'कस्टम हायरिंग हब और वेयरहाउस स्थापित करने के लिए ₹2 करोड़ तक के ऋण पर 3% ब्याज छूट।',
      en: '3% interest subvention on bank loans up to ₹2 Crores to build custom hiring hubs and storage.',
    },
    overview: {
      ta: 'விவசாய இயந்திரங்கள், அறுவடைக்கு பிந்தைய பதப்படுத்தும் கூடங்கள், மற்றும் குளிர்பதன கிடங்குகள் அமைப்பதற்கு ₹2 கோடி வரையிலான கடன்களுக்கு ஆண்டுக்கு 3% வட்டி மானியமும், CGTMSE மூலமாக அரசு கடன் உத்தரவாதமும் வழங்கப்படுகிறது.',
      te: 'వ్యవసాయ యంత్రాల హబ్‌లు, కోల్డ్ స్టోరేజీలు మరియు ప్రాసెసింగ్ యూనిట్ల ఏర్పాటుకు ₹2 కోట్ల వరకు 3% వడ్డీ రాయితీ మరియు క్రెడిట్ గ్యారెంటీ లభిస్తుంది.',
      hi: 'कृषि मशीनरी हब, कोल्ड स्टोरेज और वेयरहाउस निर्माण हेतु बैंकों से ₹2 करोड़ तक के लोन पर 3% प्रति वर्ष ब्याज छूट और सरकारी क्रेडिट गारंटी उपलब्ध है।',
      en: 'Medium-to-long term debt financing for post-harvest management and community farming assets like custom hiring machinery with 3% annual interest subvention for 7 years.',
    },
    benefits: {
      ta: [
        'ஆண்டுக்கு 3% வட்டி மானியம் (அதிகபட்சம் 7 ஆண்டுகளுக்கு)',
        'ரூ. 2 கோடி வரை கடன் வசதி',
        'CGTMSE திட்டத்தின் கீழ் அரசு பிணையம் (No third-party collateral needed up to ₹2 Cr)',
      ],
      te: [
        'సంవత్సరానికి 3% వడ్డీ రాయితీ (గరిష్టంగా 7 సంవత్సరాలు)',
        'రూ. 2 కోట్ల వరకు బ్యాంకు రుణాలు',
        'కొలేటరల్ రహిత గ్యారెంటీ (CGTMSE)',
      ],
      hi: [
        '3% वार्षिक ब्याज छूट (अधिकतम 7 वर्षों के लिए)',
        '₹2 करोड़ तक की ऋण सीमा',
        'बिना किसी अतिरिक्त गारंटी के CGTMSE क्रेडिट कवर',
      ],
      en: [
        '3% per annum interest subvention up to 7 years',
        'Loan amount up to ₹2 Crore covered',
        'Credit guarantee coverage under CGTMSE scheme',
      ],
    },
    eligibility: {
      ta: ['இயந்திர உரிமையாளர்கள், உழவர் உற்பத்தியாளர் நிறுவனங்கள் (FPO), கிராமப்புற தொழில்முனைவோர்'],
      te: ['యంత్ర యజమానులు, రైతు ఉత్పత్తిదారుల సంఘాలు (FPO), గ్రామీణ వ్యాపారులు'],
      hi: ['मशीनरी मालिक, किसान उत्पादक संगठन (FPO), ग्रामीण कृषि उद्यमी'],
      en: ['Machine owners, FPOs, PACS, Agri-entrepreneurs, and startups'],
    },
    documentsRequired: {
      ta: ['திட்ட அறிக்கை (Project DPR)', 'பான் மற்றும் ஆதார் அட்டை', 'வங்கி கணக்கு அறிக்கை (6 மாதங்கள்)', 'நில ஆவணம் அல்லது வாடகை ஒப்பந்தம்'],
      te: ['ప్రాజెక్ట్ రిపోర్ట్ (DPR)', 'పాన్ & ఆధార్ కార్డు', 'బ్యాంక్ స్టేట్‌మెంట్', 'స్థలం పత్రాలు'],
      hi: ['परियोजना रिपोर्ट (DPR)', 'पैन एवं आधार कार्ड', '6 माह का बैंक स्टेटमेंट', 'भूमि या परिसर का पट्टा'],
      en: ['Detailed Project Report (DPR)', 'PAN and Aadhaar Card', '6-month Bank Statement', 'Land or premise lease agreement'],
    },
    howToApply: {
      ta: 'agriinfra.dac.gov.in போர்ட்டலில் ஆன்லைனில் விண்ணப்பித்து உங்கள் திட்ட அறிக்கையை சமர்ப்பிக்கலாம்.',
      te: 'agriinfra.dac.gov.in పోర్టల్ ద్వారా ఆన్‌లైన్‌లో దరఖాస్తు చేసుకోవచ్చు.',
      hi: 'agriinfra.dac.gov.in पोर्टल पर सीधे ऑनलाइन आवेदन करें।',
      en: 'Apply online directly at agriinfra.dac.gov.in with project report.',
    },
    applyUrl: 'https://agriinfra.dac.gov.in',
    helpline: '011-23382012',
    state: 'All India',
    isActive: true,
  },

  // ── 3. PM-KISAN (Pradhan Mantri Kisan Samman Nidhi) ────────────────────────
  {
    id: 'pm-kisan-samman',
    targetRole: 'FARMER',
    category: 'DIRECT_BENEFIT',
    subsidyBadge: {
      ta: '₹6,000 / ஆண்டு',
      te: '₹6,000 / ఏటా',
      hi: '₹6,000 / वर्ष',
      en: '₹6,000 / Year',
    },
    title: {
      ta: 'பிரதமர் கிசான் சம்மான் நிதி (PM-KISAN)',
      te: 'పీఎం కిసాన్ సమ్మాన్ నిధి',
      hi: 'प्रधानमंत्री किसान सम्मान निधि (PM-KISAN)',
      en: 'PM-KISAN Samman Nidhi',
    },
    shortDesc: {
      ta: 'அனைத்து விவசாயிகளுக்கும் ஆண்டுக்கு ₹6,000 நேரடி பண உதவி (4 மாதத்திற்கு ஒருமுறை ₹2,000).',
      te: 'రైతులకు ప్రతి సంవత్సరం ₹6,000 నేరుగా బ్యాంక్ ఖాతాలో జమ (4 నెలలకు ఒకసారి ₹2,000).',
      hi: 'सभी किसान परिवारों को प्रति वर्ष ₹6,000 की सीधी नकद सहायता (₹2,000 की 3 किस्तों में)।',
      en: 'Direct income support of ₹6,000 per year in 3 equal installments of ₹2,000 every 4 months.',
    },
    overview: {
      ta: 'சாகுபடி செலவுகள் மற்றும் வீட்டு தேவைகளை பூர்த்தி செய்வதற்காக நிலம் வைத்திருக்கும் அனைத்து விவசாய குடும்பங்களுக்கும் மத்திய அரசு வழங்கும் நேரடி பண உதவி திட்டம்.',
      te: 'రైతుల విత్తనాలు, ఎరువులు మరియు వ్యవసాయ అవసరాల ఖర్చుల కోసం కేంద్ర ప్రభుత్వం నేరుగా అందించే ఆర్థిక సహాయం.',
      hi: 'कृषि और घरेलू आवश्यकताओं के लिए सभी पात्र भूमिधारक किसान परिवारों को प्रति वर्ष ₹6,000 की निश्चित आर्थिक सहायता सीधे बैंक खाते में दी जाती है।',
      en: 'Direct cash transfer scheme for all landholding farmer families across India to supplement their financial needs for agricultural inputs and domestic expenses.',
    },
    benefits: {
      ta: [
        'ஆண்டுக்கு ₹6,000 நேரடி வங்கி கணக்கில் வரவு',
        'மத்திய அரசால் 100% நிதியுதவி',
        'இடைத்தரகர் இல்லாமல் நேரடியாக ஆதார் இணைக்கப்பட்ட கணக்கிற்கு பணம்',
      ],
      te: [
        'ఏటా ₹6,000 నేరుగా బ్యాంక్ ఖాతాలో జమ',
        '100% కేంద్ర ప్రభుత్వ నిధులు',
        'మధ్యవర్తులు లేకుండా నేరుగా లబ్ధిదారునికి చేరే నగదు',
      ],
      hi: [
        'प्रति वर्ष ₹6,000 सीधे बैंक खाते में',
        '100% केंद्र सरकार द्वारा वित्तपोषित',
        'बिचौलियों के बिना सीधे आधार लिंक्ड खाते में भुगतान',
      ],
      en: [
        '₹6,000 credited directly into Aadhaar-linked bank accounts annually',
        '100% centrally funded scheme',
        'Zero commission or middlemen involved',
      ],
    },
    eligibility: {
      ta: ['சொந்தமாக சாகுபடி நிலம் வைத்துள்ள விவசாயிகள் (e-KYC கட்டாயம்)'],
      te: ['వ్యవసాయ భూమి గల రైతులు (e-KYC తప్పనిసరి)'],
      hi: ['खेती योग्य भूमि के स्वामी किसान (e-KYC अनिवार्य)'],
      en: ['Farmer families holding cultivable agricultural land (e-KYC mandatory)'],
    },
    documentsRequired: {
      ta: ['ஆதார் அட்டை', 'நில உரிமை பட்டா / சிட்டா', 'ஆதார் இணைக்கப்பட்ட வங்கி கணக்கு எண்'],
      te: ['ఆధార్ కార్డు', 'పట్టాదారు పాస్ బుక్', 'ఆధార్ లింక్ అయిన బ్యాంక్ ఖాతా'],
      hi: ['आधार कार्ड', 'जमीन के दस्तावेज (खतौनी)', 'आधार से जुड़ा सक्रिय बैंक खाता'],
      en: ['Aadhaar Card', 'Land Record (Patta/Chitta)', 'Active Aadhaar-seeded Bank Account'],
    },
    howToApply: {
      ta: 'pmkisan.gov.in தளத்தில் "New Farmer Registration" கிளிக் செய்து விண்ணப்பிக்கலாம், அல்லது அருகில் உள்ள இ-சேவை மையத்தை அணுகலாம்.',
      te: 'pmkisan.gov.in లో "New Farmer Registration" లేదా మీ-సేవ కేంద్రం ద్వారా దరఖాస్తు చేయండి.',
      hi: 'pmkisan.gov.in पोर्टल पर "New Farmer Registration" पर जाकर ऑनलाइन अथवा CSC केंद्र से आवेदन करें।',
      en: 'Apply online via pmkisan.gov.in under New Farmer Registration or visit your nearest CSC / e-Seva centre.',
    },
    applyUrl: 'https://pmkisan.gov.in',
    helpline: '155261',
    state: 'All India',
    isActive: true,
  },

  // ── 4. PMFBY (Pradhan Mantri Fasal Bima Yojana) ─────────────────────────────
  {
    id: 'pmfby-crop-insurance',
    targetRole: 'FARMER',
    category: 'INSURANCE',
    subsidyBadge: {
      ta: '1.5% - 2% குறைந்த பிரீமியம்',
      te: '1.5% - 2% అతి తక్కువ ప్రీమియం',
      hi: '1.5% - 2% न्यूनतम प्रीमियम',
      en: '1.5% - 2% Low Premium',
    },
    title: {
      ta: 'பிரதம மந்திரி பயிர் காப்பீட்டுத் திட்டம் (PMFBY)',
      te: 'ప్రధాన మంత్రి ఫసల్ బీమా యోజన (PMFBY)',
      hi: 'प्रधानमंत्री फसल बीमा योजना (PMFBY)',
      en: 'Pradhan Mantri Fasal Bima Yojana (Crop Insurance)',
    },
    shortDesc: {
      ta: 'வறட்சி, பெருமழை, பூச்சி தாக்குதலால் ஏற்படும் பயிர் சேதத்திற்கு முழுமையான காப்பீட்டு இழப்பீடு.',
      te: 'కరువు, వరదలు, తెగుళ్లు మరియు అకాల వర్షాల వల్ల కలిగే పంట నష్టానికి పూర్తి బీమా పరిహారం.',
      hi: 'बाढ़, सूखा, ओलावृष्टि और कीट प्रकोप से होने वाले फसल नुकसान पर संपूर्ण बीमा सुरक्षा।',
      en: 'Complete crop insurance cover against natural calamities, drought, floods, and unseasonal rains.',
    },
    overview: {
      ta: 'விவசாயிகள் இயற்கை பேரிடர்களால் பாதிக்கப்படும்போது அவர்களின் பொருளாதார இழப்பை தவிர்க்கும் மிகக்குறைந்த பிரீமியம் கொண்ட பயிர் காப்பீட்டு திட்டம். காரிஃப் பயிர்களுக்கு 2%, ரபி பயிர்களுக்கு 1.5% மட்டுமே விவசாயி செலுத்த வேண்டும்.',
      te: 'ప్రకృతి వైపరీత్యాల వల్ల పంట నష్టపోయినప్పుడు రైతులకు ఆర్థిక రక్షణ కల్పించే అతి తక్కువ ప్రీమియం పంట బీమా పథకం. ఖరీఫ్ పంటలకు 2%, రబీ పంటలకు 1.5% ప్రీమియం మాత్రమే.',
      hi: 'प्राकृतिक आपदाओं के समय किसानों को वित्तीय स्थिरता प्रदान करने वाली योजना। किसान को खरीफ फसलों के लिए केवल 2% और रबी फसलों के लिए केवल 1.5% का मामूली प्रीमियम देना होता है।',
      en: 'Comprehensive crop insurance covering non-preventable natural risks from pre-sowing to post-harvest. Farmers pay a uniform minimal premium of 2% for Kharif, 1.5% for Rabi.',
    },
    benefits: {
      ta: [
        'முழு சாகுபடி செலவிற்கும் காப்பீட்டு பாதுகாப்பு',
        'அறுவடைக்கு பிந்தைய சேதத்திற்கும் (14 நாட்கள் வரை) இழப்பீடு உண்டு',
        'உள்ளூர் பேரிடர் (ஆலங்கட்டி மழை, நிலச்சரிவு) பாதிப்புகளுக்கு உடனடி ஆய்வு',
      ],
      te: [
        'మొత్తం పంట పెట్టుబడికి బీమా రక్షణ',
        'కోత తర్వాత 14 రోజుల వరకు నష్టపరిహారం లభిస్తుంది',
        'స్థానిక వైపరీత్యాలకు శీఘ్ర సర్వే మరియు పరిహారం',
      ],
      hi: [
        'पूरी फसल लागत का बीमा संरक्षण',
        'कटाई के बाद 14 दिनों तक चक्रवात या बेमौसम बारिश से नुकसान की भरपाई',
        'स्थानीय आपदाओं (ओलावृष्टि, जलभराव) पर त्वरित मुआवजा',
      ],
      en: [
        'Comprehensive financial risk cover for crop loss',
        'Post-harvest losses covered up to 14 days after cutting',
        'Rapid assessment for localized calamities like hailstorms and floods',
      ],
    },
    eligibility: {
      ta: ['அறிவிக்கப்பட்ட பயிர்களை பயிரிடும் நில உரிமையாளர்கள், குத்தகை விவசாயிகள் மற்றும் பகிர்வாளர்கள்'],
      te: ['నోటిఫై చేయబడిన పంటలు సాగుచేసే రైతులు మరియు కౌలు రైతులు'],
      hi: ['अधिसूचित फसलें उगाने वाले सभी भूस्वामी, बटाईदार और काश्तकार किसान'],
      en: ['All farmers including tenant farmers and sharecroppers cultivating notified crops'],
    },
    documentsRequired: {
      ta: ['பயிர் சாகுபடி அடங்கல் (VAO/Village Officer)', 'ஆதார் அட்டை', 'வங்கி பாஸ்புக்', 'நில ஆவணம் (பட்டா)'],
      te: ['పంట సాగు ధృవీకరణ పత్రం (VAO)', 'ఆధార్ కార్డు', 'బ్యాంక్ పాస్‌బుక్', 'పట్టాదారు పాస్ బుక్'],
      hi: ['बुवाई प्रमाण पत्र / पटवारी रिपोर्ट', 'आधार कार्ड', 'बैंक पासबुक', 'खसरा / खतौनी'],
      en: ['Crop Sowing Certificate (VAO/Patwari)', 'Aadhaar Card', 'Bank Passbook', 'Land record (Patta)'],
    },
    howToApply: {
      ta: 'pmfby.gov.in இணையதளம், உங்கள் தொடக்க வேளாண்மை கூட்டுறவு வங்கி (PACCS), அல்லது இ-சேவை மையம் மூலம் சாகுபடி செய்த 30 நாட்களுக்குள் பதிவு செய்ய வேண்டும்.',
      te: 'pmfby.gov.in లో లేదా స్థానిక వ్యవసాయ సహకార సంఘం / మీ-సేవ కేంద్రంలో నమోదు చేసుకోండి.',
      hi: 'pmfby.gov.in पोर्टल अथवा प्राथमिक कृषि सहकारी समिति (PACS) / CSC केंद्र से बुवाई के तय समय के भीतर बीमा कराएं।',
      en: 'Enroll via pmfby.gov.in, your local Primary Agricultural Credit Society (PACS), or CSC centre before the cutoff date.',
    },
    applyUrl: 'https://pmfby.gov.in',
    helpline: '14447',
    state: 'All India',
    isActive: true,
  },

  // ── 5. Per Drop More Crop (Micro Irrigation - TN & Central) ────────────────
  {
    id: 'micro-irrigation-subsidy',
    targetRole: 'FARMER',
    category: 'IRRIGATION',
    subsidyBadge: {
      ta: '100% இலவச மானியம்',
      te: '100% ఉచిత రాయితీ',
      hi: '100% तक सब्सिडी',
      en: 'Up to 100% Subsidy',
    },
    title: {
      ta: 'சொட்டு நீர் பாசன மானியம் (Micro Irrigation)',
      te: 'సూక్ష్మ సేద్యం (డ్రిప్ & స్ప్రింక్లర్) సబ్సిడీ',
      hi: 'प्रति बूंद अधिक फसल - सूक्ष्म सिंचाई (ड्रिप व स्प्रिंकलर)',
      en: 'Per Drop More Crop - Drip & Sprinkler Irrigation',
    },
    shortDesc: {
      ta: 'சிறு/குறு விவசாயிகளுக்கு 100% இலவச அரசு மானியத்திலும், பிற விவசாயிகளுக்கு 75% மானியத்திலும் சொட்டு நீர் பாசனம்.',
      te: 'చిన్న, సన్నకారు రైతులకు 100% ఉచితంగా, ఇతర రైతులకు 75% రాయితీతో డ్రిప్ మరియు స్ప్రింక్లర్ పరికరాలు.',
      hi: 'लघु व सीमांत किसानों को 100% तक और अन्य किसानों को 75% तक अनुदान पर ड्रिप व स्प्रिंकलर सिंचाई।',
      en: '100% subsidy for small and marginal farmers (75% for others) in Tamil Nadu for drip and sprinkler systems.',
    },
    overview: {
      ta: 'குறைந்த நீர் பயன்பாட்டில் அதிக மகசூல் பெற தமிழக தோட்டக்கலை மற்றும் வேளாண்மை துறை வழங்கும் திட்டம். சிறு மற்றும் குறு விவசாயிகளுக்கு (5 ஏக்கருக்குள்) முழு அமைப்பும் 100% இலவச மானியத்தில் நிறுவப்படுகிறது.',
      te: 'తక్కువ నీటితో ఎక్కువ దిగుబడి సాధించేందుకు ఉద్యానవన మరియు వ్యవసాయ శాఖ అందించే పథకం. చిన్న/సన్నకారు రైతులకు 100% రాయితీ అందుబాటులో ఉంది.',
      hi: 'जल संरक्षण और उत्पादकता बढ़ाने हेतु ड्रिप एवं स्प्रिंकलर सिस्टम लगाने पर तमिलनाडु व अन्य राज्यों में 75% से 100% तक अनुदान दिया जाता है।',
      en: 'State and central scheme promoting precision water efficiency. In Tamil Nadu, small and marginal farmers receive 100% subsidy, while other farmers receive 75% subsidy.',
    },
    benefits: {
      ta: [
        'சிறு/குறு விவசாயிகளுக்கு 100% இலவச அரசு மானியம்',
        'தண்ணீர் பயன்பாட்டில் 50% சேமிப்பு மற்றும் களை வளர்ச்சி கட்டுப்பாடு',
        'உரங்களை நேரடியாக வேர்களுக்கு அனுப்பும் முறை (Fertigation)',
      ],
      te: [
        'చిన్న మరియు సన్నకారు రైతులకు 100% ఉచిత రాయితీ',
        '50% నీటి ఆదా మరియు కలుపు నియంత్రణ',
        'ఎరువుల సమర్థవంతమైన వినియోగం',
      ],
      hi: [
        'लघु व सीमांत किसानों को 100% तक मुफ्त सरकारी सहायता',
        '50% तक पानी की बचत व खरपतवार पर नियंत्रण',
        'उर्वरक की सीधी जड़ों तक सटीक आपूर्ति (फर्टिगेशन)',
      ],
      en: [
        '100% subsidy for small & marginal farmers in Tamil Nadu',
        'Saves up to 50% water while boosting crop yields by 30-40%',
        'Enables direct fertilizer delivery to root zone (fertigation)',
      ],
    },
    eligibility: {
      ta: ['பாசன நீர் ஆதாரம் (கிணறு அல்லது ஆழ்துளை கிணறு) மற்றும் மின் இணைப்பு உள்ள விவசாயிகள்'],
      te: ['బోరుబావి లేదా బావి నీటి సౌకర్యం మరియు విద్యుత్ కనెక్షన్ ఉన్న రైతులు'],
      hi: ['कुआं, नलकूप या सिंचाई का पक्का जल स्रोत रखने वाले किसान'],
      en: ['Farmers with assured irrigation water source (well/borewell) and electricity'],
    },
    documentsRequired: {
      ta: ['சிட்டா மற்றும் அடங்கல்', 'நில வரைபடம் (FMB Sketch)', 'ஆதார் அட்டை', 'நீர் மற்றும் மண் பரிசோதனை சான்றிதழ்'],
      te: ['పట్టా పాస్ బుక్', 'FMB స్కెచ్', 'ఆధార్ కార్డు', 'నీరు & నేల పరీక్ష నివేదిక'],
      hi: ['जमीन की खतौनी / खसरा', 'नक्शा (FMB)', 'आधार कार्ड', 'जल एवं मृदा परीक्षण रिपोर्ट'],
      en: ['Chitta and Adangal', 'FMB Field Sketch', 'Aadhaar Card', 'Soil & Water test report'],
    },
    howToApply: {
      ta: 'tnhorticulture.tn.gov.in போர்ட்டலில் ஆன்லைனில் பதிவு செய்யலாம் அல்லது வட்டார தோட்டக்கலை உதவி இயக்குநர் அலுவலகத்தை நேரில் அணுகலாம்.',
      te: 'ఉద్యానవన శాఖ కార్యాలయం లేదా సంబంధిత పోర్టల్ ద్వారా దరఖాస్తు చేసుకోవచ్చు.',
      hi: 'संबंधित राज्य उद्यान विभाग पोर्टल या उपनिदेशक उद्यान कार्यालय में संपर्क करें।',
      en: 'Register online at tnhorticulture.tn.gov.in or contact the Assistant Director of Horticulture office.',
    },
    applyUrl: 'https://tnhorticulture.tn.gov.in',
    helpline: '1800-425-4444',
    state: 'Tamil Nadu & Central',
    isActive: true,
  },

  // ── 6. Kisan Credit Card (KCC) ─────────────────────────────────────────────
  {
    id: 'kisan-credit-card',
    targetRole: 'FARMER',
    category: 'LOAN_CREDIT',
    subsidyBadge: {
      ta: '4% குறைந்த வட்டி கடன்',
      te: '4% స్వల్ప వడ్డీ రుణం',
      hi: '4% ब्याज दर',
      en: '4% Effective Interest',
    },
    title: {
      ta: 'கிசான் கடன் அட்டை திட்டம் (Kisan Credit Card - KCC)',
      te: 'కిసాన్ క్రెడిట్ కార్డు (KCC)',
      hi: 'किसान क्रेडिट कार्ड (KCC योजना)',
      en: 'Kisan Credit Card (KCC)',
    },
    shortDesc: {
      ta: 'பயிர் சாகுபடிக்கு ₹3 லட்சம் வரை வெறும் 4% குறைந்த வட்டியில் கடன் வசதி.',
      te: 'పంట సాగు మరియు పెట్టుబడి కోసం ₹3 లక్షల వరకు కేవలం 4% తక్కువ వడ్డీతో బ్యాంక్ రుణం.',
      hi: 'फसल की बुवाई और देखरेख हेतु ₹3 लाख तक का अल्पकालिक ऋण मात्र 4% रियायती ब्याज दर पर।',
      en: 'Short-term cultivation credit up to ₹3 Lakhs at only 4% interest rate with prompt repayment.',
    },
    overview: {
      ta: 'விவசாயிகள் கந்துவட்டிக்காரர்களிடம் சிக்காமல் இருக்கவும், விதை, உரம் மற்றும் அறுவடை செலவுகளை எளிதாக சமாளிக்கவும் வங்கிகள் மூலம் மிகக்குறைந்த 4% வட்டியில் வழங்கப்படும் நெகிழ்வான கடன் அட்டை.',
      te: 'రైతులు విత్తనాలు, ఎరువులు మరియు పంట నిర్వహణ ఖర్చులను తీర్చుకోవడానికి బ్యాంకుల ద్వారా లభించే స్వల్పకాలిక రుణ సదుపాయం.',
      hi: 'साहूकारों के चंगुल से किसानों को बचाने और समय पर कृषि लागत जुटाने के लिए 4% की रियायती ब्याज दर पर आसान लोन की सुविधा।',
      en: 'Provides timely institutional credit to farmers for seasonal cultivation, post-harvest expenses, and maintenance of farm assets up to ₹3 Lakh at an effective 4% interest rate.',
    },
    benefits: {
      ta: [
        'வங்கி கடன் அட்டை மூலம் ATM-ல் எப்போது வேண்டுமானாலும் பணம் எடுக்கலாம்',
        'சரியான நேரத்தில் திரும்ப செலுத்தினால் வட்டி வெறும் 4% மட்டுமே (3% அரசு வட்டி மானியம்)',
        'ரூ. 1.60 லட்சம் வரை பிணையம் (No collateral) தேவையில்லை',
      ],
      te: [
        'ATM ద్వారా ఎప్పుడైనా నగదు ఉపసంహరణ సౌకర్యం',
        'సకాలంలో చెల్లిస్తే వడ్డీ కేవలం 4% మాత్రమే (3% వడ్డీ రాయితీ)',
        'రూ. 1.60 లక్షల వరకు ఎలాంటి తనఖా అవసరం లేదు',
      ],
      hi: [
        'ATM कार्ड की तरह कभी भी पैसे निकालने की सुविधा',
        'समय पर पुनर्भुगतान पर प्रभावी ब्याज दर मात्र 4% (3% शीघ्र भुगतान प्रोत्साहन)',
        '₹1.60 लाख तक बिना किसी बंधक (Collateral-free) के लोन',
      ],
      en: [
        'ATM-enabled smart card for instant cash withdrawals as needed',
        'Effective 4% rate with prompt repayment (7% minus 3% incentive)',
        'Collateral-free loans up to ₹1.60 Lakhs',
      ],
    },
    eligibility: {
      ta: ['விவசாயிகள், குத்தகை விவசாயிகள், கால்நடை வளர்ப்போர் மற்றும் மீன்வளர்ப்பு செய்வோர்'],
      te: ['రైతులు, కౌలుదారులు, పశుపోషకులు మరియు మత్స్యకారులు'],
      hi: ['सभी किसान, काश्तकार, बटाईदार, पशुपालक एवं मत्स्य पालक'],
      en: ['Owner cultivators, tenant farmers, dairy farmers, and fisheries'],
    },
    documentsRequired: {
      ta: ['ஆதார் அட்டை மற்றும் பான் கார்டு', 'நில உரிமை பட்டா / சிட்டா', 'சாகுபடி பயிர் விவரம்'],
      te: ['ఆధార్ & పాన్ కార్డు', 'పట్టాదారు పాస్ బుక్', 'పంట సాగు వివరాలు'],
      hi: ['आधार कार्ड व पैन कार्ड', 'जमीन के राजस्व दस्तावेज', 'फसल बुवाई घोषणा पत्र'],
      en: ['Aadhaar Card and PAN Card', 'Land record (Patta/Chitta)', 'Crop cultivation declaration'],
    },
    howToApply: {
      ta: 'உங்கள் அருகில் உள்ள தொடக்க கூட்டுறவு வங்கி அல்லது வணிக வங்கியில் ஒரு பக்க எளிய விண்ணப்ப படிவத்தை சமர்ப்பித்து பெறலாம்.',
      te: 'స్థానిక వాణిజ్య బ్యాంకు లేదా ప్రాథమిక సహకార సంఘంలో దరఖాస్తు చేసుకోండి.',
      hi: 'किसी भी वाणिज्यिक बैंक, ग्रामीण बैंक या प्राथमिक सहकारी बैंक शाखा में आवेदन करें।',
      en: 'Submit the simple one-page form at any commercial bank, RRB, or Cooperative Society branch.',
    },
    applyUrl: 'https://www.myscheme.gov.in/schemes/kcc',
    helpline: '1800-180-1551',
    state: 'All India',
    isActive: true,
  },

  // ── 7. PM-KUSUM (Solar Agricultural Pumps) ─────────────────────────────────
  {
    id: 'pm-kusum-solar-pump',
    targetRole: 'BOTH',
    category: 'MACHINERY_SUBSIDY',
    subsidyBadge: {
      ta: '60% - 90% மானியம்',
      te: '60% - 90% రాయితీ',
      hi: '60% - 90% सब्सिडी',
      en: '60% - 90% Subsidy',
    },
    title: {
      ta: 'பிரதமர் குசும் சூரிய ஒளி பம்புசெட் திட்டம் (PM-KUSUM)',
      te: 'పీఎం కుసుమ్ సోలార్ పంప్ పథకం',
      hi: 'प्रधानमंत्री कुसुम योजना (सोलर कृषि पंप)',
      en: 'PM-KUSUM Solar Agricultural Pumps',
    },
    shortDesc: {
      ta: 'விவசாய நிலங்களுக்கு சூரிய சக்தி சோலார் பம்புசெட் அமைக்க 60% முதல் 90% வரை அரசு மானியம்.',
      te: 'వ్యవసాయ భూములకు సోలార్ పంపుసెట్ల ఏర్పాటుకు 60% నుండి 90% వరకు భారీ ప్రభుత్వ రాయితీ.',
      hi: 'खेतों में सौर ऊर्जा संचालित पंप लगाने पर 60% से 90% तक सरकारी अनुदान।',
      en: '60% to 90% subsidy to install standalone solar pumps and solarize existing agri-grid pumps.',
    },
    overview: {
      ta: 'மின் இணைப்பு இல்லாத அல்லது டீசல் பம்புகளை பயன்படுத்தும் விவசாயிகளுக்கு 3 முதல் 10 குதிரைத்திறன் (HP) வரை சூரிய ஒளி மூலம் இயங்கும் மோட்டார்களை மிக குறைந்த செலவில் அமைக்க மத்திய-மாநில அரசுகள் வழங்கும் திட்டம்.',
      te: 'డీజిల్ పంపుల స్థానంలో లేదా విద్యుత్ సౌకర్యం లేని భూములకు సోలార్ పంపుసెట్లు ఏర్పాటు చేయడానికి ఇచ్చే భారీ రాయితీ పథకం.',
      hi: 'डीजल चालित सिंचाई पंपों को सौर ऊर्जा पंपों में बदलने और नए सोलर पंप लगाने हेतु केंद्र व राज्य सरकारों की 60-90% वित्तीय सहायता।',
      en: 'Replaces expensive diesel pumps with clean solar-powered agricultural pumpsets (3HP to 10HP) with joint funding from Central (30%), State (30-60%), and bank loan.',
    },
    benefits: {
      ta: [
        'டீசல் செலவு பூஜ்ஜியம்; பகல் நேரத்தில் தடையில்லா இலவச பாசனம்',
        '60% முதல் 90% வரை அரசு மானியம் (விவசாயி பங்கு வெறும் 10-20% மட்டுமே)',
        'கூடுதல் சோலார் மின்சாரத்தை மின்வாரியத்திற்கு விற்று கூடுதல் வருமானம் பெறலாம்',
      ],
      te: [
        'డీజిల్ ఖర్చులు లేవు; పగటిపూట నిరంతర ఉచిత సాగునీరు',
        '60% నుండి 90% వరకు సబ్సిడీ (రైతు వాటా కేవలం 10-20% మాత్రమే)',
        'మిగులు విద్యుత్తును గ్రిడ్‌కు అమ్మి అదనపు ఆదాయం పొందవచ్చు',
      ],
      hi: [
        'डीजल खर्च पूरी तरह समाप्त; दिन के समय निर्बाध निःशुल्क सिंचाई',
        '60% से 90% सरकारी सब्सिडी (किसान अंश मात्र 10-20%)',
        'अतिरिक्त सौर बिजली को ग्रिड को बेचकर अतिरिक्त आय का अवसर',
      ],
      en: [
        'Zero fuel cost; reliable daytime irrigation with solar power',
        '60% to 90% total subsidy (farmer pays only 10% to 20%)',
        'Option to sell surplus generated solar power back to the electricity grid',
      ],
    },
    eligibility: {
      ta: ['நில உரிமை மற்றும் கிணறு/போர்வெல் நீர் ஆதாரம் உள்ள அனைத்து விவசாயிகள்'],
      te: ['భూమి హక్కు మరియు నీటి వనరు ఉన్న రైతులు'],
      hi: ['जल स्रोत व कृषि भूमि रखने वाले व्यक्तिगत किसान या समूह'],
      en: ['Farmers with cultivable land and borewell or open well source'],
    },
    documentsRequired: {
      ta: ['பட்டா / சிட்டா ஆவணம்', 'ஆதார் அட்டை', 'வங்கி பாஸ்புக்', 'தண்ணீர் மட்டம் உறுதி ஆவணம்'],
      te: ['పట్టా పాస్ బుక్', 'ఆధార్ కార్డు', 'బ్యాంక్ పాస్‌బుక్'],
      hi: ['खतौनी / पट्टा', 'आधार कार्ड', 'बैंक खाता विवरण'],
      en: ['Land record (Patta)', 'Aadhaar Card', 'Bank Passbook', 'Proof of water source'],
    },
    howToApply: {
      ta: 'pmkusum.mnre.gov.in அல்லது தமிழ்நாடு வேளாண் பொறியியல் துறை (AED) அலுவலகத்தில் விண்ணப்பிக்கலாம்.',
      te: 'pmkusum.mnre.gov.in లేదా రాష్ట్ర పునరుత్పాదక ఇంధన సంస్థ (TEDA/NEDCAP) ద్వారా దరఖాస్తు చేయండి.',
      hi: 'pmkusum.mnre.gov.in अथवा राज्य ऊर्जा विकास निगम पोर्टल से सीधे आवेदन करें।',
      en: 'Apply via pmkusum.mnre.gov.in or contact your State Agricultural Engineering Department.',
    },
    applyUrl: 'https://pmkusum.mnre.gov.in',
    helpline: '1800-180-3333',
    state: 'All India',
    isActive: true,
  },

  // ── 8. Soil Health Card Scheme ─────────────────────────────────────────────
  {
    id: 'soil-health-card',
    targetRole: 'FARMER',
    category: 'SOIL_SEEDS',
    subsidyBadge: {
      ta: '100% இலவச பரிசோதனை',
      te: '100% ఉచిత పరీక్ష',
      hi: '100% निःशुल्क जांच',
      en: '100% Free Soil Test',
    },
    title: {
      ta: 'மண் வள அட்டை திட்டம் (Soil Health Card)',
      te: 'సాయిల్ హెల్త్ కార్డ్ పథకం (భూసార పరీక్ష)',
      hi: 'मृदा स्वास्थ्य कार्ड योजना (सॉइल हेल्थ कार्ड)',
      en: 'Soil Health Card Scheme',
    },
    shortDesc: {
      ta: 'மண்ணின் சத்துக்களை இலவசமாக பரிசோதித்து உர பரிந்துரை வழங்கும் அரசு திட்டம்.',
      te: 'భూసారాన్ని ఉచితంగా పరీక్షించి పంటల వారీగా ఎరువుల మోతాదును తెలియజేసే పథకం.',
      hi: 'खेत की मिट्टी की निःशुल्क पोषक जांच और फसलों हेतु संतुलित खाद की सिफारिश।',
      en: 'Free soil nutrient testing every 2 years with crop-specific fertilizer recommendations.',
    },
    overview: {
      ta: 'மண்ணில் உள்ள 12 முக்கிய சத்துக்களை (N, P, K, pH, நுண்ணூட்டங்கள்) ஆய்வு செய்து, எந்த பயிருக்கு எவ்வளவு உரம் இட வேண்டும் என்ற துல்லியமான வழிகாட்டுதலை விவசாயிகளுக்கு அரசு இலவசமாக வழங்குகிறது.',
      te: 'నేలలోని 12 పోషకాలను పరీక్షించి, సరైన మోతాదులో ఎరువులు వాడేందుకు రైతులకు ప్రభుత్వం ఉచితంగా కార్డును అందిస్తుంది.',
      hi: 'मिट्टी के 12 प्रमुख मापदंडों की जांच कर किसानों को फसल-वार संतुलित उर्वरक उपयोग की सलाह दी जाती है, जिससे लागत कम और उत्पादन अधिक होता है।',
      en: 'Provides comprehensive diagnostic report of 12 nutrient parameters in your soil to optimize fertilizer usage, reduce unnecessary input costs, and protect soil fertility.',
    },
    benefits: {
      ta: [
        'தேவையற்ற உரச் செலவை 20% முதல் 30% வரை மிச்சப்படுத்தலாம்',
        'மண்ணின் வளம் பாதுகாக்கப்பட்டு மகசூல் 10-15% அதிகரிக்கிறது',
        'அரசு சான்றளிக்கப்பட்ட ஆய்வகத்தில் 100% இலவச பரிசோதனை',
      ],
      te: [
        'అనవసరమైన ఎరువుల ఖర్చు 20% నుండి 30% వరకు తగ్గుతుంది',
        'నేల సారం రక్షించబడి దిగుబడి 10-15% పెరుగుతుంది',
        '100% ఉచిత ప్రయోగశాల పరీక్ష',
      ],
      hi: [
        'उर्वरक खर्च में 20% से 30% की बचत',
        'मिट्टी की उपजाऊ शक्ति की रक्षा और उत्पादन में 10-15% की वृद्धि',
        'सरकारी प्रयोगशालाओं में 100% निःशुल्क मृदा परीक्षण',
      ],
      en: [
        'Reduces chemical fertilizer costs by 20% to 30%',
        'Improves soil health and boosts yield by 10% to 15%',
        '100% free lab testing sponsored by Department of Agriculture',
      ],
    },
    eligibility: {
      ta: ['அனைத்து நில உரிமையாளர்கள் மற்றும் விவசாயிகள்'],
      te: ['భూమి ఉన్న రైతులందరూ'],
      hi: ['सभी किसान परिवार'],
      en: ['All cultivators across India'],
    },
    documentsRequired: {
      ta: ['ஆதார் அட்டை', 'வயல் மண் மாதிரி (Soil sample)', 'நில சர்வே எண் (Survey No)'],
      te: ['ఆధార్ కార్డు', 'మట్టి నమూనా', 'సర్వే నంబర్'],
      hi: ['आधार कार्ड', 'खेत की मिट्टी का नमूना', 'खसरा/सर्वे नंबर'],
      en: ['Aadhaar Card', 'Soil sample collected from farm', 'Survey number / Patta copy'],
    },
    howToApply: {
      ta: 'உங்கள் கிராம வேளாண்மை அலுவலரிடம் (AAO) மண் மாதிரியை ஒப்படைக்கலாம் அல்லது soilhealth.dac.gov.in போர்ட்டலில் ஆன்லைனில் முடிவுகளை பார்க்கலாம்.',
      te: 'గ్రామ వ్యవసాయ సహాయకునికి మట్టి నమూనా అందించండి లేదా soilhealth.dac.gov.in లో చూడండి.',
      hi: 'ग्राम कृषि समन्वयक अथवा नजदीकी कृषि विज्ञान केंद्र में मिट्टी का नमूना जमा करें।',
      en: 'Submit a soil sample to your Assistant Agricultural Officer (AAO) or track results at soilhealth.dac.gov.in.',
    },
    applyUrl: 'https://soilhealth.dac.gov.in',
    helpline: '1800-180-1551',
    state: 'All India',
    isActive: true,
  },
];
