class ByteModal extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this._isOpen = false;
    this._backdrop = null;
  }

  static get observedAttributes() {
    return ['open', 'title', 'size', 'closable'];
  }

  connectedCallback() {
    this.render();
    this.setupEventListeners();
    
    if (this.hasAttribute('open')) {
      this.open();
    }
  }

  disconnectedCallback() {
    this.close();
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (this.shadowRoot) {
      if (name === 'open') {
        if (newValue !== null) {
          this.open();
        } else {
          this.close();
        }
      } else {
        this.render();
      }
    }
  }

  get title() {
    return this.getAttribute('title') || '';
  }

  get size() {
    return this.getAttribute('size') || 'md';
  }

  get closable() {
    return this.getAttribute('closable') !== 'false';
  }

  get isOpen() {
    return this._isOpen;
  }

  open() {
    if (this._isOpen) return;
    
    this._isOpen = true;
    this.setAttribute('open', '');
    
    // Create backdrop
    this._backdrop = document.createElement('div');
    this._backdrop.className = 'modal-backdrop';
    document.body.appendChild(this._backdrop);
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden';
    
    // Show modal
    const modal = this.shadowRoot.querySelector('.modal-overlay');
    if (modal) {
      modal.style.display = 'flex';
      // Trigger animation
      requestAnimationFrame(() => {
        modal.classList.add('modal-overlay--open');
      });
    }
    
    // Focus management
    this.trapFocus();
    
    this.dispatchEvent(new CustomEvent('byte-modal-open', {
      bubbles: true,
      detail: { modal: this }
    }));
  }

  close() {
    if (!this._isOpen) return;
    
    this._isOpen = false;
    this.removeAttribute('open');
    
    const modal = this.shadowRoot.querySelector('.modal-overlay');
    if (modal) {
      modal.classList.remove('modal-overlay--open');
      
      // Wait for animation to complete
      setTimeout(() => {
        modal.style.display = 'none';
      }, 150);
    }
    
    // Remove backdrop
    if (this._backdrop) {
      this._backdrop.remove();
      this._backdrop = null;
    }
    
    // Restore body scroll
    document.body.style.overflow = '';
    
    this.dispatchEvent(new CustomEvent('byte-modal-close', {
      bubbles: true,
      detail: { modal: this }
    }));
  }

  setupEventListeners() {
    // Close button
    this.shadowRoot.addEventListener('click', (e) => {
      const closeButton = e.target.closest('.modal__close');
      if (closeButton && this.closable) {
        this.close();
      }
    });

    // Backdrop click
    this.shadowRoot.addEventListener('click', (e) => {
      if (e.target.classList.contains('modal-overlay') && this.closable) {
        this.close();
      }
    });

    // Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this._isOpen && this.closable) {
        this.close();
      }
    });
  }

  trapFocus() {
    const modal = this.shadowRoot.querySelector('.modal');
    const focusableElements = modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    
    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];
    
    if (firstElement) {
      firstElement.focus();
    }
    
    modal.addEventListener('keydown', (e) => {
      if (e.key === 'Tab') {
        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            e.preventDefault();
            lastElement.focus();
          }
        } else {
          if (document.activeElement === lastElement) {
            e.preventDefault();
            firstElement.focus();
          }
        }
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
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        z-index: var(--z-modal, 400);
        pointer-events: none;
      }

      :host([open]) {
        pointer-events: auto;
      }

      .modal-overlay {
        position: fixed;
        inset: 0;
        display: none;
        align-items: center;
        justify-content: center;
        background-color: rgba(0, 0, 0, 0.75);
        padding: var(--space-4, 1rem);
        opacity: 0;
        transition: opacity var(--duration-fast, 150ms) var(--ease-out, ease-out);
      }

      .modal-overlay--open {
        opacity: 1;
      }

      .modal {
        width: 100%;
        background-color: var(--color-bg-primary-rgb, rgb(17, 24, 39));
        border: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        border-radius: var(--radius-lg, 0.5rem);
        box-shadow: var(--shadow-xl, 0 25px 50px -12px rgba(0, 0, 0, 0.25));
        font-family: var(--font-mono, monospace);
        transform: scale(0.95);
        transition: transform var(--duration-fast, 150ms) var(--ease-out, ease-out);
      }

      .modal-overlay--open .modal {
        transform: scale(1);
      }

      /* Modal sizes */
      .modal--sm {
        max-width: 400px;
      }

      .modal--md {
        max-width: 500px;
      }

      .modal--lg {
        max-width: 700px;
      }

      .modal--xl {
        max-width: 900px;
      }

      .modal--full {
        max-width: 95vw;
        max-height: 95vh;
      }

      .modal__header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: var(--space-4, 1rem);
        border-bottom: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
      }

      .modal__title {
        margin: 0;
        font-size: var(--text-lg, 1.125rem);
        font-weight: var(--font-weight-semibold, 600);
        color: var(--color-text-primary-rgb, rgb(243, 244, 246));
      }

      .modal__close {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 2rem;
        height: 2rem;
        background: none;
        border: none;
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        cursor: pointer;
        border-radius: var(--radius-base, 0.25rem);
        transition: var(--transition-colors, all 150ms ease-out);
      }

      .modal__close:hover {
        background-color: var(--color-bg-tertiary-rgb, rgb(55, 65, 81));
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
      }

      .modal__content {
        padding: var(--space-4, 1rem);
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
        line-height: var(--leading-normal, 1.5);
        max-height: 60vh;
        overflow-y: auto;
      }

      .modal__footer {
        display: flex;
        justify-content: flex-end;
        gap: var(--space-2, 0.5rem);
        padding: var(--space-4, 1rem);
        border-top: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        background-color: var(--color-bg-secondary-rgb, rgb(31, 41, 55));
      }

      /* Hide sections if they don't have content */
      .modal__header:empty,
      .modal__footer:empty {
        display: none;
      }

      .modal__content:empty {
        padding: 0;
      }

      /* Adjust borders when sections are hidden */
      .modal__header:empty + .modal__content {
        border-top: none;
      }

      .modal__content + .modal__footer:empty {
        border-top: none;
      }

      @media (max-width: 640px) {
        .modal {
          margin: var(--space-4, 1rem);
          max-width: none;
        }
        
        .modal--full {
          max-width: none;
          max-height: none;
          height: 100%;
        }
      }
    `;
  }

  getTemplate() {
    const hasTitle = this.title || this.closable;
    
    const headerHtml = hasTitle ? `
      <div class="modal__header">
        <h2 class="modal__title">${this.title}</h2>
        ${this.closable ? `
          <button class="modal__close" aria-label="Close modal">
            <i class="fas fa-times"></i>
          </button>
        ` : ''}
      </div>
    ` : '';

    return `
      <div class="modal-overlay" role="dialog" aria-modal="true" ${this.title ? `aria-labelledby="modal-title"` : ''}>
        <div class="modal modal--${this.size}">
          ${headerHtml}
          <div class="modal__content">
            <slot></slot>
          </div>
          <div class="modal__footer">
            <slot name="footer"></slot>
          </div>
        </div>
      </div>
    `;
  }
}

// Add global backdrop styles
if (!document.querySelector('#byte-modal-styles')) {
  const style = document.createElement('style');
  style.id = 'byte-modal-styles';
  style.textContent = `
    .modal-backdrop {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(0, 0, 0, 0.5);
      z-index: 399;
    }
  `;
  document.head.appendChild(style);
}

customElements.define('byte-modal', ByteModal);