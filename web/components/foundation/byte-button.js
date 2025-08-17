class ByteButton extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  static get observedAttributes() {
    return ['variant', 'size', 'disabled', 'icon', 'loading'];
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

  get variant() {
    return this.getAttribute('variant') || 'secondary';
  }

  get size() {
    return this.getAttribute('size') || 'base';
  }

  get disabled() {
    return this.hasAttribute('disabled');
  }

  get icon() {
    return this.getAttribute('icon');
  }

  get loading() {
    return this.hasAttribute('loading');
  }

  setupEventListeners() {
    this.shadowRoot.addEventListener('click', (e) => {
      if (this.disabled || this.loading) {
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      
      // Dispatch custom event
      this.dispatchEvent(new CustomEvent('byte-click', {
        bubbles: true,
        detail: { button: this }
      }));
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
        display: inline-block;
      }

      .btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: var(--space-2, 0.5rem);
        padding: 0 var(--space-4, 1rem);
        border: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        border-radius: var(--radius-base, 0.25rem);
        background-color: var(--color-bg-secondary-rgb, rgb(31, 41, 55));
        color: var(--color-text-primary-rgb, rgb(243, 244, 246));
        font-family: var(--font-mono, monospace);
        font-size: var(--text-sm, 0.875rem);
        font-weight: var(--font-weight-medium, 500);
        text-decoration: none;
        cursor: pointer;
        transition: var(--transition-colors, all 150ms ease-out);
        user-select: none;
        box-sizing: border-box;
        outline: none;
      }

      .btn:hover:not(:disabled) {
        background-color: var(--color-bg-tertiary-rgb, rgb(55, 65, 81));
        border-color: var(--color-border-secondary-rgb, rgb(75, 85, 99));
      }

      .btn:focus {
        box-shadow: var(--glow-focus, 0 0 0 2px rgb(34, 197, 94, 0.5));
      }

      .btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      /* Variants */
      .btn--primary {
        background-color: rgb(var(--color-interactive-primary, 34, 197, 94));
        border-color: rgb(var(--color-interactive-primary, 34, 197, 94));
        color: var(--color-bg-primary-rgb, rgb(17, 24, 39));
      }

      .btn--primary:hover:not(:disabled) {
        background-color: rgb(var(--color-interactive-primary-hover, 22, 163, 74));
        border-color: rgb(var(--color-interactive-primary-hover, 22, 163, 74));
      }

      .btn--secondary {
        background-color: transparent;
        border-color: var(--color-border-primary-rgb, rgb(55, 65, 81));
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
      }

      .btn--ghost {
        background-color: transparent;
        border-color: transparent;
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
      }

      .btn--danger {
        background-color: rgb(var(--color-interactive-danger, 239, 68, 68));
        border-color: rgb(var(--color-interactive-danger, 239, 68, 68));
        color: var(--color-bg-primary-rgb, rgb(17, 24, 39));
      }

      /* Sizes */
      .btn--sm {
        height: var(--button-height-sm, 2rem);
        padding: 0 var(--space-3, 0.75rem);
        font-size: var(--text-xs, 0.75rem);
      }

      .btn--base {
        height: var(--button-height-base, 2.5rem);
        padding: 0 var(--space-4, 1rem);
        font-size: var(--text-sm, 0.875rem);
      }

      .btn--lg {
        height: var(--button-height-lg, 3rem);
        padding: 0 var(--space-6, 1.5rem);
        font-size: var(--text-base, 1rem);
      }

      /* Icon and loading states */
      .btn__icon {
        flex-shrink: 0;
        font-size: 0.875em;
      }

      .btn__spinner {
        width: 1em;
        height: 1em;
        border: 2px solid currentColor;
        border-top: 2px solid transparent;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }

      @keyframes spin {
        to {
          transform: rotate(360deg);
        }
      }

      .btn__text:empty {
        display: none;
      }
    `;
  }

  getTemplate() {
    const iconHtml = this.icon ? `<i class="btn__icon fas fa-${this.icon}"></i>` : '';
    const spinnerHtml = this.loading ? '<div class="btn__spinner"></div>' : '';
    const content = this.loading ? spinnerHtml : iconHtml;
    
    return `
      <button 
        class="btn btn--${this.variant} btn--${this.size}" 
        ${this.disabled || this.loading ? 'disabled' : ''}
        type="button"
      >
        ${content}
        <span class="btn__text"><slot></slot></span>
      </button>
    `;
  }
}

customElements.define('byte-button', ByteButton);