# React + TypeScript + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) (or [oxc](https://oxc.rs) when used in [rolldown-vite](https://vite.dev/guide/rolldown)) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

# MindPal Frontend

A calm, minimal reflection interface for the MindPal FastAPI backend.

## Stack

- React + Vite + TypeScript
- Tailwind CSS
- React Router
- Axios
- Recharts

## Run Locally

1. Install dependencies:

```bash
npm install
```

2. Configure API base URL:

```bash
copy .env.example .env
```

`VITE_API_BASE_URL` defaults to `http://localhost:8000`.

3. Start the app:

```bash
npm run dev
```

4. Build for production:

```bash
npm run build
```

## Main Screens

- `/chat`: reflection chat with conversation sidebar
- `/insights`: emotion, habit, and time-pattern charts

## Backend Requirements

Run backend at `http://localhost:8000` with these endpoints available:

- `POST /chat`
- `GET /conversations`
- `POST /conversations`
- `DELETE /conversations/{id}`
- `GET /conversations/{id}/messages`
- `GET /insights/emotions`
- `GET /insights/habits`
- `GET /insights/time`
