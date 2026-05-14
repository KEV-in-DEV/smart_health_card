import 'package:flutter/material.dart';

class AppColors {
  static const burkinaGreen = Color(0xFF2E7D32);
  static const burkinaOrange = Color(0xFFF57C00);
  static const emergencyRed = Color(0xFFD32F2F);
  static const background = Color(0xFFF5F5F5);
  static const text = Color(0xFF212121);
  static const accent = Color(0xFF03A9F4);
  static const white = Colors.white;
  static const mutedText = Color(0xFF616161);
  static const border = Color(0xFFE0E0E0);
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkText = Color(0xFFF5F5F5);
}

class AppTextSizes {
  static const double title = 26;
  static const double subtitle = 20;
  static const double body = 16;
  static const double small = 14;
  static const double button = 17;
}

class AppSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppStrings {
  static const appName = 'Smart Health Card';
  static const agentId = 'ID agent';
  static const password = 'Mot de passe';
  static const login = 'Connexion';
  static const logout = 'Déconnexion';
  static const publicAccess = 'Accès public';
  static const agentAccess = 'Connexion agent';
  static const publicQrOnly = 'Scanner un QR code sans connexion';
  static const publicDataOnly = 'Infos publiques uniquement';
  static const requiredFields =
      'Veuillez remplir tous les champs obligatoires.';
  static const loading = 'Chargement...';
  static const readCard = 'Lire une carte';
  static const writeCard = 'Créer / modifier une carte';
  static const scanQr = 'Scanner QR code';
  static const recentCards = 'Dernières cartes lues';
  static const history = 'Historique';
  static const settings = 'Paramètres';
  static const appSettings = 'Paramètres de l’application';
  static const offlineMode = 'Mode hors ligne';
  static const security = 'Sécurité';
  static const connectedAgent = 'Agent connecté';
  static const home = 'Accueil';
  static const back = 'Retour';
  static const putCardNearPhone = 'Posez la carte sur le téléphone';
  static const enableNfc = 'Activez le NFC';
  static const cardDetected = 'Carte détectée';
  static const blankCardDetected = 'Carte vierge détectée';
  static const readingCard = 'Lecture en cours';
  static const writingCard = 'Écriture en cours';
  static const incompatibleCard = 'Carte non compatible';
  static const agentRequired = 'Connexion agent requise pour modifier';
  static const continueToNfc = 'Continuer vers l’écriture NFC';
  static const startNfcRead = 'Démarrer la lecture NFC';
  static const startNfcWrite = 'Démarrer l’écriture NFC';
  static const writeOnCard = 'Écrire sur la carte';
  static const writeSuccess = 'Carte écrite avec succès.';
  static const cardVerified = 'Carte vérifiée';
  static const signatureInvalid = 'Signature invalide';
  static const scanSimulation = 'Simuler le scan';
  static const labelPreview = 'Étiquette à imprimer';
  static const generateQr = 'Générer le QR code';
  static const printLabel = 'Imprimer l’étiquette';
  static const darkTheme = 'Thème sombre';
  static const noData = 'Aucune donnée disponible pour le moment.';
}
