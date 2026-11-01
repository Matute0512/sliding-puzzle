# Inspección Automática de Android Vitals (Google Play Developer Reporting API)

Esta herramienta conecta el entorno de desarrollo directamente con la **Google Play Developer Reporting API** para extraer y auditar en tiempo real:
- **Crashes (Fallas críticas / SIGSEGV / Excepciones no controladas)**
- **ANRs (Application Not Responding / Bloqueos del hilo principal)**
- **Stack traces completos desofuscados**
- **Dispositivos y versiones de Android afectadas**

---

## 🔐 Configuración de Credenciales

El script detecta automáticamente las credenciales en el siguiente orden de prioridad:

1. Variable de entorno `PLAY_CONSOLE_CREDENTIALS` o `GOOGLE_APPLICATION_CREDENTIALS`.
2. Archivos en la raíz del proyecto coincidentes con:
   - `sliding-puzzle-*.json`
   - `play_service_account*.json`
   - `.credentials/*.json`

> [!NOTE]
> Todos estos patrones están protegidos en `.gitignore` para evitar filtraciones accidentales al repositorio git.

---

## 🚀 Uso del Script

Requisitos:
```bash
py -m pip install -r tools/play_reporting/requirements.txt
```

### Comandos frecuentes:

```bash
# Consultar los últimos reportes y stack traces
py tools/play_reporting/fetch_vitals.py

# Ver solo problemas agrupados sin el volcado completo de stack traces
py tools/play_reporting/fetch_vitals.py --no-traces

# Filtrar únicamente por Crashes
py tools/play_reporting/fetch_vitals.py --type CRASH

# Filtrar únicamente por ANRs
py tools/play_reporting/fetch_vitals.py --type APPLICATION_NOT_RESPONDING

# Exportar datos crudos en JSON
py tools/play_reporting/fetch_vitals.py --json
```

---

## 🤖 Cómo solicitar la inspección a Antigravity

Podés pedir en cualquier momento:
- *"Revisá los últimos crashes de Play Console y decime si hay errores nuevos en producción."*
- *"Ejecutá el script de Android Vitals e inspeccioná el stack trace del último ANR para proponer una corrección."*
- *"Consultá si la versión v3.2.2+23 registró fallas en Play Console."*

