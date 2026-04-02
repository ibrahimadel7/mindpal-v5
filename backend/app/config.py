import logging
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

# Resolve the path to the .env file relative to this config file's location.
# This ensures the .env file is found regardless of the current working directory.
_BACKEND_DIR = Path(__file__).resolve().parent.parent
_ENV_FILE_PATH = _BACKEND_DIR / ".env"

# Explicitly load the .env file at module import time.
# This ensures environment variables are available before pydantic-settings
# attempts to read them, regardless of how the application is started.
load_dotenv(dotenv_path=_ENV_FILE_PATH, override=False)


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
    llm_max_tokens: int = 160
    llm_timeout_seconds: int = 60
    llm_stream_connect_timeout_seconds: int = 15
    llm_stream_read_timeout_seconds: int = 180
    llm_stream_write_timeout_seconds: int = 30
    llm_max_retries: int = 3

    chroma_persist_dir: str = "./chroma_data"
    chroma_messages_collection: str = "mindpal_messages"
    chroma_kb_collection: str = "mindpal_kb"

    graph_state_path: str = "./mindpal_graph.json"

    retrieval_top_k_messages: int = 5
    retrieval_top_k_kb: int = 3

    memory_max_items: int = 10
    memory_summary_max_tokens: int = 120
    memory_summary_temperature: float = 0.1
    memory_summary_min_chars: int = 80

    cors_origins: str = Field(
        default="http://localhost:5173,http://127.0.0.1:5173,http://localhost:4173,http://127.0.0.1:4173",
        alias="CORS_ORIGINS",
    )
    cors_origin_regex: str = Field(
        default=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        alias="CORS_ORIGIN_REGEX",
    )

    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE_PATH),
        env_file_encoding="utf-8",
        extra="ignore",
        populate_by_name=True,
    )

    @field_validator("groq_api_key", mode="after")
    @classmethod
    def validate_groq_api_key(cls, value: str) -> str:
        """Validate that the Groq API key is set and not a placeholder value."""
        # Define exact placeholder values (lowercase for comparison)
        placeholder_values = {
            "",
            "your_groq_api_key_here",
            "your-api-key-here",
            "your_groq_key_here",
            "replace_with_your_groq_api_key",
            "gsk_xxx",  # Only reject exact 'gsk_xxx' placeholder, not valid keys
        }
        
        stripped = value.strip()
        
        # Debug logging to help users understand what's being loaded
        logger.debug(f"GROQ_API_KEY raw value: '{value}' (length: {len(value)})")
        logger.debug(f"GROQ_API_KEY stripped value: '{stripped}' (length: {len(stripped)})")
        
        # Check for empty string
        if not stripped:
            logger.warning(
                "GROQ_API_KEY is empty. "
                "LLM features will fall back to local heuristics. "
                "Set a valid key in %s or via the GROQ_API_KEY environment variable.",
                _ENV_FILE_PATH,
            )
            return ""
        
        # Check for exact placeholder match (case-insensitive)
        if stripped.lower() in {v.lower() for v in placeholder_values}:
            logger.warning(
                "GROQ_API_KEY is still a placeholder value ('%s'). "
                "LLM features will fall back to local heuristics. "
                "Set a valid key in %s or via the GROQ_API_KEY environment variable.",
                stripped,
                _ENV_FILE_PATH,
            )
            return ""
        
        # Valid key - must be at least 20 characters and start with 'gsk_' (actual Groq key format)
        if not stripped.lower().startswith("gsk_"):
            logger.warning(
                "GROQ_API_KEY does not appear to be a valid Groq API key format. "
                "Expected format: gsk_... "
                "LLM features may not work correctly.",
            )
            # Don't return empty - let it through but warn (more lenient)
        
        logger.info(f"GROQ_API_KEY configured successfully (length: {len(stripped)})")
        return stripped


@lru_cache
def get_settings() -> Settings:
    return Settings()
