# Volley Score 🏐

Une application mobile moderne, performante et facile à maintenir pour suivre les scores et les statistiques de matchs de volley-ball. Conçue pour Android, elle peut également être exécutée et testée localement comme application de bureau sous Linux.

L'application est entièrement rédigée en **français**, fonctionne **sans connexion (hors ligne)** et **ne nécessite aucun compte ou inscription**.

---

## 🚀 Fonctionnalités

- **Menu de Navigation Principal (Bottom Navigation)** :
  - **Matchs** : Historique et suivi des matchs enregistrés.
  - **Collectifs** : Gestion des collectifs (équipes), des joueurs et des statistiques cumulées.
- **Gestion des Collectifs & Joueurs (Offline-First)** :
  - Création de collectifs personnalisés avec choix du format : **3x3**, **4x4** ou **6x6**.
  - **Autocomplétion intelligente** lors de l'ajout de joueurs : propose les joueurs existants dans la base globale au fur et à mesure de la saisie (nom/prénom).
  - Enregistrement centralisé et automatique des joueurs créés pour une réutilisation rapide multi-collectifs.
- **Configuration de Match & Feuille de Présence** :
  - Choix de la formule de victoire : **2 sets gagnants** (Best of 3) ou **3 sets gagnants** (Best of 5).
  - Choix du collectif à engager pour le match (avec affichage du type : 3x3, 4x4, 6x6).
  - **Gestion des absents** : Option pour marquer les joueurs absents afin de les exclure de la feuille de match et éviter de les compter dans les présents.
  - **Numéros de maillots à la carte** : Personnalisation facultative des numéros de maillots pour chaque match (pré-remplis avec le numéro par défaut).
  - **Validations d'intégrité** :
    - Unicité des numéros de maillots des joueurs présents sur la feuille de match.
    - Nombre minimum de joueurs présents respecté selon le format (min. 3 pour 3x3, 4 pour 4x4, 6 pour 6x6).
- **Marquage intelligent & Saisie Plein Écran** :
  - Affichage clair du score, du set en cours, de l'indicateur du serveur, et modification interactive de l'intitulé du match directement depuis l'AppBar.
  - Commutateur **"Ignorer les stats"** pour ne compter que les points (saisie ultra-rapide).
  - **Interface de saisie plein écran** : Grille de grands boutons uniformes et ordonnés pour consigner rapidement l'action du point (Ace, Attaque, Contre, Fautes variées) et le joueur concerné sans risque d'erreur de saisie en plein match.
  - Bouton **Annuler (Undo)** pour corriger immédiatement les erreurs de marquage (permet de remonter dans le temps, même sur les sets précédents).
- **Persistance & Reprise** :
  - Sauvegarde automatique et transparente de l'état du match à chaque point marqué.
  - Possibilité de quitter l'application à tout moment et de **reprendre le match** en cours depuis l'onglet Matchs.
- **Statistiques Cumulées & Export** :
  - **Stats de Match** : Graphiques de répartition des points et tableau de contribution individuelle des joueurs.
  - **Stats Globale de Collectif** : Dans l'onglet Collectifs, visualisez le bilan cumulé (matchs gagnés/perdus, sets gagnés/perdus, points marqués et commis) et la contribution historique globale de chaque joueur.
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
│   └── match_model.dart       # Modèles de données (Player, Team, VolleyballMatch, VolleyballSet, PointEvent)
│
├── services/
│   └── storage_service.dart   # Persistance locale (fichiers JSON pour matchs, collectifs et joueurs globaux)
│
└── screens/
    ├── home_screen.dart       # Conteneur principal (BottomNavigationBar, liste des matchs)
    ├── teams_tab.dart         # Liste des collectifs, suppression et accès aux statistiques globales
    ├── team_management_screen.dart # Formulaire d'édition de collectif et autocomplétion des joueurs
    ├── team_stats_screen.dart # Tableau de bord statistique cumulé d'un collectif
    ├── match_setup_screen.dart # Formulaire de création de match, vérification des numéros et des présents
    ├── match_screen.dart      # Tableau d'affichage interactif et contrôle du match
    ├── point_logging_screen.dart # Console plein écran de saisie des points et d'attribution des actions
    └── stats_screen.dart      # Visualisation des résultats du match et export CSV
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
- [match_test.dart](file:///home/lykso/Repos/VBMatchTracker/test/match_test.dart) : Valide les règles métier et les calculs de statistiques.
- [widget_test.dart](file:///home/lykso/Repos/VBMatchTracker/test/widget_test.dart) : Valide le bon démarrage de l'interface utilisateur.

---

## 🤝 Comment Contribuer

Pour maintenir l'application **simple, légère et facile à éditer**, veuillez respecter les consignes suivantes lors de vos contributions :

1. **Pas de bibliothèque de gestion d'état complexe** : Utilisez le mécanisme de base de Flutter (`setState` ou `ChangeNotifier`) plutôt que d'ajouter Redux, BLoC ou Riverpod, afin de préserver une lisibilité maximale pour les futurs développeurs.
2. **Soutien des Tests** : Si vous modifiez les règles de score du volley-ball (par exemple, pour introduire des sets à 21 points), ajoutez ou modifiez les tests correspondants dans `test/match_test.dart` et assurez-vous que `flutter test` passe avec succès.
3. **Localisation en Français** : Veillez à ce que tous les messages, boutons, actions et intitulés ajoutés à l'interface soient rédigés dans un français correct et naturel.
4. **Zéro dépendance réseau** : L'application doit rester 100% autonome et locale. N'ajoutez pas de connecteurs Firebase, d'API REST distantes ou de bibliothèques d'authentification sans l'accord préalable de l'équipe produit.
