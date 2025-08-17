# Developer Implementation Guide

## Overview

This guide provides developers with practical instructions for implementing the Byte design system. It covers setup, integration patterns, code examples, and best practices for building consistent, accessible, and performant interfaces across all platforms.

## Getting Started

### Prerequisites

- Node.js 18+
- Modern build system (Vite, Webpack, or similar)
- CSS preprocessor support (optional but recommended)
- Basic understanding of CSS custom properties and modern JavaScript

### Installation & Setup

#### 1. Design System Package Structure

```
byte-design-system/
├── src/
│   ├── tokens/
│   │   ├── colors.css
│   │   ├── spacing.css
│   │   ├── typography.css
│   │   └── index.css
│   ├── components/
│   │   ├── button/
│   │   │   ├── button.css
│   │   │   ├── button.js
│   │   │   └── button.stories.js
│   │   └── index.css
│   ├── themes/
│   │   ├── dark-terminal.css
│   │   ├── light-minimal.css
│   │   └── index.css
│   └── utils/
│       ├── animations.css
│       ├── layout.css
│       └── index.css
├── dist/
├── package.json
└── README.md
```

#### 2. CSS Import Strategy

```css
/* main.css - Import order is important */

/* 1. Design tokens (foundational) */
@import './tokens/index.css';

/* 2. Base styles and resets */
@import './base/reset.css';
@import './base/typography.css';

/* 3. Layout utilities */
@import './utils/layout.css';
@import './utils/animations.css';

/* 4. Component styles */
@import './components/index.css';

/* 5. Theme variations */
@import './themes/index.css';

/* 6. Responsive overrides */
@import './responsive/mobile.css';
@import './responsive/tablet.css';
@import './responsive/desktop.css';
```

#### 3. JavaScript Module Setup

```javascript
// design-system.js
export { ThemeController } from './controllers/ThemeController.js';
export { TouchGestureHandler } from './utils/TouchGestureHandler.js';
export { ContextDetector } from './utils/ContextDetector.js';
export { ComponentRegistry } from './utils/ComponentRegistry.js';

// Component exports
export { Button } from './components/Button.js';
export { FileItem } from './components/FileItem.js';
export { PhotoGallery } from './components/PhotoGallery.js';
export { GitHistory } from './components/GitHistory.js';
```

## Core Implementation Patterns

### 1. Component Architecture

#### Base Component Class

```javascript
// BaseComponent.js
export class BaseComponent {
  constructor(element, options = {}) {
    this.element = element;
    this.options = { ...this.defaultOptions, ...options };
    this.state = {};
    this.listeners = new Map();
    
    this.init();
  }
  
  get defaultOptions() {
    return {};
  }
  
  init() {
    this.bindEvents();
    this.render();
  }
  
  bindEvents() {
    // Override in subclasses
  }
  
  render() {
    // Override in subclasses
  }
  
  addEventListener(event, handler, options = {}) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event).push({ handler, options });
    this.element.addEventListener(event, handler, options);
  }
  
  removeEventListener(event, handler) {
    if (this.listeners.has(event)) {
      const eventListeners = this.listeners.get(event);
      const index = eventListeners.findIndex(l => l.handler === handler);
      if (index > -1) {
        eventListeners.splice(index, 1);
        this.element.removeEventListener(event, handler);
      }
    }
  }
  
  setState(newState) {
    const prevState = { ...this.state };
    this.state = { ...this.state, ...newState };
    this.onStateChange(this.state, prevState);
  }
  
  onStateChange(newState, prevState) {
    // Override in subclasses
  }
  
  destroy() {
    // Clean up event listeners
    this.listeners.forEach((eventListeners, event) => {
      eventListeners.forEach(({ handler }) => {
        this.element.removeEventListener(event, handler);
      });
    });
    this.listeners.clear();
  }
}
```

#### Example Component Implementation

