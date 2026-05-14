import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/database/local_storage.dart';
import 'package:smart_health_card/models/agent.dart';
import 'package:smart_health_card/services/encryption_service.dart';
import 'package:smart_health_card/services/nfc_service.dart';
import 'package:smart_health_card/services/qr_service.dart';

final storageProvider = Provider<LocalStorage>((ref) => LocalStorage());
final encryptionProvider = Provider<EncryptionService>(
  (ref) => EncryptionService(),
);
final nfcServiceProvider = Provider<NfcService>((ref) => NfcService());
final qrServiceProvider = Provider<QrService>((ref) => QrService());

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

class AgentSessionController extends Notifier<Agent?> {
  @override
  Agent? build() => null;

  void login(Agent agent) {
    state = agent;
  }

  void logout() {
    state = null;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

final agentSessionProvider = NotifierProvider<AgentSessionController, Agent?>(
  AgentSessionController.new,
);

final isAgentConnectedProvider = Provider<bool>((ref) {
  return ref.watch(agentSessionProvider) != null;
});
