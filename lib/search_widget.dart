import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmartSearchBar extends StatefulWidget {
  final String hintText;
  final String collectionName;
  final Function(String)? onResultSelected;

  const SmartSearchBar({
    super.key,
    this.hintText = 'ابحث هنا...',
    required this.collectionName,
    this.onResultSelected,
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<String> _results = [];
  List<String> _history = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();

    // إعداد الحركة
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// ✅ تحميل سجل البحث
  Future<void> _loadSearchHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('search_history')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _history = List<String>.from(doc['history'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("⚠️ فشل تحميل السجل: $e");
    }
  }

  /// ✅ حفظ مصطلح في السجل
  Future<void> _saveSearchToHistory(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || query.isEmpty) return;

    try {
      final ref =
          FirebaseFirestore.instance.collection('search_history').doc(user.uid);

      _history.remove(query);
      _history.insert(0, query);
      if (_history.length > 10) _history = _history.sublist(0, 10);

      await ref.set({'history': _history});
    } catch (e) {
      debugPrint("⚠️ فشل حفظ السجل: $e");
    }
  }

  /// ✅ حذف عنصر من السجل
  Future<void> _deleteHistoryItem(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _history.remove(query);
      setState(() {});
      final ref =
          FirebaseFirestore.instance.collection('search_history').doc(user.uid);
      await ref.set({'history': _history});
    } catch (e) {
      debugPrint("⚠️ فشل حذف السجل: $e");
    }
  }

  /// ✅ البحث في Firestore
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: "$query\uf8ff")
          .limit(10)
          .get();

      final List<String> names =
          snapshot.docs.map((doc) => doc['name'].toString()).toList();

      setState(() {
        _results = names;
        _showSuggestions = true;
      });
      _animController.forward();
    } catch (e) {
      debugPrint("⚠️ خطأ أثناء البحث: $e");
    }

    setState(() => _isLoading = false);
  }

  void _onSelect(String value) {
    _controller.text = value;
    _saveSearchToHistory(value);
    widget.onResultSelected?.call(value);
    FocusScope.of(context).unfocus();
    _animController.reverse();
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ شريط البحث بتصميم برتقالي جميل
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.orange.shade300, Colors.orange.shade500],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.orange.withOpacity(0.3),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  ),
  child: TextField(
    controller: _controller,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    cursorColor: Colors.white,
    decoration: InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      prefixIcon: const Icon(Icons.search, color: Colors.white),
      suffixIcon: _controller.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                _controller.clear();
                setState(() => _showSuggestions = false);
              },
            )
          : null,
      border: InputBorder.none,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  ),
),

        const SizedBox(height: 10),
        // ✅ عرض الاقتراحات أو السجل مع حركة جميلة
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _showSuggestions
              ? FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.grey[900] : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _results.isNotEmpty
                            ? _results.length
                            : _history.length,
                        itemBuilder: (context, index) {
                          final item = _results.isNotEmpty
                              ? _results[index]
                              : _history[index];
                          final isHistory = _history.contains(item);

                          return ListTile(
                            leading: Icon(
                              isHistory ? Icons.history : Icons.place_outlined,
                              color: isHistory
                                  ? Colors.grey
                                  : Colors.orangeAccent,
                            ),
                            title: Text(
                              item,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: isHistory
                                ? IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.redAccent),
                                    tooltip: 'حذف من السجل',
                                    onPressed: () =>
                                        _deleteHistoryItem(item),
                                  )
                                : null,
                            onTap: () => _onSelect(item),
                          );
                        },
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
