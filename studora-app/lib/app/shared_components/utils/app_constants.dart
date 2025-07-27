import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appwriteDatabaseId = '';

  static const String legalDocumentsCollectionId = '';
  static const String countriesCollectionId = '';
  static const String collegesCollectionId = '';
  static const String usersCollectionId = '';
  static const String itemsCollectionId = '';
  static const String lostFoundItemsCollectionId = '';
  static const String categoriesCollectionId = '';
  static const String conversationsCollectionId = '';
  static const String messagesCollectionId = '';
  static const String reportsCollectionId = '';
  static const String itemsImagesBucketId = '';
  static const String supportTicketsCollectionId = '';

  static const String updateConversationsFunctionId = '';
  static const String createMessageFunctionId = '';
  static const String getUserProfileFunctionId = '';
  static const String deleteUserAccountFunctionId = '';
  static const String notifyOnNewMessageFunctionId = '';
  static const String markMessagesAsReadFunctionId = '';
  static const String deleteUnverifiedUserFunctionId = '';
  static const String deleteConversationsFunctionId = '';
  static const String getPublicsListingsFunctionId = '';

  static const String categoryTypeSale = 'sale';
  static const String categoryTypeRental = 'rental';
  static const String categoryTypeLostFound = 'lf';

  static const Map<String, IconData> lostAndFoundIcons = {
    'Electronics': CupertinoIcons.device_phone_portrait,
    'ID Cards': CupertinoIcons.person_crop_square,
    'Keys': CupertinoIcons.lock_shield,
    'Wallets & Bags': Icons.account_balance_wallet_outlined,
    'Clothing': Icons.checkroom,
    'Documents': CupertinoIcons.doc_text,
    'Other': CupertinoIcons.question_circle,
  };
}
