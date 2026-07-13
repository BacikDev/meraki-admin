import 'package:flutter/material.dart';

import 'theme.dart';

class AdminSpacing {
  static const double xs = 6;
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 36;
  static const double xxl = 48;
}

class AdminRadius {
  static const double small = 12;
  static const double medium = 18;
  static const double large = 24;
  static const double extraLarge = 30;
}

class AdminSizes {
  static const double sidebarWidth = 290;
  static const double topBarHeight = 82;
  static const double buttonHeight = 52;
  static const double inputHeight = 54;
  static const double iconBox = 52;
}

class AdminBorders {
  static const Color soft = Color(0xFFF0E8EC);
  static const Color strong = Color(0xFFE8DCE3);

  static BorderSide get softSide {
    return const BorderSide(
      color: soft,
      width: 1,
    );
  }

  static BorderSide get strongSide {
    return const BorderSide(
      color: strong,
      width: 1,
    );
  }
}

class AdminShadows {
  static List<BoxShadow> get card {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.035),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> get elevated {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ];
  }
}

class AdminDecorations {
  static BoxDecoration get card {
    return BoxDecoration(
      color: AdminColors.white,
      borderRadius: BorderRadius.circular(AdminRadius.large),
      border: Border.all(
        color: AdminBorders.soft,
      ),
      boxShadow: AdminShadows.card,
    );
  }

  static BoxDecoration get input {
    return BoxDecoration(
      color: AdminColors.background,
      borderRadius: BorderRadius.circular(AdminRadius.medium),
    );
  }

  static BoxDecoration primaryTint({
    double radius = AdminRadius.medium,
  }) {
    return BoxDecoration(
      color: AdminColors.primaryLight,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

class AdminBreakpoints {
  static const double mobile = 700;
  static const double tablet = 950;
  static const double desktop = 1200;

  static bool isMobile(double width) => width < mobile;

  static bool isTablet(double width) {
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(double width) => width >= desktop;
}