"""
Uzhavan On-Device Neural NLP Model Training Script
Trains a custom lightweight Neural Network (MLP) for agricultural intent classification
supporting Tamil, Tanglish, Telugu, Hindi, and English.
Exports weights, biases, and vocabulary dictionary into mobile/assets/models/uzhavan_ai_model.json.
"""

import json
import os
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.neural_network import MLPClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score

# ── 1. Multilingual Agricultural Dataset ───────────────────────────────────────

DATASET = [
    # ── Intent: greeting ──
    ("வணக்கம்", "greeting"),
    ("வணக்கம் உழவன்", "greeting"),
    ("ஹலோ", "greeting"),
    ("hello", "greeting"),
    ("hi there", "greeting"),
    ("hey", "greeting"),
    ("good morning", "greeting"),
    ("நமஸ்காரம்", "greeting"),
    ("నమస్కారం", "greeting"),
    ("నమస్తే", "greeting"),
    ("नमस्ते", "greeting"),
    ("வணக்கம் ஐயா", "greeting"),
    ("வணக்கம் தம்பி", "greeting"),
    ("vanakkam", "greeting"),
    ("namaste", "greeting"),
    ("namaskaram", "greeting"),
    ("உதவி வேண்டும்", "greeting"),
    ("help me", "greeting"),
    ("agent please", "greeting"),

    # ── Intent: book_tractor ──
    ("டிராக்டர் வேண்டும்", "book_tractor"),
    ("டிராக்டர் வாடகைக்கு வேண்டும்", "book_tractor"),
    ("எனக்கு ஒரு டிராக்டர் தேவை", "book_tractor"),
    ("டிராக்டர் உழவுக்கு வேண்டும்", "book_tractor"),
    ("உழவு செய்ய டிராக்டர் வேண்டும்", "book_tractor"),
    ("tractor", "book_tractor"),
    ("i need a tractor", "book_tractor"),
    ("book a tractor", "book_tractor"),
    ("tractor for ploughing", "book_tractor"),
    ("want tractor for farm", "book_tractor"),
    ("tractor vennum", "book_tractor"),
    ("tractor theva", "book_tractor"),
    ("oru tractor venum", "book_tractor"),
    ("ulavu seiya tractor thevai", "book_tractor"),
    ("నాకు ట్రాక్టర్ కావాలి", "book_tractor"),
    ("ట్రాక్టర్ అద్దెకు కావాలి", "book_tractor"),
    ("నా పొలానికి ట్రాక్టర్ కావాలి", "book_tractor"),
    ("मुझे ट्रैक्टर चाहिए", "book_tractor"),
    ("खेत के लिए ट्रैक्टर बुक करो", "book_tractor"),
    ("ट्रैक्टर किराए पर चाहिए", "book_tractor"),
    ("டிராக்டர் வாடகைக்கு கொடுங்க", "book_tractor"),
    ("ஒரு டிராக்டர் புக் பண்ணுங்க", "book_tractor"),

    # ── Intent: book_harvester ──
    ("அறுவடை எந்திரம் வேண்டும்", "book_harvester"),
    ("நெல் அறுவடைக்கு மெஷின் வேண்டும்", "book_harvester"),
    ("ஹார்வெஸ்டர் வேண்டும்", "book_harvester"),
    ("அறுவடை செய்ய வேண்டும்", "book_harvester"),
    ("பயிர் அறுவடை எந்திரம்", "book_harvester"),
    ("harvester", "book_harvester"),
    ("i need a harvester", "book_harvester"),
    ("combine harvester needed", "book_harvester"),
    ("paddy harvester for rent", "book_harvester"),
    ("book harvest machine", "book_harvester"),
    ("harvester venum", "book_harvester"),
    ("nel aruvadai machine theva", "book_harvester"),
    ("aruvadai seiya machine", "book_harvester"),
    ("వరి కోత యంత్రం కావాలి", "book_harvester"),
    ("హార్వెస్టర్ అద్దెకు కావాలి", "book_harvester"),
    ("धान काटने वाली मशीन चाहिए", "book_harvester"),
    ("हार्वेस्टर चाहिए", "book_harvester"),
    ("फसल काटने की मशीन", "book_harvester"),

    # ── Intent: book_sprayer ──
    ("தெளிப்பான் வேண்டும்", "book_sprayer"),
    ("மருந்து தெளிக்க எந்திரம் வேண்டும்", "book_sprayer"),
    ("பூச்சிக்கொல்லி தெளிப்பான்", "book_sprayer"),
    ("ஸ்ப்ரேயர் மெஷின் வேண்டும்", "book_sprayer"),
    ("sprayer", "book_sprayer"),
    ("i need a pesticide sprayer", "book_sprayer"),
    ("sprayer machine for hire", "book_sprayer"),
    ("power sprayer needed", "book_sprayer"),
    ("spray machine", "book_sprayer"),
    ("sprayer venum", "book_sprayer"),
    ("marundhu thelikka machine", "book_sprayer"),
    ("మందు పిచికారీ యంత్రం కావాలి", "book_sprayer"),
    ("స్ప్రేయర్ కావాలి", "book_sprayer"),
    ("कीटनाशक छिड़कने की मशीन", "book_sprayer"),
    ("स्प्रेयर चाहिए", "book_sprayer"),

    # ── Intent: book_seeder ──
    ("விதைப்பான் வேண்டும்", "book_seeder"),
    ("விதை விதைக்க மெஷின் வேண்டும்", "book_seeder"),
    ("சீடர் எந்திரம்", "book_seeder"),
    ("seeder", "book_seeder"),
    ("seed drill machine", "book_seeder"),
    ("i need a seeder", "book_seeder"),
    ("sowing machine for rent", "book_seeder"),
    ("seeder venum", "book_seeder"),
    ("vidhai vidhaikka machine", "book_seeder"),
    ("విత్తనాలు నాటే యంత్రం కావాలి", "book_seeder"),
    ("సీడర్ కావాలి", "book_seeder"),
    ("बीज बोने की मशीन", "book_seeder"),
    ("सीडर चाहिए", "book_seeder"),

    # ── Intent: book_rotavator ──
    ("ரோட்டவேட்டர் வேண்டும்", "book_rotavator"),
    ("மண் கிளற ரோட்டவேட்டர்", "book_rotavator"),
    ("ரோட்டவேட்டர் வாடகைக்கு", "book_rotavator"),
    ("rotavator", "book_rotavator"),
    ("rotary tiller needed", "book_rotavator"),
    ("i need a rotavator", "book_rotavator"),
    ("rotovator machine for rent", "book_rotavator"),
    ("rotavator venum", "book_rotavator"),
    ("mann kilara rotavator", "book_rotavator"),
    ("రోటావేటర్ కావాలి", "book_rotavator"),
    ("భూమి దున్నడానికి రోటావేటర్", "book_rotavator"),
    ("रोटावेटर चाहिए", "book_rotavator"),
    ("मिट्टी तैयार करने वाला रोटावेटर", "book_rotavator"),

    # ── Intent: book_plough ──
    ("கலப்பை வேண்டும்", "book_plough"),
    ("ஏர் உழ கலப்பை", "book_plough"),
    ("டிஸ்க் கலப்பை வேண்டும்", "book_plough"),
    ("plough", "book_plough"),
    ("plow machine", "book_plough"),
    ("disc plough needed", "book_plough"),
    ("ploughing equipment", "book_plough"),
    ("kalappai venum", "book_plough"),
    ("er kalappai theva", "book_plough"),
    ("నాగలి కావాలి", "book_plough"),
    ("దుక్కి దున్నే నాగలి", "book_plough"),
    ("हल चाहिए", "book_plough"),
    ("जुताई के लिए हल", "book_plough"),

    # ── Intent: specify_area ──
    ("1 ஏக்கர்", "specify_area"),
    ("2 ஏக்கர் நிலம்", "specify_area"),
    ("3 ஏக்கர்", "specify_area"),
    ("4 ஏக்கர் வயல்", "specify_area"),
    ("5 ஏக்கர்", "specify_area"),
    ("10 ஏக்கர் நிலம் இருக்கு", "specify_area"),
    ("இரண்டு ஏக்கர்", "specify_area"),
    ("மூன்று ஏக்கர் நிலம்", "specify_area"),
    ("ஐந்து ஏக்கர் நிலப்பரப்பு", "specify_area"),
    ("1 acre", "specify_area"),
    ("2 acres", "specify_area"),
    ("3 acres of land", "specify_area"),
    ("5 acres area", "specify_area"),
    ("half acre", "specify_area"),
    ("2.5 acres", "specify_area"),
    ("rendu acre", "specify_area"),
    ("moonu acre", "specify_area"),
    ("anju acre nilam", "specify_area"),
    ("1 ఎకరం", "specify_area"),
    ("2 ఎకరాలు", "specify_area"),
    ("3 ఎకరాల పొలం", "specify_area"),
    ("5 ఎకరాలు", "specify_area"),
    ("1 एकड़", "specify_area"),
    ("2 एकड़ जमीन", "specify_area"),
    ("3 एकड़ खेत", "specify_area"),
    ("5 एकड़", "specify_area"),
    ("10 एकड़ जमीन है", "specify_area"),
    ("50 சென்ட்", "specify_area"),
    ("100 சென்ட்", "specify_area"),

    # ── Intent: specify_date ──
    ("இன்று", "specify_date"),
    ("இன்றே வேண்டும்", "specify_date"),
    ("நாளை", "specify_date"),
    ("நாளை காலை", "specify_date"),
    ("நாளைக்கு வேண்டும்", "specify_date"),
    ("2 நாட்களில்", "specify_date"),
    ("இந்த வாரம்", "specify_date"),
    ("அடுத்த வாரம்", "specify_date"),
    ("today", "specify_date"),
    ("tomorrow", "specify_date"),
    ("tomorrow morning", "specify_date"),
    ("day after tomorrow", "specify_date"),
    ("in 2 days", "specify_date"),
    ("this week", "specify_date"),
    ("next week", "specify_date"),
    ("innikku", "specify_date"),
    ("naalaikku", "specify_date"),
    ("rendu naal kazhichu", "specify_date"),
    ("ఈ రోజు", "specify_date"),
    ("రేపు", "specify_date"),
    ("ఎల్లుండి", "specify_date"),
    ("2 రోజుల్లో", "specify_date"),
    ("आज", "specify_date"),
    ("कल", "specify_date"),
    ("कल सुबह", "specify_date"),
    ("परसों", "specify_date"),
    ("दो दिन में", "specify_date"),

    # ── Intent: select_owner ──
    ("முதல்", "select_owner"),
    ("முதல் நபர்", "select_owner"),
    ("முதலாவது", "select_owner"),
    ("இரண்டாவது", "select_owner"),
    ("மூன்றாவது", "select_owner"),
    ("first one", "select_owner"),
    ("second one", "select_owner"),
    ("third", "select_owner"),
    ("number 1", "select_owner"),
    ("number 2", "select_owner"),
    ("number 3", "select_owner"),
    ("first owner", "select_owner"),
    ("muthal aal", "select_owner"),
    ("rendavathu aal", "select_owner"),
    ("మొదటి", "select_owner"),
    ("రెండవ", "select_owner"),
    ("మూడవ", "select_owner"),
    ("पहला", "select_owner"),
    ("दूसरा", "select_owner"),
    ("तीसरा", "select_owner"),
    ("1", "select_owner"),
    ("2", "select_owner"),
    ("3", "select_owner"),

    # ── Intent: confirm_booking ──
    ("ஆம்", "confirm_booking"),
    ("சரி", "confirm_booking"),
    ("உறுதி", "confirm_booking"),
    ("அனுப்பு", "confirm_booking"),
    ("புக் பண்ணுங்க", "confirm_booking"),
    ("சரி அனுப்புங்க", "confirm_booking"),
    ("yes", "confirm_booking"),
    ("confirm", "confirm_booking"),
    ("ok", "confirm_booking"),
    ("send request", "confirm_booking"),
    ("confirm booking", "confirm_booking"),
    ("proceed", "confirm_booking"),
    ("sari", "confirm_booking"),
    ("aam", "confirm_booking"),
    ("urudhi", "confirm_booking"),
    ("anuppunga", "confirm_booking"),
    ("అవును", "confirm_booking"),
    ("సరే", "confirm_booking"),
    ("ఖరారు చేయండి", "confirm_booking"),
    ("हाँ", "confirm_booking"),
    ("ठीक है", "confirm_booking"),
    ("कन्फर्म करो", "confirm_booking"),
    ("भेज दो", "confirm_booking"),

    # ── Intent: cancel_booking ──
    ("வேண்டாம்", "cancel_booking"),
    ("ரத்து செய்", "cancel_booking"),
    ("இல்லை", "cancel_booking"),
    ("நிறுத்து", "cancel_booking"),
    ("no", "cancel_booking"),
    ("cancel", "cancel_booking"),
    ("stop", "cancel_booking"),
    ("don't want", "cancel_booking"),
    ("abort", "cancel_booking"),
    ("vendaam", "cancel_booking"),
    ("rathu sei", "cancel_booking"),
    ("illa", "cancel_booking"),
    ("వద్దు", "cancel_booking"),
    ("రద్దు చేయండి", "cancel_booking"),
    ("లేదు", "cancel_booking"),
    ("नहीं", "cancel_booking"),
    ("रद्द करो", "cancel_booking"),
    ("मत करो", "cancel_booking"),

    # ── Intent: check_earnings ──
    ("வருமானம்", "check_earnings"),
    ("என் வருமானம் எவ்வளவு", "check_earnings"),
    ("வருமானம் பார்க்க வேண்டும்", "check_earnings"),
    ("earnings", "check_earnings"),
    ("check earnings", "check_earnings"),
    ("my income", "check_earnings"),
    ("how much earned", "check_earnings"),
    ("varumaanam", "check_earnings"),
    ("en varumaanam evvalavu", "check_earnings"),
    ("ఆదాయం", "check_earnings"),
    ("నా సంపాదన ఎంత", "check_earnings"),
    ("कमाई", "check_earnings"),
    ("मेरी कमाई कितनी है", "check_earnings"),

    # ── Intent: switch_role ──
    ("என் எந்திரங்கள்", "switch_role"),
    ("உரிமையாளர் பகுதி", "switch_role"),
    ("விவசாயி பகுதி", "switch_role"),
    ("வாடகைக்கு எடுக்க", "switch_role"),
    ("switch to owner", "switch_role"),
    ("switch to farmer", "switch_role"),
    ("owner mode", "switch_role"),
    ("farmer mode", "switch_role"),
    ("en enthirangal", "switch_role"),
    ("urimaiyalar", "switch_role"),
    ("vivasaayi", "switch_role"),
    ("యజమాని మోడ్", "switch_role"),
    ("రైతు మోడ్", "switch_role"),
    ("मालिक मोड", "switch_role"),
    ("किसान मोड", "switch_role"),
]

