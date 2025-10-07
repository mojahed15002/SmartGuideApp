import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_notifier.dart';
import '../sign_in_panel.dart';

class SignUpPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const SignUpPage({super.key, required this.themeNotifier});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;

  // 🔢 قائمة الدول
  final List<Map<String, String>> countryCodes = [
    {'name': 'السعودية', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'الإمارات', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'مصر', 'code': '+20', 'flag': '🇪🇬'},
    {'name': 'الأردن', 'code': '+962', 'flag': '🇯🇴'},
    {'name': 'الكويت', 'code': '+965', 'flag': '🇰🇼'},
    {'name': 'قطر', 'code': '+974', 'flag': '🇶🇦'},
    {'name': 'عُمان', 'code': '+968', 'flag': '🇴🇲'},
    {'name': 'البحرين', 'code': '+973', 'flag': '🇧🇭'},
    {'name': 'لبنان', 'code': '+961', 'flag': '🇱🇧'},
    {'name': 'العراق', 'code': '+964', 'flag': '🇮🇶'},
    {'name': 'فلسطين', 'code': '+970', 'flag': '🇵🇸'},
    {'name': 'سوريا', 'code': '+963', 'flag': '🇸🇾'},
    {'name': 'اليمن', 'code': '+967', 'flag': '🇾🇪'},
    {'name': 'الجزائر', 'code': '+213', 'flag': '🇩🇿'},
    {'name': 'المغرب', 'code': '+212', 'flag': '🇲🇦'},
    {'name': 'تونس', 'code': '+216', 'flag': '🇹🇳'},
    {'name': 'ليبيا', 'code': '+218', 'flag': '🇱🇾'},
    {'name': 'السودان', 'code': '+249', 'flag': '🇸🇩'},
    {'name': 'موريتانيا', 'code': '+222', 'flag': '🇲🇷'},
    {'name': 'تركيا', 'code': '+90', 'flag': '🇹🇷'},
    {'name': 'الولايات المتحدة', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'كندا', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'المملكة المتحدة', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'فرنسا', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'ألمانيا', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'إسبانيا', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'إيطاليا', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'الهند', 'code': '+91', 'flag': '🇮🇳'},
  ];

  String selectedCode = '+970'; // الافتراضي فلسطين 🇵🇸

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final fullPhone = '$selectedCode${_phoneController.text.trim()}';

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': fullPhone,
        'birthDate': _birthDate?.toIso8601String(),
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الحساب بنجاح 🎉')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignInPanel(themeNotifier: widget.themeNotifier),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ أثناء إنشاء الحساب';
      if (e.code == 'email-already-in-use') msg = 'هذا البريد مستخدم بالفعل';
      if (e.code == 'weak-password') msg = 'كلمة المرور ضعيفة جداً';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'أنشئ حسابك الآن ✨',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'يرجى إدخال الاسم الكامل' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'يرجى إدخال بريد صحيح' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) =>
                          v != null && v.length < 6 ? 'كلمة المرور قصيرة جداً' : null,
                    ),
                    const SizedBox(height: 16),

                    // ✅ رقم الهاتف مع اختيار الدولة
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCode,
                            decoration: const InputDecoration(
                              labelText: 'الدولة',
                              border: OutlineInputBorder(),
                            ),
                            items: countryCodes.map((country) {
                              return DropdownMenuItem<String>(
                                value: country['code'],
                                child: Text('${country['flag']} ${country['name']} (${country['code']})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCode = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              border: OutlineInputBorder(),
                              hintText: '5XXXXXXXX',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال رقم الهاتف';
                              }
                              if (!RegExp(r'^[0-9]{6,}$').hasMatch(value)) {
                                return 'الرجاء إدخال رقم صالح';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _birthDate == null
                                ? 'تاريخ الميلاد: لم يتم التحديد'
                                : 'تاريخ الميلاد: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(now.year - 18),
                              firstDate: DateTime(1900),
                              lastDate: now,
                              locale: const Locale('en', 'US'),
                              helpText: 'تحديد تاريخ الميلاد',
                            );
                            if (picked != null) setState(() => _birthDate = picked);
                          },
                          child: const Text('اختيار'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _signUp,
                            icon: const Icon(Icons.person_add),
                            label: const Text('إنشاء حساب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SignInPanel(themeNotifier: widget.themeNotifier),
                          ),
                        );
                      },
                      child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
