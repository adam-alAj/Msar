import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_icons.dart';

// ─── HELP DATA ────────────────────────────────────────────────────────────────

class _HelpEntry {
  final String question;
  final String answer;
  const _HelpEntry(this.question, this.answer);
}

class _HelpGroup {
  final String title;
  final IconData icon;
  final List<_HelpEntry> entries;
  const _HelpGroup(this.title, this.icon, this.entries);
}

final _helpData = [
  _HelpGroup('الخريطة والقائمة', AppIcons.map, [
    _HelpEntry('كيف أشاهد حالة الحواجز؟', 'افتح التطبيق وستظهر لك الخريطة مباشرة. كل دبوس يمثل حاجزاً: الأخضر سالك، البرتقالي أزمة، والأحمر مغلق. اضغط على أي دبوس لمعرفة التفاصيل.'),
    _HelpEntry('ما الفرق بين الخريطة والقائمة؟', 'الخريطة تعرض الحواجز على خريطة تفاعلية حسب موقعها الجغرافي. القائمة تعرضها ككروت مرتبة حسب القرب منك مع نسب الحالة لكل اتجاه.'),
    _HelpEntry('كيف أبحث عن حاجز معين؟', 'استخدم شريط البحث في أعلى الشاشة. اكتب اسم الحاجز وستظهر اقتراحات فورية. في الخريطة: اختر اقتراحاً وستنتقل الخريطة إليه. في القائمة: تُفلتر الكروت تلقائياً.'),
    _HelpEntry('ماذا تعني الألوان على الخريطة؟', 'أخضر (سالك): الحاجز مفتوح والمرور طبيعي. برتقالي (أزمة): ازدحام أو تأخير. أحمر (مغلق): الحاجز مغلق ولا يمكن العبور.'),
  ]),
  _HelpGroup('التصويت', AppIcons.vote, [
    _HelpEntry('كيف أصوّت على حالة حاجز؟', 'افتح تفاصيل الحاجز ثم اضغط "تصويت". اختر الاتجاه (داخل أو خارج) والحالة (سالك / أزمة / مغلق) ثم اضغط إرسال.'),
    _HelpEntry('هل يجب أن أكون قرب الحاجز للتصويت؟', 'لا، يمكنك التصويت من أي مكان. هذا يتيح لك الإبلاغ بناءً على معلومات من أصدقاء أو مصادر أخرى.'),
    _HelpEntry('كيف تُحسب الحالة النهائية؟', 'تُجمع أصوات آخر ٦٠ دقيقة. الحالة التي تحصل على أعلى نسبة تصويت تصبح الحالة المعروضة. كلما زاد عدد المصوتين، زادت دقة المعلومة.'),
    _HelpEntry('هل تصويتي مجهول؟', 'نعم، لا يظهر اسمك أو معلوماتك الشخصية لأي مستخدم آخر. فقط نتيجة التصويت تظهر بشكل إجمالي.'),
  ]),
  _HelpGroup('التعليقات', AppIcons.comment, [
    _HelpEntry('ما فائدة التعليق عند التصويت؟', 'التعليق يعطي تفاصيل إضافية للمسافرين مثل "تفتيش دقيق" أو "ازدحام بسبب حادث". يظهر في قسم آراء المسافرين على صفحة تفاصيل الحاجز.'),
    _HelpEntry('هل التعليقات مجهولة؟', 'نعم، التعليقات مجهولة تماماً. لا يظهر اسم الكاتب أو أي معلومة تعريفية.'),
    _HelpEntry('لماذا لا أرى تعليقي؟', 'تظهر فقط تعليقات الساعة الأخيرة في قسم آراء المسافرين. التعليقات الأقدم تظهر عند الضغط على "عرض الكل".'),
  ]),
  _HelpGroup('الحساب والإعدادات', AppIcons.settings, [
    _HelpEntry('كيف أغيّر المظهر (فاتح / داكن)؟', 'اذهب إلى الإعدادات واختر المظهر المناسب: شمس (تلقائي حسب الشروق والغروب)، نظام، فاتح، أو داكن.'),
    _HelpEntry('كيف أختار منطقة معينة؟', 'اضغط على أيقونة الموقع في أعلى الشاشة لفتح قائمة المناطق. اختر المنطقة المطلوبة وستُعرض حواجزها فقط.'),
    _HelpEntry('كيف أسجل الخروج؟', 'اضغط على أيقونة الخروج في أعلى يسار الشاشة الرئيسية.'),
  ]),
  _HelpGroup('استكشاف الأخطاء', AppIcons.error, [
    _HelpEntry('الخريطة لا تظهر أي حواجز', 'تأكد من اتصالك بالإنترنت. اسحب الشاشة للأسفل لتحديث البيانات. إذا اخترت منطقة معينة، جرب إزالة الفلتر.'),
    _HelpEntry('التطبيق يقول "محدث منذ وقت طويل"', 'اضغط على مؤشر التحديث أو أيقونة التحديث لجلب أحدث البيانات من الخادم.'),
    _HelpEntry('لا أستطيع تسجيل الدخول', 'تأكد من اتصالك بالإنترنت. جرب تسجيل الدخول بحساب Google أو برقم الهاتف. إذا استمرت المشكلة، أعد تشغيل التطبيق.'),
  ]),
];

