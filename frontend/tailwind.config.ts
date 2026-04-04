import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        sand: {
          50: '#f8f6f2',
          100: '#f2ede6',
          200: '#e7ddd1',
          300: '#d5c6b4',
          400: '#c3ae96',
        },
        clay: {
          50: '#f2ede7',
          100: '#e7ddd1',
          200: '#d6c4af',
          300: '#bea489',
          400: '#a98765',
        },
        sage: {
          100: '#e2e6df',
          200: '#c6d0c1',
          300: '#9daf9f',
        },
        ink: {
          700: '#5a5148',
          800: '#3f372f',
          900: '#261f19',
        },
      },
      fontFamily: {
        heading: ['Fraunces', 'serif'],
        body: ['Plus Jakarta Sans', 'sans-serif'],
      },
      boxShadow: {
        soft: '0 18px 40px -32px rgba(50, 40, 28, 0.45)',
        panel: '0 24px 60px -40px rgba(50, 40, 28, 0.45)',
      },
      borderRadius: {
        soft: '1.1rem',
        bubble: '1.3rem',
        panel: '1.5rem',
        card: '1.75rem',
      },
      keyframes: {
        rise: {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
      animation: {
        rise: 'rise 320ms ease-out forwards',
        'rise-delayed': 'rise 420ms ease-out forwards',
      },
    },
  },
  plugins: [],
}

export default config