```javascript
// FileItem.js
import { BaseComponent } from './BaseComponent.js';
import { TouchGestureHandler } from '../utils/TouchGestureHandler.js';

export class FileItem extends BaseComponent {
  get defaultOptions() {
    return {
      selectable: false,
      swipeActions: true,
      iconMapping: {
        '.js': 'fab fa-js-square',
        '.css': 'fab fa-css3-alt',
        '.html': 'fab fa-html5',
        '.git': 'fab fa-git-alt',
        default: 'fas fa-file'
      }
    };
  }
  
  init() {
    super.init();
    
    if (this.options.swipeActions && 'ontouchstart' in window) {
      this.gestureHandler = new TouchGestureHandler(this.element);
      this.setupSwipeActions();
    }
  }
  
  bindEvents() {
    this.addEventListener('click', this.handleClick.bind(this));
    this.addEventListener('keydown', this.handleKeydown.bind(this));
    
    if (this.gestureHandler) {
      this.addEventListener('mobile-swipeleft', this.handleSwipeLeft.bind(this));
      this.addEventListener('mobile-swiperight', this.handleSwipeRight.bind(this));
    }
  }
  
  render() {
    const data = this.getData();
    
    this.element.innerHTML = `
      <div class="file-item__icon">
        <i class="${this.getFileIcon(data.name)}"></i>
      </div>
      <div class="file-item__details">
        <span class="file-item__name">${data.name}</span>
        <span class="file-item__meta">${data.size} • ${data.modified}</span>
      </div>
      <div class="file-item__actions">
        ${this.renderActions(data)}
      </div>
      ${this.options.swipeActions ? this.renderSwipeActions(data) : ''}
    `;
    
    // Add accessibility attributes
    this.element.setAttribute('role', 'listitem');
    this.element.setAttribute('tabindex', '0');
    if (data.type === 'directory') {
      this.element.setAttribute('aria-expanded', 'false');
    }
  }
  
  getData() {
    return {
      name: this.element.dataset.name || 'Unknown',
      size: this.element.dataset.size || '0',
      modified: this.element.dataset.modified || 'Unknown',
      type: this.element.dataset.type || 'file'
    };
  }
  
  getFileIcon(filename) {
    const extension = filename.split('.').pop().toLowerCase();
    return this.options.iconMapping[`.${extension}`] || this.options.iconMapping.default;
  }
  
  renderActions(data) {
    return `
      <button class="btn btn--ghost btn--sm" data-action="edit" aria-label="Edit ${data.name}">
        <i class="fas fa-edit"></i>
      </button>
      <button class="btn btn--ghost btn--sm" data-action="download" aria-label="Download ${data.name}">
        <i class="fas fa-download"></i>
      </button>
    `;
  }
  
  renderSwipeActions(data) {
    return `
      <div class="file-item__swipe-actions">
        <button class="file-item__swipe-action file-item__swipe-action--edit" data-action="edit">
          <i class="fas fa-edit"></i>
        </button>
        <button class="file-item__swipe-action file-item__swipe-action--delete" data-action="delete">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    `;
  }
  
  handleClick(e) {
    const action = e.target.closest('[data-action]');
    if (action) {
      e.preventDefault();
      this.executeAction(action.dataset.action);
    } else {
      this.executeAction('open');
    }
  }
  
  handleKeydown(e) {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      this.executeAction('open');
    }
  }
  
  handleSwipeLeft(e) {
    this.element.classList.add('file-item--swiped');
  }
  
  handleSwipeRight(e) {
    this.element.classList.remove('file-item--swiped');
  }
  
  executeAction(action) {
    const customEvent = new CustomEvent('file-action', {
      detail: {
        action,
        file: this.getData(),
        element: this.element
      },
      bubbles: true
    });
    this.element.dispatchEvent(customEvent);
  }
  
  setupSwipeActions() {
    // Additional setup for swipe actions if needed
  }
  
  destroy() {
    if (this.gestureHandler) {
      this.gestureHandler.destroy();
    }
    super.destroy();
  }
}

// Auto-initialize file items
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.file-item').forEach(element => {
    new FileItem(element);
  });
});
```

