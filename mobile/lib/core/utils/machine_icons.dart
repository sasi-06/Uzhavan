import 'package:flutter/material.dart';

IconData machineIcon(String type) => switch (type) {
      'tractor' => Icons.agriculture,
      'harvester' => Icons.grass,
      'plough' => Icons.landslide,
      'seeder' => Icons.scatter_plot,
      'sprayer' => Icons.water_drop,
      _ => Icons.precision_manufacturing,
    };
