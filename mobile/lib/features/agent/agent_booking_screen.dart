import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/models/agent_dialogue_state.dart';
import '../../core/models/machine_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/agent_dialogue_engine.dart';
import '../../core/services/booking_broadcaster.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';

class AgentBookingScreen extends StatefulWidget {
  const AgentBookingScreen({super.key, this.initialSpeech});

  final String? initialSpeech;

  @override
  State<AgentBookingScreen> createState() => _AgentBookingScreenState();
}

class _AgentBookingScreenState extends State<AgentBookingScreen>
    with TickerProviderStateMixin {
  late final AgentDialogueEngine _engine;
  late final TtsService _tts;
  late final stt.SpeechToText _speech;
  late final ScrollController _scrollCtrl;
  late final AnimationController _micPulse;
  late final AnimationController _dotAnim;
  TextEditingController _textCtrl = TextEditingController();

  bool _speechAvailable = false;
  bool _isListening = false;
  String _lang = 'ta';
  String _langCode = 'ta-IN';

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
    _speech = stt.SpeechToText();
    _scrollCtrl = ScrollController();
    _textCtrl = TextEditingController();
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _dotAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _engine = AgentDialogueEngine(lang: _lang);
    _engine.addListener(_onStateChange);
    _engine.startConversation();
    if (widget.initialSpeech != null && widget.initialSpeech!.trim().isNotEmpty) {
      _engine.processInput(widget.initialSpeech!.trim());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      final userLang = appState.user?.preferredLanguage ?? 'ta';
      if (userLang != _lang) {
        setState(() {
          _lang = userLang;
          _langCode = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[_lang] ?? 'ta-IN';
        });
      }
      _initSpeech();
      _speakLatestAgentMessage();
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  void _onStateChange() {
    // Auto-trigger machine search when step becomes searchingOwners
    if (_engine.state.currentStep == DialogueStep.searchingOwners &&
        !_engine.state.isSearching) {
      _searchOwners();
    }

    // Auto-trigger broadcast when step is done and broadcasting
    if (_engine.state.currentStep == DialogueStep.done &&
        _engine.state.isBroadcasting) {
      _broadcastRequest();
    }

    _speakLatestAgentMessage();
    _scrollToBottom();
    if (mounted) setState(() {});
  }

  Future<void> _searchOwners() async {
    _engine.setSearching(true);
    final appState = context.read<AppState>();
    final results = await appState.machineRepo.search(
      latitude: appState.latitude,
      longitude: appState.longitude,
      type: _engine.state.machineType,
      startDate: _engine.state.preferredDate,
      endDate: _engine.state.preferredDate?.add(const Duration(days: 1)),
    );
    _engine.setOwnerResults(results);
  }

  Future<void> _broadcastRequest() async {
    final s = _engine.state;
    final appState = context.read<AppState>();
    final user = appState.user;
    if (user == null || s.selectedOwner == null) {
      _engine.setBroadcastSent();
      return;
    }

    await BookingBroadcaster.instance.broadcastRequest(
      farmerId: user.id,
      farmerName: user.name,
      farmerPhone: user.phone,
      selectedOwner: s.selectedOwner!,
      areaAcres: s.areaAcres ?? 1,
      preferredDate: s.preferredDate ?? DateTime.now().add(const Duration(days: 1)),
      machineType: s.machineType ?? 'tractor',
      lang: _lang,
    );
    _engine.setBroadcastSent();
  }

  void _speakLatestAgentMessage() {
    final msgs = _engine.state.messages;
    if (msgs.isEmpty) return;
    final last = msgs.last;
    if (last.isAgent) {
      _tts.setLanguage(_langCode);
      _tts.speak(last.text);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onQuickReply(String reply) {
    _tts.stop();
    _engine.processInput(reply);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initSpeech();
    }
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1C2526),
            content: const Text(
              'மைக் சாதனம் கிடைக்கவில்லை. மாதிரி குரல் உள்ளீட்டைச் சோதிக்கலாம்.',
              style: TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'சோதிக்க / Test',
              textColor: const Color(0xFF81C784),
              onPressed: _showVoiceTestDialog,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    if (_isListening) return;
    _tts.stop();
    setState(() => _isListening = true);
    _engine.setListening(true);

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _langCode,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => _isListening = false);
          _engine.setListening(false);
          _engine.processInput(result.recognizedWords);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _engine.setListening(false);
  }

  void _submitTextInput(String text) {
    if (text.trim().isEmpty) return;
    _tts.stop();
    _engine.processInput(text.trim());
  }

  void _showVoiceTestDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final samples = [
          '🚜 டிராக்டர் வேண்டும் 3 ஏக்கருக்கு நாளை',
          '🌾 அறுவடை எந்திரம் 2 ஏக்கர்',
          '💧 தெளிப்பான் 1 ஏக்கர்',
          '👨‍🌾 முதல் நபர்',
          '👨‍🌾 இரண்டாவது',
          '✅ ஆம், அனுப்பு',
          '🚫 ரத்து செய்',
        ];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.record_voice_over_rounded, color: Color(0xFF81C784)),
                  SizedBox(width: 8),
                  Text(
                    'குரல் உருவகப்படுத்தல் / Voice Catch Test',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'பேசிய குரல் உள்ளீடாக சோதிக்க ஒரு வாக்கியத்தைத் தொடவும்:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: samples.map((s) {
                  return ActionChip(
                    backgroundColor: const Color(0xFF1C2526),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                    label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final clean = s.replaceFirst(RegExp(r'^[^\w\s\u0B80-\u0BFF]+'), '').trim();
                      _submitTextInput(clean);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _engine.removeListener(_onStateChange);
    _engine.dispose();
    _micPulse.dispose();
    _dotAnim.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = _engine.state;

    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1610),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'உழவன் உதவியாளர்',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'AI Booking Agent • On-Device',
                  style: TextStyle(color: AppColors.mintAccent.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over_rounded, color: AppColors.mintAccent),
            tooltip: 'குரல் சோதனை / Voice Catch Test',
            onPressed: _showVoiceTestDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Restart',
            onPressed: () {
              _tts.stop();
              _engine.reset();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(state.currentStep),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: state.messages.length + (state.isSearching ? 1 : 0),
              itemBuilder: (context, index) {
                if (state.isSearching && index == state.messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = state.messages[index];
                return _buildMessage(msg, state);
              },
            ),
          ),

          // Owner map / list (shown when owners available)
          if (state.currentStep == DialogueStep.showOwners &&
              state.availableOwners.isNotEmpty)
            _buildOwnerList(state.availableOwners),

          // Input bar
          _buildInputBar(state),
        ],
      ),
    );
  }

  Widget _buildProgressBar(DialogueStep step) {
    const steps = DialogueStep.values;
    final progress = (steps.indexOf(step) + 1) / (steps.length);
    return Container(
      height: 3,
      decoration: const BoxDecoration(color: Color(0xFF0F1E14)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF34D399)]),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(AgentMessage msg, AgentDialogueState state) {
    final isAgent = msg.isAgent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isAgent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAgent) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: isAgent
                        ? const Color(0xFF132417)
                        : null,
                    gradient: !isAgent
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                          )
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isAgent ? 4 : 20),
                      bottomRight: Radius.circular(isAgent ? 20 : 4),
                    ),
                    border: isAgent
                        ? Border.all(color: const Color(0x354ADE80))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isAgent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      if (isAgent && msg.aiBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            msg.aiBadge!,
                            style: const TextStyle(
                              color: AppColors.mintAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        msg.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isAgent) const SizedBox(width: 8),
            ],
          ),
          // Quick reply buttons
          if (isAgent && msg.quickReplies.isNotEmpty &&
              state.messages.last == msg)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.quickReplies.map((reply) => _QuickReplyChip(
                  label: reply,
                  onTap: () => _onQuickReply(reply),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF15803D)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF132417),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0x354ADE80)),
            ),
            child: AnimatedBuilder(
              animation: _dotAnim,
              builder: (_, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset = ((_dotAnim.value * 3) - i).clamp(0.0, 1.0);
                    final opacity = (offset < 0.5 ? offset * 2 : (1 - offset) * 2).clamp(0.3, 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(74, 222, 128, opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerList(List<MachineModel> owners) {
    return Container(
      height: 142,
      decoration: const BoxDecoration(
        color: Color(0xFF0C1710),
        border: Border(top: BorderSide(color: Color(0x2E4ADE80))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: owners.length,
        itemBuilder: (_, i) => _OwnerCard(
          owner: owners[i],
          index: i + 1,
          onTap: () => _engine.ownerSelectedFromCard(owners[i]),
        ),
      ),
    );
  }

  Widget _buildInputBar(AgentDialogueState state) {
    if (state.currentStep == DialogueStep.done) {
      return _buildDoneBar();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1610),
        border: Border(top: BorderSide(color: Color(0x2E4ADE80))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF132417),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    cursorColor: const Color(0xFF4ADE80),
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      hintText: _lang == 'ta'
                          ? 'தட்டச்சு செய்யுங்கள்...'
                          : _lang == 'te'
                              ? 'టైప్ చేయండి...'
                              : _lang == 'hi'
                                  ? 'टाइप करें...'
                                  : 'Type your response...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: (v) {
                      _submitTextInput(v);
                      _textCtrl.clear();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: () {
                _submitTextInput(_textCtrl.text);
                _textCtrl.clear();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Mic button
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedBuilder(
                animation: _micPulse,
                builder: (_, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                            : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.5 * _micPulse.value),
                                blurRadius: 16,
                                spreadRadius: 4,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneBar() {
    final appState = context.read<AppState>();
    final lang = appState.user?.preferredLanguage ?? 'ta';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1610),
        border: Border(top: BorderSide(color: Color(0x2E4ADE80))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      lang == 'ta'
                          ? 'முன்பதிவு அனுப்பப்பட்டது!'
                          : 'Booking Request Sent!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // New booking button
            GestureDetector(
              onTap: () {
                _tts.stop();
                _engine.reset();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.mintAccent),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'ta' ? 'மீண்டும் முன்பதிவு செய்' : 'New Booking',
                      style: const TextStyle(
                        color: AppColors.mintAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Reply Chip ──────────────────────────────────────────────────────────

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF132A1C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x554ADE80)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF86EFAC),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Owner Card ────────────────────────────────────────────────────────────────

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.owner,
    required this.index,
    required this.onTap,
  });
  final MachineModel owner;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ownerName = owner.owner?.name ?? 'உரிமையாளர்';
    final shortName = ownerName.split('/').first.trim();
    final dist = owner.distanceKm;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF142418), Color(0xFF0E1A11)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x404ADE80)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.mintAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: AppColors.mintAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (dist != null)
              Row(
                children: [
                  const Icon(Icons.near_me_rounded, color: AppColors.mintAccent, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${dist.toStringAsFixed(1)} km',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.mintAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                owner.displayPrice,
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

