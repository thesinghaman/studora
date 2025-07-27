import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import 'package:studora/app/services/logger_service.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  var connectionStatus = List<ConnectivityResult>.empty().obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<NetworkService> init() async {
    await _initConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectionChange,
    );
    return this;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<bool> isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      LoggerService.logInfo(
        "NetworkService",
        "isInternetAvailable",
        "No internet connection (SocketException).",
      );
      return false;
    } on TimeoutException catch (_) {
      LoggerService.logInfo(
        "NetworkService",
        "isInternetAvailable",
        "No internet connection (Timeout).",
      );
      return false;
    }
  }

  Future<bool> hasActiveConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _setConnectionStatus(results);
      return isConnected();
    } catch (e) {
      LoggerService.logError("NetworkService", "hasActiveConnection", e);
      _setConnectionStatus([ConnectivityResult.none]);
      return false;
    }
  }

  void _handleConnectionChange(List<ConnectivityResult> results) {
    final bool wasConnected = isConnected();
    _setConnectionStatus(results);
    final bool isNowConnected = isConnected();
    if (kDebugMode) {
      LoggerService.logInfo(
        "NetworkService",
        "_handleConnectionChange",
        "Network Status Updated: $results",
      );
    }

    if (wasConnected && !isNowConnected) {
      Get.rawSnackbar(
        message: "No Internet Connection",
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _initConnectivity() async {
    try {
      var results = await _connectivity.checkConnectivity();
      _setConnectionStatus(results);
    } catch (e) {
      LoggerService.logError("NetworkService", "_initConnectivity", e);
      _setConnectionStatus([ConnectivityResult.none]);
    }
  }

  void _setConnectionStatus(List<ConnectivityResult> results) {
    connectionStatus.assignAll(results);
  }

  bool isConnected() {
    return connectionStatus.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }
}
