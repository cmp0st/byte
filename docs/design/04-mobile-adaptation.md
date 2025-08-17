# Mobile Adaptation Guidelines

## Overview

The Byte is designed to provide an optimal experience across all devices, from desktop computers to mobile phones. This document outlines the responsive design patterns, mobile-specific adaptations, and cross-platform considerations needed to maintain the terminal-first aesthetic while ensuring usability on touch devices.

## Mobile-First Design Principles

### Core Philosophy

1. **Progressive Enhancement**: Start with mobile constraints, enhance for larger screens
2. **Touch-First Interactions**: Design for finger navigation while supporting mouse/keyboard
3. **Content Priority**: Prioritize essential information and actions on smaller screens
4. **Performance Optimization**: Minimize data usage and optimize for slower connections
5. **Adaptive Contexts**: Maintain context detection capabilities across all screen sizes

### Touch Interface Considerations

- Minimum touch target size: 44px × 44px (iOS guidelines)
- Adequate spacing between interactive elements: 8px minimum
- Gesture support for common actions (swipe, pinch, long press)
- Haptic feedback for important interactions (where supported)

## Responsive Breakpoints

### Breakpoint Strategy

```css
/* Mobile-first breakpoint system */
:root {
  --breakpoint-xs: 0px;        /* Extra small phones */
  --breakpoint-sm: 640px;      /* Small phones landscape, large phones portrait */
  --breakpoint-md: 768px;      /* Tablets portrait */
  --breakpoint-lg: 1024px;     /* Tablets landscape, small desktops */
  --breakpoint-xl: 1280px;     /* Large desktops */
  --breakpoint-2xl: 1536px;    /* Extra large desktops */
}

/* Device-specific breakpoints */
@custom-media --mobile-xs (max-width: 374px);      /* iPhone SE, small Android */
@custom-media --mobile-sm (min-width: 375px) and (max-width: 639px); /* iPhone 12, standard mobile */
@custom-media --mobile-lg (min-width: 640px) and (max-width: 767px);  /* Large phones landscape */
@custom-media --tablet (min-width: 768px) and (max-width: 1023px);    /* Tablets */
@custom-media --desktop (min-width: 1024px);                          /* Desktop and up */
```

### Responsive Typography Scale

```css
/* Base typography scales responsively */
:root {
  /* Mobile typography (default) */
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.125rem;   /* 18px */
  --text-xl: 1.25rem;    /* 20px */
  --text-2xl: 1.5rem;    /* 24px */
}

/* Tablet adjustments */
@media (min-width: 768px) {
  :root {
    --text-xs: 0.8125rem;  /* 13px */
    --text-sm: 0.9375rem;  /* 15px */
    --text-base: 1.0625rem; /* 17px */
    --text-lg: 1.1875rem;  /* 19px */
    --text-xl: 1.375rem;   /* 22px */
    --text-2xl: 1.625rem;  /* 26px */
  }
}

/* Desktop scale */
@media (min-width: 1024px) {
  :root {
    --text-xs: 0.75rem;    /* 12px */
    --text-sm: 0.875rem;   /* 14px */
    --text-base: 1rem;     /* 16px */
    --text-lg: 1.125rem;   /* 18px */
    --text-xl: 1.25rem;    /* 20px */
    --text-2xl: 1.5rem;    /* 24px */
  }
}
```

## Layout Adaptations

### Header Navigation

```css
/* Mobile header - simplified and touch-friendly */
.header {
  height: var(--header-height-mobile, 4rem); /* Taller for easier touch */
  padding: 0 var(--space-4);
}

.header__nav {
  display: none; /* Hide complex navigation on mobile */
}

.header__mobile-menu {
  display: block;
}

@media (min-width: 768px) {
  .header {
    height: var(--header-height, 3.5rem);
  }
  
  .header__nav {
    display: flex;
  }
  
  .header__mobile-menu {
    display: none;
  }
}

/* Mobile menu overlay */
.mobile-menu {
  position: fixed;
  inset: 0;
  z-index: var(--z-modal);
  background-color: var(--color-bg-primary);
  transform: translateX(-100%);
  transition: transform var(--duration-base) var(--ease-out);
}

.mobile-menu--open {
  transform: translateX(0);
}

.mobile-menu__nav {
  padding: var(--space-6) var(--space-4);
}

.mobile-menu__item {
  display: block;
  padding: var(--space-3) 0;
  border-bottom: var(--border-1) solid var(--color-border-primary);
  color: var(--color-text-primary);
  font-size: var(--text-lg);
  text-decoration: none;
}
```

### Sidebar Behavior

