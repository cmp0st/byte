# Component Library Documentation

## Overview

The Byte component library provides reusable UI elements that maintain consistency across all interfaces while adapting to different contexts (photo albums, git repositories, websites, regular folders). Each component is designed with the terminal-first aesthetic and supports the configurable theming system.

## Foundation Components

### Button Component

```html
<!-- Base button structure -->
<button class="btn btn--primary btn--md" type="button">
  <i class="btn__icon fas fa-download"></i>
  <span class="btn__text">Download</span>
</button>
```

```css
/* Button base styles */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  height: var(--button-height-base);
  padding: 0 var(--space-4);
  border: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-base);
  background-color: var(--color-bg-secondary);
  color: var(--color-text-primary);
  font-family: var(--font-mono);
  font-size: var(--text-sm);
  font-weight: var(--font-weight-medium);
  text-decoration: none;
  cursor: pointer;
  transition: var(--transition-colors);
  user-select: none;
}

.btn:hover {
  background-color: var(--color-bg-tertiary);
  border-color: var(--color-border-secondary);
}

.btn:focus {
  outline: none;
  box-shadow: var(--glow-focus);
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Button variants */
.btn--primary {
  background-color: var(--color-interactive-primary);
  border-color: var(--color-interactive-primary);
  color: var(--color-bg-primary);
}

.btn--primary:hover {
  background-color: var(--color-interactive-primary-hover);
  border-color: var(--color-interactive-primary-hover);
}

.btn--secondary {
  background-color: transparent;
  border-color: var(--color-border-primary);
  color: var(--color-text-secondary);
}

.btn--ghost {
  background-color: transparent;
  border-color: transparent;
  color: var(--color-text-muted);
}

/* Button sizes */
.btn--sm {
  height: var(--button-height-sm);
  padding: 0 var(--space-3);
  font-size: var(--text-xs);
}

.btn--lg {
  height: var(--button-height-lg);
  padding: 0 var(--space-6);
  font-size: var(--text-base);
}

/* Icon handling */
.btn__icon {
  flex-shrink: 0;
  font-size: 0.875em;
}

.btn__text:empty + .btn__icon,
.btn__icon:only-child {
  margin: 0;
}
```

### Input Component

```html
<!-- Input with label -->
<div class="input-group">
  <label class="input-group__label" for="filename">File name</label>
  <div class="input-wrapper">
    <input 
      class="input" 
      type="text" 
      id="filename" 
      placeholder="Enter filename..."
      value="">
    <i class="input__icon fas fa-file"></i>
  </div>
  <p class="input-group__help">Enter a valid filename without extension</p>
</div>
```

```css
.input-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.input-group__label {
  font-size: var(--text-xs);
  font-weight: var(--font-weight-medium);
  color: var(--color-text-secondary);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
}

.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.input {
  width: 100%;
  height: var(--input-height-base);
  padding: 0 var(--space-3);
  background-color: var(--color-bg-secondary);
  border: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-base);
  color: var(--color-text-primary);
  font-family: var(--font-mono);
  font-size: var(--text-sm);
  transition: var(--transition-colors);
}

.input:focus {
  outline: none;
  border-color: var(--color-interactive-primary);
  box-shadow: var(--glow-focus);
}

.input::placeholder {
  color: var(--color-text-muted);
}

.input__icon {
  position: absolute;
  right: var(--space-3);
  color: var(--color-text-muted);
  pointer-events: none;
}

.input-group__help {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
  margin: 0;
}
```

### Card Component

```html
<div class="card">
  <div class="card__header">
    <h3 class="card__title">
      <i class="card__icon fas fa-folder"></i>
      Repository Info
    </h3>
    <div class="card__actions">
      <button class="btn btn--ghost btn--sm">
        <i class="fas fa-ellipsis-h"></i>
      </button>
    </div>
  </div>
  
  <div class="card__content">
    <p>Content goes here...</p>
  </div>
  
  <div class="card__footer">
    <button class="btn btn--secondary btn--sm">Cancel</button>
    <button class="btn btn--primary btn--sm">Save</button>
  </div>
</div>
```

```css
.card {
  background-color: var(--color-bg-secondary);
  border: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-4);
  border-bottom: var(--border-1) solid var(--color-border-primary);
}

.card__title {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin: 0;
  font-size: var(--text-sm);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-primary);
}

.card__icon {
  font-size: var(--text-sm);
  color: var(--color-text-muted);
}

.card__actions {
  display: flex;
  gap: var(--space-2);
}

.card__content {
  padding: var(--space-4);
  color: var(--color-text-secondary);
  font-size: var(--text-sm);
  line-height: var(--leading-normal);
}

.card__footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  padding: var(--space-4);
  border-top: var(--border-1) solid var(--color-border-primary);
  background-color: var(--color-bg-tertiary);
}
```

