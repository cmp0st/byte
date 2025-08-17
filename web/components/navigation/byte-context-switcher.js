class ByteContextSwitcher extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  static get observedAttributes() {
    return ['context-type', 'context-label', 'views', 'active-view'];
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

  get contextType() {
    return this.getAttribute('context-type') || 'folder';
  }

  get contextLabel() {
    return this.getAttribute('context-label') || this.getDefaultLabel();
  }

  get views() {
    const viewsAttr = this.getAttribute('views');
    if (viewsAttr) {
      try {
        return JSON.parse(viewsAttr);
      } catch {
        return viewsAttr.split(',').map(v => v.trim());
      }
    }
    return this.getDefaultViews();
  }

  get activeView() {
    return this.getAttribute('active-view') || this.views[0];
  }

  getDefaultLabel() {
    const labels = {
      'photo': 'photo album',
      'git': 'git repo',
      'website': 'website',
      'folder': 'folder'
    };
    return labels[this.contextType] || 'folder';
  }

  getDefaultViews() {
    const defaultViews = {
      'photo': ['gallery', 'list', 'slideshow'],
      'git': ['history', 'files', 'branches'],
      'website': ['preview', 'files', 'console'],
      'folder': ['list', 'grid']
    };
    return defaultViews[this.contextType] || ['list'];
  }

  getContextIcon() {
    const icons = {
      'photo': 'fas fa-images',
      'git': 'fab fa-git-alt', 
      'website': 'fas fa-globe',
      'folder': 'fas fa-folder'
    };
    return icons[this.contextType] || 'fas fa-folder';
  }

  getContextColor() {
    const colors = {
      'photo': 'var(--color-context-photo, 168, 85, 247)',
      'git': 'var(--color-context-git, 249, 115, 22)',
      'website': 'var(--color-context-website, 59, 130, 246)',
      'folder': 'var(--color-text-muted, 156, 163, 175)'
    };
    return colors[this.contextType] || 'var(--color-text-muted, 156, 163, 175)';
  }

  setupEventListeners() {
    this.shadowRoot.addEventListener('click', (e) => {
      const viewOption = e.target.closest('.context-switcher__option');
      if (viewOption && !viewOption.classList.contains('context-switcher__option--active')) {
        const view = viewOption.textContent.trim();
        this.setAttribute('active-view', view);
        
        this.dispatchEvent(new CustomEvent('byte-view-change', {
          bubbles: true,
          detail: { 
            view,
            contextType: this.contextType,
            switcher: this
          }
        }));
        
        this.render();
      }
    });
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

      .context-switcher {
        display: flex;
        align-items: center;
        gap: var(--space-4, 1rem);
        padding: var(--space-2, 0.5rem) 0;
        font-size: var(--text-xs, 0.75rem);
        font-family: var(--font-mono, monospace);
      }

      .context-switcher__info,
      .context-switcher__views {
        display: flex;
        align-items: center;
        gap: var(--space-2, 0.5rem);
      }

      .context-switcher__label {
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        user-select: none;
      }

      .context-switcher__badge {
        display: flex;
        align-items: center;
        gap: var(--space-1, 0.25rem);
        padding: var(--space-1, 0.25rem) var(--space-2, 0.5rem);
        border-radius: var(--radius-base, 0.25rem);
        font-size: var(--text-xs, 0.75rem);
        font-weight: var(--font-weight-medium, 500);
        user-select: none;
      }

      .context-switcher__badge--photo {
        background-color: rgba(var(--color-context-photo, 168, 85, 247), 0.1);
        color: rgb(var(--color-context-photo, 168, 85, 247));
      }

      .context-switcher__badge--git {
        background-color: rgba(var(--color-context-git, 249, 115, 22), 0.1);
        color: rgb(var(--color-context-git, 249, 115, 22));
      }

      .context-switcher__badge--website {
        background-color: rgba(var(--color-context-website, 59, 130, 246), 0.1);
        color: rgb(var(--color-context-website, 59, 130, 246));
      }

      .context-switcher__badge--folder {
        background-color: rgba(var(--color-text-muted, 156, 163, 175), 0.1);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
      }

      .context-switcher__options {
        display: flex;
        align-items: center;
        gap: var(--space-1, 0.25rem);
      }

      .context-switcher__option {
        padding: var(--space-1, 0.25rem) var(--space-2, 0.5rem);
        background: none;
        border: none;
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        font-family: var(--font-mono, monospace);
        font-size: var(--text-xs, 0.75rem);
        cursor: pointer;
        transition: var(--transition-colors, all 150ms ease-out);
        border-radius: var(--radius-sm, 0.125rem);
        user-select: none;
      }

      .context-switcher__option:hover {
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
        background-color: rgba(var(--color-text-muted, 156, 163, 175), 0.1);
      }

      .context-switcher__option--active {
        color: rgb(var(--color-interactive-primary, 34, 197, 94));
        background-color: rgba(var(--color-interactive-primary, 34, 197, 94), 0.1);
      }

      .context-switcher__option--active:hover {
        color: rgb(var(--color-interactive-primary, 34, 197, 94));
        background-color: rgba(var(--color-interactive-primary, 34, 197, 94), 0.2);
      }

      .context-switcher__separator {
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        margin: 0 var(--space-1, 0.25rem);
        user-select: none;
      }

      @media (max-width: 640px) {
        .context-switcher {
          flex-direction: column;
          align-items: flex-start;
          gap: var(--space-2, 0.5rem);
        }
      }
    `;
  }

  getTemplate() {
    const views = this.views;
    const activeView = this.activeView;
    
    const viewOptionsHtml = views.map((view, index) => {
      const isActive = view === activeView;
      const separator = index < views.length - 1 ? '<span class="context-switcher__separator">|</span>' : '';
      
      return `
        <button class="context-switcher__option ${isActive ? 'context-switcher__option--active' : ''}"
                aria-pressed="${isActive}">
          ${view}
        </button>
        ${separator}
      `;
    }).join('');

    return `
      <div class="context-switcher">
        <div class="context-switcher__info">
          <span class="context-switcher__label">type:</span>
          <span class="context-switcher__badge context-switcher__badge--${this.contextType}">
            <i class="${this.getContextIcon()}"></i>
            ${this.contextLabel}
          </span>
        </div>
        
        ${views.length > 1 ? `
          <div class="context-switcher__views">
            <span class="context-switcher__label">view:</span>
            <div class="context-switcher__options" role="tablist">
              ${viewOptionsHtml}
            </div>
          </div>
        ` : ''}
      </div>
    `;
  }
}

customElements.define('byte-context-switcher', ByteContextSwitcher);