```css
/* Mobile: Sidebar becomes bottom sheet or overlay */
@media (max-width: 767px) {
  .sidebar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 60vh;
    max-height: 500px;
    background-color: var(--color-bg-secondary);
    border-top: var(--border-1) solid var(--color-border-primary);
    border-radius: var(--radius-xl) var(--radius-xl) 0 0;
    transform: translateY(100%);
    transition: transform var(--duration-base) var(--ease-out);
    z-index: var(--z-modal);
  }
  
  .sidebar--open {
    transform: translateY(0);
  }
  
  .sidebar__handle {
    display: block;
    width: 40px;
    height: 4px;
    background-color: var(--color-border-secondary);
    border-radius: var(--radius-full);
    margin: var(--space-2) auto;
    cursor: pointer;
  }
}

/* Tablet: Collapsible sidebar */
@media (min-width: 768px) and (max-width: 1023px) {
  .sidebar {
    width: var(--sidebar-width-collapsed);
    transition: width var(--duration-base) var(--ease-out);
  }
  
  .sidebar--expanded {
    width: var(--sidebar-width);
  }
  
  .sidebar__handle {
    display: none;
  }
}

/* Desktop: Full sidebar */
@media (min-width: 1024px) {
  .sidebar {
    position: static;
    width: var(--sidebar-width);
    height: auto;
    transform: none;
    border-radius: 0;
  }
}
```

## Component Adaptations

### File Browser Mobile

```css
/* Mobile file browser adaptations */
@media (max-width: 767px) {
  .file-browser {
    border-radius: 0;
    border-left: none;
    border-right: none;
  }
  
  .file-item {
    padding: var(--space-4);
    min-height: var(--hit-target-min);
  }
  
  .file-item__name {
    font-size: var(--text-base); /* Larger for better readability */
  }
  
  .file-item__actions {
    opacity: 1; /* Always visible on mobile */
  }
  
  /* Swipe actions */
  .file-item {
    position: relative;
    overflow: hidden;
  }
  
  .file-item__swipe-actions {
    position: absolute;
    right: 0;
    top: 0;
    bottom: 0;
    display: flex;
    transform: translateX(100%);
    transition: transform var(--duration-base) var(--ease-out);
  }
  
  .file-item--swiped .file-item__swipe-actions {
    transform: translateX(0);
  }
  
  .file-item__swipe-action {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 60px;
    background-color: var(--color-interactive-primary);
    color: white;
    border: none;
    cursor: pointer;
  }
}
```

### Photo Gallery Mobile

```css
@media (max-width: 767px) {
  .photo-gallery__grid {
    grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
    gap: var(--space-2);
  }
  
  .photo-gallery__controls {
    flex-direction: column;
    gap: var(--space-3);
    align-items: flex-start;
  }
  
  .photo-gallery__actions {
    width: 100%;
    justify-content: space-between;
  }
  
  /* Photo viewer modal for mobile */
  .photo-viewer {
    position: fixed;
    inset: 0;
    z-index: var(--z-modal);
    background-color: black;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .photo-viewer__image {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }
  
  .photo-viewer__controls {
    position: absolute;
    bottom: var(--space-4);
    left: var(--space-4);
    right: var(--space-4);
    display: flex;
    justify-content: space-between;
    background-color: rgb(0 0 0 / 0.7);
    padding: var(--space-3);
    border-radius: var(--radius-lg);
  }
}
```

### Git History Mobile

```css
@media (max-width: 767px) {
  .git-history__list {
    max-height: none; /* Remove height restriction on mobile */
  }
  
  .commit-item {
    padding: var(--space-3);
  }
  
  .commit-item__timeline {
    display: none; /* Hide timeline on mobile to save space */
  }
  
  .commit-item__header {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-1);
  }
  
  .commit-item__message {
    font-size: var(--text-base);
    line-height: var(--leading-tight);
  }
  
  .commit-item__meta {
    order: -1;
    font-size: var(--text-xs);
  }
  
  /* Expandable commit details */
  .commit-item__details {
    max-height: 0;
    overflow: hidden;
    transition: max-height var(--duration-base) var(--ease-out);
  }
  
  .commit-item--expanded .commit-item__details {
    max-height: 200px;
    padding-top: var(--space-2);
  }
}
```

## Touch Interactions

### Gesture Support