## Navigation Components

### Breadcrumb Component

```html
<nav class="breadcrumb" aria-label="Breadcrumb">
  <span class="breadcrumb__prompt">$</span>
  <span class="breadcrumb__command">cd</span>
  <ol class="breadcrumb__list">
    <li class="breadcrumb__item">
      <a href="/" class="breadcrumb__link">root</a>
    </li>
    <li class="breadcrumb__item">
      <a href="/projects" class="breadcrumb__link">projects</a>
    </li>
    <li class="breadcrumb__item">
      <span class="breadcrumb__current">my-app</span>
    </li>
  </ol>
</nav>
```

```css
.breadcrumb {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-family: var(--font-mono);
  font-size: var(--text-sm);
}

.breadcrumb__prompt {
  color: var(--color-text-muted);
}

.breadcrumb__command {
  color: var(--color-text-secondary);
}

.breadcrumb__list {
  display: flex;
  align-items: center;
  margin: 0;
  padding: 0;
  list-style: none;
}

.breadcrumb__item:not(:last-child)::after {
  content: '/';
  margin: 0 var(--space-1);
  color: var(--color-text-muted);
}

.breadcrumb__link {
  color: var(--color-interactive-primary);
  text-decoration: none;
  transition: var(--transition-colors);
}

.breadcrumb__link:hover {
  color: var(--color-interactive-primary-hover);
}

.breadcrumb__current {
  color: var(--color-text-primary);
  font-weight: var(--font-weight-medium);
}
```

### Context Switcher

```html
<div class="context-switcher">
  <div class="context-switcher__info">
    <span class="context-switcher__label">type:</span>
    <span class="context-switcher__badge context-switcher__badge--git">
      <i class="fab fa-git-alt"></i>
      git repo
    </span>
  </div>
  
  <div class="context-switcher__views">
    <span class="context-switcher__label">view:</span>
    <div class="context-switcher__options">
      <button class="context-switcher__option context-switcher__option--active">
        history
      </button>
      <button class="context-switcher__option">files</button>
      <button class="context-switcher__option">branches</button>
    </div>
  </div>
</div>
```

```css
.context-switcher {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-2) 0;
  font-size: var(--text-xs);
}

.context-switcher__info,
.context-switcher__views {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.context-switcher__label {
  color: var(--color-text-muted);
}

.context-switcher__badge {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-base);
  font-size: var(--text-xs);
  font-weight: var(--font-weight-medium);
}

.context-switcher__badge--photo {
  background-color: rgb(var(--color-context-photo) / 0.1);
  color: var(--color-context-photo);
}

.context-switcher__badge--git {
  background-color: rgb(var(--color-context-git) / 0.1);
  color: var(--color-context-git);
}

.context-switcher__badge--website {
  background-color: rgb(var(--color-context-website) / 0.1);
  color: var(--color-context-website);
}

.context-switcher__options {
  display: flex;
  align-items: center;
  gap: var(--space-1);
}

.context-switcher__option {
  padding: var(--space-1) var(--space-2);
  background: none;
  border: none;
  color: var(--color-text-muted);
  font-family: var(--font-mono);
  font-size: var(--text-xs);
  cursor: pointer;
  transition: var(--transition-colors);
}

.context-switcher__option:hover {
  color: var(--color-text-secondary);
}

.context-switcher__option--active {
  color: var(--color-interactive-primary);
}

.context-switcher__option:not(:last-child)::after {
  content: '|';
  margin-left: var(--space-2);
  color: var(--color-text-muted);
}
```

## Context-Specific Components

### File Browser Component

```html
<div class="file-browser">
  <div class="file-browser__header">
    <div class="file-browser__title">
      <i class="fas fa-folder file-browser__icon"></i>
      <span>files</span>
      <span class="file-browser__count">(12 items)</span>
    </div>
    <div class="file-browser__actions">
      <button class="btn btn--ghost btn--sm">
        <i class="fas fa-sort-alpha-down"></i>
      </button>
    </div>
  </div>
  
  <div class="file-browser__list">
    <!-- File items -->
    <div class="file-item">
      <div class="file-item__icon">
        <i class="fas fa-file-code file-item__type-icon"></i>
      </div>
      <div class="file-item__details">
        <span class="file-item__name">index.html</span>
        <span class="file-item__meta">2.1kb • Modified 2h ago</span>
      </div>
      <div class="file-item__actions">
        <button class="btn btn--ghost btn--sm">
          <i class="fas fa-edit"></i>
        </button>
      </div>
    </div>
  </div>
</div>
```

