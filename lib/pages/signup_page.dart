import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_notifier.dart';
import '../sign_in_panel.dart';
import '../l10n/gen/app_localizations.dart'; // ✅ الترجمة
import '../l10n/country_localizations_extension.dart';
import 'swipeable_page_route.dart';
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

  final List<Map<String, String>> countryCodes = [
  {'key': 'saudi', 'code': '+966', 'flag': '🇸🇦'},
  {'key': 'uae', 'code': '+971', 'flag': '🇦🇪'},
  {'key': 'egypt', 'code': '+20', 'flag': '🇪🇬'},
  {'key': 'jordan', 'code': '+962', 'flag': '🇯🇴'},
  {'key': 'kuwait', 'code': '+965', 'flag': '🇰🇼'},
  {'key': 'qatar', 'code': '+974', 'flag': '🇶🇦'},
  {'key': 'oman', 'code': '+968', 'flag': '🇴🇲'},
  {'key': 'bahrain', 'code': '+973', 'flag': '🇧🇭'},
  {'key': 'lebanon', 'code': '+961', 'flag': '🇱🇧'},
  {'key': 'iraq', 'code': '+964', 'flag': '🇮🇶'},
  {'key': 'palestine', 'code': '+970', 'flag': '🇵🇸'},
  {'key': 'syria', 'code': '+963', 'flag': '🇸🇾'},
  {'key': 'yemen', 'code': '+967', 'flag': '🇾🇪'},
  {'key': 'algeria', 'code': '+213', 'flag': '🇩🇿'},
  {'key': 'morocco', 'code': '+212', 'flag': '🇲🇦'},
  {'key': 'tunisia', 'code': '+216', 'flag': '🇹🇳'},
  {'key': 'libya', 'code': '+218', 'flag': '🇱🇾'},
  {'key': 'sudan', 'code': '+249', 'flag': '🇸🇩'},
  {'key': 'mauritania', 'code': '+222', 'flag': '🇲🇷'},
  {'key': 'turkey', 'code': '+90', 'flag': '🇹🇷'},
  {'key': 'usa', 'code': '+1', 'flag': '🇺🇸'},
  {'key': 'canada', 'code': '+1', 'flag': '🇨🇦'},
  {'key': 'uk', 'code': '+44', 'flag': '🇬🇧'},
  {'key': 'france', 'code': '+33', 'flag': '🇫🇷'},
  {'key': 'germany', 'code': '+49', 'flag': '🇩🇪'},
  {'key': 'spain', 'code': '+34', 'flag': '🇪🇸'},
  {'key': 'italy', 'code': '+39', 'flag': '🇮🇹'},
  {'key': 'india', 'code': '+91', 'flag': '🇮🇳'},
  ];

  String selectedCode = '+970';

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      final fullPhone = '$selectedCode${_phoneController.text.trim()}';

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': fullPhone,
        'birthDate': _birthDate?.toIso8601String(),
        'createdAt': DateTime.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.accountCreated)),
      );

      Navigator.pushReplacement(
        context,
        SwipeablePageRoute(
          page: SignInPanel(themeNotifier: widget.themeNotifier),
        ),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = AppLocalizations.of(context)!.signUpError;
      if (e.code == 'email-already-in-use') msg = AppLocalizations.of(context)!.emailInUse;
      if (e.code == 'weak-password') msg = AppLocalizations.of(context)!.weakPassword;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.createAccount),
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
                        AppLocalizations.of(context)!.createYourAccount,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.fullName,
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? AppLocalizations.of(context)!.enterFullName
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? AppLocalizations.of(context)!.enterValidEmail
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) => v != null && v.length < 6
                            ? AppLocalizations.of(context)!.shortPassword
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
  initialValue: selectedCode,
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.country,
    border: const OutlineInputBorder(),
  ),
  items: countryCodes.map((country) {
    final key = country['key']!;
    final countryName = AppLocalizations.of(context)!.getCountryName(key);
    return DropdownMenuItem<String>(
      value: country['code'],
      child: Text('${country['flag']} $countryName (${country['code']})'),
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
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.phoneNumber,
                                border: const OutlineInputBorder(),
                                hintText: '5XXXXXXXX',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.enterPhone;
                                }
                                if (!RegExp(r'^[0-9]{6,}$').hasMatch(value)) {
                                  return AppLocalizations.of(context)!.invalidPhone;
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
                                  ? AppLocalizations.of(context)!.birthNotSelected
                                  : '${AppLocalizations.of(context)!.birthDate}: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
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
                                helpText: AppLocalizations.of(context)!.selectBirthDate,
                              );
                              if (picked != null) setState(() => _birthDate = picked);
                            },
                            child: Text(AppLocalizations.of(context)!.choose),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _loading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _signUp,
                              icon: const Icon(Icons.person_add),
                              label: Text(AppLocalizations.of(context)!.createAccount),
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
                              builder: (_) => SignInPanel(
                                  themeNotifier: widget.themeNotifier),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.alreadyHaveAccount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
