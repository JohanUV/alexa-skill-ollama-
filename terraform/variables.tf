variable "ollama_host" {
  description = "URL del servidor Ollama"
  type        = string
  default     = "http://host.docker.internal:11434"
}

variable "ollama_model" {
  description = "Modelo de Ollama a utilizar"
  type        = string
  default     = "qwen3:1.7b"
}
