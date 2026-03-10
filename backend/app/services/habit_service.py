from app.schemas.analysis import HabitDetectionResult
from app.services.llm_service import LLMService


class HabitService:
    """LLM-based habit extraction service."""

    def __init__(self, llm_service: LLMService | None = None) -> None:
        self.llm = llm_service or LLMService()

    async def detect_habits(self, message: str) -> HabitDetectionResult:
        system_prompt = (
            "You are a habit extraction system. Return valid JSON only in format "
            '{"habits":[{"habit":"studying","confidence":0.88}]}. '
            "Extract explicit or strongly implied user habits/behaviors."
        )
        user_prompt = f"Extract habits from this message: {message}"
        data = await self.llm.generate_structured_json(system_prompt=system_prompt, user_prompt=user_prompt)
        return HabitDetectionResult.model_validate(data)
