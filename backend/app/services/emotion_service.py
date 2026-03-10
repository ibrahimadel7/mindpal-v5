from app.schemas.analysis import EmotionDetectionResult
from app.services.llm_service import LLMService

ALLOWED_EMOTIONS = {"joy", "sadness", "anger", "fear", "anxiety", "stress", "neutral"}


class EmotionService:
    """LLM-based emotion extraction service."""

    def __init__(self, llm_service: LLMService | None = None) -> None:
        self.llm = llm_service or LLMService()

    async def detect_emotions(self, message: str) -> EmotionDetectionResult:
        system_prompt = (
            "You are an emotion extraction system. Return valid JSON only in format "
            '{"emotions":[{"label":"sadness","confidence":0.8}]}. '
            "Use only: joy, sadness, anger, fear, anxiety, stress, neutral."
        )
        user_prompt = f"Extract emotions from this message: {message}"
        data = await self.llm.generate_structured_json(system_prompt=system_prompt, user_prompt=user_prompt)
        result = EmotionDetectionResult.model_validate(data)
        filtered = [e for e in result.emotions if e.label in ALLOWED_EMOTIONS]
        if not filtered:
            filtered = [EmotionDetectionResult.model_validate({"emotions": [{"label": "neutral", "confidence": 0.6}]}).emotions[0]]
        return EmotionDetectionResult(emotions=filtered)
