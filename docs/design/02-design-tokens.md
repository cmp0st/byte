# Design Tokens Specification

## Overview

Design tokens are the foundational design decisions that define the visual language of the Byte. They provide a single source of truth for spacing, typography, colors, shadows, and other visual properties that ensure consistency across all interfaces and platforms.

## Token Categories

### Spacing Scale

```css
:root {
  /* Base spacing unit: 4px */
  --space-px: 1px;
  --space-0: 0;
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-5: 1.25rem;  /* 20px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-10: 2.5rem;  /* 40px */
  --space-12: 3rem;    /* 48px */
  --space-16: 4rem;    /* 64px */
  --space-20: 5rem;    /* 80px */
  --space-24: 6rem;    /* 96px */
}
```

### Typography Scale

```css
:root {
  /* Font families */
  --font-mono: 'JetBrains Mono', 'SF Mono', 'Monaco', 'Inconsolata', 'Roboto Mono', monospace;
  --font-sans: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  
  /* Font sizes - based on minor third scale (1.2) */
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.125rem;   /* 18px */
  --text-xl: 1.25rem;    /* 20px */
  --text-2xl: 1.5rem;    /* 24px */
  --text-3xl: 1.875rem;  /* 30px */
  --text-4xl: 2.25rem;   /* 36px */
  
  /* Font weights */
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  
  /* Line heights */
  --leading-none: 1;
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.75;
  
  /* Letter spacing */
  --tracking-tighter: -0.05em;
  --tracking-tight: -0.025em;
  --tracking-normal: 0em;
  --tracking-wide: 0.025em;
  --tracking-wider: 0.05em;
}
```

### Border & Radius

```css
:root {
  /* Border widths */
  --border-0: 0px;
  --border-1: 1px;
  --border-2: 2px;
  --border-4: 4px;
  
  /* Border radius */
  --radius-none: 0;
  --radius-sm: 0.125rem;   /* 2px */
  --radius-base: 0.25rem;  /* 4px */
  --radius-md: 0.375rem;   /* 6px */
  --radius-lg: 0.5rem;     /* 8px */
  --radius-xl: 0.75rem;    /* 12px */
  --radius-2xl: 1rem;      /* 16px */
  --radius-full: 9999px;
}
```

### Shadows & Elevation

```css
:root {
  /* Shadow tokens for elevation */
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-sm: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-base: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-md: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);
  
  /* Terminal-specific shadows (more subtle) */
  --shadow-terminal-sm: 0 1px 2px 0 rgb(0 0 0 / 0.3);
  --shadow-terminal-md: 0 2px 4px 0 rgb(0 0 0 / 0.4);
  --shadow-terminal-lg: 0 4px 8px 0 rgb(0 0 0 / 0.5);
  
  /* Glow effects for interactive elements */
  --glow-primary: 0 0 0 3px rgb(var(--color-interactive-primary) / 0.1);
  --glow-focus: 0 0 0 2px rgb(var(--color-interactive-primary) / 0.5);
}
```

### Motion & Animation

```css
:root {
  /* Duration tokens */
  --duration-instant: 0ms;
  --duration-fast: 150ms;
  --duration-base: 250ms;
  --duration-slow: 350ms;
  --duration-slower: 500ms;
  
  /* Easing functions */
  --ease-linear: linear;
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-terminal: cubic-bezier(0.25, 0.46, 0.45, 0.94); /* Custom terminal feel */
  
  /* Transition presets */
  --transition-colors: color var(--duration-fast) var(--ease-out),
                       background-color var(--duration-fast) var(--ease-out),
                       border-color var(--duration-fast) var(--ease-out);
  --transition-transform: transform var(--duration-base) var(--ease-out);
  --transition-opacity: opacity var(--duration-fast) var(--ease-out);
  --transition-all: all var(--duration-base) var(--ease-out);
}
```

### Breakpoints