# ── 2. Data Augmentation ───────────────────────────────────────────────────────

# Multiply samples with subtle prefixes/suffixes to make the model robust
PREFIXES = ["", "தயவுசெய்து ", "எனக்கு ", "please ", "i want ", "can i get ", "கொஞ்சம் "]
SUFFIXES = ["", " வேண்டும்", " please", " venum", " theva", " కావాలి", " चाहिए"]

augmented_texts = []
augmented_labels = []

for text, label in DATASET:
    augmented_texts.append(text)
    augmented_labels.append(label)
    # Balanced augmentation for all classes
    if label.startswith("book_") or label.startswith("specify_"):
        for p in ["", "தயவுசெய்து ", "please "]:
            for s in ["", " வேண்டும்", " please"]:
                if p or s:
                    augmented_texts.append(f"{p}{text}{s}".strip())
                    augmented_labels.append(label)
    else:
        # Augment conversation control intents (confirm, cancel, greeting, owner, etc.)
        for rep in range(3):
            augmented_texts.append(text)
            augmented_labels.append(label)
            augmented_texts.append(f"please {text}".strip())
            augmented_labels.append(label)

print(f"Total training utterances after augmentation: {len(augmented_texts)}")

# ── 3. Vectorization with Word + Character N-Grams ─────────────────────────────

