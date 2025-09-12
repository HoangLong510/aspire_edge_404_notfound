import 'package:flutter/material.dart';

class IndustryDef {
  final String id;      // 'it' | 'health' | 'art' | 'science'
  final String name;    // hiển thị
  final int order;      // để sort dropdown
  final IconData icon;  // optional

  const IndustryDef(this.id, this.name, this.order, this.icon);
}

const INDUSTRIES = <IndustryDef>[
  IndustryDef('it',      'Information Technology', 1, Icons.computer),
  IndustryDef('health',  'Healthcare',             2, Icons.health_and_safety),
  IndustryDef('art',     'Art',                    3, Icons.palette),
  IndustryDef('science', 'Science',                4, Icons.science),
];

// Helpers
IndustryDef? industryById(String? id) =>
    INDUSTRIES.firstWhere((e) => e.id == id, orElse: () => const IndustryDef('', '', 999, Icons.help));

IndustryDef? industryByName(String? name) =>
    INDUSTRIES.firstWhere((e) => e.name.toLowerCase() == (name ?? '').toLowerCase(),
        orElse: () => const IndustryDef('', '', 999, Icons.help));
