import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String appwriteDatabaseId = dotenv.env['APPWRITE_DATABASE_ID'] ?? '';

  static String legalDocumentsCollectionId =
      dotenv.env['LEGAL_DOCUMENTS_COLLECTION_ID'] ?? '';
  static String countriesCollectionId =
      dotenv.env['COUNTRIES_COLLECTION_ID'] ?? '';
  static String collegesCollectionId =
      dotenv.env['COLLEGES_COLLECTION_ID'] ?? '';
  static String usersCollectionId = dotenv.env['USERS_COLLECTION_ID'] ?? '';
  static String itemsCollectionId = dotenv.env['ITEMS_COLLECTION_ID'] ?? '';
  static String lostFoundItemsCollectionId =
      dotenv.env['LOST_FOUND_ITEMS_COLLECTION_ID'] ?? '';
  static String categoriesCollectionId =
      dotenv.env['CATEGORIES_COLLECTION_ID'] ?? '';
  static String conversationsCollectionId =
      dotenv.env['CONVERSATIONS_COLLECTION_ID'] ?? '';
  static String messagesCollectionId =
      dotenv.env['MESSAGES_COLLECTION_ID'] ?? '';
  static String reportsCollectionId = dotenv.env['REPORTS_COLLECTION_ID'] ?? '';
  static String itemsImagesBucketId =
      dotenv.env['ITEMS_IMAGES_BUCKET_ID'] ?? '';
  static String supportTicketsCollectionId =
      dotenv.env['SUPPORT_TICKETS_COLLECTION_ID'] ?? '';

  static String updateConversationsFunctionId =
      dotenv.env['UPDATE_CONVERSATIONS_FUNCTION_ID'] ?? '';
  static String createMessageFunctionId =
      dotenv.env['CREATE_MESSAGE_FUNCTION_ID'] ?? '';
  static String getUserProfileFunctionId =
      dotenv.env['GET_USER_PROFILE_FUNCTION_ID'] ?? '';
  static String deleteUserAccountFunctionId =
      dotenv.env['DELETE_USER_ACCOUNT_FUNCTION_ID'] ?? '';
  static String notifyOnNewMessageFunctionId =
      dotenv.env['NOTIFY_ON_NEW_MESSAGE_FUNCTION_ID'] ?? '';
  static String markMessagesAsReadFunctionId =
      dotenv.env['MARK_MESSAGES_AS_READ_FUNCTION_ID'] ?? '';
  static String deleteUnverifiedUserFunctionId =
      dotenv.env['DELETE_UNVERIFIED_USER_FUNCTION_ID'] ?? '';
  static String deleteConversationsFunctionId =
      dotenv.env['DELETE_CONVERSATIONS_FUNCTION_ID'] ?? '';
  static String getPublicsListingsFunctionId =
      dotenv.env['GET_PUBLIC_LISTINGS_FUNCTION_ID'] ?? '';

  static String studoraBackendFunctionId =
      dotenv.env['STUDORA_BACKEND_FUNCTION_ID'] ?? '';

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