### 2. Theme Integration

#### Theme Controller Implementation

```javascript
// ThemeController.js
export class ThemeController {
  constructor() {
    this.themes = new Map();
    this.currentTheme = null;
    this.customColors = null;
    
    this.loadBuiltInThemes();
    this.loadSavedTheme();
  }
  
  loadBuiltInThemes() {
    // Dark Terminal Theme
    this.registerTheme('dark-terminal', {
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
        'border-primary': '#374151',
        'context-photo': '#10b981',
        'context-git': '#f59e0b',
        'context-website': '#3b82f6',
        'context-terminal': '#8b5cf6'
      }
    });
    
    // Light Minimal Theme
    this.registerTheme('light-minimal', {
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
        'border-primary': '#e5e7eb',
        'context-photo': '#059669',
        'context-git': '#d97706',
        'context-website': '#2563eb',
        'context-terminal': '#7c3aed'
      }
    });
  }
  
  registerTheme(id, theme) {
    this.themes.set(id, theme);
  }
  
  applyTheme(themeId) {
    const theme = this.themes.get(themeId);
    if (!theme) {
      console.warn(`Theme '${themeId}' not found`);
      return false;
    }
    
    this.applyColors(theme.colors);
    this.currentTheme = themeId;
    this.saveTheme(themeId);
    
    // Dispatch theme change event
    document.dispatchEvent(new CustomEvent('theme-changed', {
      detail: { theme: themeId, colors: theme.colors }
    }));
    
    return true;
  }
  
  applyCustomColors(colors) {
    const validatedColors = this.validateColors(colors);
    if (!validatedColors) {
      console.error('Invalid color configuration');
      return false;
    }
    
    this.applyColors(validatedColors);
    this.customColors = validatedColors;
    this.currentTheme = 'custom';
    this.saveCustomColors(validatedColors);
    
    document.dispatchEvent(new CustomEvent('theme-changed', {
      detail: { theme: 'custom', colors: validatedColors }
    }));
    
    return true;
  }
  
  applyColors(colors) {
    const root = document.documentElement;
    
    Object.entries(colors).forEach(([key, value]) => {
      root.style.setProperty(`--color-${key}`, value);
    });
    
    // Update meta theme-color for mobile browsers
    this.updateMetaThemeColor(colors['bg-primary']);
  }
  
  updateMetaThemeColor(color) {
    let metaThemeColor = document.querySelector('meta[name="theme-color"]');
    if (!metaThemeColor) {
      metaThemeColor = document.createElement('meta');
      metaThemeColor.name = 'theme-color';
      document.head.appendChild(metaThemeColor);
    }
    metaThemeColor.content = color;
  }
  
  validateColors(colors) {
    const required = ['bg-primary', 'bg-secondary', 'text-primary', 'interactive-primary'];
    const validated = {};
    
    // Check required colors
    for (const key of required) {
      if (!colors[key] || !this.isValidColor(colors[key])) {
        console.error(`Invalid or missing required color: ${key}`);
        return null;
      }
      validated[key] = colors[key];
    }
    
    // Add optional colors with defaults
    const optional = {
      'bg-tertiary': colors['bg-secondary'],
      'text-secondary': colors['text-primary'],
      'text-muted': this.adjustColorOpacity(colors['text-primary'], 0.7),
      'border-primary': this.adjustColorOpacity(colors['text-primary'], 0.2),
      'interactive-secondary': colors['interactive-primary'],
      'context-photo': colors['interactive-primary'],
      'context-git': colors['interactive-primary'],
      'context-website': colors['interactive-primary'],
      'context-terminal': colors['interactive-primary']
    };
    
    Object.entries(optional).forEach(([key, defaultValue]) => {
      validated[key] = colors[key] || defaultValue;
    });
    
    return validated;
  }
  
  isValidColor(color) {
    const style = new Option().style;
    style.color = color;
    return style.color !== '';
  }
  
  adjustColorOpacity(hexColor, opacity) {
    // Convert hex to rgba with opacity
    const r = parseInt(hexColor.slice(1, 3), 16);
    const g = parseInt(hexColor.slice(3, 5), 16);
    const b = parseInt(hexColor.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }
  
  saveTheme(themeId) {
    localStorage.setItem('byte-theme', themeId);
  }
  
  saveCustomColors(colors) {
    localStorage.setItem('byte-custom-colors', JSON.stringify(colors));
  }
  
  loadSavedTheme() {
    const savedTheme = localStorage.getItem('byte-theme');
    const savedCustomColors = localStorage.getItem('byte-custom-colors');
    
    if (savedTheme === 'custom' && savedCustomColors) {
      try {
        const colors = JSON.parse(savedCustomColors);
        this.applyCustomColors(colors);
      } catch (e) {
        console.warn('Failed to load custom colors, falling back to default theme');
        this.applyTheme('dark-terminal');
      }
    } else if (savedTheme && this.themes.has(savedTheme)) {
      this.applyTheme(savedTheme);
    } else {
      this.applyTheme('dark-terminal');
    }
  }
  
  getAvailableThemes() {
    return Array.from(this.themes.entries()).map(([id, theme]) => ({
      id,
      name: theme.name
    }));
  }
  
  getCurrentTheme() {
    return this.currentTheme;
  }
}

// Global theme controller instance
export const themeController = new ThemeController();
```

