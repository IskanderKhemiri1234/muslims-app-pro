
import 'package:flutter/material.dart';
import 'package:quran_madina_flutter/quran_madina_flutter.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  static const int _totalPages = 604;

  int _currentPage = 1;

  Future<void> _goToPage() async {
    final controller = TextEditingController(
      text: _currentPage.toString(),
    );

    final selectedPage = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'الانتقال إلى صفحة',
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'أدخل رقم الصفحة من 1 إلى 604',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final page = int.tryParse(controller.text.trim());

                if (page == null || page < 1 || page > _totalPages) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('رقم الصفحة غير صحيح'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, page);
              },
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (selectedPage != null && mounted) {
      setState(() {
        _currentPage = selectedPage;
      });
    }
  }

  void _changePage(int value) {
    final newPage = (_currentPage + value)
        .clamp(1, _totalPages)
        .toInt();

    if (newPage == _currentPage) return;

    setState(() {
      _currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF111A16)
        : const Color(0xFFF1E9D5);

    final pageColor = isDark
        ? const Color(0xFF202A23)
        : const Color(0xFFFFFCF3);

    final textColor = isDark
        ? const Color(0xFFE8DFC9)
        : const Color(0xFF26382C);

    final accentColor = isDark
        ? const Color(0xFFD6B66D)
        : const Color(0xFF16734B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'المصحف الشريف',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'الانتقال إلى صفحة',
            onPressed: _goToPage,
            icon: const Icon(Icons.find_in_page_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مصحف المدينة المنورة',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'صفحة $_currentPage من $_totalPages',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: pageColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: QuranMadinaFlutter(
                      key: ValueKey(_currentPage),
                      page: _currentPage,
                      bundled: true,
                      headless: true,
                      fontSize: 22,
                      textColor: isDark ? '#E8DFC9' : '#26382C',
                      backgroundColor: isDark ? '#202A23' : '#FFFCF3',
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Slider(
                    value: _currentPage.toDouble(),
                    min: 1,
                    max: _totalPages.toDouble(),
                    divisions: _totalPages - 1,
                    activeColor: accentColor,
                    inactiveColor: accentColor.withValues(alpha: 0.2),
                    onChanged: (value) {
                      setState(() {
                        _currentPage = value.round();
                      });
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _currentPage > 1
                              ? () => _changePage(-1)
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('السابقة'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _currentPage < _totalPages
                              ? () => _changePage(1)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('التالية'),
                        ),
                      ),
                    ],
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
