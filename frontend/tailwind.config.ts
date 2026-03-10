import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        sand: {
          50: '#f8f4ef',
          100: '#f1e9df',
          200: '#e5d8c8',
          300: '#d7c4ad',
          400: '#c5aa89',
        },
        clay: {
          50: '#f5f1ed',
          100: '#ece1d6',
          200: '#dbc6b0',
          300: '#c6a88e',
          400: '#ae8669',
        },
        sage: {
          100: '#dfe5db',
          200: '#c1ceb9',
          300: '#9fb194',
        },
        ink: {
          700: '#51463d',
          800: '#3f362f',
          900: '#2b2520',
        },
      },
      fontFamily: {
        heading: ['Cormorant Garamond', 'serif'],
        body: ['Nunito Sans', 'sans-serif'],
      },
      boxShadow: {
        soft: '0 10px 30px -16px rgba(63, 54, 47, 0.28)',
      },
      borderRadius: {
        soft: '1rem',
        bubble: '1.15rem',
      },
      keyframes: {
        rise: {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
      animation: {
        rise: 'rise 320ms ease-out forwards',
      },
    },
  },
  plugins: [],
}

export default config