### 3. Context Detection System

```javascript
// ContextDetector.js
export class ContextDetector {
  constructor() {
    this.contexts = new Map();
    this.registerBuiltInContexts();
  }
  
  registerBuiltInContexts() {
    // Photo Album Context
    this.registerContext('photo', {
      name: 'Photo Album',
      icon: 'fas fa-images',
      color: 'var(--color-context-photo)',
      detector: (files) => {
        const imageFiles = files.filter(file => 
          /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(file.name)
        );
        return imageFiles.length / files.length > 0.7 && imageFiles.length > 3;
      },
      priority: 10
    });
    
    // Git Repository Context
    this.registerContext('git', {
      name: 'Git Repository',
      icon: 'fab fa-git-alt',
      color: 'var(--color-context-git)',
      detector: (files) => {
        return files.some(file => file.name === '.git' && file.type === 'directory');
      },
      priority: 20
    });
    
    // Website Context
    this.registerContext('website', {
      name: 'Website',
      icon: 'fas fa-globe',
      color: 'var(--color-context-website)',
      detector: (files) => {
        const hasIndex = files.some(file => 
          file.name === 'index.html' || file.name === 'index.htm'
        );
        const webFiles = files.filter(file =>
          /\.(html|htm|css|js)$/i.test(file.name)
        );
        return hasIndex && webFiles.length > 0;
      },
      priority: 15
    });
    
    // Regular Folder Context (default)
    this.registerContext('folder', {
      name: 'Folder',
      icon: 'fas fa-folder',
      color: 'var(--color-text-muted)',
      detector: () => true,
      priority: 1
    });
  }
  
  registerContext(id, context) {
    this.contexts.set(id, context);
  }
  
  detectContext(files) {
    const contexts = Array.from(this.contexts.values())
      .filter(context => context.detector(files))
      .sort((a, b) => b.priority - a.priority);
    
    return contexts[0] || this.contexts.get('folder');
  }
  
  applyContext(contextId, element) {
    const context = this.contexts.get(contextId);
    if (!context) return;
    
    // Add context class
    element.classList.add(`context-${contextId}`);
    
    // Update context indicators
    const contextBadges = element.querySelectorAll('.context-badge');
    contextBadges.forEach(badge => {
      badge.innerHTML = `
        <i class="${context.icon}"></i>
        ${context.name}
      `;
      badge.style.setProperty('--context-color', context.color);
    });
    
    // Dispatch context change event
    element.dispatchEvent(new CustomEvent('context-changed', {
      detail: { context: contextId, info: context },
      bubbles: true
    }));
  }
}

export const contextDetector = new ContextDetector();
```

