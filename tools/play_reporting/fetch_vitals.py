#!python
"""Herramienta de inspección de Android Vitals (Crashes & ANRs)

Consulta la Google Play Developer Reporting API (v1beta1) para extraer
problemas agrupados (errorIssues) y reportes individuales con stack trace (errorReports).
"""

import argparse
import datetime
import json
import os
import sys
from pathlib import Path

# Asegurar compatibilidad de encoding en terminales Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

try:
    import requests
    from google.auth.transport.requests import Request
    from google.oauth2 import service_account
except ImportError:
    print(
        "ERROR: Faltan dependencias. Instálalas ejecutando:\n"
        "  py -m pip install -r tools/play_reporting/requirements.txt",
        file=sys.stderr,
    )
    sys.exit(1)

SCOPES = ["https://www.googleapis.com/auth/playdeveloperreporting"]
DEFAULT_PACKAGE_NAME = "dev.matute.slidingpuzzle"
API_BASE = "https://playdeveloperreporting.googleapis.com/v1beta1"


def find_credentials_file() -> Path | None:
    """Busca el archivo de credenciales de la cuenta de servicio."""
    # 1. Variable de entorno explícita
    for env_var in [
        "PLAY_CONSOLE_CREDENTIALS",
        "GOOGLE_APPLICATION_CREDENTIALS",
    ]:
        env_val = os.getenv(env_var)
        if env_val and Path(env_val).exists():
            return Path(env_val)

    # 2. Archivos en la raíz del proyecto
    root_dir = Path(__file__).resolve().parent.parent.parent
    patterns = [
        "sliding-puzzle-*.json",
        "play_service_account*.json",
        ".credentials/*.json",
    ]
    for pattern in patterns:
        matches = list(root_dir.glob(pattern))
        if matches:
            return matches[0]

    return None


def get_authenticated_session(creds_path: Path) -> requests.Session:
    """Genera una sesión HTTP con el token OAuth2 Bearer de Google."""
    creds = service_account.Credentials.from_service_account_file(
        str(creds_path), scopes=SCOPES
    )
    creds.refresh(Request())

    session = requests.Session()
    session.headers.update(
        {
            "Authorization": f"Bearer {creds.token}",
            "Accept": "application/json",
        }
    )
    return session


def _build_interval_params(days: int) -> dict[str, int]:
    """Genera los parámetros DateTimeInterval para Google Play Developer Reporting API.

    La API exige fechas UTC alineadas a la hora (minutos y segundos omitidos o en cero).
    """
    now = datetime.datetime.now(datetime.timezone.utc)
    past = now - datetime.timedelta(days=days)
    return {
        "interval.startTime.year": past.year,
        "interval.startTime.month": past.month,
        "interval.startTime.day": past.day,
        "interval.startTime.hours": 0,
        "interval.endTime.year": now.year,
        "interval.endTime.month": now.month,
        "interval.endTime.day": now.day,
        "interval.endTime.hours": now.hour,
    }


def fetch_error_issues(
    session: requests.Session,
    package_name: str,
    page_size: int = 10,
    filter_type: str = "ALL",
    days: int = 14,
) -> list[dict]:
    """Obtiene el listado agrupado de problemas de estabilidad (Crashes / ANRs)."""
    url = f"{API_BASE}/apps/{package_name}/errorIssues:search"
    params: dict = {"pageSize": page_size}
    params.update(_build_interval_params(days))

    filters = []
    if filter_type in ("ANR", "CRASH"):
        filters.append(f"errorIssueType = {filter_type}")

    if filters:
        params["filter"] = " AND ".join(filters)

    resp = session.get(url, params=params)
    if resp.status_code != 200:
        print(f"Error {resp.status_code} al consultar errorIssues: {resp.text}", file=sys.stderr)
        return []

    return resp.json().get("errorIssues", [])


def fetch_error_reports(
    session: requests.Session,
    package_name: str,
    page_size: int = 10,
    filter_type: str = "ALL",
    days: int = 14,
) -> list[dict]:
    """Obtiene los últimos reportes individuales con stack trace."""
    url = f"{API_BASE}/apps/{package_name}/errorReports:search"
    params: dict = {"pageSize": page_size}
    params.update(_build_interval_params(days))

    filters = []
    if filter_type in ("ANR", "CRASH"):
        filters.append(f"errorIssueType = {filter_type}")

    if filters:
        params["filter"] = " AND ".join(filters)

    resp = session.get(url, params=params)
    if resp.status_code != 200:
        print(f"Error {resp.status_code} al consultar errorReports: {resp.text}", file=sys.stderr)
        return []

    return resp.json().get("errorReports", [])