```css
.file-browser {
  background-color: var(--color-bg-secondary);
  border: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.file-browser__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-3) var(--space-4);
  border-bottom: var(--border-1) solid var(--color-border-primary);
  background-color: var(--color-bg-tertiary);
}

.file-browser__title {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--color-text-primary);
}

.file-browser__icon {
  color: var(--color-text-muted);
}

.file-browser__count {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}

.file-browser__list {
  max-height: 400px;
  overflow-y: auto;
}

.file-item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-2) var(--space-4);
  border-bottom: var(--border-1) solid var(--color-border-primary);
  cursor: pointer;
  transition: var(--transition-colors);
}

.file-item:hover {
  background-color: var(--color-bg-tertiary);
}

.file-item:last-child {
  border-bottom: none;
}

.file-item__icon {
  flex-shrink: 0;
  width: var(--space-4);
  text-align: center;
}

.file-item__type-icon {
  font-size: var(--text-sm);
  color: var(--color-text-muted);
}

.file-item__details {
  flex: 1;
  min-width: 0;
}

.file-item__name {
  display: block;
  font-size: var(--text-sm);
  color: var(--color-text-primary);
  font-weight: var(--font-weight-medium);
  font-family: var(--font-mono);
  text-overflow: ellipsis;
  overflow: hidden;
  white-space: nowrap;
}

.file-item__meta {
  display: block;
  font-size: var(--text-xs);
  color: var(--color-text-muted);
  margin-top: var(--space-1);
}

.file-item__actions {
  opacity: 0;
  transition: var(--transition-opacity);
}

.file-item:hover .file-item__actions {
  opacity: 1;
}
```

### Photo Gallery Component

```html
<div class="photo-gallery">
  <div class="photo-gallery__controls">
    <div class="photo-gallery__info">
      <i class="fas fa-images"></i>
      <span>47 photos</span>
      <span class="photo-gallery__size">142.3 MB</span>
    </div>
    <div class="photo-gallery__actions">
      <button class="btn btn--ghost btn--sm">
        <i class="fas fa-download"></i>
        Download All
      </button>
      <button class="btn btn--ghost btn--sm">
        <i class="fas fa-play"></i>
        Slideshow
      </button>
    </div>
  </div>
  
  <div class="photo-gallery__grid">
    <div class="photo-item">
      <div class="photo-item__image">
        <img src="image.jpg" alt="Photo" loading="lazy">
        <div class="photo-item__overlay">
          <i class="fas fa-search-plus"></i>
        </div>
      </div>
      <div class="photo-item__details">
        <span class="photo-item__name">IMG_001.jpg</span>
        <span class="photo-item__size">2.3 MB</span>
      </div>
    </div>
  </div>
</div>
```

```css
.photo-gallery__controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-3) 0;
  border-bottom: var(--border-1) solid var(--color-border-primary);
  margin-bottom: var(--space-4);
}

.photo-gallery__info {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
}

.photo-gallery__size {
  color: var(--color-text-muted);
}

.photo-gallery__actions {
  display: flex;
  gap: var(--space-2);
}

.photo-gallery__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(var(--gallery-thumbnail-size), 1fr));
  gap: var(--gallery-gap);
}

.photo-item {
  cursor: pointer;
  transition: var(--transition-transform);
}

.photo-item:hover {
  transform: scale(1.02);
}

.photo-item__image {
  position: relative;
  aspect-ratio: var(--gallery-aspect-ratio);
  background-color: var(--color-bg-tertiary);
  border-radius: var(--radius-base);
  overflow: hidden;
}

.photo-item__image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.photo-item__overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: rgb(0 0 0 / 0.6);
  opacity: 0;
  transition: var(--transition-opacity);
}

.photo-item:hover .photo-item__overlay {
  opacity: 1;
}

.photo-item__overlay i {
  font-size: var(--text-xl);
  color: white;
}

.photo-item__details {
  padding: var(--space-2) 0;
  text-align: center;
}

.photo-item__name {
  display: block;
  font-size: var(--text-xs);
  color: var(--color-text-secondary);
  font-family: var(--font-mono);
  text-overflow: ellipsis;
  overflow: hidden;
  white-space: nowrap;
}

.photo-item__size {
  display: block;
  font-size: var(--text-xs);
  color: var(--color-text-muted);
  margin-top: var(--space-1);
}
```

### Git History Component

