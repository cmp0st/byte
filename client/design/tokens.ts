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

  // Font weights (lighter, more elegant)
  fontWeight: {
    light: '300',
    normal: '400',
    medium: '450',
    semibold: '500',
    bold: '600',
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

  // Colors (RGB values for easy manipulation) - Dark teal theme
  colors: {
    // Background colors (dark teal inspired)
    bg: {
      primary: [8, 12, 16],       // #080c10 - deep dark blue-grey
      secondary: [15, 23, 28],    // #0f171c - slightly teal-tinted
      tertiary: [22, 35, 42],     // #16232a - card backgrounds with teal hint
    },
    
    // Text colors (softer, more elegant)
    text: {
      primary: [240, 248, 250],   // #f0f8fa - soft white with teal hint
      secondary: [190, 210, 220], // #bedadc - muted teal-grey
      muted: [140, 160, 170],     // #8ca0aa - subtle teal-grey
      inverse: [8, 12, 16],       // #080c10 - matches primary bg
    },

    // Border colors (subtle teal tones)
    border: {
      primary: [35, 50, 60],      // #23323c - teal-tinted border
      secondary: [50, 70, 80],    // #324650 - slightly more visible
      muted: [70, 90, 100],       // #465a64 - muted teal border
    },

    // Interactive colors (teal accent palette)
    interactive: {
      primary: [20, 184, 166],     // teal-500 - main accent
      primaryHover: [13, 148, 136], // teal-600 - hover state
      danger: [239, 68, 68],       // red-500 - keep for errors
      dangerHover: [220, 38, 38],  // red-600
      warning: [245, 158, 11],     // amber-500 - keep for warnings
      info: [56, 189, 248],        // sky-400 - lighter blue
    },

    // Status colors (teal-coordinated)
    status: {
      success: [20, 184, 166],    // teal-500 - matches primary
      error: [239, 68, 68],       // red-500
      warning: [245, 158, 11],    // amber-500
      info: [56, 189, 248],       // sky-400
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