```css
:root {
  /* Responsive breakpoints */
  --breakpoint-sm: 640px;   /* Mobile landscape */
  --breakpoint-md: 768px;   /* Tablet */
  --breakpoint-lg: 1024px;  /* Desktop */
  --breakpoint-xl: 1280px;  /* Large desktop */
  --breakpoint-2xl: 1536px; /* Extra large */
}
```

### Z-Index Scale

```css
:root {
  /* Z-index tokens for layering */
  --z-base: 0;
  --z-docked: 10;      /* Docked elements */
  --z-dropdown: 100;    /* Dropdown menus */
  --z-sticky: 200;     /* Sticky elements */
  --z-fixed: 300;      /* Fixed elements */
  --z-modal: 400;      /* Modal backgrounds */
  --z-popover: 500;    /* Popovers, tooltips */
  --z-toast: 600;      /* Toast notifications */
  --z-tooltip: 700;    /* Tooltips */
  --z-debug: 9999;     /* Debug overlays */
}
```

## Semantic Tokens

### Layout Tokens

```css
:root {
  /* Container sizes */
  --container-xs: 475px;
  --container-sm: 640px;
  --container-md: 768px;
  --container-lg: 1024px;
  --container-xl: 1280px;
  --container-2xl: 1536px;
  
  /* Header heights */
  --header-height: 3.5rem;        /* 56px - main header */
  --subheader-height: 2.5rem;     /* 40px - context bar */
  --footer-height: 2rem;          /* 32px - status bar */
  
  /* Sidebar widths */
  --sidebar-width: 16rem;         /* 256px - file browser */
  --sidebar-width-collapsed: 3rem; /* 48px - collapsed */
  
  /* Grid spacing */
  --grid-gap-sm: var(--space-2);
  --grid-gap-md: var(--space-4);
  --grid-gap-lg: var(--space-6);
}
```

### Interactive Tokens

```css
:root {
  /* Interactive element sizing */
  --button-height-sm: 2rem;       /* 32px */
  --button-height-base: 2.5rem;   /* 40px */
  --button-height-lg: 3rem;       /* 48px */
  
  --input-height-sm: 2rem;        /* 32px */
  --input-height-base: 2.5rem;    /* 40px */
  --input-height-lg: 3rem;        /* 48px */
  
  /* Focus ring */
  --focus-ring-width: 2px;
  --focus-ring-offset: 2px;
  --focus-ring-color: var(--color-interactive-primary);
  
  /* Hit targets (minimum touch/click area) */
  --hit-target-min: 44px;
}
```

### Context-Specific Tokens

```css
:root {
  /* Terminal interface */
  --terminal-line-height: 1.4;
  --terminal-char-width: 0.6em;
  --terminal-padding: var(--space-4);
  
  /* Photo gallery */
  --gallery-thumbnail-size: 200px;
  --gallery-gap: var(--space-4);
  --gallery-aspect-ratio: 1;
  
  /* File browser */
  --file-row-height: 2.5rem;
  --file-icon-size: 1rem;
  --file-indent: var(--space-4);
  
  /* Git interface */
  --commit-timeline-width: 2px;
  --commit-dot-size: 8px;
  --diff-line-height: 1.4;
}
```

## Platform-Specific Adjustments

### Mobile Tokens

```css
@media (max-width: 768px) {
  :root {
    /* Adjust spacing for mobile */
    --space-scale-factor: 0.875; /* Reduce spacing by 12.5% */
    
    /* Larger touch targets */
    --button-height-base: 3rem;   /* 48px - larger for touch */
    --input-height-base: 3rem;
    
    /* Typography adjustments */
    --text-base: 1rem;            /* Keep base size */
    --leading-normal: 1.6;        /* Increase line height for readability */
    
    /* Layout adjustments */
    --sidebar-width: 100vw;       /* Full width on mobile */
    --header-height: 4rem;        /* Taller header for mobile */
  }
}
```

### High DPI Adjustments