vectorizer = TfidfVectorizer(
    analyzer='word',
    ngram_range=(1, 2),
    min_df=1,
    sublinear_tf=True,
    max_features=1200,
)

X = vectorizer.fit_transform(augmented_texts).toarray()
y = np.array(augmented_labels)

classes = sorted(list(set(y)))
class_to_idx = {c: i for i, c in enumerate(classes)}
y_indices = np.array([class_to_idx[lbl] for lbl in y])

X_train, X_test, y_train, y_test = train_test_split(
    X, y_indices, test_size=0.15, random_state=42, stratify=y_indices
)

# ── 4. Train Multilayer Perceptron Neural Network ─────────────────────────────

print("Training On-Device Neural Network (MLPClassifier)...")
mlp = MLPClassifier(
    hidden_layer_sizes=(64,),
    activation='relu',
    solver='adam',
    learning_rate_init=0.008,
    max_iter=400,
    random_state=42,
)

mlp.fit(X_train, y_train)

train_acc = accuracy_score(y_train, mlp.predict(X_train))
test_acc = accuracy_score(y_test, mlp.predict(X_test))

print(f"Train Accuracy: {train_acc * 100:.2f}%")
print(f"Test Accuracy:  {test_acc * 100:.2f}%")

# Classification report
print("\nClassification Report:")
print(classification_report(y_test, mlp.predict(X_test), target_names=classes, zero_division=0))

