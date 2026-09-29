import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/large_action_button.dart';
import '../../core/widgets/status_banner.dart';
import '../../core/widgets/page_voice_reader_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSearch, this.onBookings});

  final VoidCallback? onSearch;
  final VoidCallback? onBookings;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final userName = user?.name ?? 'விவசாயி';

    final isOwner = user?.role == 'owner';

    final tamilSpeechText = isOwner
        ? 'வணக்கம் $userName! உழவன் செயலிற்கு வரவேற்கிறோம். உங்கள் எந்திரங்களின் முன்பதிவுகளை பார்க்க "என் முன்பதிவு" பொத்தானை அழுத்தவும்.'
        : 'வணக்கம் $userName! உழவன் செயலிற்கு வரவேற்கிறோம். '
          'விவசாய எந்திரங்களை வாடகைக்கு எடுக்க "எந்திரம் தேடு" பொத்தானை அழுத்தவும். '
          'உங்கள் முன்பதிவுகளை பார்க்க "என் முன்பதிவு" பொத்தானை அழுத்தவும். '
          'அல்லது கீழே உள்ள பச்சை மைக் பொத்தானை அழுத்தி குரல் மூலம் பேசுங்கள்.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Bar with Tamil Voice Reader
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'வணக்கம், $userName 🙏',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'உழவன் குரல் போர்டல்',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PageVoiceReaderButton(
                  textToRead: tamilSpeechText,
                  label: '🔊 கேளுங்கள்',
                  languageCode: 'ta-IN',
                ),
              ],
            ),
            const SizedBox(height: 20),

            StatusBanner(
              type: StatusType.success,
              icon: Icons.agriculture_rounded,
              message: isOwner ? 'உங்கள் எந்திரங்கள் தயார் நிலையில் உள்ளன' : 'உங்கள் பகுதியில் டிராக்டர்கள் தயார் நிலையில் உள்ளன',
            ),
            const SizedBox(height: 28),

            if (!isOwner) ...[
              LargeActionButton(
                icon: Icons.search_rounded,
                label: 'எந்திரம் தேடு / Find Machine',
                onTap: onSearch ?? () {},
              ),
              const SizedBox(height: 16),
            ],
            LargeActionButton(
              icon: Icons.calendar_today_rounded,
              label: 'என் முன்பதிவு / My Bookings',
              color: AppColors.info,
              onTap: onBookings ?? () {},
            ),

            const Spacer(),

            // Tamil Voice Prompt Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'கீழே உள்ள பச்சை மைக் பொத்தானை அழுத்தி தமிழில் பேசலாம்!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