def print_markdown_summary(issues: list[dict], reports: list[dict], show_stacktraces: bool = True):
    print("\n# 📊 Reporte de Estabilidad — Google Play Console (Android Vitals)")
    print(f"Total de problemas agrupados encontrados: **{len(issues)}**")
    print(f"Total de reportes individuales analizados: **{len(reports)}**\n")

    if issues:
        print("## 🚨 Problemas Agrupados (Error Issues)\n")
        print("| Tipo | Causa Principal | Ubicación | Ocurrencias | Usuarios | Última Vez |")
        print("| :--- | :--- | :--- | :---: | :---: | :--- |")
        for issue in issues:
            tipo = issue.get("type", "UNKNOWN")
            tipo_icon = "💥 CRASH" if tipo == "CRASH" else "⏳ ANR" if tipo in ("ANR", "APPLICATION_NOT_RESPONDING") else tipo
            causa = issue.get("cause", "N/A").replace("|", "\\|")
            if len(causa) > 60:
                causa = causa[:57] + "..."
            ubicacion = issue.get("location", "N/A")
            report_count = issue.get("errorReportCount", "0")
            users = issue.get("distinctUsers", "0")
            last_time = issue.get("lastErrorReportTime", "N/A").replace("T", " ").replace("Z", " UTC")
            print(f"| {tipo_icon} | `{causa}` | `{ubicacion}` | {report_count} | {users} | {last_time} |")
        print()

    if reports and show_stacktraces:
        print("## 🔍 Detalle de Stack Traces Recientes\n")
        for i, rep in enumerate(reports, 1):
            tipo = rep.get("type", "UNKNOWN")
            time_str = rep.get("eventTime", "N/A").replace("T", " ").replace("Z", " UTC")
            dev_info = rep.get("deviceModel", {})
            marketing = dev_info.get("marketingName", "Dispositivo desconocido")
            device_id = dev_info.get("deviceId", {})
            brand = device_id.get("buildBrand", "")
            os_ver = rep.get("osVersion", {}).get("apiLevel", "N/A")
            app_ver = rep.get("appVersion", {}).get("versionCode", "N/A")

            print(f"### #{i} — [{tipo}] {brand} {marketing} (Android API {os_ver}) | Versión app: {app_ver}")
            print(f"**Fecha:** {time_str}")
            print("```text")
            report_text = rep.get("reportText", "Sin stack trace disponible.")
            lines = report_text.strip().splitlines()
            if len(lines) > 40:
                print("\n".join(lines[:40]))
                print(f"\n... [{len(lines) - 40} líneas adicionales omitidas] ...")
            else:
                print("\n".join(lines))
            print("```\n")


def main():
    parser = argparse.ArgumentParser(description="Consulta Google Play Developer Reporting API")
    parser.add_argument("--package", default=DEFAULT_PACKAGE_NAME, help="Package name de la app")
    parser.add_argument("--creds", help="Ruta al archivo JSON de credenciales")
    parser.add_argument("--type", choices=["ALL", "CRASH", "ANR"], default="ALL", help="Filtrar por tipo")
    parser.add_argument("--days", type=int, default=14, help="Días hacia atrás a consultar (default: 14)")
    parser.add_argument("--limit", type=int, default=10, help="Cantidad máxima de elementos a consultar")
    parser.add_argument("--no-traces", action="store_true", help="No imprimir los stack traces detallados")
    parser.add_argument("--json", action="store_true", help="Salida en formato JSON crudo")

    args = parser.parse_args()

    creds_path = Path(args.creds) if args.creds else find_credentials_file()
    if not creds_path or not creds_path.exists():
        print(
            "ERROR: No se encontró el archivo de credenciales de la cuenta de servicio.\n"
            "Guárdalo en la raíz del proyecto como 'sliding-puzzle-*.json' o define PLAY_CONSOLE_CREDENTIALS.",
            file=sys.stderr,
        )
        sys.exit(1)

    session = get_authenticated_session(creds_path)
    issues = fetch_error_issues(
        session, args.package, page_size=args.limit, filter_type=args.type, days=args.days
    )
    reports = fetch_error_reports(
        session, args.package, page_size=args.limit, filter_type=args.type, days=args.days
    )

    if args.json:
        print(json.dumps({"errorIssues": issues, "errorReports": reports}, indent=2))
    else:
        print_markdown_summary(issues, reports, show_stacktraces=not args.no_traces)


if __name__ == "__main__":
    main()
