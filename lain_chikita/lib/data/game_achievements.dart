import 'package:fifty_achievement_engine/fifty_achievement_engine.dart' as fifty;

const List<fifty.Achievement> achievementList = [
  // --- INCREMENTALES (CountCondition) ---
  fifty.Achievement(
    id: 'beginner',
    name: 'Beginner',
    description: 'This is just the beginning',
    condition: fifty.CountCondition('level_up', target: 1), // 1 level up to unlock
    rarity: fifty.AchievementRarity.common,
    points: 50,
  ),
  fifty.Achievement(
    id: 'love_is_in_the_air',
    name: 'Love is in the air',
    description: 'Love is in the air',
    condition: fifty.CountCondition('level_up', target: 50),
    rarity: fifty.AchievementRarity.uncommon,
    points: 100,
  ),
  fifty.Achievement(
    id: 'lain_chikita_lover',
    name: 'Lain Chikita lover',
    description: "Let's All Love Lain Chikita",
    condition: fifty.CountCondition('level_up', target: 100),
    rarity: fifty.AchievementRarity.rare,
    points: 200,
  ),
  fifty.Achievement(
    id: 'cereal_enjoyer',
    name: 'Cereal enjoyer',
    description: "You really love cereal, don't you?",
    condition: fifty.CountCondition('level_up', target: 1000),
    rarity: fifty.AchievementRarity.epic,
    points: 500,
  ),
  fifty.Achievement(
    id: 'love_miner',
    name: 'Love miner',
    description: "You really love mining, don't you?",
    condition: fifty.CountCondition('level_up', target: 5000),
    rarity: fifty.AchievementRarity.legendary,
    points: 1000,
  ),

  // --- DESBLOQUEABLES 1 VEZ (EventCondition) ---
  fifty.Achievement(
    id: 'god_is_watching_you',
    name: 'God is watching you',
    description: "God is watching you, but you don't need to be afraid",
    condition: fifty.EventCondition('god_is_watching_you'),
    rarity: fifty.AchievementRarity.legendary,
    points: 1000,
    hidden: true,
  ),
  fifty.Achievement(
    id: 'keep_your_love_safe',
    name: 'Keep your love safe',
    description: 'Save your progress',
    condition: fifty.EventCondition('keep_your_love_safe'),
    rarity: fifty.AchievementRarity.common,
    points: 100,
  ),
  fifty.Achievement(
    id: 'welcome_to_the_wired',
    name: 'Welcome to the Wired',
    description: 'Load your progress',
    condition: fifty.EventCondition('welcome_to_the_wired'),
    rarity: fifty.AchievementRarity.uncommon,
    points: 200,
  ),
  fifty.Achievement(
    id: 'lets_all_love_lain',
    name: "Let's All Love Lain",
    description: "Let's All Love Lain",
    condition: fifty.EventCondition('lets_all_love_lain'),
    rarity: fifty.AchievementRarity.legendary,
    points: 1000,
    hidden: true,
  ),
  fifty.Achievement(
    id: 'pretty_girl',
    name: 'Pretty girl',
    description: "You're so pretty",
    condition: fifty.EventCondition('pretty_girl'),
    rarity: fifty.AchievementRarity.rare,
    points: 200,
  ),
  fifty.Achievement(
    id: 'i_have_lost_it_all',
    name: 'I have lost it all',
    description: 'Oops! you lost your money',
    condition: fifty.EventCondition('i_have_lost_it_all'),
    rarity: fifty.AchievementRarity.legendary,
    points: 1000,
    hidden: true,
  ),
];
