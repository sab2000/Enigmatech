# --- Full organize_enigmator.ps1 ---
$projectRoot = "C:\Users\Asus\enigmator_techno"
$libPath = Join-Path $projectRoot "lib"
$modelsPath = Join-Path $libPath "models"

# Create folders
New-Item -ItemType Directory -Path $libPath, $modelsPath -Force

# Generate main.dart
@"
import 'package:flutter/material.dart';
import 'package:enigmator_techno/password_gate.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enigmator Techno',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const PasswordGate(),
    );
  }
}
"@ | Out-File -Encoding UTF8 (Join-Path $libPath "main.dart")

Write-Output "✅ All files generated in $libPath"
