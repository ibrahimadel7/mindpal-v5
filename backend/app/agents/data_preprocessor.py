from __future__ import annotations

from typing import Any


class DataPreprocessor:
    """Convert structured graph and analytics data to natural language for LLM analysis."""

    @staticmethod
    def preprocess_habit_emotion_links(links: list[dict[str, Any]]) -> list[str]:
        """
        Convert habit-emotion associations to natural language.
        
        Example:
            Input: [{"habit": "late scrolling", "emotion": "anxiety", "link_strength": 0.7}]
            Output: ["Late scrolling often appears alongside anxiety (70% strength)"]
        """
        if not links:
            return []

        signals = []
        for link in links:
            habit = link.get("habit", "habit")
            emotion = link.get("emotion", "emotion")
            strength = link.get("link_strength", 0.0)
            strength_pct = int(strength * 100)

            signal = f"{habit.title()} often appears alongside {emotion} ({strength_pct}% co-occurrence)"
            signals.append(signal)

        return signals

    @staticmethod
    def preprocess_time_patterns(patterns: list[dict[str, Any]]) -> list[str]:
        """
        Convert time patterns to natural language.
        
        Example:
            Input: [{"hour_of_day": 22, "top_emotion": "stress", "message_count": 5}]
            Output: ["User shows stress spikes around 10 PM (5 messages)"]
        """
        if not patterns:
            return []

        signals = []
        for pattern in patterns:
            hour = pattern.get("hour_of_day", 0)
            emotion = pattern.get("top_emotion", "emotion")
            count = pattern.get("message_count", 1)

            # Convert 24-hour to 12-hour format
            if hour < 12:
                period = "AM"
                display_hour = hour if hour != 0 else 12
            else:
                period = "PM"
                display_hour = hour - 12 if hour != 12 else 12

            signal = f"User shows {emotion} spikes around {display_hour}:00 {period} ({count} messages)"
            signals.append(signal)

        return signals

    @staticmethod
    def preprocess_trend_summaries(emotion_stats: list[dict[str, Any]], habit_stats: list[dict[str, Any]]) -> list[str]:
        """
        Convert trend statistics to natural language.
        
        Example:
            Input (emotions): [{"label": "anxiety", "count": 8}]
            Input (habits): [{"habit": "late scrolling", "count": 6}]
            Output: ["Anxiety has been frequent (8 occurrences)", "Late scrolling is a recurring pattern (6 times)"]
        """
        signals = []

        for stat in emotion_stats:
            label = stat.get("label", "emotion")
            count = stat.get("count", 0)
            if count > 5:
                trend = "very frequent"
            elif count > 3:
                trend = "frequent"
            else:
                trend = "occasional"

            signal = f"{label.title()} has been {trend} ({count} occurrences)"
            signals.append(signal)

        for stat in habit_stats:
            habit = stat.get("habit", "habit")
            count = stat.get("count", 0)
            if count > 5:
                trend = "very recurring"
            elif count > 3:
                trend = "recurring"
            else:
                trend = "occasional"

            signal = f"{habit.title()} is a {trend} pattern ({count} times)"
            signals.append(signal)

        return signals