### 4. Responsive Implementation

```javascript
// ResponsiveManager.js
export class ResponsiveManager {
  constructor() {
    this.breakpoints = {
      mobile: '(max-width: 767px)',
      tablet: '(min-width: 768px) and (max-width: 1023px)',
      desktop: '(min-width: 1024px)'
    };
    
    this.mediaQueries = new Map();
    this.currentBreakpoint = this.getCurrentBreakpoint();
    
    this.init();
  }
  
  init() {
    Object.entries(this.breakpoints).forEach(([name, query]) => {
      const mq = window.matchMedia(query);
      this.mediaQueries.set(name, mq);
      mq.addListener(this.handleBreakpointChange.bind(this));
    });
    
    // Initial setup
    this.handleBreakpointChange();
  }
  
  getCurrentBreakpoint() {
    for (const [name, mq] of this.mediaQueries.entries()) {
      if (mq.matches) {
        return name;
      }
    }
    return 'desktop';
  }
  
  handleBreakpointChange() {
    const newBreakpoint = this.getCurrentBreakpoint();
    
    if (newBreakpoint !== this.currentBreakpoint) {
      const previousBreakpoint = this.currentBreakpoint;
      this.currentBreakpoint = newBreakpoint;
      
      // Update document class
      document.body.classList.remove(`breakpoint-${previousBreakpoint}`);
      document.body.classList.add(`breakpoint-${newBreakpoint}`);
      
      // Dispatch breakpoint change event
      document.dispatchEvent(new CustomEvent('breakpoint-changed', {
        detail: {
          current: newBreakpoint,
          previous: previousBreakpoint
        }
      }));
    }
  }
  
  isMobile() {
    return this.currentBreakpoint === 'mobile';
  }
  
  isTablet() {
    return this.currentBreakpoint === 'tablet';
  }
  
  isDesktop() {
    return this.currentBreakpoint === 'desktop';
  }
  
  onBreakpointChange(callback) {
    document.addEventListener('breakpoint-changed', callback);
  }
}

export const responsiveManager = new ResponsiveManager();
```

## Integration Examples

### 1. React Integration

```jsx
// hooks/useTheme.js
import { useState, useEffect } from 'react';
import { themeController } from '../design-system';

export function useTheme() {
  const [currentTheme, setCurrentTheme] = useState(themeController.getCurrentTheme());
  
  useEffect(() => {
    const handleThemeChange = (event) => {
      setCurrentTheme(event.detail.theme);
    };
    
    document.addEventListener('theme-changed', handleThemeChange);
    return () => document.removeEventListener('theme-changed', handleThemeChange);
  }, []);
  
  const applyTheme = (themeId) => {
    return themeController.applyTheme(themeId);
  };
  
  const applyCustomColors = (colors) => {
    return themeController.applyCustomColors(colors);
  };
  
  return {
    currentTheme,
    availableThemes: themeController.getAvailableThemes(),
    applyTheme,
    applyCustomColors
  };
}

// components/FileItem.jsx
import React from 'react';
import { useContext } from './hooks/useContext';

export function FileItem({ file, onAction }) {
  const { contextId } = useContext();
  
  const handleClick = () => {
    onAction('open', file);
  };
  
  const getFileIcon = (filename) => {
    const extension = filename.split('.').pop().toLowerCase();
    const iconMap = {
      js: 'fab fa-js-square',
      css: 'fab fa-css3-alt',
      html: 'fab fa-html5',
      git: 'fab fa-git-alt'
    };
    return iconMap[extension] || 'fas fa-file';
  };
  
  return (
    <div 
      className={`file-item context-${contextId}`}
      onClick={handleClick}
      role="listitem"
      tabIndex={0}
    >
      <div className="file-item__icon">
        <i className={getFileIcon(file.name)}></i>
      </div>
      <div className="file-item__details">
        <span className="file-item__name">{file.name}</span>
        <span className="file-item__meta">{file.size} • {file.modified}</span>
      </div>
    </div>
  );
}
```

