from app.schemas.analysis import HabitDetectionResult
from app.services.llm_service import LLMService


class HabitService:
    """LLM-based habit extraction service."""

    def __init__(self, llm_service: LLMService | None = None) -> None:
        self.llm = llm_service or LLMService()

    async def detect_habits(self, message: str) -> HabitDetectionResult:
        system_prompt = (
            "You are a behavior and habit extraction system.\n\n"
            "Return ONLY valid JSON:\n"
            '{"habits":[{"habit":"late phone use","confidence":0.85}]}\n\n'
            "Rules:\n\n"
            "- Extract only recurring or meaningful behaviors (not one-time actions)\n"
            "- Prefer specific habits over generic ones\n"
            "  (\"scrolling late at night\" > \"phone use\")\n"
            "- Include implied habits only if strongly supported\n"
            "- Max 3 habits"
        )
        user_prompt = f"Extract habits from:\n{message}"
        data = await self.llm.generate_structured_json(system_prompt=system_prompt, user_prompt=user_prompt)
        return HabitDetectionResult.model_validate(data)
