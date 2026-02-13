import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double mdd = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const insetsAllXS = EdgeInsets.all(xs);
  static const insetsAllMD = EdgeInsets.all(md);
  static const insetsAllLG = EdgeInsets.all(lg);
  static const insetsSymH16V12 = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // radius
  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 22;
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(rSm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(rMd));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(rLg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(rXl));

  // animasyon süreleri
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  // Genel boşluklar
  static const double pageH = 20; // sayfa yatay padding
  static const double pageV = 10; // sayfa dikey padding

  static const double cardPadding = 14;
  static const double cardGap = 12;
  static const double sectionGap = 20;

  // Grid boşlukları
  static const double gridGap = 16;

  // Radius
  static const double rCard = 18;
  static const double rImage = 12;
  static const double rInput = 14;

  // Hazır padding setleri
  static const pageInsets = EdgeInsets.symmetric(
    horizontal: pageH,
    vertical: pageV,
  );

  static const cardInsets = EdgeInsets.all(cardPadding);
}
