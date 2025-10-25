import 'package:flutter/material.dart';

class SwipeablePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SwipeablePageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // حركه الانزلاق من اليمين إلى اليسار (عند الفتح)
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final curvedAnimation =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

            return SlideTransition(
              position: tween.animate(curvedAnimation),
              child: child,
            );
          },
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return super
        .buildTransitions(context, animation, secondaryAnimation, child);
  }

  // ⬅️ دعم السوايب من الطرف الأيسر للرجوع (مثل iPhone)
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        // إذا سحب المستخدم من اليسار لليمين
        if (details.primaryDelta != null && details.primaryDelta! > 12) {
          Navigator.of(context).maybePop();
        }
      },
      child: super.buildPage(context, animation, secondaryAnimation),
    );
  }
}
