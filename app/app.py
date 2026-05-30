import os
import random
from flask import Flask, render_template, jsonify
from keyvault import get_n2yo_api_key

app = Flask(__name__)

N2YO_API_KEY = get_n2yo_api_key()


def gerar_detritos_simulados(n=60):
    tipos = ["Foguete", "Satelite Inativo", "Fragmento"]
    niveis = ["baixo", "medio", "alto"]
    random.seed(42)
    return [
        {
            "id": f"OBJ-{1000 + i}",
            "altitude_km": round(random.uniform(300, 2000), 1),
            "tipo": random.choice(tipos),
            "nivel_risco": random.choice(niveis),
            "velocidade_kmh": round(random.uniform(25000, 30000), 0),
            "distancia_min_km": round(random.uniform(0.5, 50), 2),
            "tamanho_cm": round(random.uniform(1, 200), 1),
        }
        for i in range(n)
    ]


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/debris")
def api_debris():
    return jsonify(gerar_detritos_simulados())


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
