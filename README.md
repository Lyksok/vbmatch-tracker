# Volley Score 🏐

Une application mobile moderne, performante et facile à maintenir pour suivre les scores et les statistiques de matchs de volley-ball. Conçue pour Android, elle peut également être exécutée et testée localement comme application de bureau sous Linux.

L'application est entièrement rédigée en **français**, fonctionne **sans connexion (hors ligne)** et **ne nécessite aucun compte ou inscription**.

---

## 🚀 Fonctionnalités

- **Configuration de match** :
  - Choix de la formule : **2 sets gagnants** (Best of 3) ou **3 sets gagnants** (Best of 5).
  - Personnalisation de l'équipe : nom de l'équipe locale et liste des joueurs (noms et numéros).
  - Sauvegarde de la dernière équipe configurée pour ne pas avoir à la ressaisir à chaque match.
- **Marquage intelligent & Saisie rapide** :
  - Affichage clair du score, du set en cours et de l'indicateur du serveur.
  - Commutateur **"Ignorer les stats"** pour ne compter que les points (saisie ultra-rapide).
  - Saisie statistique fluide : pour chaque point, sélectionnez l'équipe, puis l'action ayant terminé le point (Ace, Attaque, Contre, Fautes variées) et le joueur concerné.
  - Bouton **Annuler (Undo)** pour corriger immédiatement les erreurs de marquage (permet de remonter dans le temps, même sur les sets précédents).
- **Persistance & Reprise** :
  - Sauvegarde automatique et transparente de l'état du match à chaque point marqué.
  - Possibilité de quitter l'application à tout moment et de **reprendre le match** en cours depuis l'écran d'accueil.
- **Statistiques & Export** :
  - Onglet de synthèse visuel (graphiques de répartition des points gagnés et concédés).
  - Tableau détaillé des statistiques individuelles de chaque joueur (Aces, Attaques, Blocs, Fautes et contribution nette).
  - Bouton **"Exporter CSV"** qui copie les données dans le presse-papiers sous un format CSV standardisé (avec séparateur `;` adapté pour Excel en version française).

---

## 🛠️ Architecture du Projet

L'application est structurée de manière simple et modulaire afin d'être **facile à maintenir** :

```
lib/
│
├── main.dart                  # Point d'entrée de l'application & Thème global
│
├── models/
│   └── match_model.dart       # Logique métier du volley-ball (points, sets, undo) et modèles de données
│
├── services/
│   └── storage_service.dart   # Persistance locale (lecture/écriture de fichiers JSON individuels)
│
└── screens/
    ├── home_screen.dart       # Tableau de bord d'accueil (liste des matchs, chargement, suppression)
    ├── match_setup_screen.dart # Formulaire de création de match et gestion d'équipe
    ├── match_screen.dart      # Tableau d'affichage interactif et panneau de saisie des actions
    └── stats_screen.dart      # Visualisation des résultats et export CSV
```

---

## 💻 Comment Exécuter l'Application

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version stable) installé sur votre machine.

### Exécuter localement sous Linux (Recommandé pour le développement)
Puisque le SDK Android nécessite une installation lourde, vous pouvez compiler et exécuter l'application instantanément en tant qu'application de bureau Linux :

```bash
flutter run -d linux
```

### Exécuter sur Android
Si vous possédez un appareil Android connecté ou un émulateur et que votre SDK Android est configuré :

```bash
# Lister les appareils connectés
flutter devices

# Lancer l'application sur l'appareil de votre choix
flutter run -d <id_appareil>

# Compiler l'APK de production
flutter build apk --release
```

---

## 🧪 Comment Tester

L'application dispose d'un ensemble de tests unitaires couvrant la logique de calcul des scores (tie-breaks, sets classiques, règles de l'écart de 2 points) et l'agrégation des statistiques.

Pour lancer les tests automatisés, exécutez la commande suivante dans le terminal :

```bash
flutter test
```

Les tests sont situés dans le dossier :
- [match_test.dart](file:///home/lykso/Documents/antigravity/zealous-faraday/test/match_test.dart) : Valide les règles métier et les calculs de statistiques.
- [widget_test.dart](file:///home/lykso/Documents/antigravity/zealous-faraday/test/widget_test.dart) : Valide le bon démarrage de l'interface utilisateur.

---

## 🤝 Comment Contribuer

Pour maintenir l'application **simple, légère et facile à éditer**, veuillez respecter les consignes suivantes lors de vos contributions :

1. **Pas de bibliothèque de gestion d'état complexe** : Utilisez le mécanisme de base de Flutter (`setState` ou `ChangeNotifier`) plutôt que d'ajouter Redux, BLoC ou Riverpod, afin de préserver une lisibilité maximale pour les futurs développeurs.
2. **Soutien des Tests** : Si vous modifiez les règles de score du volley-ball (par exemple, pour introduire des sets à 21 points), ajoutez ou modifiez les tests correspondants dans `test/match_test.dart` et assurez-vous que `flutter test` passe avec succès.
3. **Localisation en Français** : Veillez à ce que tous les messages, boutons, actions et intitulés ajoutés à l'interface soient rédigés dans un français correct et naturel.
4. **Zéro dépendance réseau** : L'application doit rester 100% autonome et locale. N'ajoutez pas de connecteurs Firebase, d'API REST distantes ou de bibliothèques d'authentification sans l'accord préalable de l'équipe produit.
