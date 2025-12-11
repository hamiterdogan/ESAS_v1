#!/usr/bin/env python
# This script creates kurum_gorevlendirmesi_izin_screen.dart from hastalık_izin_screen.dart

import re

# Read the hastalık izin screen
with open('lib/features/izin_istek/screens/izin_turleri/hastalik_izin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove dart:io and file_picker imports
content = re.sub(r"import 'dart:io';?\n", '', content)
content = re.sub(r"import 'package:file_picker/file_picker.dart';?\n", '', content)

# Replace class names
content = content.replace('HastalikIzinScreen', 'KurumGorevlendirmesiIzinScreen')
content = content.replace('_HastalikIzinScreenState', '_KurumGorevlendirmesiIzinScreenState')
content = content.replace('Hastalik Izni Istek', 'Kurum Gorevlendirmesi Istek')

# Remove state variables
content = re.sub(r"  bool _acil = false;\n", '', content)
content = re.sub(r"  bool _doktorRaporuVar = false;\n", '', content)
content = re.sub(r"  File\? _doktorRaporuFile;\n", '', content)

# Remove _pickFile method
content = re.sub(r"  Future<void> _pickFile\(\) async \{.*?\n  \}\n\n", '', content, flags=re.DOTALL)

# Remove Acil Toggle section
acil_pattern = r"              // Acil Toggle\n              Row\(.*?const SizedBox\(height: 24\),\n\n"
content = re.sub(acil_pattern, '', content, flags=re.DOTALL)

# Remove Doktor Raporu Var Toggle section
doktor_toggle_pattern = r"              // Doktor Raporu Var Toggle\n              Row\(.*?const SizedBox\(height: 24\),\n"
content = re.sub(doktor_toggle_pattern, '', content, flags=re.DOTALL)

# Remove Doktor Raporu Dosya Yükleme conditional section
file_upload_pattern = r"\n              // Doktor Raporu Dosya Yükleme\n              if \(_doktorRaporuVar\).*?^\],\n"
content = re.sub(file_upload_pattern, '\n', content, flags=re.DOTALL | re.MULTILINE)

# Remove doktorRaporu from IzinIstekEkleReq
content = content.replace('doktorRaporu: _doktorRaporuVar,\n', '')

# Simplify submitForm - remove all the preview logic
submit_start = content.find('Future<void> _submitForm() async {')
submit_end = content.find('  Future<void> _showRequestPreview', submit_start)
if submit_start != -1 and submit_end != -1:
    new_submit = '''Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_baslangicTarihi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Baslangic tarihi seciniz')),
        );
        return;
      }

      if (_bitisTarihi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitis tarihi seciniz')),
        );
        return;
      }

      if (_aciklamaController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aciklama giriniz')),
        );
        return;
      }

      try {
        final request = IzinIstekEkleReq(
          izinSebebiId: 8,
          izinBaslangicTarihi: _baslangicTarihi!,
          izinBitisTarihi: _bitisTarihi!,
          aciklama: _aciklamaController.text,
          izindeBulunacagiAdres: _adresController.text,
          izinBaslangicSaat: _baslangicSaat,
          izinBaslangicDakika: _baslangicDakika,
          izinBitisSaat: _bitisSaat,
          izinBitisDakika: _bitisDakika,
          izindeGirilmeyenToplamDersSaati: _girileymeyenDersSaati,
          baskaPersonelId: _secilenPersonel?.personelId,
        );

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Istek gonderiliyor...'),
                ],
              ),
            ),
          );
        }

        final result =
            await ref.read(izinIstekRepositoryProvider).izinIstekEkle(request);

        if (mounted) {
          Navigator.of(context).pop();

          if (result is Success) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Basarili'),
                content:
                    const Text('Kurum gorevlendirmesi talebi gonderildi.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            );
          } else if (result is Failure) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Hata'),
                content: Text(result.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }
}
'''
    content = content[:submit_start] + new_submit

# Clean up extra whitespace
content = re.sub(r'\n\n\n+', '\n\n', content)

# Write the new file
with open('lib/features/izin_istek/screens/izin_turleri/kurum_gorevlendirmesi_izin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ kurum_gorevlendirmesi_izin_screen.dart created successfully!")
