# Guide de Configuration Firebase - Zoe Church Visitors

Ce guide vous explique comment configurer Firebase pour l'application d'enregistrement des visiteurs.

## Étape 1 : Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur **"Ajouter un projet"**
3. Nommez votre projet (ex: `zoe-church-visitors`)
4. Désactivez Google Analytics si vous n'en avez pas besoin
5. Cliquez sur **"Créer le projet"**

## Étape 2 : Ajouter une application Android

1. Dans votre projet Firebase, cliquez sur l'icône **Android**
2. Remplissez les informations :
   - **Nom du package** : `com.zoechurch.zoe_church_visitors`
   - **Nom de l'application** : Zoe Church Visiteurs
3. Cliquez sur **"Enregistrer l'application"**
4. Téléchargez le fichier `google-services.json`
5. Copiez ce fichier dans : `zoe_church_visitors/android/app/`

## Étape 3 : Activer Firestore

1. Dans Firebase Console, allez dans **"Build" > "Firestore Database"**
2. Cliquez sur **"Créer une base de données"**
3. Choisissez **"Mode test"** (pour commencer rapidement)
4. Sélectionnez la région la plus proche (ex: `europe-west1`)
5. Cliquez sur **"Activer"**

## Étape 4 : Configurer les règles de sécurité

Dans Firestore, allez dans l'onglet **"Règles"** et utilisez ces règles pour commencer :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

> ⚠️ **Attention** : Ces règles permettent un accès complet. En production, vous devrez les sécuriser.

## Étape 5 : Mettre à jour firebase_options.dart

Ouvrez le fichier `google-services.json` et copiez les valeurs dans `lib/firebase_options.dart` :

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'VOTRE_API_KEY',           // project_info.current_key
  appId: 'VOTRE_APP_ID',             // client.client_info.mobilesdk_app_id
  messagingSenderId: 'VOTRE_ID',     // project_info.project_number
  projectId: 'VOTRE_PROJECT_ID',     // project_info.project_id
  storageBucket: 'VOTRE_BUCKET',     // project_info.storage_bucket
);
```

## Étape 6 : Lancer l'application

```bash
cd d:\ZOE CHURCH\app\zoe_church_visitors
flutter pub get
flutter run
```

## Structure Firestore créée automatiquement

L'application créera automatiquement ces collections :

- `visitors` - Les visiteurs enregistrés
- `tasks` - Les tâches de suivi
- `team` - Les membres de l'équipe
- `settings` - Les paramètres (message automatique)

## Besoin d'aide ?

Si vous avez des questions, n'hésitez pas à demander !