```html
<div class="git-history">
  <div class="git-history__header">
    <div class="git-history__title">
      <i class="fas fa-history"></i>
      <span>commit history</span>
      <span class="git-history__branch">(main)</span>
    </div>
    <div class="git-history__actions">
      <button class="btn btn--ghost btn--sm">
        <i class="fas fa-code-branch"></i>
        Branches
      </button>
    </div>
  </div>
  
  <div class="git-history__list">
    <div class="commit-item">
      <div class="commit-item__timeline">
        <div class="commit-item__dot commit-item__dot--feature"></div>
        <div class="commit-item__line"></div>
      </div>
      <div class="commit-item__content">
        <div class="commit-item__header">
          <span class="commit-item__message">feat: add user authentication</span>
          <span class="commit-item__time">2h ago</span>
        </div>
        <div class="commit-item__meta">
          <span class="commit-item__hash">a3b4c5d</span>
          <span class="commit-item__author">by dev@localhost</span>
        </div>
        <div class="commit-item__stats">
          +127 -45 lines • 8 files changed
        </div>
      </div>
    </div>
  </div>
</div>
```

```css
.git-history {
  background-color: var(--color-bg-secondary);
  border: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.git-history__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-3) var(--space-4);
  border-bottom: var(--border-1) solid var(--color-border-primary);
  background-color: var(--color-bg-tertiary);
}

.git-history__title {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--color-text-primary);
}

.git-history__branch {
  color: var(--color-text-muted);
}

.git-history__list {
  max-height: 500px;
  overflow-y: auto;
}

.commit-item {
  display: flex;
  gap: var(--space-3);
  padding: var(--space-4);
  border-bottom: var(--border-1) solid var(--color-border-primary);
  transition: var(--transition-colors);
}

.commit-item:hover {
  background-color: var(--color-bg-tertiary);
}

.commit-item:last-child {
  border-bottom: none;
}

.commit-item__timeline {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: var(--commit-timeline-width);
  margin-top: var(--space-1);
}

.commit-item__dot {
  width: var(--commit-dot-size);
  height: var(--commit-dot-size);
  border-radius: 50%;
  flex-shrink: 0;
}

.commit-item__dot--feature {
  background-color: var(--color-status-online);
}

.commit-item__dot--fix {
  background-color: var(--color-status-error);
}

.commit-item__dot--refactor {
  background-color: var(--color-context-terminal);
}

.commit-item__line {
  width: 2px;
  flex: 1;
  background-color: var(--color-border-primary);
  margin-top: var(--space-2);
}

.commit-item__content {
  flex: 1;
  min-width: 0;
}

.commit-item__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-1);
}

.commit-item__message {
  font-size: var(--text-sm);
  color: var(--color-text-primary);
  font-weight: var(--font-weight-medium);
}

.commit-item__time {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}

.commit-item__meta {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
  margin-bottom: var(--space-1);
}

.commit-item__hash {
  font-family: var(--font-mono);
  color: var(--color-context-git);
}

.commit-item__stats {
  font-size: var(--text-xs);
  color: var(--color-text-muted);
}
```

## Interactive Components

### Modal Component

```html
<div class="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <div class="modal">
    <div class="modal__header">
      <h2 class="modal__title" id="modal-title">Upload Files</h2>
      <button class="modal__close" aria-label="Close modal">
        <i class="fas fa-times"></i>
      </button>
    </div>
    
    <div class="modal__content">
      <p>Select files to upload to the current directory.</p>
    </div>
    
    <div class="modal__footer">
      <button class="btn btn--secondary">Cancel</button>
      <button class="btn btn--primary">Upload</button>
    </div>
  </div>
</div>
```

```css
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: var(--z-modal);
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: rgb(0 0 0 / 0.75);
  padding: var(--space-4);
}

.modal {
  width: 100%;
  max-width: 500px;
  background-color: var(--color-bg-primary);
  border: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-xl);
}

.modal__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-4);
  border-bottom: var(--border-1) solid var(--color-border-primary);
}

.modal__title {
  margin: 0;
  font-size: var(--text-lg);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-primary);
}

.modal__close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 2rem;
  height: 2rem;
  background: none;
  border: none;
  color: var(--color-text-muted);
  cursor: pointer;
  border-radius: var(--radius-base);
  transition: var(--transition-colors);
}

.modal__close:hover {
  background-color: var(--color-bg-tertiary);
  color: var(--color-text-secondary);
}

.modal__content {
  padding: var(--space-4);
  color: var(--color-text-secondary);
  line-height: var(--leading-normal);
}

.modal__footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  padding: var(--space-4);
  border-top: var(--border-1) solid var(--color-border-primary);
  background-color: var(--color-bg-secondary);
}
```

