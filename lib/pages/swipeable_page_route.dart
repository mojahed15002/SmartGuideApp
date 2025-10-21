import 'package:flutter/material.dart';

class SwipeablePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SwipeablePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0); // بداية السحب من اليسار
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.primaryDelta! > 20) {
                    Navigator.of(context).maybePop(); // يسحب ويرجع
                  }
                },
                child: child,
              ),
            );
          },
        );
}
