import json
import os
import urllib.request
import urllib.error


OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://host.docker.internal:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "qwen3:1.7b")

SYSTEM_PROMPT = (
    "Eres un asistente de voz integrado en Alexa. "
    "Responde de forma breve, clara y conversacional en español. "
    "Limita tus respuestas a 2-3 oraciones como máximo."
)


def call_ai(user_message):
    url = f"{OLLAMA_HOST}/api/chat"
    payload = json.dumps({
        "model": OLLAMA_MODEL,
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


def handle_launch():
    return build_response(
        "¡Hola! Soy tu asistente con inteligencia artificial. "
        "Pregúntame lo que quieras.",
        should_end=False,
    )


def handle_ask_ai(intent):
    slots = intent.get("slots", {})
    query_slot = slots.get("query", {})
    user_query = query_slot.get("value", "")

    if not user_query:
        return build_response(
            "No escuché tu pregunta. ¿Puedes repetirla?",
            should_end=False,
        )

    answer = call_ai(user_query)
    return build_response(answer, should_end=False)


def handle_stop():
    return build_response("¡Hasta luego! Fue un placer ayudarte.")


def handle_help():
    return build_response(
        "Puedes preguntarme cualquier cosa. Por ejemplo, di: "
        "pregúntale a la inteligencia, ¿cuál es la capital de Francia?",
        should_end=False,
    )


def handle_fallback():
    return build_response(
        "No entendí eso. Intenta decir: pregunta algo.",
        should_end=False,
    )


def lambda_handler(event, context):
    print(f"Event: {json.dumps(event)}")

    request = event.get("request", {})
    request_type = request.get("type", "")

    if request_type == "LaunchRequest":
        return handle_launch()

    if request_type == "IntentRequest":
        intent = request.get("intent", {})
        intent_name = intent.get("name", "")

        handlers = {
            "AskAIIntent": lambda: handle_ask_ai(intent),
            "AMAZON.StopIntent": handle_stop,
            "AMAZON.CancelIntent": handle_stop,
            "AMAZON.HelpIntent": handle_help,
            "AMAZON.FallbackIntent": handle_fallback,
        }

        handler = handlers.get(intent_name, handle_fallback)
        return handler()

    if request_type == "SessionEndedRequest":
        return build_response("")

    return handle_fallback()