### 2. Vue.js Integration

```vue
<!-- ThemeSelector.vue -->
<template>
  <div class="theme-selector">
    <h3>Theme Configuration</h3>
    
    <div class="preset-themes">
      <button
        v-for="theme in availableThemes"
        :key="theme.id"
        :class="['theme-preset', { active: currentTheme === theme.id }]"
        @click="selectTheme(theme.id)"
      >
        {{ theme.name }}
      </button>
    </div>
    
    <div class="custom-colors">
      <label>Custom Colors</label>
      <textarea
        v-model="customColorsText"
        placeholder="bg-primary: #111827..."
        @input="parseCustomColors"
      ></textarea>
      <button @click="applyCustomColors" :disabled="!validCustomColors">
        Apply Custom Colors
      </button>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue';
import { themeController } from '../design-system';

export default {
  name: 'ThemeSelector',
  setup() {
    const currentTheme = ref(themeController.getCurrentTheme());
    const availableThemes = ref(themeController.getAvailableThemes());
    const customColorsText = ref('');
    const parsedColors = ref(null);
    
    const validCustomColors = computed(() => {
      return parsedColors.value && Object.keys(parsedColors.value).length > 0;
    });
    
    const selectTheme = (themeId) => {
      if (themeController.applyTheme(themeId)) {
        currentTheme.value = themeId;
      }
    };
    
    const parseCustomColors = () => {
      try {
        const lines = customColorsText.value.split('\n').filter(line => line.trim());
        const colors = {};
        
        lines.forEach(line => {
          const match = line.match(/^([a-zA-Z-]+):\s*(#[0-9a-fA-F]{6})$/);
          if (match) {
            colors[match[1]] = match[2];
          }
        });
        
        parsedColors.value = colors;
      } catch (e) {
        parsedColors.value = null;
      }
    };
    
    const applyCustomColors = () => {
      if (parsedColors.value && themeController.applyCustomColors(parsedColors.value)) {
        currentTheme.value = 'custom';
      }
    };
    
    onMounted(() => {
      document.addEventListener('theme-changed', (event) => {
        currentTheme.value = event.detail.theme;
      });
    });
    
    return {
      currentTheme,
      availableThemes,
      customColorsText,
      validCustomColors,
      selectTheme,
      parseCustomColors,
      applyCustomColors
    };
  }
};
</script>
```

## Performance Best Practices

### 1. CSS Optimization

```css
/* Use CSS containment for better performance */
.file-item {
  contain: layout style paint;
}

.photo-gallery {
  contain: layout;
}

/* Optimize animations with transform and opacity */
.modal {
  transform: translateY(100%);
  opacity: 0;
  transition: transform 250ms ease-out, opacity 250ms ease-out;
  will-change: transform, opacity;
}

.modal--open {
  transform: translateY(0);
  opacity: 1;
}

/* Use CSS Grid for efficient layouts */
.photo-gallery__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1rem;
  contain: layout;
}
```

### 2. JavaScript Performance

```javascript
// Debounce utility for expensive operations
export function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Throttle utility for scroll/resize handlers
export function throttle(func, limit) {
  let inThrottle;
  return function(...args) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
}

// Intersection Observer for lazy loading
export class LazyLoader {
  constructor(options = {}) {
    this.options = {
      rootMargin: '50px',
      threshold: 0.1,
      ...options
    };
    
    this.observer = new IntersectionObserver(
      this.handleIntersection.bind(this),
      this.options
    );
  }
  
  observe(element) {
    this.observer.observe(element);
  }
  
  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.loadContent(entry.target);
        this.observer.unobserve(entry.target);
      }
    });
  }
  
  loadContent(element) {
    // Load images, components, or other content
    const img = element.querySelector('img[data-src]');
    if (img) {
      img.src = img.dataset.src;
      img.classList.add('lazy-image--loaded');
    }
  }
}
```