```css
@media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
  :root {
    /* Adjust for high DPI displays */
    --border-1: 0.5px;            /* Thinner borders on retina */
    --shadow-terminal-sm: 0 0.5px 1px 0 rgb(0 0 0 / 0.3);
  }
}
```

## Token Usage Examples

### CSS Classes Using Tokens

```css
/* Button component */
.btn {
  height: var(--button-height-base);
  padding: 0 var(--space-4);
  border-radius: var(--radius-base);
  font-family: var(--font-mono);
  font-size: var(--text-sm);
  font-weight: var(--font-weight-medium);
  transition: var(--transition-colors);
  border: var(--border-1) solid var(--color-border-primary);
}

/* File browser row */
.file-row {
  height: var(--file-row-height);
  padding: 0 var(--space-3);
  border-bottom: var(--border-1) solid var(--color-border-primary);
  transition: var(--transition-colors);
}

.file-row:hover {
  background-color: var(--color-bg-tertiary);
}

/* Terminal window */
.terminal {
  font-family: var(--font-mono);
  font-size: var(--text-sm);
  line-height: var(--terminal-line-height);
  padding: var(--terminal-padding);
  background-color: var(--color-bg-primary);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-terminal-lg);
}
```

### JavaScript Token Access

```javascript
// Function to get token values in JavaScript
function getTokenValue(tokenName) {
  return getComputedStyle(document.documentElement)
    .getPropertyValue(`--${tokenName}`)
    .trim();
}

// Example usage
const primaryColor = getTokenValue('color-interactive-primary');
const baseDuration = getTokenValue('duration-base');

// Responsive token access
function getResponsiveTokenValue(tokenName) {
  const breakpointMd = parseInt(getTokenValue('breakpoint-md'));
  const isMobile = window.innerWidth < breakpointMd;
  
  if (isMobile && document.documentElement.style.getPropertyValue(`--${tokenName}-mobile`)) {
    return getTokenValue(`${tokenName}-mobile`);
  }
  
  return getTokenValue(tokenName);
}
```

## Token Organization Structure

```
tokens/
├── core/
│   ├── colors.css
│   ├── spacing.css
│   ├── typography.css
│   └── motion.css
├── semantic/
│   ├── layout.css
│   ├── interactive.css
│   └── context.css
├── platform/
│   ├── mobile.css
│   ├── desktop.css
│   └── high-dpi.css
└── themes/
    ├── dark-terminal.css
    ├── light-minimal.css
    └── custom.css
```

## Validation & Quality Assurance

### Token Validation Rules

1. **Color Tokens**: Must be valid hex, rgb, or hsl values
2. **Spacing Tokens**: Must use rem units for scalability
3. **Typography Tokens**: Font sizes must maintain readable scale
4. **Animation Tokens**: Durations should follow performance guidelines

### Automated Testing

```javascript
// Token validation tests
describe('Design Tokens', () => {
  test('all color tokens are valid', () => {
    const colorTokens = getTokensByPrefix('color-');
    colorTokens.forEach(token => {
      expect(isValidColor(token.value)).toBe(true);
    });
  });
  
  test('spacing tokens use rem units', () => {
    const spacingTokens = getTokensByPrefix('space-');
    spacingTokens.forEach(token => {
      expect(token.value).toMatch(/^\d+(\.\d+)?rem$/);
    });
  });
});
```

## Implementation Guidelines

1. **Always use tokens**: Never hardcode design values in components
2. **Semantic naming**: Use purpose-based names rather than value-based
3. **Consistent application**: Apply tokens systematically across all interfaces
4. **Platform adaptation**: Adjust tokens for different screen sizes and capabilities
5. **Regular review**: Audit and update tokens as the design system evolves

## Future Enhancements

1. **Design Token Studio**: Visual editor for creating and managing tokens
2. **Multi-brand Support**: Different token sets for different themes/brands
3. **Dynamic Tokens**: Tokens that change based on user preferences or context
4. **Token Documentation**: Automated documentation generation from token definitions
5. **Cross-Platform Sync**: Synchronize tokens across web, mobile, and desktop applications