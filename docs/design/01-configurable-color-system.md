# Configurable Color System

## Overview

The Byte implements a Slack-style configurable color palette system that allows users to instantly transform the entire interface by pasting hex codes or selecting preset themes. This system maintains the terminal-first aesthetic while providing flexibility for branding and accessibility.

## Design Philosophy

- **Terminal-first**: Dark theme with monospace fonts as the foundation
- **Developer-focused**: Clean, functional interface that doesn't distract from productivity
- **Accessibility-first**: Automatic contrast validation and adjustments
- **Instant transformation**: Changes apply immediately across all interfaces

## Technical Implementation

### CSS Custom Properties Architecture

```css
/* Root color tokens - these can be dynamically updated */
:root {
  /* Base semantic colors */
  --color-bg-primary: #111827;    /* gray-900 */
  --color-bg-secondary: #1f2937;  /* gray-800 */
  --color-bg-tertiary: #374151;   /* gray-700 */
  
  /* Text colors */
  --color-text-primary: #f9fafb;    /* gray-50 */
  --color-text-secondary: #d1d5db;  /* gray-300 */
  --color-text-muted: #9ca3af;      /* gray-400 */
  --color-text-disabled: #6b7280;   /* gray-500 */
  
  /* Interactive colors */
  --color-interactive-primary: #10b981;   /* green-500 */
  --color-interactive-secondary: #3b82f6; /* blue-500 */
  --color-interactive-accent: #f59e0b;    /* amber-500 */
  --color-interactive-danger: #ef4444;    /* red-500 */
  
  /* Border colors */
  --color-border-primary: #374151;   /* gray-700 */
  --color-border-secondary: #4b5563; /* gray-600 */
  --color-border-focus: var(--color-interactive-primary);
  
  /* Context-specific colors */
  --color-context-photo: #10b981;    /* green-500 */
  --color-context-git: #f59e0b;      /* amber-500 */
  --color-context-website: #3b82f6;  /* blue-500 */
  --color-context-terminal: #8b5cf6; /* purple-500 */
  
  /* Status colors */
  --color-status-online: #10b981;    /* green-500 */
  --color-status-warning: #f59e0b;   /* amber-500 */
  --color-status-error: #ef4444;     /* red-500 */
  --color-status-info: #3b82f6;      /* blue-500 */
}
```

### Color Token Naming Conventions

Our color system follows a semantic naming pattern:

```
--color-{category}-{variant}-{state?}

Examples:
--color-bg-primary           (background, primary variant)
--color-text-secondary       (text, secondary variant)
--color-interactive-primary-hover (interactive, primary, hover state)
--color-border-focus         (border, focus state)
--color-status-online        (status indicator, online state)
```

### Theme Switching Mechanism

#### JavaScript Theme Controller