## Testing Strategy

### 1. Component Testing

```javascript
// test/components/FileItem.test.js
import { FileItem } from '../../src/components/FileItem.js';

describe('FileItem', () => {
  let element, component;
  
  beforeEach(() => {
    element = document.createElement('div');
    element.className = 'file-item';
    element.dataset.name = 'test.js';
    element.dataset.size = '1.2KB';
    element.dataset.modified = '2h ago';
    document.body.appendChild(element);
    
    component = new FileItem(element);
  });
  
  afterEach(() => {
    component.destroy();
    document.body.removeChild(element);
  });
  
  test('renders file information correctly', () => {
    expect(element.querySelector('.file-item__name').textContent).toBe('test.js');
    expect(element.querySelector('.file-item__meta').textContent).toContain('1.2KB');
  });
  
  test('applies correct icon for file type', () => {
    const icon = element.querySelector('.file-item__icon i');
    expect(icon.className).toContain('fa-js-square');
  });
  
  test('handles click events', () => {
    const mockHandler = jest.fn();
    element.addEventListener('file-action', mockHandler);
    
    element.click();
    
    expect(mockHandler).toHaveBeenCalledWith(
      expect.objectContaining({
        detail: expect.objectContaining({
          action: 'open',
          file: expect.objectContaining({ name: 'test.js' })
        })
      })
    );
  });
});
```

### 2. Theme Testing

```javascript
// test/ThemeController.test.js
import { ThemeController } from '../../src/controllers/ThemeController.js';

describe('ThemeController', () => {
  let themeController;
  
  beforeEach(() => {
    themeController = new ThemeController();
  });
  
  test('applies built-in theme correctly', () => {
    const result = themeController.applyTheme('dark-terminal');
    
    expect(result).toBe(true);
    expect(getComputedStyle(document.documentElement).getPropertyValue('--color-bg-primary')).toBe('#111827');
  });
  
  test('validates custom colors', () => {
    const validColors = {
      'bg-primary': '#000000',
      'bg-secondary': '#111111',
      'text-primary': '#ffffff',
      'interactive-primary': '#00ff00'
    };
    
    const result = themeController.applyCustomColors(validColors);
    expect(result).toBe(true);
  });
  
  test('rejects invalid color configuration', () => {
    const invalidColors = {
      'bg-primary': 'not-a-color'
    };
    
    const result = themeController.applyCustomColors(invalidColors);
    expect(result).toBe(false);
  });
});
```

## Deployment Considerations

### 1. Build Configuration

```javascript
// vite.config.js
import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    lib: {
      entry: 'src/index.js',
      name: 'AdaptiveFSDesignSystem',
      fileName: 'byte-design-system'
    },
    cssCodeSplit: true,
    rollupOptions: {
      output: {
        assetFileNames: (assetInfo) => {
          if (assetInfo.name.endsWith('.css')) {
            return 'assets/[name]-[hash][extname]';
          }
          return 'assets/[name]-[hash][extname]';
        }
      }
    }
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "./src/tokens/index.scss";`
      }
    }
  }
});
```

### 2. CDN Distribution

```html
<!-- CDN usage -->
<link rel="stylesheet" href="https://cdn.byte.dev/design-system/1.0.0/byte.css">
<script src="https://cdn.byte.dev/design-system/1.0.0/byte.js"></script>

<script>
  // Initialize design system
  const { themeController, contextDetector } = AdaptiveFSDesignSystem;
  
  // Apply default theme
  themeController.applyTheme('dark-terminal');
</script>
```

This implementation guide provides developers with everything needed to successfully integrate and use the Byte design system across different platforms and frameworks while maintaining consistency, performance, and accessibility.