```javascript
// Touch gesture handling
class TouchGestureHandler {
  constructor(element, options = {}) {
    this.element = element;
    this.options = {
      swipeThreshold: 50,
      tapTimeout: 300,
      longPressTimeout: 500,
      ...options
    };
    
    this.touchStart = null;
    this.touchEnd = null;
    this.tapTimer = null;
    this.longPressTimer = null;
    
    this.bindEvents();
  }
  
  bindEvents() {
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: false });
    this.element.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false });
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: false });
  }
  
  handleTouchStart(e) {
    this.touchStart = {
      x: e.touches[0].clientX,
      y: e.touches[0].clientY,
      time: Date.now()
    };
    
    // Start long press timer
    this.longPressTimer = setTimeout(() => {
      this.onLongPress(e);
    }, this.options.longPressTimeout);
  }
  
  handleTouchMove(e) {
    if (!this.touchStart) return;
    
    // Clear long press if user moves finger
    clearTimeout(this.longPressTimer);
    
    const deltaX = e.touches[0].clientX - this.touchStart.x;
    const deltaY = e.touches[0].clientY - this.touchStart.y;
    
    // Prevent default if horizontal swipe (for file item actions)
    if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 10) {
      e.preventDefault();
    }
  }
  
  handleTouchEnd(e) {
    if (!this.touchStart) return;
    
    clearTimeout(this.longPressTimer);
    
    this.touchEnd = {
      x: e.changedTouches[0].clientX,
      y: e.changedTouches[0].clientY,
      time: Date.now()
    };
    
    const deltaX = this.touchEnd.x - this.touchStart.x;
    const deltaY = this.touchEnd.y - this.touchStart.y;
    const deltaTime = this.touchEnd.time - this.touchStart.time;
    
    // Detect swipe
    if (Math.abs(deltaX) > this.options.swipeThreshold && deltaTime < 300) {
      if (deltaX > 0) {
        this.onSwipeRight(e);
      } else {
        this.onSwipeLeft(e);
      }
    }
    // Detect tap
    else if (Math.abs(deltaX) < 10 && Math.abs(deltaY) < 10 && deltaTime < this.options.tapTimeout) {
      this.onTap(e);
    }
    
    this.touchStart = null;
    this.touchEnd = null;
  }
  
  onTap(e) {
    this.element.dispatchEvent(new CustomEvent('mobile-tap', { detail: e }));
  }
  
  onLongPress(e) {
    this.element.dispatchEvent(new CustomEvent('mobile-longpress', { detail: e }));
  }
  
  onSwipeLeft(e) {
    this.element.dispatchEvent(new CustomEvent('mobile-swipeleft', { detail: e }));
  }
  
  onSwipeRight(e) {
    this.element.dispatchEvent(new CustomEvent('mobile-swiperight', { detail: e }));
  }
}

// Usage example for file items
document.querySelectorAll('.file-item').forEach(item => {
  new TouchGestureHandler(item);
  
  item.addEventListener('mobile-swipeleft', (e) => {
    // Show file actions
    item.classList.add('file-item--swiped');
  });
  
  item.addEventListener('mobile-swiperight', (e) => {
    // Hide file actions
    item.classList.remove('file-item--swiped');
  });
  
  item.addEventListener('mobile-longpress', (e) => {
    // Show context menu or selection mode
    e.detail.preventDefault();
    showContextMenu(item);
  });
});
```

### Pull-to-Refresh

```css
.pull-to-refresh {
  position: relative;
  overflow: hidden;
}

.pull-to-refresh__indicator {
  position: absolute;
  top: -60px;
  left: 50%;
  transform: translateX(-50%);
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--color-bg-secondary);
  border-radius: 50%;
  transition: transform var(--duration-base) var(--ease-out);
}

.pull-to-refresh--pulling .pull-to-refresh__indicator {
  transform: translateX(-50%) translateY(80px);
}

.pull-to-refresh--refreshing .pull-to-refresh__indicator {
  transform: translateX(-50%) translateY(80px);
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: translateX(-50%) translateY(80px) rotate(0deg); }
  to { transform: translateX(-50%) translateY(80px) rotate(360deg); }
}
```

## Mobile-Specific UI Patterns

### Bottom Sheet Navigation

```css
.bottom-sheet {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background-color: var(--color-bg-primary);
  border-top: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-xl) var(--radius-xl) 0 0;
  transform: translateY(100%);
  transition: transform var(--duration-base) var(--ease-out);
  z-index: var(--z-modal);
  max-height: 80vh;
  overflow: hidden;
}

.bottom-sheet--open {
  transform: translateY(0);
}

.bottom-sheet__handle {
  width: 40px;
  height: 4px;
  background-color: var(--color-border-secondary);
  border-radius: var(--radius-full);
  margin: var(--space-3) auto var(--space-4);
  cursor: pointer;
}

.bottom-sheet__content {
  padding: 0 var(--space-4) var(--space-4);
  overflow-y: auto;
  max-height: calc(80vh - 40px);
}
```

### Context Action Sheet

