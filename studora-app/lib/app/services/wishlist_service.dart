import 'package:get/get.dart';

import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class WishlistService extends GetxService {
  static const String _className = 'WishlistService';

  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final RxSet<String> favoriteItemIds = <String>{}.obs;

  void initializeWishlist(List<String> initialIds) {
    favoriteItemIds.assignAll(Set<String>.from(initialIds));
    LoggerService.logInfo(
      _className,
      'initializeWishlist',
      'Wishlist initialized with ${initialIds.length} items.',
    );
  }

  void clearWishlist() {
    favoriteItemIds.clear();
    LoggerService.logInfo(_className, 'clearWishlist', 'Wishlist cleared.');
  }

  bool isFavorite(String itemId) {
    return favoriteItemIds.contains(itemId);
  }

  void toggleFavorite(String itemId) async {
    if (_authRepository.appUser.value == null) {
      SnackbarService.showError("Please login to add items to your wishlist.");
      return;
    }
    final bool isCurrentlyFavorite = isFavorite(itemId);

    if (isCurrentlyFavorite) {
      favoriteItemIds.remove(itemId);
    } else {
      favoriteItemIds.add(itemId);
    }

    try {
      await _authRepository.updateUserWishlist(favoriteItemIds.toList());
      SnackbarService.showSuccess(
        isCurrentlyFavorite ? "Removed from wishlist" : "Added to wishlist",
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'toggleFavorite',
        'Failed to update wishlist for $itemId: $e',
        s,
      );

      if (isCurrentlyFavorite) {
        favoriteItemIds.add(itemId);
      } else {
        favoriteItemIds.remove(itemId);
      }
      SnackbarService.showError(
        "Could not update your wishlist. Please try again.",
      );
    }
  }
}
