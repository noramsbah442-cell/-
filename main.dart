import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. إعدادات Supabase ورابط المشروع
// ==========================================
// 👈 ضع رابط مشروعك هنا (تلقاه في Settings > API في موقع Supabase)
const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String supabaseKey = 'sb_publishable_cyUJ5nsnt7Sscm868t4Y8w_4d2N2uhu';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل الاتصال مع Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const TaleemunaApp());
}

// كائن الاتصال
final supabase = Supabase.instance.client;

class TaleemunaApp extends StatelessWidget {
  const TaleemunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تعليمنا',
      theme: ThemeData(
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF1E3A8A),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl, // توجيه كامل التطبيق باللغة العربية
        child: MainAuthScreen(),
      ),
    );
  }
}

class MainAuthScreen extends StatefulWidget {
  const MainAuthScreen({super.key});

  @override
  State<MainAuthScreen> createState() => _MainAuthScreenState();
}

class _MainAuthScreenState extends State<MainAuthScreen> {
  // 0: تلميذ | 1: أستاذ
  int _selectedRole = 0;

  final _formKey = GlobalKey<FormState>();

  // الحقول النصية
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // بيانات التلميذ
  String? _selectedWilaya;
  String _studyMode = 'عن بعد'; // 'عن بعد' أو 'حضوري'
  bool _isLoading = false;

  // قائمة الولايات الجزائرية
  final List<String> _wilayas = [
    '01 - أدرار', '02 - الشلف', '03 - الأغواط', '04 - أم البواقي', '05 - باتنة',
    '06 - بجاية', '07 - بسكرة', '08 - بشار', '09 - البليدة', '10 - البويرة',
    '15 - تيزي وزو', '16 - الجزائر العاصمة', '19 - سطيف', '25 - قسنطينة',
    '31 - وهران', '35 - بومرداس', '39 - الوادي', '47 - غرداية'
  ];

  // دالة إرسال بيانات التلميذ إلى Supabase
  Future<void> _submitStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWilaya == null) {
      _showMessage('خِيّار ولايتك يعيّشك باش يسهل ربطك بالأستاذ!', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // الحفظ الفعلي في جدول students
      await supabase.from('students').insert({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'wilaya': _selectedWilaya,
        'study_mode': _studyMode,
      });

      if (!mounted) return;

      _showMessage('صَحِيت يا البطل! تم تسجيلك بنجاح في عائلة تعليمنا 🎉', Colors.green);

      // تفريغ الحقول بعد النجاح
      _formKey.currentState!.reset();
      _fullNameController.clear();
      _phoneController.clear();
      _emailController.clear();
      setState(() {
        _selectedWilaya = null;
        _studyMode = 'عن بعد';
      });

    } on PostgrestException catch (e) {
      _showMessage('خطأ في قاعدة البيانات: ${e.message}', Colors.red);
    } catch (e) {
      _showMessage('كاين مشكل فالإنترنت، عاود جرب!', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // 1. الشعار واسم التطبيق
              _buildTopHeader(),

              const SizedBox(height: 24),

              // 2. محدد التبديل: تلميذ أو أستاذ
              _buildRoleSwitcher(),

              const SizedBox(height: 24),

              // 3. المحتوى حسب الدور المختار
              if (_selectedRole == 0) ...[
                // واجهة التلميذ (مع الترحيب بالدارجة)
                _buildAlgerianStudentWelcomeCard(),
                _buildStudentForm(),
              ] else ...[
                // واجهة الأستاذ
                _buildTeacherSection(),
              ],

              const SizedBox(height: 24),

              // 4. الدخول بالبصمة
              _buildBiometricLogin(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // الهيدر والشعار
  Widget _buildTopHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          'تَعْلِيمُنَا',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const Text(
          'جسر المعرفة بين الأستاذ والتلميذ',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // التبديل بين تلميذ وأستاذ
  Widget _buildRoleSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleButton(
              title: 'أنا تلميذ 🎒',
              isSelected: _selectedRole == 0,
              onTap: () => setState(() => _selectedRole = 0),
            ),
          ),
          Expanded(
            child: _buildRoleButton(
              title: 'أنا أستاذ 👨‍🏫',
              isSelected: _selectedRole == 1,
              onTap: () => setState(() => _selectedRole = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // البطاقة الترحيبية بالدارجة الجزائرية
  Widget _buildAlgerianStudentWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇩🇿', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'طريقك للنجاح يبدا من هنا 🚀',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'مَرْحْبَا بِيكْ يَا الشَّاطِرْ فـَ تعليمنا! 🎒',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'ما تكسّرش راسك مع الدروس الصعيبة.. عمّر معلوماتك، خيّر أستاذك الزين، وقرايتك تولي ساهلة ماهلة إن شاء الله! 💪✨',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.92), height: 1.5),
          ),
        ],
      ),
    );
  }

  // نموذج إدخال بيانات التلميذ
  Widget _buildStudentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'كيفاش راك باغي تقرا؟',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),

          // اختيار نمط الدراسة (حضوري أو عن بعد)
          Row(
            children: [
              Expanded(child: _buildStudyModeOption('عن بعد', 'أونلاين مـ الدار 💻', Icons.laptop_chromebook)),
              const SizedBox(width: 12),
              Expanded(child: _buildStudyModeOption('حضوري', 'حضورياً فالقسم 🏫', Icons.apartment_rounded)),
            ],
          ),
          const SizedBox(height: 18),

          // الاسم الكامل
          _buildTextField(
            controller: _fullNameController,
            label: 'الاسم واللقب',
            hint: 'مثلاً: محمد الأمين بن علي',
            icon: Icons.person_outline_rounded,
            validator: (v) => v == null || v.isEmpty ? 'اكتب اسمك الكامل يعيّشك' : null,
          ),
          const SizedBox(height: 14),

          // الهاتف
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            hint: '06 / 07 / 05 ...',
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.length < 9 ? 'أدخل رقم هاتف صحيح' : null,
          ),
          const SizedBox(height: 14),

          // البريد الإلكتروني
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'exemple@gmail.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريد إلكتروني صالح' : null,
          ),
          const SizedBox(height: 14),

          // اختيار الولاية
          DropdownButtonFormField<String>(
            value: _selectedWilaya,
            decoration: InputDecoration(
              labelText: 'خِيّار ولايتك',
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF64748B)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            items: _wilayas.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (val) => setState(() => _selectedWilaya = val),
          ),
          const SizedBox(height: 24),

          // زر التسجيل النهائي
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'سجّلني ورانا واجدين! 🚀',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // كرت اختيار نمط الدراسة
  Widget _buildStudyModeOption(String value, String label, IconData icon) {
    final isSelected = _studyMode == value;
    return GestureDetector(
      onTap: () => setState(() => _studyMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // حقل إدخال موحد
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
        ),
      ),
    );
  }

  // واجهة مؤقتة للأستاذ
  Widget _buildTeacherSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.co_present_rounded, size: 54, color: Color(0xFF1E3A8A)),
          const SizedBox(height: 12),
          const Text(
            'فضاء الأساتذة والمعلمين 👨‍🏫',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'مرحباً بك أستاذنا الفاضل.. يمكنك تسجيل الدخول إلى حسابك ومتابعة حصصك وطلابك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('دخول الأساتذة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // الدخول بالبصمة
  Widget _buildBiometricLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('أو الدخول السريع', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 14),
        IconButton(
          onPressed: () => _showMessage('جاري فحص البصمة... 🔒', Colors.blueGrey),
          iconSize: 42,
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF1E3A8A)),
          ),
        ),
      ],
    );
  }
}
