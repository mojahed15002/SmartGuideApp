import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pages/logs_page.dart';
import 'package:flutter_application_1/sign_in_panel.dart';

import 'profile_page.dart';
import 'settings_page.dart';
import '../sign_in_panel.dart';
import 'checkpoints_page.dart';
import '../theme_notifier.dart';
import '../auth_service.dart';
import 'logs_page.dart';

class CustomDrawer extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final Function(int) onTabSelected;

  const CustomDrawer({
    super.key,
    required this.themeNotifier,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ====== رأس المستخدم ======
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfilePage(themeNotifier: themeNotifier),
                      ),
                    );
                  },
                  child: UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 40, color: Colors.orange.shade700),
                    ),
                    accountName: user?.displayName != null &&
                            user!.displayName!.isNotEmpty
                        ? Text(
                            user.displayName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : const SizedBox.shrink(),
                    accountEmail: Text(
                      user?.email ?? "",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

                // ====== عناصر التنقل ======
                _buildDrawerItem(
                  icon: Icons.home,
                  text: 'الصفحة الرئيسية',
                  onTap: () {
                    Navigator.pop(context);
                    onTabSelected(0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.place,
                  text: 'القريبة مني',
                  onTap: () {
                    Navigator.pop(context);
                    onTabSelected(2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.favorite,
                  text: 'المفضلة',
                  onTap: () {
                    Navigator.pop(context);
                    onTabSelected(1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  text: 'سجل الرحلات',
                  onTap: () {
                    Navigator.pop(context);
                   Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LogsPage(themeNotifier: themeNotifier),
                      ),
                    ); 
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shield,
                  text: 'الحواجز',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CheckpointsPage(themeNotifier: themeNotifier),
                      ),
                    );
                  },
                ),

                const Divider(color: Colors.white70, thickness: 1, height: 25),

                // ====== الوضع الداكن ======
                SwitchListTile(
                  title: const Text(
                    'الوضع الداكن',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  secondary: const Icon(Icons.dark_mode, color: Colors.white),
                  value: themeNotifier.isDarkMode,
                  onChanged: (val) => themeNotifier.toggleTheme(),
                ),

                // ====== الإعدادات ======
                _buildDrawerItem(
                  icon: Icons.settings,
                  text: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SettingsPage(themeNotifier: themeNotifier),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // ====== زر تسجيل الخروج ======
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () async {
                      final confirm = await showGeneralDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: '',
                        barrierColor: Colors.black54,
                        transitionDuration:
                            const Duration(milliseconds: 250), // مدة الأنيميشن
                        pageBuilder: (context, _, __) => const SizedBox.shrink(),
                        transitionBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return ScaleTransition(
                            scale: CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.orange, size: 30),
                                    SizedBox(width: 8),
                                    Text('تأكيد تسجيل الخروج'),
                                  ],
                                ),
                                content: Text(
                                  'هل أنت متأكد من تسجيل الخروج؟\n'
                                  'في حال تسجيل الخروج ستبقى بياناتك محفوظة.',
                                  textAlign: TextAlign.center,
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  TextButton(
                                    child: Text(
                                      'إلغاء',
                                      style:
                                          TextStyle(color: Colors.grey.shade700),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.logout, size: 18),
                                    label: const Text('تأكيد'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      if (confirm == true) {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SignInPanel(themeNotifier: themeNotifier),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
