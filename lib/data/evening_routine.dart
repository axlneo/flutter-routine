import 'package:flutter/material.dart';
import '../models/models.dart';

/// Builds the evening routine sections for a specific day (40 minutes total)
/// Day 1 = Monday, Day 7 = Sunday
List<Section> buildEveningSections(int day) {
  return [
    _getHiitSection(),
    _getRenfoSection(day),
    _getStretchSection(),
  ];
}

/// Builds the short evening routine sections for a specific day (~20 minutes)
/// Échauffement rapide (5 min) + Renfo identique (~15 min)
List<Section> buildShortEveningSections(int day) {
  return [
    _getShortWarmupSection(),
    _getRenfoSection(day),
  ];
}

// ========== SHORT WARMUP (5 min) ==========
Section _getShortWarmupSection() {
  return Section(
    title: '1) Échauffement Rapide',
    emoji: '🔥',
    color: Colors.orange,
    exercises: [
      Exercise(
        title: 'Marche rapide sur place',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🚶',
        instructions: [
          'Montée de genoux contrôlée',
          'Bras actifs',
          'Rythme soutenu',
        ],
      ),
      Exercise(
        title: 'Squat lent contrôlé',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🏋️',
        instructions: [
          'Poids du corps',
          'Descente lente',
          'Cuisses parallèles',
        ],
      ),
      Exercise(
        title: 'Gainage haut sur banc',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🧘',
        instructions: [
          'Mains sur banc',
          'Corps aligné',
          'Respiration régulière',
        ],
      ),
      Exercise(
        title: 'Good morning',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🌅',
        instructions: [
          'Sans charge',
          'Charnière hanches',
          'Jambes légèrement fléchies',
        ],
      ),
      Exercise(
        title: 'Bird-dog',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🐦',
        isBilateral: true,
        instructions: [
          'Bras et jambe opposés',
          'Équilibre',
          '🔔 Alternez au signal',
        ],
      ),
    ],
  );
}

/// Day names for display
const List<String> dayNames = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// Day themes for display
const List<Map<String, String>> dayThemes = [
  {'day': 'Lundi', 'theme': 'Épaules', 'emoji': '💪'},
  {'day': 'Mardi', 'theme': 'Dos', 'emoji': '🔙'},
  {'day': 'Mercredi', 'theme': 'Jambes & Mollets', 'emoji': '🦵'},
  {'day': 'Jeudi', 'theme': 'Tronc', 'emoji': '🎯'},
  {'day': 'Vendredi', 'theme': 'Pec / Bras', 'emoji': '💪'},
  {'day': 'Samedi', 'theme': 'Full Body', 'emoji': '🏋️'},
  {'day': 'Dimanche', 'theme': 'Mobilité', 'emoji': '🧘'},
];

// ========== HIIT SECTION (same every day) ==========
Section _getHiitSection() {
  return Section(
    title: '1) HIIT Doux',
    emoji: '🔥',
    color: Colors.orange,
    exercises: [
      Exercise(
        title: 'Marche rapide sur place',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🚶',
        instructions: [
          'Montée de genoux contrôlée',
          'Bras actifs',
          'Rythme soutenu',
        ],
      ),
      Exercise(
        title: 'Squat lent contrôlé',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🏋️',
        instructions: [
          'Poids du corps',
          'Descente lente',
          'Cuisses parallèles',
        ],
      ),
      Exercise(
        title: 'Step-back lent',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🚶',
        isBilateral: true,
        instructions: [
          'Recul contrôlé',
          'Alternance jambes',
          '🔔 Alternez au signal',
        ],
      ),
      Exercise(
        title: 'Gainage haut sur banc',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🧘',
        instructions: [
          'Mains sur banc',
          'Corps aligné',
          'Respiration régulière',
        ],
      ),
      Exercise(
        title: 'Mountain climbers lents',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🏔️',
        instructions: [
          'Position planche',
          'Genoux vers poitrine',
          'Très contrôlé',
        ],
      ),
      Exercise(
        title: 'Good morning',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🌅',
        instructions: [
          'Sans charge',
          'Charnière hanches',
          'Jambes légèrement fléchies',
        ],
      ),
      Exercise(
        title: 'Marche latérale élastique',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '↔️',
        isBilateral: true,
        instructions: [
          'Élastique autour genoux',
          'Pas contrôlés',
          '🔔 Changez de sens au signal',
        ],
      ),
      Exercise(
        title: 'Planche sur genoux',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🧘',
        instructions: [
          'Genoux au sol',
          'Alignement parfait',
          'Core serré',
        ],
      ),
      Exercise(
        title: 'Chair pose dynamique',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🪑',
        instructions: [
          'Position chaise',
          'Montée/descente contrôlée',
          'Cuisses actives',
        ],
      ),
      Exercise(
        title: 'Bird-dog',
        description: '40s effort / 20s repos',
        duration: 60,
        icon: '🐦',
        isBilateral: true,
        instructions: [
          'Bras et jambe opposés',
          'Équilibre',
          '🔔 Alternez au signal',
        ],
      ),
    ],
  );
}

