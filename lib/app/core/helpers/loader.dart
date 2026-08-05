import 'package:flutter/material.dart';

mixin Loader<T extends StatefulWidget> on State<T> {
  var isOpen = false;

  void showLoader({String messageLoader = ''}) {
    if (!isOpen) {
      isOpen = true;
      showDialog(
        barrierColor: Colors.black45,
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, double scale, child) {
                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          builder: (context, double opacity, child) {
                            return Opacity(
                              opacity: opacity,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 700),
                          curve: Curves.easeInOut,
                          builder: (context, double opacity, child) {
                            return Opacity(
                              opacity: opacity,
                              child: Text(
                                messageLoader.isEmpty ? 'Carregando...' : messageLoader,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'SFProDisplay',
                                  fontSize: 16,
                                  fontStyle: FontStyle.normal,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }

  void hideLoader() {
    if (isOpen) {
      isOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
