from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.request
import urllib.error

OLLAMA_HOST = "http://localhost:11434"
OLLAMA_MODEL = "qwen3:0.6b"

SYSTEM_PROMPT = (
    "Eres un asistente de voz integrado en Alexa. "
    "Responde de forma breve, clara y conversacional en español. "
    "Limita tus respuestas a 2-3 oraciones como maximo."
)


def warmup_model():
    print("Precargando modelo en memoria...")
    try:
        payload = json.dumps({
            "model": OLLAMA_MODEL,
            "keep_alive": "60m",
            "messages": [{"role": "user", "content": "hola /no_think"}],
            "stream": False,
        }).encode("utf-8")
        req = urllib.request.Request(
            f"{OLLAMA_HOST}/api/chat", data=payload,
            headers={"Content-Type": "application/json"}, method="POST",
        )
        with urllib.request.urlopen(req, timeout=60) as resp:
            resp.read()
        print("Modelo precargado y listo!")
    except Exception as exc:
        print(f"Error precargando modelo: {exc}")


def call_ollama(user_message):
    url = f"{OLLAMA_HOST}/api/chat"
    payload = json.dumps({
        "model": OLLAMA_MODEL,
        "keep_alive": "60m",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message + " /no_think"},
        ],
        "stream": False,
    }).encode("utf-8")

    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            body = json.loads(resp.read().decode("utf-8"))
            return body["message"]["content"]
    except (urllib.error.URLError, KeyError, IndexError) as exc:
        print(f"Error calling Ollama: {exc}")
        return "Lo siento, no pude procesar tu solicitud en este momento."


def build_response(speech, should_end=True):
    return {
        "version": "1.0",
        "response": {
            "outputSpeech": {
                "type": "PlainText",
                "text": speech,
            },
            "shouldEndSession": should_end,
        },
    }


def handle_request(event):
    request = event.get("request", {})
    request_type = request.get("type", "")

    if request_type == "LaunchRequest":
        return build_response(
            "Hola! Soy tu asistente con inteligencia artificial. Preguntame lo que quieras.",
            should_end=False,
        )

    if request_type == "IntentRequest":
        intent = request.get("intent", {})
        intent_name = intent.get("name", "")

        if intent_name == "AskAIIntent":
            slots = intent.get("slots", {})
            query = slots.get("query", {}).get("value", "")
            if not query:
                return build_response("No escuche tu pregunta. Puedes repetirla?", should_end=False)
            answer = call_ollama(query)
            return build_response(answer, should_end=False)

        if intent_name in ("AMAZON.StopIntent", "AMAZON.CancelIntent"):
            return build_response("Hasta luego! Fue un placer ayudarte.")

        if intent_name == "AMAZON.HelpIntent":
            return build_response(
                "Puedes preguntarme cualquier cosa. Por ejemplo, di: preguntale que es la gravedad.",
                should_end=False,
            )

    if request_type == "SessionEndedRequest":
        return build_response("")

    return build_response("No entendi eso. Intenta decir: pregunta algo.", should_end=False)


class AlexaHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)
        event = json.loads(body.decode("utf-8"))

        print(f"Request: {event.get('request', {}).get('type', 'unknown')}")
        response = handle_request(event)

        response_body = json.dumps(response).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_body)))
        self.end_headers()
        self.wfile.write(response_body)

    def log_message(self, format, *args):
        print(f"[Alexa] {args[0]}")


if __name__ == "__main__":
    warmup_model()
    port = 5000
    server = HTTPServer(("0.0.0.0", port), AlexaHandler)
    print(f"Servidor Alexa corriendo en http://localhost:{port}")
    print("Esperando requests de Alexa...")
    server.serve_forever()
