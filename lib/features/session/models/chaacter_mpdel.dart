import 'package:flutter/material.dart';

class Character {
  final String id;
  final String name;
  final String imageUrl;
  final String role;
  final Color bgColor;

  const Character({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.role,
    required this.bgColor,
  });
}

// Sample characters using dicebear avatar API (free, no key needed)
const List<Character> sampleCharacters = [
  Character(
    id: '1',
    name: 'Alex',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Alex',
    role: 'Hero',
    bgColor: Color(0xFFBBDEFB),
  ),
  Character(
    id: '2',
    name: 'Maya',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Maya',
    role: 'Wizard',
    bgColor: Color(0xFFF8BBD0),
  ),
  Character(
    id: '3',
    name: 'Zack',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Zack',
    role: 'Warrior',
    bgColor: Color(0xFFD7CCC8),
  ),
  Character(
    id: '4',
    name: 'Luna',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Luna',
    role: 'Archer',
    bgColor: Color(0xFFE1BEE7),
  ),
  Character(
    id: '5',
    name: 'Rex',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Rex',
    role: 'Knight',
    bgColor: Color(0xFFC8E6C9),
  ),
  Character(
    id: '6',
    name: 'Nora',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Nora',
    role: 'Healer',
    bgColor: Color(0xFFFFF9C4),
  ),
  Character(
    id: '7',
    name: 'Finn',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Finn',
    role: 'Rogue',
    bgColor: Color(0xFFFFCCBC),
  ),
  Character(
    id: '8',
    name: 'Iris',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Iris',
    role: 'Mage',
    bgColor: Color(0xFFB2EBF2),
  ),
];
