**Start api e apk
==== C:\Users\Harliton\Desktop\TCC\app\meu_bebe_mobile\api> =====**
.\.venv\Scripts\Activate.ps1
python -m uvicorn meu_bebe_api.main:app --host 0.0.0.0 --port 8000

==== C:\Users\Harliton\Desktop\TCC\app\meu_bebe_mobile> =====
# Configurar a URL da API em env-meu-bebe.json (chave única "API_BASE_URL")
flutter build apk --release --dart-define=API_BASE_URL=apiUrl
