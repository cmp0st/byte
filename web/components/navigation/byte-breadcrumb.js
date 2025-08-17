class ByteBreadcrumb extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this._path = [];
  }

  static get observedAttributes() {
    return ['path', 'prompt', 'command'];
  }

  connectedCallback() {
    this.render();
    this.setupEventListeners();
  }

  attributeChangedCallback() {
    if (this.shadowRoot) {
      this.render();
    }
  }

  get path() {
    const pathAttr = this.getAttribute('path');
    if (pathAttr) {
      try {
        return JSON.parse(pathAttr);
      } catch {
        return pathAttr.split('/').filter(Boolean);
      }
    }
    return this._path;
  }

  set path(value) {
    this._path = Array.isArray(value) ? value : [];
    this.setAttribute('path', JSON.stringify(this._path));
  }

  get prompt() {
    return this.getAttribute('prompt') || '$';
  }

  get command() {
    return this.getAttribute('command') || 'cd';
  }

  setupEventListeners() {
    this.shadowRoot.addEventListener('click', (e) => {
      const link = e.target.closest('.breadcrumb__link');
      if (link) {
        e.preventDefault();
        const index = parseInt(link.dataset.index);
        const clickedPath = this.path.slice(0, index + 1);
        
        this.dispatchEvent(new CustomEvent('byte-navigate', {
          bubbles: true,
          detail: { 
            path: clickedPath,
            fullPath: '/' + clickedPath.join('/'),
            index 
          }
        }));
      }
    });
  }

  addPath(segment) {
    this._path.push(segment);
    this.setAttribute('path', JSON.stringify(this._path));
    this.render();
  }

  navigateToIndex(index) {
    this._path = this._path.slice(0, index + 1);
    this.setAttribute('path', JSON.stringify(this._path));
    this.render();
  }

  render() {
    const styles = this.getStyles();
    const template = this.getTemplate();
    
    this.shadowRoot.innerHTML = `
      <style>${styles}</style>
      ${template}
    `;
  }

  getStyles() {
    return `
      :host {
        display: block;
      }

      .breadcrumb {
        display: flex;
        align-items: center;
        gap: var(--space-2, 0.5rem);
        font-family: var(--font-mono, monospace);
        font-size: var(--text-sm, 0.875rem);
        line-height: 1;
      }

      .breadcrumb__prompt {
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        font-weight: var(--font-weight-normal, 400);
        user-select: none;
      }

      .breadcrumb__command {
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
        font-weight: var(--font-weight-normal, 400);
        user-select: none;
      }

      .breadcrumb__list {
        display: flex;
        align-items: center;
        margin: 0;
        padding: 0;
        list-style: none;
        gap: 0;
      }

      .breadcrumb__item {
        display: flex;
        align-items: center;
      }

      .breadcrumb__item:not(:last-child)::after {
        content: '/';
        margin: 0 var(--space-1, 0.25rem);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        user-select: none;
      }

      .breadcrumb__link {
        color: rgb(var(--color-interactive-primary, 34, 197, 94));
        text-decoration: none;
        transition: var(--transition-colors, all 150ms ease-out);
        cursor: pointer;
        padding: var(--space-1, 0.25rem) 0;
        border-radius: var(--radius-sm, 0.125rem);
      }

      .breadcrumb__link:hover {
        color: rgb(var(--color-interactive-primary-hover, 22, 163, 74));
        background-color: rgba(var(--color-interactive-primary, 34, 197, 94), 0.1);
      }

      .breadcrumb__current {
        color: var(--color-text-primary-rgb, rgb(243, 244, 246));
        font-weight: var(--font-weight-medium, 500);
      }

      .breadcrumb__root {
        color: rgb(var(--color-interactive-primary, 34, 197, 94));
        text-decoration: none;
        cursor: pointer;
        padding: var(--space-1, 0.25rem);
        border-radius: var(--radius-sm, 0.125rem);
        transition: var(--transition-colors, all 150ms ease-out);
      }

      .breadcrumb__root:hover {
        color: rgb(var(--color-interactive-primary-hover, 22, 163, 74));
        background-color: rgba(var(--color-interactive-primary, 34, 197, 94), 0.1);
      }
    `;
  }

  getTemplate() {
    const pathItems = this.path;
    
    // Root item (always clickable unless we're at root)
    const rootHtml = `
      <span class="breadcrumb__root" data-index="-1">root</span>
    `;

    // Path items
    const pathHtml = pathItems.map((segment, index) => {
      const isLast = index === pathItems.length - 1;
      
      if (isLast) {
        return `
          <li class="breadcrumb__item">
            <span class="breadcrumb__current">${segment}</span>
          </li>
        `;
      } else {
        return `
          <li class="breadcrumb__item">
            <a class="breadcrumb__link" data-index="${index}">${segment}</a>
          </li>
        `;
      }
    }).join('');

    return `
      <nav class="breadcrumb" aria-label="Breadcrumb">
        <span class="breadcrumb__prompt">${this.prompt}</span>
        <span class="breadcrumb__command">${this.command}</span>
        ${rootHtml}
        ${pathItems.length > 0 ? `
          <ol class="breadcrumb__list">
            ${pathHtml}
          </ol>
        ` : ''}
      </nav>
    `;
  }
}

customElements.define('byte-breadcrumb', ByteBreadcrumb);