import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

class AgentSessionController extends Notifier<String?> {
  @override
  String? build() => null;

  void login(String agentName) {
    state = agentName;
  }

  void logout() {
    state = null;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

final agentSessionProvider = NotifierProvider<AgentSessionController, String?>(
  AgentSessionController.new,
);

final isAgentConnectedProvider = Provider<bool>((ref) {
  return ref.watch(agentSessionProvider) != null;
});

class CardRepositoryController extends Notifier<Map<String, Map<String, String>>> {
  @override
  Map<String, Map<String, String>> build() => {};

  void addCard(Map<String, String> data) {
    final key = _key(data['Nom'], data['Prénom']);
    state = {
      ...state,
      key: data,
    };
  }

  Map<String, String>? findCardByName(String nom, String prenom) {
    return state[_key(nom, prenom)];
  }

  String _key(String? nom, String? prenom) {
    return '${nom?.trim().toLowerCase() ?? ''}|${prenom?.trim().toLowerCase() ?? ''}';
  }
}

final cardRepositoryProvider = NotifierProvider<CardRepositoryController,
    Map<String, Map<String, String>>>(CardRepositoryController.new);