# ── 5. Export Neural Network Weights & Vocabulary for On-Device Inference ─────

# Layer 1: Input -> Hidden
W1 = [[float(v) for v in row] for row in mlp.coefs_[0]]
b1 = [float(v) for v in mlp.intercepts_[0]]

# Layer 2: Hidden -> Output
W2 = [[float(v) for v in row] for row in mlp.coefs_[1]]
b2 = [float(v) for v in mlp.intercepts_[1]]

# Vocabulary mapping and idf weights (convert numpy int64 -> int)
vocabulary = {str(k): int(v) for k, v in vectorizer.vocabulary_.items()}
idf_list = [float(v) for v in vectorizer.idf_]

model_artifact = {
    "version": "1.0.0",
    "model_name": "UzhavanAgriOnDeviceNeuralNlp",
    "architecture": "MLP(in->64->out)",
    "n_features": len(vectorizer.get_feature_names_out()),
    "n_hidden": 64,
    "n_classes": len(classes),
    "classes": classes,
    "vocabulary": vocabulary,
    "idf": idf_list,
    "weights_layer_1": W1,
    "bias_layer_1": b1,
    "weights_layer_2": W2,
    "bias_layer_2": b2,
    "train_accuracy": round(float(train_acc), 4),
    "test_accuracy": round(float(test_acc), 4),
}

output_path = os.path.join("mobile", "assets", "models", "uzhavan_ai_model.json")
os.makedirs(os.path.dirname(output_path), exist_ok=True)

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(model_artifact, f, ensure_ascii=False)

file_size_kb = os.path.getsize(output_path) / 1024
print(f"\nModel exported successfully to: {output_path}")
print(f"Model file size: {file_size_kb:.1f} KB (Ultra-lightweight for offline mobile)")