```css
.action-sheet {
  position: fixed;
  bottom: 0;
  left: var(--space-4);
  right: var(--space-4);
  background-color: var(--color-bg-secondary);
  border-radius: var(--radius-xl) var(--radius-xl) 0 0;
  padding: var(--space-4);
  transform: translateY(100%);
  transition: transform var(--duration-base) var(--ease-out);
  z-index: var(--z-modal);
}

.action-sheet--open {
  transform: translateY(0);
}

.action-sheet__item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-4) 0;
  border-bottom: var(--border-1) solid var(--color-border-primary);
  color: var(--color-text-primary);
  text-decoration: none;
  transition: var(--transition-colors);
}

.action-sheet__item:last-child {
  border-bottom: none;
}

.action-sheet__item:hover {
  background-color: var(--color-bg-tertiary);
}

.action-sheet__icon {
  width: 24px;
  text-align: center;
  color: var(--color-text-muted);
}

.action-sheet__item--destructive {
  color: var(--color-status-error);
}
```

## Performance Optimizations

### Image Optimization

```css
/* Responsive images */
.responsive-image {
  width: 100%;
  height: auto;
  object-fit: cover;
}

/* Lazy loading support */
.lazy-image {
  opacity: 0;
  transition: opacity var(--duration-base) var(--ease-out);
}

.lazy-image--loaded {
  opacity: 1;
}

/* Blur placeholder */
.image-placeholder {
  background: linear-gradient(90deg, var(--color-bg-tertiary) 25%, var(--color-bg-secondary) 50%, var(--color-bg-tertiary) 75%);
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
}

@keyframes loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

### Virtual Scrolling for Large Lists

```javascript
class VirtualScroller {
  constructor(container, options = {}) {
    this.container = container;
    this.options = {
      itemHeight: 60,
      bufferSize: 5,
      ...options
    };
    
    this.visibleItems = [];
    this.scrollTop = 0;
    this.viewportHeight = 0;
    
    this.init();
  }
  
  init() {
    this.container.style.overflow = 'auto';
    this.container.addEventListener('scroll', this.handleScroll.bind(this));
    
    // Create viewport
    this.viewport = document.createElement('div');
    this.viewport.style.position = 'relative';
    this.container.appendChild(this.viewport);
    
    this.updateViewport();
  }
  
  setItems(items) {
    this.items = items;
    this.totalHeight = items.length * this.options.itemHeight;
    this.viewport.style.height = `${this.totalHeight}px`;
    this.renderVisibleItems();
  }
  
  handleScroll() {
    this.scrollTop = this.container.scrollTop;
    this.renderVisibleItems();
  }
  
  renderVisibleItems() {
    if (!this.items) return;
    
    const startIndex = Math.floor(this.scrollTop / this.options.itemHeight);
    const endIndex = Math.min(
      startIndex + Math.ceil(this.container.clientHeight / this.options.itemHeight) + this.options.bufferSize,
      this.items.length
    );
    
    // Clear existing items
    this.viewport.innerHTML = '';
    
    // Render visible items
    for (let i = Math.max(0, startIndex - this.options.bufferSize); i < endIndex; i++) {
      const item = this.createItemElement(this.items[i], i);
      item.style.position = 'absolute';
      item.style.top = `${i * this.options.itemHeight}px`;
      item.style.width = '100%';
      item.style.height = `${this.options.itemHeight}px`;
      this.viewport.appendChild(item);
    }
  }
  
  createItemElement(data, index) {
    // Override this method to create custom item elements
    const element = document.createElement('div');
    element.textContent = data.name || `Item ${index}`;
    element.className = 'virtual-item';
    return element;
  }
}
```

## Testing & Validation

### Mobile Testing Checklist

- [ ] Touch targets meet minimum size requirements (44px)
- [ ] Adequate spacing between interactive elements
- [ ] Readable text at all breakpoints
- [ ] Proper keyboard support for external keyboards
- [ ] Gesture recognition works correctly
- [ ] Performance testing on mid-range devices
- [ ] Battery usage optimization
- [ ] Network usage optimization
- [ ] Accessibility testing with screen readers

### Cross-Platform Considerations

1. **iOS Safari**: Test viewport meta tag, touch events, CSS scroll behavior
2. **Android Chrome**: Verify touch responsiveness, performance on lower-end devices
3. **Progressive Web App**: Test app-like behaviors, offline functionality
4. **Tablet Interfaces**: Ensure proper adaptation for larger touch screens

### Device-Specific Adaptations

```css
/* iPhone specific optimizations */
@supports (-webkit-appearance: none) and (stroke: currentColor) {
  .ios-safe-area {
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
  }
}

/* Android specific optimizations */
@media screen and (-webkit-device-pixel-ratio: 2) and (orientation: portrait) {
  .android-optimization {
    /* Android-specific CSS */
  }
}
```

This mobile adaptation strategy ensures that the Byte maintains its developer-focused aesthetic while providing an excellent user experience across all devices and platforms.