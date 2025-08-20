// Byte Design System - TypeScript Tokens
// Converted from web/styles/tokens/

export const tokens = {
  // Spacing (converted from rem to pixel values for React Native)
  space: {
    px: 1,
    0: 0,
    1: 4,   // 0.25rem
    2: 8,   // 0.5rem
    3: 12,  // 0.75rem
    4: 16,  // 1rem
    5: 20,  // 1.25rem
    6: 24,  // 1.5rem
    8: 32,  // 2rem
    10: 40, // 2.5rem
    12: 48, // 3rem
    16: 64, // 4rem
    20: 80, // 5rem
    24: 96, // 6rem
  },

  // Font families
  fonts: {
    mono: 'JetBrains Mono, SF Mono, Monaco, Inconsolata, Roboto Mono, monospace',
    sans: 'system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif',
  },

  // Font sizes (converted to pixel values)
  fontSize: {
    xs: 12,   // 0.75rem
    sm: 14,   // 0.875rem
    base: 16, // 1rem
    lg: 18,   // 1.125rem
    xl: 20,   // 1.25rem
    '2xl': 24, // 1.5rem
    '3xl': 30, // 1.875rem
    '4xl': 36, // 2.25rem
  },

  // Font weights
  fontWeight: {
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
  },

  // Line heights
  lineHeight: {
    none: 1,
    tight: 1.25,
    normal: 1.5,
    relaxed: 1.75,
  },

  // Border radius (converted to pixel values)
  borderRadius: {
    none: 0,
    sm: 2,   // 0.125rem
    base: 4, // 0.25rem
    md: 6,   // 0.375rem
    lg: 8,   // 0.5rem
    xl: 12,  // 0.75rem
    '2xl': 16, // 1rem
    full: 9999,
  },

  // Border widths
  borderWidth: {
    0: 0,
    1: 1,
    2: 2,
    4: 4,
  },

  // Colors (RGB values for easy manipulation)
  colors: {
    // Background colors (dark theme)
    bg: {
      primary: [17, 24, 39],     // gray-900
      secondary: [31, 41, 55],   // gray-800
      tertiary: [55, 65, 81],    // gray-700
    },
    
    // Text colors
    text: {
      primary: [243, 244, 246],  // gray-100
      secondary: [209, 213, 219], // gray-300
      muted: [156, 163, 175],    // gray-400
      inverse: [17, 24, 39],     // gray-900
    },

    // Border colors
    border: {
      primary: [55, 65, 81],     // gray-700
      secondary: [75, 85, 99],   // gray-600
      muted: [107, 114, 128],    // gray-500
    },

    // Interactive colors
    interactive: {
      primary: [34, 197, 94],     // green-500
      primaryHover: [22, 163, 74], // green-600
      danger: [239, 68, 68],      // red-500
      dangerHover: [220, 38, 38], // red-600
      warning: [245, 158, 11],    // amber-500
      info: [59, 130, 246],       // blue-500
    },

    // Status colors
    status: {
      success: [34, 197, 94],     // green-500
      error: [239, 68, 68],       // red-500
      warning: [245, 158, 11],    // amber-500
      info: [59, 130, 246],       // blue-500
    },
  },

  // Component-specific tokens
  components: {
    button: {
      height: {
        sm: 32,   // 2rem
        base: 40, // 2.5rem
        lg: 48,   // 3rem
      },
      padding: {
        sm: 12,   // 0.75rem
        base: 16, // 1rem
        lg: 24,   // 1.5rem
      },
    },
    
    input: {
      height: {
        sm: 32,   // 2rem
        base: 40, // 2.5rem
        lg: 48,   // 3rem
      },
    },

    header: {
      height: 56, // 3.5rem
    },

    sidebar: {
      width: 256,      // 16rem
      widthCollapsed: 48, // 3rem
    },
  },

  // Shadows (adapted for React Native)
  shadows: {
    sm: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.1,
      shadowRadius: 2,
      elevation: 2,
    },
    base: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 4,
    },
    lg: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.15,
      shadowRadius: 8,
      elevation: 8,
    },
  },

  // Animation durations (in milliseconds)
  duration: {
    instant: 0,
    fast: 150,
    base: 250,
    slow: 350,
    slower: 500,
  },
} as const;

// Helper functions for color manipulation
export const rgb = (colorArray: readonly [number, number, number]) =>
  `rgb(${colorArray[0]}, ${colorArray[1]}, ${colorArray[2]})`;

export const rgba = (colorArray: readonly [number, number, number], alpha: number) =>
  `rgba(${colorArray[0]}, ${colorArray[1]}, ${colorArray[2]}, ${alpha})`;

// Type exports for TypeScript
export type Tokens = typeof tokens;
export type SpaceValue = keyof typeof tokens.space;
export type FontSize = keyof typeof tokens.fontSize;
export type Color = readonly [number, number, number];