// ========== RENFORCEMENT SECTION (varies by day) ==========
Section _getRenfoSection(int day) {
  final exercises = <Exercise>[];
  String title = '';

  switch (day) {
    case 1: // Lundi - Épaules
      title = '2) Renfo Épaules';
      exercises.addAll([
        Exercise(
          title: 'Overhead press unilatéral',
          description: '3×10 reps/bras',
          duration: 300,
          icon: '💪',
          sets: 3,
          reps: 10,
          isBilateral: true,
          instructions: [
            'Curl → Rotation → Press',
            'Mouvement fluide',
            '🔔 Changez de bras au signal',
          ],
        ),
        Exercise(
          title: 'Rotation externe élastique',
          description: '3×12 reps/côté',
          duration: 240,
          icon: '↪️',
          sets: 3,
          reps: 12,
          isBilateral: true,
          instructions: [
            'Coude 90° collé au corps',
            'Rotation externe lente',
            '🔔 Changez au signal',
          ],
        ),
        Exercise(
          title: 'Shrugs',
          description: '3×12 reps',
          duration: 180,
          icon: '🔼',
          sets: 3,
          reps: 12,
          instructions: [
            'Haltères légers',
            'Épaules vers oreilles',
            'Contraction haute',
          ],
        ),
        Exercise(
          title: 'Face pull élastique',
          description: '3×15 reps',
          duration: 180,
          icon: '🎯',
          sets: 3,
          reps: 15,
          instructions: [
            'Tirage vers visage',
            'Coudes hauts',
            'Squeeze omoplates',
          ],
        ),
      ]);
      break;

    case 2: // Mardi - Dos
      title = '2) Renfo Dos';
      exercises.addAll([
        Exercise(
          title: 'Rowing unilatéral banc',
          description: '3×12 reps/bras',
          duration: 300,
          icon: '🚣',
          sets: 3,
          reps: 12,
          isBilateral: true,
          instructions: [
            'Main et genou sur banc',
            'Tirage coude vers hanches',
            '🔔 Changez de bras au signal',
          ],
        ),
        Exercise(
          title: 'Tirage élastique horizontal',
          description: '3×15 reps',
          duration: 180,
          icon: '↔️',
          sets: 3,
          reps: 15,
          instructions: [
            'Assis au sol',
            'Tirage vers nombril',
            'Serrez omoplates',
          ],
        ),
        Exercise(
          title: 'Bird dog chargé',
          description: '3×8 reps/côté',
          duration: 240,
          icon: '🐦',
          sets: 3,
          reps: 8,
          isBilateral: true,
          instructions: [
            'Haltère léger',
            'Extension bras/jambe opposés',
            '🔔 Changez au signal',
          ],
        ),
        Exercise(
          title: 'Superman',
          description: '3×10 reps',
          duration: 180,
          icon: '🦸',
          sets: 3,
          reps: 10,
          instructions: [
            'Ventre au sol',
            'Levez bras et jambes',
            'Tenez 2 secondes',
          ],
        ),
      ]);
      break;

    case 3: // Mercredi - Jambes & Mollets
      title = '2) Renfo Jambes';
      exercises.addAll([
        Exercise(
          title: 'Squat haltère léger',
          description: '3×12 reps',
          duration: 240,
          icon: '🏋️',
          sets: 3,
          reps: 12,
          instructions: [
            'Haltère goblet',
            'Descente contrôlée',
            'Cuisses parallèles',
          ],
        ),
        Exercise(
          title: 'Fente courte',
          description: '3×10 reps/jambe',
          duration: 300,
          icon: '🚶',
          sets: 3,
          reps: 10,
          isBilateral: true,
          instructions: [
            'Pas court',
            'Genou avant 90°',
            '🔔 Changez de jambe au signal',
          ],
        ),
        Exercise(
          title: 'Mollet jambe tendue',
          description: '3×8 reps/jambe',
          duration: 240,
          icon: '🦶',
          sets: 3,
          reps: 8,
          isBilateral: true,
          instructions: [
            'Sur marche ou step',
            'Montée lente et haute',
            '🔔 Changez au signal',
          ],
        ),
        Exercise(
          title: 'Mollet genou fléchi',
          description: '3×10 reps',
          duration: 180,
          icon: '🦵',
          sets: 3,
          reps: 10,
          instructions: [
            'Assis',
            'Poids sur cuisses',
            'Soléaire ciblé',
          ],
        ),
      ]);
      break;

    case 4: // Jeudi - Tronc
      title = '2) Renfo Tronc';
      exercises.addAll([
        Exercise(
          title: 'Dead bug',
          description: '3×12 reps',
          duration: 240,
          icon: '🪲',
          sets: 3,
          reps: 12,
          isBilateral: true,
          instructions: [
            'Dos au sol, bras/jambes en l\'air',
            'Extension opposée',
            '🔔 Alternez au signal',
          ],
        ),
        Exercise(
          title: 'Planche genoux',
          description: '3×30 sec',
          duration: 180,
          icon: '🧘',
          sets: 3,
          instructions: [
            'Genoux au sol',
            'Corps aligné',
            'Serrez le core',
          ],
        ),
        Exercise(
          title: 'Hollow hold léger',
          description: '3×20 sec',
          duration: 180,
          icon: '🥣',
          sets: 3,
          instructions: [
            'Dos au sol',
            'Jambes légèrement levées',
            'Bas du dos plaqué',
          ],
        ),
        Exercise(
          title: 'Rotation tronc élastique',
          description: '3×10 reps/côté',
          duration: 240,
          icon: '🔄',
          sets: 3,
          reps: 10,
          isBilateral: true,
          instructions: [
            'Debout, élastique fixé',
            'Rotation contrôlée',
            '🔔 Changez de côté au signal',
          ],
        ),
      ]);
      break;

    case 5: // Vendredi - Pec/Bras
      title = '2) Renfo Pec/Bras';
      exercises.addAll([
        Exercise(
          title: 'Développé haltère',
          description: '3×10 reps',
          duration: 240,
          icon: '🏋️',
          sets: 3,
          reps: 10,
          instructions: [
            'Sur banc ou sol',
            'Descente contrôlée',
            'Coudes 45°',
          ],
        ),
        Exercise(
          title: 'Pull-over léger',
          description: '3×10 reps',
          duration: 180,
          icon: '🔙',
          sets: 3,
          reps: 10,
          instructions: [
            'Un haltère',
            'Bras tendus',
            'Étirement pectoraux',
          ],
        ),
        Exercise(
          title: 'Curl biceps',
          description: '3×12 reps',
          duration: 180,
          icon: '💪',
          sets: 3,
          reps: 12,
          instructions: [
            'Haltères légers',
            'Contraction haute',
            'Descente lente',
          ],
        ),
        Exercise(
          title: 'Extension triceps élastique',
          description: '3×12 reps',
          duration: 180,
          icon: '💪',
          sets: 3,
          reps: 12,
          instructions: [
            'Élastique derrière',
            'Extension au-dessus tête',
            'Coudes fixes',
          ],
        ),
      ]);
      break;

    case 6: // Samedi - Full Body
      title = '2) Renfo Full Body';
      exercises.addAll([
        Exercise(
          title: 'Hinge haltère',
          description: '3×10 reps',
          duration: 180,
          icon: '🏋️',
          sets: 3,
          reps: 10,
          instructions: [
            'Romanian deadlift',
            'Hanches vers arrière',
            'Dos neutre',
          ],
        ),
        Exercise(
          title: 'Rowing élastique',
          description: '3×12 reps',
          duration: 180,
          icon: '🚣',
          sets: 3,
          reps: 12,
          instructions: [
            'Tirage horizontal',
            'Squeeze omoplates',
            'Retour contrôlé',
          ],
        ),
        Exercise(
          title: 'Step-up',
          description: '3×10 reps/jambe',
          duration: 300,
          icon: '📦',
          sets: 3,
          reps: 10,
          isBilateral: true,
          instructions: [
            'Sur banc ou marche',
            'Poussée jambe avant',
            '🔔 Changez de jambe au signal',
          ],
        ),
        Exercise(
          title: 'Press overhead bilatéral',
          description: '3×10 reps',
          duration: 180,
          icon: '⬆️',
          sets: 3,
          reps: 10,
          instructions: [
            'Deux haltères',
            'Press vertical',
            'Core engagé',
          ],
        ),
      ]);
      break;

    case 7: // Dimanche - Mobilité
      title = '2) Mobilité Active';
      exercises.addAll([
        Exercise(
          title: 'Overhead unilatéral',
          description: '2×10 reps/bras',
          duration: 180,
          icon: '🔼',
          sets: 2,
          reps: 10,
          isBilateral: true,
          instructions: [
            'Haltère très léger',
            'Amplitude complète',
            '🔔 Changez de bras au signal',
          ],
        ),
        Exercise(
          title: 'Proprioception croix',
          description: '2×1min/bras',
          duration: 240,
          icon: '➕',
          sets: 2,
          isBilateral: true,
          instructions: [
            'Petite haltère',
            'Dessiner croix lente',
            'Contrôle total',
            '🔔 Changez au signal',
          ],
        ),
        Exercise(
          title: 'Équilibre coussin',
          description: '2×45 sec/jambe',
          duration: 180,
          icon: '⚖️',
          sets: 2,
          isBilateral: true,
          instructions: [
            'Sur coussin ou Bosu',
            'Stabilité',
            '🔔 Changez au signal',
          ],
        ),
        Exercise(
          title: 'Squat lent profond',
          description: '3×10 reps',
          duration: 180,
          icon: '🏋️',
          sets: 3,
          reps: 10,
          instructions: [
            'Poids du corps',
            'Très contrôlé',
            'Amplitude max',
          ],
        ),
      ]);
      break;
  }

  return Section(
    title: title,
    emoji: '💪',
    color: Colors.blue,
    exercises: exercises,
  );
}

