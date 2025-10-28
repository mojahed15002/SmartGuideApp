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
import 'edit_profile_page.dart';

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
  final loc = AppLocalizations.of(context)!;
  if (travelCount >= 25) return loc.badgeExpert;
  if (travelCount >= 10) return loc.badgeActive;
  return loc.badgeFirst(10 - travelCount);
}


  double get _progressToNext {
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

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      userData = userDoc.data();
      favoritesCount = (userData?['favorites'] as List?)?.length ?? 0;
    }

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
    final loc = AppLocalizations.of(context)!;
    try {
      await Share.share(
        'جرب تطبيق المرشد السياحي الذكي! 🌆🗺️',
        subject: loc.shareApp,
      );
    } catch (e) {
      debugPrint('share error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.comingSoon)),
      );
    }
  }

Future<void> _signOut() async {
  final loc = AppLocalizations.of(context)!;
  final isDark = widget.themeNotifier.isDarkMode;

  // ✅ عرض نافذة تأكيد الخروج (مترجمة + حسب الثيم)
  final bool? confirmLogout = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor:
          isDark ? const Color(0xFF2C2C2C) : Colors.white, // 🎨 لون الخلفية حسب الثيم
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        loc.logoutConfirmTitle, // 🟢 مثال: "هل أنت متأكد من تسجيل الخروج؟"
        textAlign: TextAlign.right,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.orangeAccent : Colors.deepOrange,
        ),
      ),
      content: Text(
        loc.logoutConfirmMessage, // 🟢 مثال: "في حال سجلت الخروج، ستبقى بياناتك محفوظة 🙂"
        textAlign: TextAlign.right,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            loc.cancel,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            loc.confirmLogout,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  // ✅ تنفيذ الخروج فقط إذا وافق المستخدم
  if (confirmLogout == true) {
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
}



  Future<void> _deleteAccount() async {
  final loc = AppLocalizations.of(context)!;
  final isDark = widget.themeNotifier.isDarkMode;
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) return;

  // 🧱 تأكيد نية الحذف
  final bool? confirmDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.deleteAccount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.orangeAccent : Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        loc.deleteAccountConfirmMessage,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            loc.cancel,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            loc.confirmDelete,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  if (confirmDelete != true) return;

  // ✅ تحديد طريقة تسجيل الدخول
  final providerId = currentUser.providerData.isNotEmpty
      ? currentUser.providerData.first.providerId
      : null;

  try {
    // 🟢 التحقق الأمني قبل الحذف
    if (providerId == 'password') {
      final TextEditingController passController = TextEditingController();
      final password = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            loc.reenterPassword,
            style: TextStyle(
              color: isDark ? Colors.orangeAccent : Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: loc.password,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, passController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(loc.confirm),
            ),
          ],
        ),
      );

      if (password == null || password.isEmpty) return;

      final cred = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(cred);
    } else if (providerId == 'google.com') {
      final googleProvider = GoogleAuthProvider();
      await currentUser.reauthenticateWithProvider(googleProvider);
    }

    // ✅ بعد التحقق الناجح، نعرض عدّ تنازلي قبل الحذف
    int secondsLeft = 5;
    bool cancelled = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // نستخدم StatefulBuilder لتحديث العدّ داخل الـDialog
        return StatefulBuilder(
          builder: (context, setState) {
            Future.delayed(const Duration(seconds: 1), () {
              if (secondsLeft > 0 && mounted && !cancelled) {
                setState(() => secondsLeft--);
              } else if (secondsLeft == 0 && !cancelled) {
                Navigator.pop(context); // إغلاق النافذة بعد العدّ
              }
            });

            return AlertDialog(
              backgroundColor:
                  isDark ? const Color(0xFF2C2C2C) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                "⏳ ${loc.deletingSoon}",
                style: TextStyle(
                  color: isDark ? Colors.orangeAccent : Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${loc.accountWillBeDeleted} ($secondsLeft)",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (5 - secondsLeft) / 5,
                    backgroundColor:
                        isDark ? Colors.white24 : Colors.orange.withOpacity(0.2),
                    color: Colors.redAccent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    Navigator.pop(context);
                  },
                  child: Text(
                    loc.cancelDelete,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // لو المستخدم لغى العدّ، نوقف العملية
    if (cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.deletionCancelled),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 🔥 حذف الحساب فعليًا بعد انتهاء العدّ
    await currentUser.delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.accountDeletedSuccess),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SignInPanel(themeNotifier: widget.themeNotifier),
      ),
      (r) => false,
    );
  } catch (e) {
    debugPrint('❌ Delete account error: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${loc.reauthFailed}: $e'),
        backgroundColor: Colors.redAccent,
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
  onPressed: () async {
    // ننتظر لما المستخدم يرجع من صفحة التعديل
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(themeNotifier: widget.themeNotifier),
      ),
    );

    // لو رجع بنتيجة تدل على نجاح التعديل، نعيد تحميل البيانات
    if (result == true) {
      await _loadUserAndStats();
      if (mounted) setState(() {});
    }
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
                    _sectionTitle(loc.tripStats),
                    _cardTile(
                      icon: Icons.favorite,
                      title: loc.favoritesTitle,
                      subtitle: '$favoritesCount ${loc.places}',
                    ),
                    _cardTile(
                      icon: Icons.map_outlined,
                      title: loc.tripsCount,
                      subtitle: '$travelCount ${loc.tripsDone}',
                    ),
                    _cardTile(
                      icon: Icons.place,
                      title: loc.lastDestination,
                      subtitle: lastDestination ?? loc.noData,
                    ),
                    _cardTile(
                      icon: Icons.route,
                      title: loc.totalDistance,
                      subtitle: _formatDistance(totalDistanceM),
                    ),
                    _cardTile(
                      icon: Icons.timer_outlined,
                      title: loc.totalTime,
                      subtitle: _formatDuration(totalDurationS),
                    ),
                    _cardTile(
                      icon: Icons.location_city,
                      title: loc.currentCity,
                      subtitle: currentCity ?? '—',
                    ),

                    const SizedBox(height: 8),
                    const Divider(thickness: 1),

                    // ————— تحكم المستخدم
                    _sectionTitle(loc.settings),
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
                            PopupMenuItem(value: 'ar', child: Text(loc.arabic)),
                            PopupMenuItem(value: 'en', child: Text(loc.english)),
                          ],
                          child: const Icon(Icons.translate),
                        ),
                      ),
                    ),
                    _cardTile(
                      icon: Icons.notifications_active_outlined,
                      title: loc.notifications,
                      subtitle: loc.comingSoon,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.notificationsSoon)),
                        );
                      },
                    ),
                    _cardTile(
                      icon: Icons.share,
                      title: loc.shareApp,
                      subtitle: loc.shareAppDesc,
                      onTap: _shareApp,
                    ),
                    _cardTile(
                      icon: Icons.feedback_outlined,
                      title: loc.sendFeedback,
                      subtitle: loc.helpImprove,
                      onTap: _sendFeedback,
                    ),

                    const SizedBox(height: 8),
                    const Divider(thickness: 1),

                    // ————— Gamification
                    _sectionTitle(loc.achievements),
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
                                  '${loc.yourLevel}: $_level',
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(thickness: 1),

                    // ————— إعدادات الحساب
                    _sectionTitle(loc.accountSettings),
                    if (_passwordEditable(user))
                      _cardTile(
                        icon: Icons.lock_outline,
                        title: loc.changePassword,
                        subtitle: loc.resetPassword,
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
                        title: loc.changePassword,
                        subtitle: loc.notAvailable,
                      ),
                    _cardTile(
                      icon: Icons.delete_forever,
                      title: loc.deleteAccount,
                      subtitle: loc.deleteAccountDesc,
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
    final loc = AppLocalizations.of(context)!;
    if (u == null) return '—';
    if (u.isAnonymous) return loc.visitorAccount;
    final hasGoogle = u.providerData.any((p) => p.providerId == 'google.com');
    if (hasGoogle) return loc.googleAccount;
    return loc.registeredAccount;
  }

  bool _passwordEditable(User? u) {
    if (u == null) return false;
    if (u.isAnonymous) return false;
    final hasGoogle = u.providerData.any((p) => p.providerId == 'google.com');
    return !hasGoogle;
  }
}