### Toast Notification Component

```html
<div class="toast toast--success">
  <div class="toast__icon">
    <i class="fas fa-check-circle"></i>
  </div>
  <div class="toast__content">
    <div class="toast__title">Upload Complete</div>
    <div class="toast__message">3 files uploaded successfully</div>
  </div>
  <button class="toast__close">
    <i class="fas fa-times"></i>
  </button>
</div>
```

```css
.toast {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  padding: var(--space-4);
  background-color: var(--color-bg-secondary);
  border: var(--border-1) solid var(--color-border-primary);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  max-width: 400px;
  position: relative;
}

.toast--success {
  border-left: 4px solid var(--color-status-online);
}

.toast--error {
  border-left: 4px solid var(--color-status-error);
}

.toast--warning {
  border-left: 4px solid var(--color-status-warning);
}

.toast--info {
  border-left: 4px solid var(--color-status-info);
}

.toast__icon {
  flex-shrink: 0;
  width: var(--space-5);
  height: var(--space-5);
  display: flex;
  align-items: center;
  justify-content: center;
}

.toast--success .toast__icon {
  color: var(--color-status-online);
}

.toast--error .toast__icon {
  color: var(--color-status-error);
}

.toast__content {
  flex: 1;
  min-width: 0;
}

.toast__title {
  font-size: var(--text-sm);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-primary);
  margin-bottom: var(--space-1);
}

.toast__message {
  font-size: var(--text-xs);
  color: var(--color-text-secondary);
  line-height: var(--leading-normal);
}

.toast__close {
  flex-shrink: 0;
  background: none;
  border: none;
  color: var(--color-text-muted);
  cursor: pointer;
  padding: var(--space-1);
  border-radius: var(--radius-base);
  transition: var(--transition-colors);
}

.toast__close:hover {
  color: var(--color-text-secondary);
  background-color: var(--color-bg-tertiary);
}
```

## Status & Feedback Components

### Status Indicator

```html
<div class="status-indicator status-indicator--online">
  <div class="status-indicator__dot"></div>
  <span class="status-indicator__text">Online</span>
</div>
```

```css
.status-indicator {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-xs);
}

.status-indicator__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.status-indicator--online .status-indicator__dot {
  background-color: var(--color-status-online);
  animation: pulse 2s infinite;
}

.status-indicator--offline .status-indicator__dot {
  background-color: var(--color-text-muted);
}

.status-indicator--warning .status-indicator__dot {
  background-color: var(--color-status-warning);
}

.status-indicator--error .status-indicator__dot {
  background-color: var(--color-status-error);
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
```

### Progress Bar

```html
<div class="progress">
  <div class="progress__label">
    <span>Uploading files...</span>
    <span>67%</span>
  </div>
  <div class="progress__track">
    <div class="progress__fill" style="width: 67%"></div>
  </div>
</div>
```

```css
.progress {
  width: 100%;
}

.progress__label {
  display: flex;
  justify-content: space-between;
  margin-bottom: var(--space-2);
  font-size: var(--text-xs);
  color: var(--color-text-secondary);
}

.progress__track {
  width: 100%;
  height: 6px;
  background-color: var(--color-bg-tertiary);
  border-radius: var(--radius-full);
  overflow: hidden;
}

.progress__fill {
  height: 100%;
  background-color: var(--color-interactive-primary);
  border-radius: var(--radius-full);
  transition: width var(--duration-base) var(--ease-out);
}
```

## Component Usage Guidelines

### Context Adaptation

Components automatically adapt their appearance based on the detected context:

```css
/* Context-specific color adjustments */
.context-photo .card__icon {
  color: var(--color-context-photo);
}

.context-git .card__icon {
  color: var(--color-context-git);
}

.context-website .card__icon {
  color: var(--color-context-website);
}
```

### Responsive Behavior

All components include responsive design patterns:

```css
@media (max-width: 768px) {
  .photo-gallery__grid {
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  }
  
  .file-item {
    padding: var(--space-3) var(--space-4);
  }
  
  .modal {
    margin: var(--space-4);
  }
}
```

### Accessibility Features

- ARIA labels and roles
- Keyboard navigation support
- Focus management
- Screen reader compatibility
- High contrast mode support

### Performance Considerations

- Lazy loading for images
- Virtual scrolling for large lists
- Debounced interactions
- Optimized animations
- Minimal DOM manipulation

This component library provides a solid foundation for building consistent, accessible, and performant user interfaces across all platforms of the Byte.