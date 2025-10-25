import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme_notifier.dart';
import '../l10n/gen/app_localizations.dart';
import 'custom_drawer.dart';
// صفحات مساعدة اختيارية (بدّل المسارات إذا لزم)
import 'forgot_password_page.dart'; // لتغيير/استعادة كلمة المرور
import '../sign_in_panel.dart';        // للعودة بعد تسجيل الخروج

class ProfilePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const ProfilePage({super.key, required this.themeNotifier});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;

  User? user;
  Map<String, dynamic>? userData;

  // إحصائيات
  int favoritesCount = 0;
  int travelCount = 0;
  String? lastDestination;
  double totalDistanceM = 0;   // مجموع المسافات بالمتر (اختياري)
  double totalDurationS = 0;   // مجموع الزمن بالثواني (اختياري)

  // الموقع الحالي/المدينة
  String? currentCity;
  bool _isLoading = true;

  // مستويات gamification
  String get _level {
    if (travelCount >= 25) return 'خبير';
    if (travelCount >= 10) return 'مستكشف';
    return 'مبتدئ';
  }

  double get _progressToNext {
    // تقدم نحو المستوى التالي (مقياس بسيط مبني على عدد الرحلات)
    final nextTarget = travelCount >= 25 ? 25 : (travelCount >= 10 ? 25 : 10);
    final currentBase = travelCount >= 25 ? 25 : (travelCount >= 10 ? 10 : 0);
    final span = nextTarget - currentBase;
    if (span == 0) return 1.0;
    final p = (travelCount - currentBase) / span;
    return p.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([
        _loadUserAndStats(),
        _loadCurrentCity(),
      ]);
    } catch (e) {
      debugPrint('⚠️ Profile load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserAndStats() async {
    if (user == null) return;

    // users/<uid>
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      userData = userDoc.data();
      favoritesCount = (userData?['favorites'] as List?)?.length ?? 0;
    }

    // travel_logs: نجمع الإحصائيات
    final logsSnap = await FirebaseFirestore.instance
        .collection('travel_logs')
        .where('user_id', isEqualTo: user!.uid)
        .orderBy('time')
        .get();

    travelCount = logsSnap.docs.length;

    if (travelCount > 0) {
      final last = logsSnap.docs.last.data();
      lastDestination = last['place_name'] ?? '—';
    }

    // مجموع المسافة/الوقت إن وُجدت الحقول (distance_m, duration_s)
    double td = 0;
    double tt = 0;
    for (final d in logsSnap.docs) {
      final m = d.data();
      if (m['distance_m'] != null) {
        final v = (m['distance_m'] as num?)?.toDouble() ?? 0;
        td += v;
      }
      if (m['duration_s'] != null) {
        final v = (m['duration_s'] as num?)?.toDouble() ?? 0;
        tt += v;
      }
    }
    totalDistanceM = td;
    totalDurationS = tt;
  }

  Future<void> _loadCurrentCity() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        currentCity = '—';
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        currentCity = pm.locality?.isNotEmpty == true
            ? pm.locality
            : (pm.administrativeArea ?? '—');
      } else {
        currentCity = '—';
      }
    } catch (e) {
      debugPrint('⚠️ City load error: $e');
      currentCity = '—';
    }
  }

  String _formatDistance(double meters) {
    if (meters <= 0) return '—';
    if (meters >= 1000) {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(2)} كم';
    }
    return '${meters.toStringAsFixed(0)} م';
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '—';
    final s = seconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    if (h > 0) return '$h س $m د';
    if (m > 0) return '$m د $ss ث';
    return '$ss ث';
    }

  Future<void> _toggleTheme() async {
    widget.themeNotifier.toggleTheme();
    // حفظ في Firestore (اختياري)
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    setState(() {});
  }

  Future<void> _changeLanguage(String lang) async {
    widget.themeNotifier.setLanguage(lang);
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'language': lang,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    setState(() {});
  }

  Future<void> _sendFeedback() async {
    // هنا يا إما تفتح فورم داخل التطبيق، أو تستخدم mailto.
    // مبدئيًا نعرض Dialog بسيط:
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.feedback),
        content: Text(loc.feedbackThanks),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'جرب تطبيق المرشد السياحي الذكي! 🌆🗺️',
        subject: 'Smart City Guide',
      );
    } catch (e) {
      debugPrint('share error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر المشاركة الآن')),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SignInPanel(themeNotifier: widget.themeNotifier),
      ),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;
    try {
      await user!.delete();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SignInPanel(themeNotifier: widget.themeNotifier),
        ),
        (r) => false,
      );
    } catch (e) {
      // في العادة يحتاج Re-auth
      debugPrint('delete error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إعادة تسجيل الدخول لحذف الحساب.'),
        ),
      );
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12, bottom: 6),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _cardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.12),
          child: Icon(icon, color: Colors.orange),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = loc.localeName == 'ar';
    final isDark = widget.themeNotifier.isDarkMode;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.profile),
          backgroundColor: Colors.orange,
        ),
        drawer: CustomDrawer(themeNotifier: widget.themeNotifier),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ————— معلومات أساسية
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundImage: (userData?['photoUrl'] != null &&
                                    (userData!['photoUrl'] as String).isNotEmpty)
                                ? NetworkImage(userData!['photoUrl'])
                                : const AssetImage(
                                    'assets/images/default_user.png',
                                  ) as ImageProvider,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userData?['name'] ??
                                user?.displayName ??
                                loc.user,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData?['email'] ?? user?.email ?? '—',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _accountType(user),
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              // هنا لاحقًا تفتح EditProfilePage لتعديل الاسم/الصورة
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('قريبًا: تعديل المعلومات'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(loc.edit),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                              foregroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(thickness: 1),

                    // ————— إحصائيات التطبيق
                    _sectionTitle('إحصائيات الرحلات'),
                    _cardTile(
                      icon: Icons.favorite,
                      title: loc.favoritesTitle,
                      subtitle: '$favoritesCount ${loc.places}',
                    ),
                    _cardTile(
                      icon: Icons.map_outlined,
                      title: 'عدد الرحلات',
                      subtitle: '$travelCount ${loc.tripsDone}',
                    ),
                    _cardTile(
                      icon: Icons.place,
                      title: loc.lastDestination,
                      subtitle: lastDestination ?? loc.noData,
                    ),
                    _cardTile(
                      icon: Icons.route,
                      title: 'المسافة الإجمالية',
                      subtitle: _formatDistance(totalDistanceM),
                    ),
                    _cardTile(
                      icon: Icons.timer_outlined,
                      title: 'الوقت الكلي للرحلات',
                      subtitle: _formatDuration(totalDurationS),
                    ),
                    _cardTile(
                      icon: Icons.location_city,
                      title: 'المدينة الحالية',
                      subtitle: currentCity ?? '—',
                    ),

                    const SizedBox(height: 8),
                    const Divider(thickness: 1),

                    // ————— تحكم المستخدم
                    _sectionTitle(loc.settings),
                    // الثيم
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: SwitchListTile(
                        value: widget.themeNotifier.isDarkMode,
                        onChanged: (_) => _toggleTheme(),
                        title: Text(loc.theme),
                        subtitle:
                            Text(widget.themeNotifier.isDarkMode ? loc.dark : loc.light),
                        secondary: const Icon(Icons.brightness_6, color: Colors.orange),
                      ),
                    ),
                    // اللغة
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading:
                            const Icon(Icons.language, color: Colors.orange),
                        title: Text(loc.language),
                        subtitle:
                            Text(userData?['language'] ?? (isArabic ? 'ar' : 'en')),
                        trailing: PopupMenuButton<String>(
                          onSelected: _changeLanguage,
                          itemBuilder: (c) => [
                            const PopupMenuItem(value: 'ar', child: Text('العربية')),
                            const PopupMenuItem(value: 'en', child: Text('English')),
                          ],
                          child: const Icon(Icons.translate),
                        ),
                      ),
                    ),
                    // إشعارات - Placeholder
                    _cardTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'الإشعارات',
                      subtitle: 'قريبًا…',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ميزة الإشعارات قريبًا')),
                        );
                      },
                    ),
                    // مشاركة التطبيق
                    _cardTile(
                      icon: Icons.share,
                      title: 'مشاركة التطبيق',
                      subtitle: 'انشر التطبيق بين أصدقائك',
                      onTap: _shareApp,
                    ),
                    // إرسال ملاحظات
                    _cardTile(
                      icon: Icons.feedback_outlined,
                      title: 'إرسال ملاحظات',
                      subtitle: 'ساعدنا على تحسين التجربة',
                      onTap: _sendFeedback,
                    ),

                    const SizedBox(height: 8),
                    const Divider(thickness: 1),

                    // ————— Gamification
                    _sectionTitle('الإنجازات'),
                    Card(
                      elevation: 3,
                      color: Colors.orange.shade50,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events,
                                    color: Colors.orange, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'مستواك: $_level',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _progressToNext,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(10),
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              travelCount >= 10
                                  ? (travelCount >= 25
                                      ? '🎉 حصلت على شارة المستكشف الخبير!'
                                      : '🎉 حصلت على شارة المستكشف النشط!')
                                  : 'اكتشف ${10 - travelCount} أماكن إضافية لتحصل على أول شارة',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(thickness: 1),

                    // ————— إعدادات الحساب
                    _sectionTitle('إعدادات الحساب'),
                    // تغيير كلمة المرور (إن كان بريد/باسوورد)
                    if (_passwordEditable(user))
                      _cardTile(
                        icon: Icons.lock_outline,
                        title: 'تغيير كلمة المرور',
                        subtitle: 'أعد ضبط كلمة المرور الخاصة بك',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ForgotPasswordPage(themeNotifier: widget.themeNotifier),
                            ),
                          );
                        },
                      )
                    else
                      _cardTile(
                        icon: Icons.lock_outline,
                        title: 'تغيير كلمة المرور',
                        subtitle: 'غير متاح لحسابات Google/ضيف',
                      ),

                    // حذف الحساب
                    _cardTile(
                      icon: Icons.delete_forever,
                      title: 'حذف الحساب',
                      subtitle: 'سيتم حذف حسابك نهائيًا (قد يتطلب إعادة تسجيل الدخول)',
                      onTap: _deleteAccount,
                    ),

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: Text(loc.signOut),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  String _accountType(User? u) {
    if (u == null) return '—';
    if (u.isAnonymous) return 'زائر';
    // إذا فيه مزود Google
    final hasGoogle = u.providerData.any((p) => p.providerId == 'google.com');
    if (hasGoogle) return 'حساب Google';
    return 'حساب مسجل';
  }

  bool _passwordEditable(User? u) {
    if (u == null) return false;
    if (u.isAnonymous) return false;
    final hasGoogle = u.providerData.any((p) => p.providerId == 'google.com');
    return !hasGoogle; // فقط الإيميل/باسوورد نسمحله يغير
  }
}