// ========== STRETCH SECTION (same every day) ==========
Section _getStretchSection() {
  return Section(
    title: '3) Stretch & Massage',
    emoji: '🧘',
    color: Colors.green,
    exercises: [
      Exercise(
        title: 'Automassage quadriceps',
        description: '3 minutes',
        duration: 180,
        icon: '🦵',
        instructions: [
          'Rouleau de massage',
          'Mouvements lents',
          'Insister sur points sensibles',
        ],
      ),
      Exercise(
        title: 'Stretch chaîne postérieure',
        description: '2 minutes',
        duration: 120,
        icon: '🧘',
        instructions: [
          'Ischios-jambiers',
          'Sans forcer',
          'Respiration profonde',
        ],
      ),
      Exercise(
        title: 'Étirement psoas',
        description: '2 minutes (1min/côté)',
        duration: 120,
        icon: '🧎',
        isBilateral: true,
        instructions: [
          'Position chevalier',
          'Poussez hanches vers avant',
          '🔔 Changez au signal',
        ],
      ),
      Exercise(
        title: 'Étirement trapèze/cou',
        description: '2 minutes (1min/côté)',
        duration: 120,
        icon: '🙆',
        isBilateral: true,
        instructions: [
          'Inclinez tête',
          'Main sur tête (douceur)',
          '🔔 Changez au signal',
        ],
      ),
      Exercise(
        title: 'Respiration finale',
        description: '1 minute',
        duration: 60,
        icon: '🫁',
        instructions: [
          'Allongé',
          'Respirations profondes',
          'Relâchement total',
        ],
      ),
    ],
  );
}
