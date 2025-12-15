#!/usr/bin/env python3
# -*- coding: utf-8 -*-

file_path = r'C:\Users\User\Desktop\projects\flutter\esas_v1\lib\features\izin_istek\screens\izin_ekle_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 1982 (0-indexed = 1981) çevresinde değişiklik yap
old_start = 1981  # 0-indexed for line 1982
old_end = 1990    # 0-indexed for line 1991

new_lines = lines[:old_start] + [
    "    ref.read(izinIstekRepositoryProvider).izinIstekEkle(request);\n",
    "    \n",
    "    // Provider'ları yenile\n",
    "    ref.refresh(devamEdenIsteklerimProvider);\n",
    "    ref.refresh(tamamlananIsteklerimProvider);\n",
    "    \n",
    "    ScaffoldMessenger.of(context).showSnackBar(\n",
    "      const SnackBar(\n",
    "        content: Text('İzin isteği başarıyla oluşturuldu'),\n",
    "        backgroundColor: Colors.green,\n",
    "      ),\n",
    "    );\n",
    "    Navigator.pop(context);\n",
] + lines[old_end:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("File updated successfully")
