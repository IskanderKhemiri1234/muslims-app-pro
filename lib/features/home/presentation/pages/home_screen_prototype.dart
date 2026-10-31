
import 'package:flutter/material.dart';

class HomeScreenPrototype extends StatelessWidget {
  const HomeScreenPrototype({super.key});

  static const Color background = Color(0xFF080F0D);
  static const Color surface = Color(0xFF14221C);
  static const Color emerald = Color(0xFF3C9B72);
  static const Color gold = Color(0xFFD8B66A);
  static const Color primaryText = Color(0xFFF4F1E8);
  static const Color secondaryText = Color(0xFFA9B8B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildGreeting(),
              const SizedBox(height: 22),
              _buildPrayerCard(),
              const SizedBox(height: 30),
              _buildSectionTitle('مساحتك اليومية', 'كل ما تحتاجه'),
              const SizedBox(height: 15),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _buildSectionTitle('رحلتك مع القرآن', 'متابعة القراءة'),
              const SizedBox(height: 15),
              _buildQuranCard(),
              const SizedBox(height: 28),
              _buildDailyReminder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.mosque_outlined,
            color: gold,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MUSLIMS',
              style: TextStyle(
                color: primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            Text(
              'رفيق يومك',
              style: TextStyle(
                color: secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: primaryText,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.settings_outlined,
            color: primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'السلام عليكم',
          style: TextStyle(
            color: primaryText,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'اجعل يومك عامرًا بالذكر والطمأنينة.',
          style: TextStyle(
            color: secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1C3B2D),
            Color(0xFF102019),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: emerald.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.nights_stay_outlined,
                color: gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'الصلاة القادمة',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: emerald.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'المواقيت',
                  style: TextStyle(
                    color: Color(0xFF91D2B0),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'الفجر',
            style: TextStyle(
              color: primaryText,
              fontSize: 31,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '--:--',
            style: TextStyle(
              color: gold,
              fontSize: 38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                color: gold,
                size: 17,
              ),
              SizedBox(width: 8),
              Text(
                'سيظهر العد التنازلي عند ربط مواقيت الصلاة',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.menu_book_rounded, 'القرآن'),
      (Icons.explore_outlined, 'القبلة'),
      (Icons.favorite_border_rounded, 'الأذكار'),
      (Icons.calendar_month_outlined, 'الصلوات'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];

        return Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(
                action.$1,
                color: index == 0 ? gold : emerald,
                size: 25,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              action.$2,
              style: const TextStyle(
                color: primaryText,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuranCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 65,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: gold,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'واصل رحلتك مع القرآن',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'احفظ موضع قراءتك وتابع ختمتك',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: gold,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReminder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF17241E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold.withValues(alpha: 0.12),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: gold,
                size: 18,
              ),
              SizedBox(width: 9),
              Text(
                'تذكير اليوم',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Text(
            'ألا بذكر الله تطمئن القلوب',
            style: TextStyle(
              color: primaryText,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'الرعد · 28',
            style: TextStyle(
              color: secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
