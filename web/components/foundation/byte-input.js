class ByteInput extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  static get observedAttributes() {
    return ['label', 'placeholder', 'value', 'type', 'disabled', 'required', 'icon', 'help'];
  }

  connectedCallback() {
    this.render();
    this.setupEventListeners();
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (this.shadowRoot && oldValue !== newValue) {
      if (name === 'value') {
        const input = this.shadowRoot.querySelector('.input');
        if (input && input.value !== newValue) {
          input.value = newValue || '';
        }
      } else {
        this.render();
      }
    }
  }

  get label() {
    return this.getAttribute('label');
  }

  get placeholder() {
    return this.getAttribute('placeholder') || '';
  }

  get value() {
    const input = this.shadowRoot?.querySelector('.input');
    return input ? input.value : (this.getAttribute('value') || '');
  }

  set value(val) {
    this.setAttribute('value', val);
    const input = this.shadowRoot?.querySelector('.input');
    if (input) {
      input.value = val;
    }
  }

  get type() {
    return this.getAttribute('type') || 'text';
  }

  get disabled() {
    return this.hasAttribute('disabled');
  }

  get required() {
    return this.hasAttribute('required');
  }

  get icon() {
    return this.getAttribute('icon');
  }

  get help() {
    return this.getAttribute('help');
  }

  setupEventListeners() {
    const input = this.shadowRoot.querySelector('.input');
    if (!input) return;

    input.addEventListener('input', (e) => {
      this.setAttribute('value', e.target.value);
      this.dispatchEvent(new CustomEvent('byte-input', {
        bubbles: true,
        detail: { value: e.target.value, input: this }
      }));
    });

    input.addEventListener('change', (e) => {
      this.dispatchEvent(new CustomEvent('byte-change', {
        bubbles: true,
        detail: { value: e.target.value, input: this }
      }));
    });

    input.addEventListener('focus', (e) => {
      this.dispatchEvent(new CustomEvent('byte-focus', {
        bubbles: true,
        detail: { input: this }
      }));
    });

    input.addEventListener('blur', (e) => {
      this.dispatchEvent(new CustomEvent('byte-blur', {
        bubbles: true,
        detail: { input: this }
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
    
    // Re-setup event listeners after render
    this.setupEventListeners();
  }

  getStyles() {
    return `
      :host {
        display: block;
      }

      .input-group {
        display: flex;
        flex-direction: column;
        gap: var(--space-1, 0.25rem);
      }

      .input-group__label {
        font-size: var(--text-xs, 0.75rem);
        font-weight: var(--font-weight-medium, 500);
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
        text-transform: uppercase;
        letter-spacing: var(--tracking-wide, 0.025em);
        font-family: var(--font-mono, monospace);
      }

      .input-wrapper {
        position: relative;
        display: flex;
        align-items: center;
      }

      .input {
        width: 100%;
        height: var(--input-height-base, 2.5rem);
        padding: 0 var(--space-3, 0.75rem);
        background-color: var(--color-bg-secondary-rgb, rgb(31, 41, 55));
        border: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        border-radius: var(--radius-base, 0.25rem);
        color: var(--color-text-primary-rgb, rgb(243, 244, 246));
        font-family: var(--font-mono, monospace);
        font-size: var(--text-sm, 0.875rem);
        transition: var(--transition-colors, all 150ms ease-out);
        outline: none;
        box-sizing: border-box;
      }

      .input:focus {
        border-color: rgb(var(--color-interactive-primary, 34, 197, 94));
        box-shadow: var(--glow-focus, 0 0 0 2px rgb(34, 197, 94, 0.5));
      }

      .input::placeholder {
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
      }

      .input:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      .input--with-icon {
        padding-right: calc(var(--space-3, 0.75rem) + var(--space-6, 1.5rem));
      }

      .input__icon {
        position: absolute;
        right: var(--space-3, 0.75rem);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        pointer-events: none;
        font-size: var(--text-sm, 0.875rem);
      }

      .input-group__help {
        font-size: var(--text-xs, 0.75rem);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        margin: 0;
        font-family: var(--font-mono, monospace);
      }

      .required-indicator {
        color: rgb(var(--color-interactive-danger, 239, 68, 68));
        margin-left: var(--space-1, 0.25rem);
      }
    `;
  }

  getTemplate() {
    const labelHtml = this.label ? `
      <label class="input-group__label">
        ${this.label}
        ${this.required ? '<span class="required-indicator">*</span>' : ''}
      </label>
    ` : '';

    const iconHtml = this.icon ? `<i class="input__icon fas fa-${this.icon}"></i>` : '';
    
    const helpHtml = this.help ? `
      <p class="input-group__help">${this.help}</p>
    ` : '';

    return `
      <div class="input-group">
        ${labelHtml}
        <div class="input-wrapper">
          <input 
            class="input ${this.icon ? 'input--with-icon' : ''}"
            type="${this.type}"
            placeholder="${this.placeholder}"
            value="${this.value}"
            ${this.disabled ? 'disabled' : ''}
            ${this.required ? 'required' : ''}
          />
          ${iconHtml}
        </div>
        ${helpHtml}
      </div>
    `;
  }
}

customElements.define('byte-input', ByteInput);