// ─── HELP SCREEN ──────────────────────────────────────────────────────────────

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('مساعدة'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
        itemCount: _helpData.length + 1,
        itemBuilder: (context, index) {
          if (index == _helpData.length) return _buildContactSection(colorScheme);
          return _buildGroup(_helpData[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildGroup(_HelpGroup group, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(children: [
          Icon(group.icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(group.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.primary)),
        ]),
        const SizedBox(height: 8),
        ...group.entries.map((e) => _HelpAccordionItem(entry: e)),
      ],
    );
  }

  Widget _buildContactSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Icon(AppIcons.send, size: 28, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text('تواصل معنا', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text(
          'لم تجد إجابة؟ اضغط على أي بريد إلكتروني للتواصل معنا',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _EmailTile(email: 'adam1alafandi1@gmail.com', name: 'Adam'),
        const SizedBox(height: 6),
        _EmailTile(email: 'mohammadayyad004@gmail.com', name: 'Mohammad'),
        const SizedBox(height: 6),
        _EmailTile(email: '202303862@bethlehem.edu', name: 'Baha'),
      ]),
    );
  }
}

// ─── ACCORDION ITEM ───────────────────────────────────────────────────────────

class _HelpAccordionItem extends StatefulWidget {
  final _HelpEntry entry;
  const _HelpAccordionItem({required this.entry});

  @override
  State<_HelpAccordionItem> createState() => _HelpAccordionItemState();
}

class _HelpAccordionItemState extends State<_HelpAccordionItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(widget.entry.question, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface))),
              Icon(_expanded ? AppIcons.caretUp : AppIcons.caretDown, size: 12, color: colorScheme.onSurfaceVariant),
            ]),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(widget.entry.answer, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.6)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}


class _EmailTile extends StatelessWidget {
  static const _subject = 'استفسار من تطبيق مسار';
  static const _body = 'السلام عليكم،\n\nأكتب إليكم بخصوص تطبيق مسار...\n\n';

  final String email;
  final String name;

  const _EmailTile({required this.email, required this.name});

  Future<void> _launch(BuildContext context) async {
    final encodedSubject = Uri.encodeComponent(_subject);
    final encodedBody = Uri.encodeComponent(_body);

    // 1. Try Gmail app directly
    final gmailUri = Uri.parse('googlegmail:///co?to=$email&subject=$encodedSubject&body=$encodedBody');
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      return;
    }

    // 2. Fallback: mailto (opens default mail client)
    final mailtoUri = Uri.parse('mailto:$email?subject=$encodedSubject&body=$encodedBody');
    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // 3. Fallback: copy to clipboard + SnackBar
    if (!context.mounted) return;
    await Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('لا يوجد تطبيق بريد مثبت — تم نسخ البريد الإلكتروني: $email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _launch(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(AppIcons.send, size: 14, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(email, style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600))),
          Text(name, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
