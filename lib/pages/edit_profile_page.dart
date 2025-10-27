import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../theme_notifier.dart';

class EditProfilePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const EditProfilePage({super.key, required this.themeNotifier});
  
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
  
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  File? _pickedImage;
  String? _imageUrl;
  bool _isSaving = false;
  bool _isGuest = false;
  bool _updated = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (user.isAnonymous) {
      setState(() => _isGuest = true);
      return;
    }
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      _nameController.text = data?['name'] ?? user.displayName ?? '';
      _imageUrl = data?['photoUrl'] ?? user.photoURL;
    } else {
      _nameController.text = user.displayName ?? '';
      _imageUrl = user.photoURL;
    }

    setState(() {});
  }

  // 📸 اختيار صورة من المعرض أو الكاميرا
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في اختيار الصورة: $e');
    }
  }

  // ☁️ رفع الصورة إلى Firebase Storage
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${user.uid}.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('⚠️ خطأ أثناء رفع الصورة إلى Firebase Storage: $e');
      return null;
    }
  }

  // 💾 حفظ المعلومات الشخصية
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String? uploadedUrl = _imageUrl;
      if (_pickedImage != null) {
        uploadedUrl = await _uploadImageToFirebase(_pickedImage!);
      }

      // ✳️ تحديث Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'photoUrl': uploadedUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✳️ تحديث FirebaseAuth
      await user.updateDisplayName(_nameController.text.trim());
      if (uploadedUrl != null) {
        await user.updatePhotoURL(uploadedUrl);
      }
      if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('✅ تم حفظ التعديلات بنجاح'),
      backgroundColor: Colors.green,
    ),
  );

  setState(() {
    _updated = true; // علّم إنو صار تحديث فعلاً
  });
}


    } catch (e) {
      debugPrint('⚠️ خطأ أثناء الحفظ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title: const Text('التقاط من الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeNotifier.isDarkMode;

    if (_isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '🚫 لا يمكنك تعديل الملف الشخصي أثناء تسجيل الدخول كزائر.\nيرجى إنشاء حساب لتفعيل هذه الميزة.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

   return WillPopScope(
  onWillPop: () async {
    Navigator.pop(context, _updated); // لما يرجع نرسل النتيجة
    return false;
  },
  child: Scaffold(
    appBar: AppBar(
      title: const Text('تعديل الملف الشخصي'),
      backgroundColor: Colors.orange,
      leading: BackButton(
        onPressed: () => Navigator.pop(context, _updated), // نفس الفكرة للسهم
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // 🟠 صورة المستخدم
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.orange.shade100,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? NetworkImage(_imageUrl!)
                            : null,
                    child: (_imageUrl == null || _imageUrl!.isEmpty)
                        ? const Icon(Icons.person,
                            size: 60, color: Colors.orange)
                        : null,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _showImagePickerOptions,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // الاسم الكامل
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'الرجاء إدخال الاسم' : null,
            ),

            const SizedBox(height: 30),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'جارٍ الحفظ...' : 'حفظ التعديلات',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ),
          ],
        ),
      ),
    ),
    backgroundColor: isDark ? Colors.black87 : Colors.white,
  ),
);
  }
}