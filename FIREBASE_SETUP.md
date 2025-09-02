# Configuration Firebase pour TodoList Flutter

## Étapes de configuration

### 1. Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur "Créer un projet"
3. Nommez votre projet (ex: "todo-list-flutter")
4. Activez Google Analytics (optionnel)
5. Créez le projet

### 2. Configurer les services Firebase

#### Authentification

1. Dans la console Firebase, allez dans "Authentication"
2. Cliquez sur "Commencer"
3. Allez dans l'onglet "Sign-in method"
4. Activez "Email/Password"
5. Activez "Google" et configurez le nom du projet

#### Firestore Database

1. Dans la console Firebase, allez dans "Firestore Database"
2. Cliquez sur "Créer une base de données"
3. Choisissez "Commencer en mode test" (pour le développement)
4. Sélectionnez une région proche de vos utilisateurs

#### Storage

1. Dans la console Firebase, allez dans "Storage"
2. Cliquez sur "Commencer"
3. Acceptez les règles par défaut (pour le développement)
4. Sélectionnez une région

#### Analytics

1. Dans la console Firebase, allez dans "Analytics"
2. Activez Google Analytics si ce n'est pas déjà fait
3. Configurez les événements personnalisés si nécessaire

#### Crashlytics

1. Dans la console Firebase, allez dans "Crashlytics"
2. Activez Crashlytics pour votre projet
3. Configurez les alertes si nécessaire

#### Cloud Messaging

1. Dans la console Firebase, allez dans "Cloud Messaging"
2. Configurez les notifications push
3. Testez l'envoi de messages

### 3. Configurer l'application Flutter

#### Pour Web :

1. Dans la console Firebase, cliquez sur l'icône Web
2. Nommez votre app (ex: "todo-list-web")
3. Copiez la configuration Firebase
4. Remplacez le contenu de `lib/firebase_options.dart` par la configuration générée

#### Pour Android :

1. Dans la console Firebase, cliquez sur l'icône Android
2. Entrez le nom du package : `com.example.todoList`
3. Téléchargez le fichier `google-services.json`
4. Placez-le dans `android/app/`

#### Pour iOS :

1. Dans la console Firebase, cliquez sur l'icône iOS
2. Entrez l'ID du bundle : `com.example.todoList`
3. Téléchargez le fichier `GoogleService-Info.plist`
4. Placez-le dans `ios/Runner/`

### 4. Configuration Google Sign-In

#### Pour Web :

1. Dans la console Google Cloud, activez l'API Google Sign-In
2. Configurez les domaines autorisés

#### Pour Android :

1. Ajoutez votre empreinte SHA-1 dans la console Firebase
2. Obtenez votre empreinte avec : `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

#### Pour iOS :

1. Ajoutez l'URL de redirection dans la console Firebase
2. Format : `com.googleusercontent.apps.YOUR_CLIENT_ID`

### 5. Variables d'environnement (optionnel)

Pour la production, créez un fichier `.env` :

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

## Test de l'application

1. Lancez l'application : `flutter run`
2. Testez la connexion avec email/mot de passe
3. Testez la connexion Google
4. Vérifiez que la déconnexion fonctionne

## Dépannage

### Erreurs courantes :

1. **"Firebase not initialized"** : Vérifiez que `firebase_options.dart` est correctement configuré
2. **"Google Sign-In failed"** : Vérifiez la configuration OAuth dans la console Google
3. **"Invalid API key"** : Vérifiez que les clés API sont correctes dans `firebase_options.dart`

### Logs utiles :

```dart
// Activez les logs de debug
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug info: $message');
}
```

## Sécurité

1. **Règles Firestore** : Utilisez les règles fournies dans `firestore.rules`
2. **Règles Storage** : Utilisez les règles fournies dans `storage.rules`
3. **Clés API** : Ne commitez jamais les vraies clés API en production
4. **Domaines autorisés** : Limitez les domaines autorisés pour Google Sign-In
5. **Authentification** : Configurez les règles d'authentification appropriées
6. **Permissions** : Vérifiez que les utilisateurs ne peuvent accéder qu'à leurs propres données

## Déploiement des règles

### Firestore

```bash
firebase deploy --only firestore:rules
```

### Storage

```bash
firebase deploy --only storage
```

## Ressources

- [Documentation Firebase Flutter](https://firebase.flutter.dev/)
- [Guide d'authentification Firebase](https://firebase.google.com/docs/auth)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
