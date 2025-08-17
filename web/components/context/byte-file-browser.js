class ByteFileBrowser extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this._files = [];
    this._selectedFiles = new Set();
  }

  static get observedAttributes() {
    return ['title', 'files', 'sort-by', 'sort-order', 'show-hidden'];
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

  get title() {
    return this.getAttribute('title') || 'files';
  }

  get files() {
    const filesAttr = this.getAttribute('files');
    if (filesAttr) {
      try {
        return JSON.parse(filesAttr);
      } catch {
        return [];
      }
    }
    return this._files;
  }

  set files(value) {
    this._files = Array.isArray(value) ? value : [];
    this.setAttribute('files', JSON.stringify(this._files));
  }

  get sortBy() {
    return this.getAttribute('sort-by') || 'name';
  }

  get sortOrder() {
    return this.getAttribute('sort-order') || 'asc';
  }

  get showHidden() {
    return this.hasAttribute('show-hidden');
  }

  setupEventListeners() {
    this.shadowRoot.addEventListener('click', (e) => {
      const fileItem = e.target.closest('.file-item');
      const actionButton = e.target.closest('.file-item__action');
      const sortButton = e.target.closest('.file-browser__sort');
      
      if (sortButton) {
        this.handleSort();
      } else if (actionButton) {
        e.stopPropagation();
        const action = actionButton.dataset.action;
        const fileData = JSON.parse(fileItem.dataset.file);
        this.handleFileAction(action, fileData, fileItem);
      } else if (fileItem) {
        const fileData = JSON.parse(fileItem.dataset.file);
        this.handleFileClick(fileData, fileItem, e);
      }
    });

    this.shadowRoot.addEventListener('dblclick', (e) => {
      const fileItem = e.target.closest('.file-item');
      if (fileItem) {
        const fileData = JSON.parse(fileItem.dataset.file);
        this.handleFileDoubleClick(fileData, fileItem);
      }
    });
  }

  handleSort() {
    const newOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    this.setAttribute('sort-order', newOrder);
    
    this.dispatchEvent(new CustomEvent('byte-sort', {
      bubbles: true,
      detail: { 
        sortBy: this.sortBy,
        sortOrder: newOrder,
        browser: this 
      }
    }));
  }

  handleFileClick(fileData, fileItem, event) {
    if (event.ctrlKey || event.metaKey) {
      // Multi-select
      if (this._selectedFiles.has(fileData.name)) {
        this._selectedFiles.delete(fileData.name);
        fileItem.classList.remove('file-item--selected');
      } else {
        this._selectedFiles.add(fileData.name);
        fileItem.classList.add('file-item--selected');
      }
    } else {
      // Single select
      this.shadowRoot.querySelectorAll('.file-item--selected').forEach(item => {
        item.classList.remove('file-item--selected');
      });
      this._selectedFiles.clear();
      this._selectedFiles.add(fileData.name);
      fileItem.classList.add('file-item--selected');
    }
    
    this.dispatchEvent(new CustomEvent('byte-file-select', {
      bubbles: true,
      detail: { 
        file: fileData,
        selected: Array.from(this._selectedFiles),
        browser: this 
      }
    }));
  }

  handleFileDoubleClick(fileData, fileItem) {
    this.dispatchEvent(new CustomEvent('byte-file-open', {
      bubbles: true,
      detail: { 
        file: fileData,
        browser: this 
      }
    }));
  }

  handleFileAction(action, fileData, fileItem) {
    this.dispatchEvent(new CustomEvent('byte-file-action', {
      bubbles: true,
      detail: { 
        action,
        file: fileData,
        browser: this 
      }
    }));
  }

  getFileIcon(file) {
    if (file.type === 'directory') {
      return 'fas fa-folder';
    }
    
    const ext = file.name.split('.').pop()?.toLowerCase();
    const iconMap = {
      'js': 'fab fa-js-square',
      'ts': 'fab fa-js-square',
      'html': 'fab fa-html5',
      'css': 'fab fa-css3-alt',
      'md': 'fab fa-markdown',
      'json': 'fas fa-code',
      'yml': 'fas fa-code',
      'yaml': 'fas fa-code',
      'txt': 'fas fa-file-alt',
      'pdf': 'fas fa-file-pdf',
      'jpg': 'fas fa-file-image',
      'jpeg': 'fas fa-file-image',
      'png': 'fas fa-file-image',
      'gif': 'fas fa-file-image',
      'svg': 'fas fa-file-image',
      'mp4': 'fas fa-file-video',
      'mov': 'fas fa-file-video',
      'mp3': 'fas fa-file-audio',
      'wav': 'fas fa-file-audio',
      'zip': 'fas fa-file-archive',
      'tar': 'fas fa-file-archive',
      'gz': 'fas fa-file-archive'
    };
    
    return iconMap[ext] || 'fas fa-file';
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  formatFileTime(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    
    if (diff < 60000) return 'just now';
    if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago';
    if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago';
    if (diff < 2592000000) return Math.floor(diff / 86400000) + 'd ago';
    
    return date.toLocaleDateString();
  }

  getSortedFiles() {
    const files = [...this.files];
    
    if (!this.showHidden) {
      files.filter(file => !file.name.startsWith('.'));
    }
    
    files.sort((a, b) => {
      // Directories first
      if (a.type === 'directory' && b.type !== 'directory') return -1;
      if (a.type !== 'directory' && b.type === 'directory') return 1;
      
      let comparison = 0;
      switch (this.sortBy) {
        case 'size':
          comparison = (a.size || 0) - (b.size || 0);
          break;
        case 'modified':
          comparison = (a.modified || 0) - (b.modified || 0);
          break;
        case 'name':
        default:
          comparison = a.name.localeCompare(b.name);
          break;
      }
      
      return this.sortOrder === 'desc' ? -comparison : comparison;
    });
    
    return files;
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

      .file-browser {
        background-color: var(--color-bg-secondary-rgb, rgb(31, 41, 55));
        border: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        border-radius: var(--radius-lg, 0.5rem);
        overflow: hidden;
        font-family: var(--font-mono, monospace);
      }

      .file-browser__header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: var(--space-3, 0.75rem) var(--space-4, 1rem);
        border-bottom: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        background-color: var(--color-bg-tertiary-rgb, rgb(55, 65, 81));
      }

      .file-browser__title {
        display: flex;
        align-items: center;
        gap: var(--space-2, 0.5rem);
        font-size: var(--text-sm, 0.875rem);
        color: var(--color-text-primary-rgb, rgb(243, 244, 246));
      }

      .file-browser__icon {
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
      }

      .file-browser__count {
        font-size: var(--text-xs, 0.75rem);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
      }

      .file-browser__actions {
        display: flex;
        gap: var(--space-2, 0.5rem);
      }

      .file-browser__sort {
        background: none;
        border: none;
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        cursor: pointer;
        padding: var(--space-1, 0.25rem);
        border-radius: var(--radius-sm, 0.125rem);
        transition: var(--transition-colors, all 150ms ease-out);
      }

      .file-browser__sort:hover {
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
        background-color: rgba(var(--color-text-muted, 156, 163, 175), 0.1);
      }

      .file-browser__list {
        max-height: var(--file-browser-max-height, 400px);
        overflow-y: auto;
      }

      .file-item {
        display: flex;
        align-items: center;
        gap: var(--space-3, 0.75rem);
        padding: var(--space-2, 0.5rem) var(--space-4, 1rem);
        border-bottom: var(--border-1, 1px) solid var(--color-border-primary-rgb, rgb(55, 65, 81));
        cursor: pointer;
        transition: var(--transition-colors, all 150ms ease-out);
        user-select: none;
      }

      .file-item:hover {
        background-color: var(--color-bg-tertiary-rgb, rgb(55, 65, 81));
      }

      .file-item:last-child {
        border-bottom: none;
      }

      .file-item--selected {
        background-color: rgba(var(--color-interactive-primary, 34, 197, 94), 0.1);
        border-color: rgba(var(--color-interactive-primary, 34, 197, 94), 0.3);
      }

      .file-item__icon {
        flex-shrink: 0;
        width: var(--file-icon-size, 1rem);
        text-align: center;
      }

      .file-item__type-icon {
        font-size: var(--text-sm, 0.875rem);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
      }

      .file-item__type-icon--directory {
        color: rgb(var(--color-context-website, 59, 130, 246));
      }

      .file-item__details {
        flex: 1;
        min-width: 0;
      }

      .file-item__name {
        display: block;
        font-size: var(--text-sm, 0.875rem);
        color: var(--color-text-primary-rgb, rgb(243, 244, 246));
        font-weight: var(--font-weight-medium, 500);
        text-overflow: ellipsis;
        overflow: hidden;
        white-space: nowrap;
      }

      .file-item__meta {
        display: block;
        font-size: var(--text-xs, 0.75rem);
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        margin-top: var(--space-1, 0.25rem);
      }

      .file-item__actions {
        display: flex;
        gap: var(--space-1, 0.25rem);
        opacity: 0;
        transition: var(--transition-opacity, opacity 150ms ease-out);
      }

      .file-item:hover .file-item__actions {
        opacity: 1;
      }

      .file-item__action {
        background: none;
        border: none;
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        cursor: pointer;
        padding: var(--space-1, 0.25rem);
        border-radius: var(--radius-sm, 0.125rem);
        transition: var(--transition-colors, all 150ms ease-out);
        font-size: var(--text-xs, 0.75rem);
      }

      .file-item__action:hover {
        color: var(--color-text-secondary-rgb, rgb(209, 213, 219));
        background-color: rgba(var(--color-text-muted, 156, 163, 175), 0.1);
      }

      .file-browser__empty {
        padding: var(--space-8, 2rem);
        text-align: center;
        color: var(--color-text-muted-rgb, rgb(156, 163, 175));
        font-size: var(--text-sm, 0.875rem);
      }
    `;
  }

  getTemplate() {
    const files = this.getSortedFiles();
    const count = files.length;
    
    const filesHtml = files.length > 0 ? files.map(file => `
      <div class="file-item" data-file='${JSON.stringify(file)}'>
        <div class="file-item__icon">
          <i class="file-item__type-icon ${file.type === 'directory' ? 'file-item__type-icon--directory' : ''} ${this.getFileIcon(file)}"></i>
        </div>
        <div class="file-item__details">
          <span class="file-item__name">${file.name}</span>
          <span class="file-item__meta">
            ${file.size ? this.formatFileSize(file.size) : ''}
            ${file.size && file.modified ? ' • ' : ''}
            ${file.modified ? 'Modified ' + this.formatFileTime(file.modified) : ''}
          </span>
        </div>
        <div class="file-item__actions">
          ${file.type === 'directory' ? `
            <button class="file-item__action" data-action="open" title="Open folder">
              <i class="fas fa-arrow-right"></i>
            </button>
          ` : `
            <button class="file-item__action" data-action="edit" title="Edit file">
              <i class="fas fa-edit"></i>
            </button>
            <button class="file-item__action" data-action="download" title="Download file">
              <i class="fas fa-download"></i>
            </button>
          `}
        </div>
      </div>
    `).join('') : `
      <div class="file-browser__empty">
        <i class="fas fa-folder-open" style="font-size: 2rem; margin-bottom: 1rem; display: block;"></i>
        No files found
      </div>
    `;

    return `
      <div class="file-browser">
        <div class="file-browser__header">
          <div class="file-browser__title">
            <i class="file-browser__icon fas fa-folder"></i>
            <span>${this.title}</span>
            <span class="file-browser__count">(${count} items)</span>
          </div>
          <div class="file-browser__actions">
            <button class="file-browser__sort" title="Sort files">
              <i class="fas fa-sort-alpha-${this.sortOrder === 'asc' ? 'down' : 'up'}"></i>
            </button>
          </div>
        </div>
        
        <div class="file-browser__list">
          ${filesHtml}
        </div>
      </div>
    `;
  }
}

customElements.define('byte-file-browser', ByteFileBrowser);