```javascript
class ThemeController {
  constructor() {
    this.themes = new Map();
    this.currentTheme = 'dark-terminal';
    this.loadPresetThemes();
  }

  // Load preset themes
  loadPresetThemes() {
    this.themes.set('dark-terminal', {
      name: 'Dark Terminal',
      colors: {
        'bg-primary': '#111827',
        'bg-secondary': '#1f2937',
        'bg-tertiary': '#374151',
        'text-primary': '#f9fafb',
        'text-secondary': '#d1d5db',
        'text-muted': '#9ca3af',
        'interactive-primary': '#10b981',
        'interactive-secondary': '#3b82f6',
        'context-photo': '#10b981',
        'context-git': '#f59e0b',
        'context-website': '#3b82f6',
        'context-terminal': '#8b5cf6'
      }
    });

    this.themes.set('light-minimal', {
      name: 'Light Minimal',
      colors: {
        'bg-primary': '#ffffff',
        'bg-secondary': '#f9fafb',
        'bg-tertiary': '#f3f4f6',
        'text-primary': '#111827',
        'text-secondary': '#374151',
        'text-muted': '#6b7280',
        'interactive-primary': '#059669',
        'interactive-secondary': '#2563eb',
        'context-photo': '#059669',
        'context-git': '#d97706',
        'context-website': '#2563eb',
        'context-terminal': '#7c3aed'
      }
    });

    this.themes.set('dracula', {
      name: 'Dracula',
      colors: {
        'bg-primary': '#282a36',
        'bg-secondary': '#44475a',
        'bg-tertiary': '#6272a4',
        'text-primary': '#f8f8f2',
        'text-secondary': '#f8f8f2',
        'text-muted': '#6272a4',
        'interactive-primary': '#50fa7b',
        'interactive-secondary': '#8be9fd',
        'context-photo': '#50fa7b',
        'context-git': '#ffb86c',
        'context-website': '#8be9fd',
        'context-terminal': '#bd93f9'
      }
    });
  }

  // Apply theme by name
  applyTheme(themeName) {
    const theme = this.themes.get(themeName);
    if (!theme) return false;

    this.applyColors(theme.colors);
    this.currentTheme = themeName;
    localStorage.setItem('byte-theme', themeName);
    return true;
  }

  // Apply custom color palette from user input
  applyCustomColors(colorPalette) {
    const validatedColors = this.validateAndAdjustColors(colorPalette);
    this.applyColors(validatedColors);
    
    // Save custom theme
    this.themes.set('custom', {
      name: 'Custom',
      colors: validatedColors
    });
    
    this.currentTheme = 'custom';
    localStorage.setItem('byte-theme', 'custom');
    localStorage.setItem('byte-custom-colors', JSON.stringify(validatedColors));
  }

  // Apply colors to CSS custom properties
  applyColors(colors) {
    const root = document.documentElement;
    
    Object.entries(colors).forEach(([key, value]) => {
      root.style.setProperty(`--color-${key}`, value);
    });

    // Trigger re-computation of derived colors
    this.updateDerivedColors();
  }

  // Update derived colors (hover states, etc.)
  updateDerivedColors() {
    const root = document.documentElement;
    
    // Generate hover states by adjusting lightness
    const interactivePrimary = getComputedStyle(root).getPropertyValue('--color-interactive-primary');
    const hoverColor = this.adjustColorLightness(interactivePrimary, -10);
    root.style.setProperty('--color-interactive-primary-hover', hoverColor);
  }

  // Validate colors and ensure accessibility
  validateAndAdjustColors(colors) {
    const validated = { ...colors };
    
    // Check contrast ratios
    Object.entries(validated).forEach(([key, color]) => {
      if (key.startsWith('text-')) {
        const bgColor = validated['bg-primary'];
        const contrast = this.calculateContrast(color, bgColor);
        
        if (contrast < 4.5) { // WCAG AA standard
          validated[key] = this.adjustColorForContrast(color, bgColor, 4.5);
        }
      }
    });
    
    return validated;
  }

  // Parse color palette from user input (various formats)
  parseColorPalette(input) {
    const lines = input.split('\n').filter(line => line.trim());
    const colors = {};
    
    lines.forEach(line => {
      const match = line.match(/^([a-zA-Z-]+):\s*(#[0-9a-fA-F]{6})$/);
      if (match) {
        colors[match[1]] = match[2];
      }
    });
    
    return colors;
  }

  // Utility functions
  calculateContrast(color1, color2) {
    // Implementation of WCAG contrast ratio calculation
    // Returns ratio between 1 and 21
  }

  adjustColorLightness(hexColor, percent) {
    // Adjust HSL lightness by percentage
    // Returns new hex color
  }

  adjustColorForContrast(textColor, bgColor, targetRatio) {
    // Adjust text color to meet contrast requirements
    // Returns adjusted hex color
  }
}

// Initialize theme controller
const themeController = new ThemeController();

// Load saved theme on startup
const savedTheme = localStorage.getItem('byte-theme');
if (savedTheme) {
  themeController.applyTheme(savedTheme);
}
```

#### HTML Theme Selector Component

