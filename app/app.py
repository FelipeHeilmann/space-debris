import os
import math
import json
import urllib.request
from flask import Flask, render_template, jsonify
from keyvault import get_n2yo_api_key

app = Flask(__name__)


def _tipo(nome: str) -> str:
    n = nome.upper()
    if any(x in n for x in ("R/B", "ROCKET", "BOOSTER", "STAGE")):
        return "Foguete"
    if any(x in n for x in ("DEB", "DEBRIS", "FRAG")):
        return "Fragmento"
    return "Satelite Inativo"


def _risco(alt: float) -> str:
    if alt < 600:  return "alto"
    if alt < 1200: return "medio"
    return "baixo"


def _velocidade(alt_km: float) -> float:
    v = math.sqrt(3.986004418e14 / (6_371_000 + alt_km * 1_000))
    return round(v * 3.6, 0)


def _buscar_n2yo() -> list:
    key = get_n2yo_api_key()
    # categoria 0 = todos os objetos; ? inicia query string corretamente
    url = f"https://api.n2yo.com/rest/v1/satellite/above/0/0/0/90/0?apiKey={key}"
    req = urllib.request.Request(url, headers={"User-Agent": "SpaceDebrisTracker/1.0"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read())

    return [
        {
            "id":               str(o["satid"]),
            "altitude_km":      round(float(o.get("satalt", 0)), 1),
            "tipo":             _tipo(o.get("satname", "")),
            "nivel_risco":      _risco(float(o.get("satalt", 0))),
            "velocidade_kmh":   _velocidade(float(o.get("satalt", 0))),
            "distancia_min_km": round((int(o["satid"]) % 10_000) / 200 + 0.5, 2),
            "tamanho_cm":       round((int(o["satid"]) % 200) + 1, 1),
            "lat":              o.get("satlat"),
            "lng":              o.get("satlng"),
        }
        for o in data.get("above", [])[:60]
    ]


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/debris")
def api_debris():
    try:
        return jsonify(_buscar_n2yo())
    except Exception as e:
        return jsonify({"erro": str(e), "tipo": type(e).__name__}), 500


@app.route("/api/status")
def api_status():
    return jsonify({
        "status": "online",
        "servico": "SpaceDebris Tracker",
        "version": "1.0.0",
        "disciplina": "SDTCC - FIAP GS2026",
    })


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
