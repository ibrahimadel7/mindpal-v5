from __future__ import annotations

import json
from pathlib import Path

import networkx as nx

from app.config import get_settings


class GraphService:
    """NetworkX graph for user-message-emotion-habit relationships."""

    _instance: GraphService | None = None

    def __new__(cls) -> GraphService:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.graph = nx.Graph()
            cls._instance.settings = get_settings()
        return cls._instance

    def load_state(self) -> None:
        path = Path(self.settings.graph_state_path)
        if not path.exists():
            return
        data = json.loads(path.read_text(encoding="utf-8"))
        self.graph = nx.node_link_graph(data)

    def save_state(self) -> None:
        path = Path(self.settings.graph_state_path)
        data = nx.node_link_data(self.graph)
        path.write_text(json.dumps(data), encoding="utf-8")

    def update_relationships(
        self,
        user_id: int,
        message_id: int,
        emotions: list[dict],
        habits: list[dict],
    ) -> None:
        user_node = f"user:{user_id}"
        msg_node = f"message:{message_id}"
        self.graph.add_node(user_node, kind="User")
        self.graph.add_node(msg_node, kind="Message")
        self.graph.add_edge(user_node, msg_node, relation="authored")

        for emotion in emotions:
            e_node = f"emotion:{emotion['label']}"
            self.graph.add_node(e_node, kind="Emotion")
            self.graph.add_edge(msg_node, e_node, relation="expresses", weight=emotion.get("confidence", 0.5))

        for habit in habits:
            h_node = f"habit:{habit['habit']}"
            self.graph.add_node(h_node, kind="Habit")
            self.graph.add_edge(msg_node, h_node, relation="mentions", weight=habit.get("confidence", 0.5))

        for emotion in emotions:
            e_node = f"emotion:{emotion['label']}"
            for habit in habits:
                h_node = f"habit:{habit['habit']}"
                existing = self.graph.get_edge_data(e_node, h_node, default={}).get("weight", 0.0)
                self.graph.add_edge(e_node, h_node, relation="correlates", weight=existing + 1.0)

    def top_emotion_habit_correlations(self, top_k: int = 10) -> list[dict]:
        rows: list[dict] = []
        for u, v, attrs in self.graph.edges(data=True):
            if attrs.get("relation") == "correlates":
                rows.append({"from": u, "to": v, "weight": attrs.get("weight", 0.0)})
        rows.sort(key=lambda item: item["weight"], reverse=True)
        return rows[:top_k]

    def update_memory_relationships(self, *, habits: list[str], emotions: list[str]) -> None:
        clean_habits = [item.strip() for item in habits if str(item).strip()]
        clean_emotions = [item.strip() for item in emotions if str(item).strip()]
        for emotion in clean_emotions:
            e_node = f"emotion:{emotion}"
            self.graph.add_node(e_node, kind="Emotion")
            for habit in clean_habits:
                h_node = f"habit:{habit}"
                self.graph.add_node(h_node, kind="Habit")
                existing = self.graph.get_edge_data(e_node, h_node, default={}).get("weight", 0.0)
                self.graph.add_edge(e_node, h_node, relation="correlates", weight=existing + 1.0)
