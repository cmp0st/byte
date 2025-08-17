class ByteCard extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  static get observedAttributes() {
    return ['title', 'icon'];
  }

  connectedCallback() {
    this.render();
  }

  attributeChangedCallback() {
    if (this.shadowRoot) {
      this.render();
    }
  }

  get title() {
    return this.getAttribute('title');
  }

  get icon() {
    return this.getAttribute('icon');
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

      .card {
        background-color: var(--color-bg-secondary-rgb, rgb(31, 41, 55));
        border: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        border-radius: var(--radius-lg, 0.5rem);
        overflow: hidden;
        font-family: var(--font-mono, monospace);
      }

      .card__header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: var(--space-4, 1rem);
        border-bottom: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        background-color: var(--color-bg-tertiary-rgb, rgb(55, 65, 81));
      }

      .card__title {
        display: flex;
        align-items: center;
        gap: var(--space-2, 0.5rem);
        margin: 0;
        font-size: var(--text-sm, 0.875rem);
        font-weight: var(--font-weight-semibold, 600);
        color: var(--color-text-primary-rgb, rgb(243, 244, 246));
      }

      .card__icon {
        font-size: var(--text-sm, 0.875rem);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
      }

      .card__actions {
        display: flex;
        gap: var(--space-2, 0.5rem);
      }

      .card__content {
        padding: var(--space-4, 1rem);
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
        font-size: var(--text-sm, 0.875rem);
        line-height: var(--leading-normal, 1.5);
      }

      .card__footer {
        display: flex;
        justify-content: flex-end;
        gap: var(--space-2, 0.5rem);
        padding: var(--space-4, 1rem);
        border-top: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        background-color: var(--color-bg-tertiary-rgb, rgb(55, 65, 81));
      }

      /* Hide sections if they don't have content */
      .card__header:empty,
      .card__footer:empty {
        display: none;
      }

      .card__content:empty {
        display: none;
      }

      /* Adjust borders when sections are hidden */
      .card__header:empty + .card__content {
        border-top: none;
      }

      .card__content + .card__footer:empty {
        display: none;
      }

      /* Slot styling */
      ::slotted([slot="actions"]) {
        display: flex;
        gap: var(--space-2, 0.5rem);
      }
    `;
  }

  getTemplate() {
    const hasTitle = this.title || this.icon;
    const iconHtml = this.icon ? `<i class="card__icon fas fa-${this.icon}"></i>` : '';
    
    const headerHtml = hasTitle ? `
      <div class="card__header">
        <h3 class="card__title">
          ${iconHtml}
          ${this.title || ''}
        </h3>
        <div class="card__actions">
          <slot name="actions"></slot>
        </div>
      </div>
    ` : '';

    return `
      <div class="card">
        ${headerHtml}
        <div class="card__content">
          <slot></slot>
        </div>
        <div class="card__footer">
          <slot name="footer"></slot>
        </div>
      </div>
    `;
  }
}

customElements.define('byte-card', ByteCard);