```html
<div class="theme-selector bg-gray-800 rounded border border-gray-700">
  <div class="border-b border-gray-700 px-4 py-3">
    <h3 class="text-sm font-semibold text-gray-100">Theme Configuration</h3>
  </div>
  
  <div class="p-4 space-y-4">
    <!-- Preset Themes -->
    <div>
      <label class="text-xs text-gray-400 mb-2 block">Preset Themes</label>
      <div class="grid grid-cols-3 gap-2">
        <button class="preset-theme p-3 rounded border border-gray-600 hover:border-gray-500" 
                data-theme="dark-terminal">
          <div class="w-full h-8 rounded mb-2 bg-gray-900"></div>
          <div class="text-xs text-gray-300">Dark Terminal</div>
        </button>
        
        <button class="preset-theme p-3 rounded border border-gray-600 hover:border-gray-500" 
                data-theme="light-minimal">
          <div class="w-full h-8 rounded mb-2 bg-gray-100"></div>
          <div class="text-xs text-gray-300">Light Minimal</div>
        </button>
        
        <button class="preset-theme p-3 rounded border border-gray-600 hover:border-gray-500" 
                data-theme="dracula">
          <div class="w-full h-8 rounded mb-2" style="background: #282a36;"></div>
          <div class="text-xs text-gray-300">Dracula</div>
        </button>
      </div>
    </div>
    
    <!-- Custom Color Paste -->
    <div>
      <label class="text-xs text-gray-400 mb-2 block">Custom Color Palette</label>
      <textarea 
        id="color-palette-input"
        class="w-full h-32 bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm text-gray-300 font-mono"
        placeholder="bg-primary: #111827
bg-secondary: #1f2937
text-primary: #f9fafb
interactive-primary: #10b981
...">
      </textarea>
      <button 
        id="apply-custom-colors"
        class="mt-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded text-sm">
        Apply Custom Colors
      </button>
    </div>
    
    <!-- Color Preview -->
    <div class="color-preview">
      <label class="text-xs text-gray-400 mb-2 block">Preview</label>
      <div class="grid grid-cols-8 gap-1">
        <div class="h-8 rounded" style="background: var(--color-bg-primary);" title="bg-primary"></div>
        <div class="h-8 rounded" style="background: var(--color-bg-secondary);" title="bg-secondary"></div>
        <div class="h-8 rounded" style="background: var(--color-text-primary);" title="text-primary"></div>
        <div class="h-8 rounded" style="background: var(--color-interactive-primary);" title="interactive-primary"></div>
        <div class="h-8 rounded" style="background: var(--color-context-photo);" title="context-photo"></div>
        <div class="h-8 rounded" style="background: var(--color-context-git);" title="context-git"></div>
        <div class="h-8 rounded" style="background: var(--color-context-website);" title="context-website"></div>
        <div class="h-8 rounded" style="background: var(--color-context-terminal);" title="context-terminal"></div>
      </div>
    </div>
  </div>
</div>
```

## Integration with Tailwind CSS

### Configuration Override

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        // Map Tailwind colors to our CSS custom properties
        'primary': {
          50: 'rgb(var(--color-primary-50) / <alpha-value>)',
          500: 'var(--color-interactive-primary)',
          600: 'var(--color-interactive-primary-hover)',
        },
        'bg': {
          primary: 'var(--color-bg-primary)',
          secondary: 'var(--color-bg-secondary)',
          tertiary: 'var(--color-bg-tertiary)',
        },
        'text': {
          primary: 'var(--color-text-primary)',
          secondary: 'var(--color-text-secondary)',
          muted: 'var(--color-text-muted)',
        }
      }
    }
  }
}
```

### Dynamic Class Generation

```css
/* Generate utility classes that use our custom properties */
.bg-adaptive-primary { background-color: var(--color-bg-primary); }
.bg-adaptive-secondary { background-color: var(--color-bg-secondary); }
.text-adaptive-primary { color: var(--color-text-primary); }
.text-adaptive-secondary { color: var(--color-text-secondary); }
.border-adaptive-primary { border-color: var(--color-border-primary); }

/* Context-specific classes */
.text-context-photo { color: var(--color-context-photo); }
.text-context-git { color: var(--color-context-git); }
.text-context-website { color: var(--color-context-website); }
.text-context-terminal { color: var(--color-context-terminal); }
```

## Accessibility Considerations

### Automatic Contrast Validation

- All text/background combinations must meet WCAG AA standards (4.5:1 minimum)
- System automatically adjusts colors that don't meet requirements
- Provides warnings for marginally accessible combinations

### Color Blind Support

- Never rely solely on color to convey information
- Include icons and text labels alongside color coding
- Test all themes with color blindness simulators

### High Contrast Mode Support

```css
@media (prefers-contrast: high) {
  :root {
    --color-bg-primary: #000000;
    --color-bg-secondary: #1a1a1a;
    --color-text-primary: #ffffff;
    --color-border-primary: #ffffff;
  }
}
```

## Implementation Checklist

- [ ] Set up CSS custom properties architecture
- [ ] Implement JavaScript theme controller
- [ ] Create theme selector UI component
- [ ] Add preset themes (dark terminal, light minimal, dracula)
- [ ] Implement custom color palette parsing
- [ ] Add contrast validation and adjustment
- [ ] Integrate with Tailwind CSS configuration
- [ ] Test accessibility compliance
- [ ] Add localStorage persistence
- [ ] Create documentation for adding new themes

## Future Enhancements

1. **Color Palette Generator**: AI-powered suggestions based on user preferences
2. **Theme Marketplace**: Community-shared themes
3. **Automatic Theme Switching**: Based on time of day or system preferences
4. **Advanced Color Tools**: Color picker, gradient generator, accessibility analyzer
5. **Brand Integration**: Import colors from design tokens or brand guidelines