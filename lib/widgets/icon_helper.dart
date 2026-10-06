import 'package:flutter/material.dart';

/// Maps icon string names stored in Hive models to Material IconData.
IconData getIconData(String? iconName) {
  switch (iconName) {
    case 'payments':
      return Icons.payments_rounded;
    case 'account_balance':
      return Icons.account_balance_rounded;
    case 'account_balance_wallet':
      return Icons.account_balance_wallet_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'shopping_cart':
      return Icons.shopping_cart_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'receipt_long':
      return Icons.receipt_long_rounded;
    case 'directions_car':
      return Icons.directions_car_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'medical_services':
      return Icons.medical_services_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'movie':
      return Icons.movie_rounded;
    case 'more_horiz':
      return Icons.more_horiz_rounded;
    case 'storefront':
      return Icons.storefront_rounded;
    case 'laptop_mac':
      return Icons.laptop_mac_rounded;
    case 'trending_up':
      return Icons.trending_up_rounded;
    case 'card_giftcard':
      return Icons.card_giftcard_rounded;
    case 'handshake':
      return Icons.handshake_rounded;
    default:
      return Icons.category_rounded;
  }
}
