import 'package:flutter/material.dart';

class SwipeablePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SwipeablePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  // ✅ نرجع بس لما السحب قوي باتجاه اليمين
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 500) {
                    Navigator.of(context).maybePop();
                  }
                },
                child: child,
              ),
            );
          },
        );
}
