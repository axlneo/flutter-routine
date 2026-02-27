import 'package:flutter/material.dart';
import '../models/models.dart';

/// Builds the morning routine sections (22 minutes total)
List<Section> buildMorningSections() {
  return [
    // ========== 1) MISE EN ROUTE - 3 min ==========
    Section(
      title: '1) Mise en route',
      emoji: '🟦',
      color: Colors.blue,
      exercises: [
        Exercise(
          title: 'Respiration diaphragmatique',
          description: '30 secondes',
          duration: 30,
          icon: '🫁',
          instructions: [
            'Allongez-vous ou asseyez-vous',
            'Main sur le ventre',
            'Inspirez par le nez (4 sec)',
            'Expirez par la bouche (6 sec)',
          ],
        ),
        Exercise(
          title: 'Cat/Cow',
          description: '1 minute',
          duration: 60,
          icon: '🐱',
          instructions: [
            'Position 4 pattes',
            'Vache: creusez le dos',
            'Chat: arrondissez le dos',
            'Alternez lentement',
          ],
        ),
        Exercise(
          title: 'Open book',
          description: '1 minute',
          duration: 60,
          icon: '📖',
          isBilateral: true,
          instructions: [
            'Sur le côté, genoux pliés',
            'Ouvrez bras vers l\'arrière',
            'Suivez la main du regard',
            '🔔 Changez de côté au signal',
          ],
        ),
        Exercise(
          title: 'Mobilité cervicale',
          description: '30 secondes',
          duration: 30,
          icon: '🧘',
          instructions: [
            'Rotations lentes',
            'Inclinaisons latérales',
            'Flexion/extension',
          ],
        ),
      ],
    ),

    // ========== 2) MOBILITÉ GÉNÉRALE - 7 min ==========
    Section(
      title: '2) Mobilité générale',
      emoji: '🟩',
      color: Colors.green,
      exercises: [
        Exercise(
          title: 'Cercles de hanches',
          description: '1 minute',
          duration: 60,
          icon: '🔄',
          isBilateral: true,
          instructions: [
            'Debout, mains sur hanches',
            'Grands cercles',
            '🔔 Changez de sens au signal',
          ],
        ),
        Exercise(
          title: 'Fente basse dynamique',
          description: '1 minute',
          duration: 60,
          icon: '🏃',
          isBilateral: true,
          instructions: [
            'Position fente basse',
            'Balancez hanches',
            'Sans forcer',
            '🔔 Changez de côté au signal',
          ],
        ),
        Exercise(
          title: 'Cercles d\'épaules',
          description: '1 minute',
          duration: 60,
          icon: '💫',
          instructions: [
            'Cercles avant/arrière',
            'Amplitude croissante',
          ],
        ),
        Exercise(
          title: 'Wall slides',
          description: '1 minute',
          duration: 60,
          icon: '🧱',
          instructions: [
            'Dos contre mur',
            'Bras en W',
            'Glissez vers le haut',
            'Contrôle lent',
          ],
        ),
        Exercise(
          title: 'Flexion genou mur',
          description: '1 minute',
          duration: 60,
          icon: '🦶',
          isBilateral: true,
          instructions: [
            'Pied contre mur',
            'Genou vers mur',
            'Tendon d\'Achille',
            '🔔 Changez de côté au signal',
          ],
        ),
        Exercise(
          title: 'Élastique dos',
          description: '1 minute',
          duration: 60,
          icon: '🎗️',
          instructions: [
            'Traction douce',
            'Décompression',
          ],
        ),
        Exercise(
          title: 'Repos actif',
          description: '1 minute',
          duration: 60,
          icon: '🧘',
          instructions: [
            'Marche sur place',
            'Respirez profondément',
          ],
        ),
      ],
    ),

    // ========== 3) RENFORCEMENT ÉPAULE - 5 min ==========
    Section(
      title: '3) Renfo épaule (kiné)',
      emoji: '🟧',
      color: Colors.orange,
      exercises: [
        Exercise(
          title: 'Rotation externe coude collé',
          description: '12 reps/côté',
          duration: 90,
          icon: '↪️',
          isBilateral: true,
          instructions: [
            'Coude collé au corps',
            'Rotation externe lente',
            'Contrôle total',
            '🔔 Changez de côté au signal',
          ],
        ),
        Exercise(
          title: 'Rotation externe 90°',
          description: '10 reps/côté',
          duration: 90,
          icon: '↗️',
          isBilateral: true,
          instructions: [
            'Coude à 90°',
            'Rotation externe',
            'Sans forcer',
            '🔔 Changez de côté au signal',
          ],
        ),
        Exercise(
          title: 'Proprioception haltère',
          description: '5 croix/bras',
          duration: 120,
          icon: '➕',
          isBilateral: true,
          instructions: [
            'Petite haltère',
            'Dessiner croix lente',
            'Mini amplitude',
            '🔔 Changez de bras au signal',
          ],
        ),
      ],
    ),

    // ========== 4) RENFORCEMENT MOLLET - 3 min ==========
    Section(
      title: '4) Renfo mollet',
      emoji: '🟨',
      color: Colors.amber,
      exercises: [
        Exercise(
          title: 'Élévation jambe tendue',
          description: '2×10/côté',
          duration: 90,
          icon: '🦶',
          isBilateral: true,
          instructions: [
            'Contre mur',
            'Jambe tendue',
            'Montée lente',
            '🔔 Changez de côté au signal',
          ],
        ),
        Exercise(
          title: 'Élévation position fente',
          description: '10/jambe',
          duration: 90,
          icon: '🏋️',
          isBilateral: true,
          instructions: [
            'Position fente',
            'Amplitude contrôlée',
            '🔔 Changez de côté au signal',
          ],
        ),
      ],
    ),

    // ========== 5) GAINAGE - 2 min ==========
    Section(
      title: '5) Gainage',
      emoji: '🟥',
      color: Colors.red,
      exercises: [
        Exercise(
          title: 'Planche frontale',
          description: '40 secondes',
          duration: 40,
          icon: '🏋️',
          instructions: [
            'Sur les avant-bras',
            'Corps aligné',
            'Gainez abdos et fessiers',
          ],
        ),
        Exercise(
          title: 'Planche latérale gauche',
          description: '40 secondes',
          duration: 40,
          icon: '↙️',
          instructions: [
            'Avant-bras gauche au sol',
            'Hanches hautes',
            'Corps bien aligné',
          ],
        ),
        Exercise(
          title: 'Planche latérale droite',
          description: '40 secondes',
          duration: 40,
          icon: '↘️',
          instructions: [
            'Avant-bras droit au sol',
            'Hanches hautes',
            'Corps bien aligné',
          ],
        ),
      ],
    ),

    // ========== 6) ÉTIREMENTS - 2 min ==========
    Section(
      title: '6) Étirements finaux',
      emoji: '🟪',
      color: Colors.purple,
      exercises: [
        Exercise(
          title: 'Étirement ischio',
          description: '30 secondes',
          duration: 30,
          icon: '🧘',
          instructions: [
            'Debout',
            'Jambe tendue devant',
            'Penchez-vous doucement',
          ],
        ),
        Exercise(
          title: 'Étirement psoas',
          description: '30 sec/côté',
          duration: 60,
          icon: '🧎',
          isBilateral: true,
          instructions: [
            'Position chevalier',
            'Hanches vers avant',
            '🔔 Changez de côté au signal',
          ],
        ),
        Exercise(
          title: 'Étirement trapèze',
          description: '30 secondes',
          duration: 30,
          icon: '🙆',
          isBilateral: true,
          instructions: [
            'Inclinez tête',
            'Main sur tête',
            'Douceur',
            '🔔 Changez de côté au signal',
          ],
        ),
      ],
    ),
  ];
}
