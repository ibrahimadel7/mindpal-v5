from functools import lru_cache
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    app_name: str = "MindPal Backend"
    environment: str = "development"
    host: str = "0.0.0.0"
    port: int = 8000
    log_level: str = "INFO"

    database_url: str = "sqlite+aiosqlite:///./mindpal.db"

    groq_api_key: str = Field(default="", alias="GROQ_API_KEY")
    groq_model: str = "llama-3.3-70b-versatile"
    groq_embedding_model: str = "text-embedding-3-large"
    llm_temperature: float = 0.4
    llm_max_tokens: int = 700
    llm_timeout_seconds: int = 60
    llm_max_retries: int = 3

    chroma_persist_dir: str = "./chroma_data"
    chroma_messages_collection: str = "mindpal_messages"
    chroma_kb_collection: str = "mindpal_kb"

    graph_state_path: str = "./mindpal_graph.json"

    retrieval_top_k_messages: int = 5
    retrieval_top_k_kb: int = 3

    cors_origins: str = Field(default="http://localhost:5173", alias="CORS_ORIGINS")

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
