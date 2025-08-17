# Byte Web Components

A framework-independent component library built with Web Components for the Byte file server interface.

## Quick Start

1. **Start the demo server:**
   ```bash
   cd web
   go run server.go
   ```

2. **Open your browser:**
   ```
   http://localhost:8080
   ```

## Architecture

- **Web Components**: Framework-agnostic custom elements
- **Vanilla JavaScript**: No external dependencies
- **CSS Custom Properties**: Theme-able design tokens
- **Go Demo Server**: Simple HTTP server for demonstrations

## Directory Structure

```
web/
├── components/          # Web Components
│   ├── foundation/      # Button, Input, Card
│   ├── navigation/      # Breadcrumb, Context Switcher
│   ├── context/         # File Browser, Photo Gallery, Git History
│   └── interactive/     # Modal, Toast, Progress
├── styles/              # CSS files
│   ├── tokens/          # Design tokens
│   └── themes/          # Theme variations
├── demos/               # Demo pages
├── server.go            # Demo web server
└── go.mod               # Go module for demo server
```

## Components

### Foundation Components

- **byte-button**: Configurable button with variants, sizes, icons, and loading states
- **byte-input**: Input field with labels, validation, icons, and help text
- **byte-card**: Container component with header, content, and footer slots

### Navigation Components

- **byte-breadcrumb**: Terminal-style path navigation with clickable segments
- **byte-context-switcher**: Context-aware view switcher with badges and options

### Context-Specific Components

- **byte-file-browser**: File listing with sorting, selection, and context actions

### Interactive Components

- **byte-modal**: Accessible modal dialog with focus trapping and backdrop

## Usage

### Basic Example

```html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="styles/tokens/core.css">
    <link rel="stylesheet" href="styles/tokens/semantic.css">
    <link rel="stylesheet" href="styles/themes/dark-terminal.css">
</head>
<body>
    <!-- Use components as HTML elements -->
    <byte-button variant="primary" icon="download">Download</byte-button>
    <byte-input label="Filename" placeholder="Enter name..."></byte-input>
    
    <!-- Load component scripts -->
    <script src="components/foundation/byte-button.js"></script>
    <script src="components/foundation/byte-input.js"></script>
</body>
</html>
```

### JavaScript API

```javascript
// Create components programmatically
const button = document.createElement('byte-button');
button.setAttribute('variant', 'primary');
button.textContent = 'Click me';

// Listen to component events
button.addEventListener('byte-click', (e) => {
    console.log('Button clicked:', e.detail);
});

// Update component properties
button.setAttribute('loading', '');
```

## Component Events

All components emit custom events with the `byte-` prefix:

- `byte-click` - Button clicks
- `byte-input` - Input value changes
- `byte-navigate` - Breadcrumb navigation
- `byte-view-change` - Context view changes
- `byte-file-select` - File selection
- `byte-file-open` - File open actions
- `byte-modal-open` - Modal opens
- `byte-modal-close` - Modal closes

## Theming

The design system uses CSS custom properties for theming. Create custom themes by overriding color tokens:

```css
:root {
  /* Override primary color */
  --color-interactive-primary: 59, 130, 246; /* blue-500 */
  
  /* Override background colors */
  --color-bg-primary: 255, 255, 255; /* white */
  --color-bg-secondary: 249, 250, 251; /* gray-50 */
}
```

## Integration with Byte

This component library is designed to be embedded into the main Byte application:

1. Copy the `web/` directory to your Go project
2. Use Go's `embed` package to include static assets
3. Serve components through your existing HTTP router
4. Connect components to your storage backend APIs

Example integration:

```go
//go:embed web
var webAssets embed.FS

func setupWebRoutes(r *mux.Router) {
    // Serve static assets
    webFS, _ := fs.Sub(webAssets, "web")
    r.PathPrefix("/static/").Handler(
        http.StripPrefix("/static/", http.FileServer(http.FS(webFS))),
    )
    
    // API endpoints for file operations
    r.HandleFunc("/api/files", handleFiles)
}
```

## Development

### Adding New Components

1. Create component file: `components/category/byte-component-name.js`
2. Follow Web Components standard with Shadow DOM
3. Use design tokens for styling
4. Emit custom events for interactions
5. Add to demo page for testing

### Design Tokens

All components use CSS custom properties from the design token system:

- **Spacing**: `--space-{size}` (4px base unit)
- **Typography**: `--text-{size}`, `--font-{family}`
- **Colors**: `--color-{semantic-name}-rgb`
- **Transitions**: `--transition-{type}`
- **Shadows**: `--shadow-{size}`

### Browser Support

- Modern browsers with Web Components support
- CSS custom properties
- ES2020 JavaScript features

For older browser support, consider using polyfills:
- [@webcomponents/webcomponentsjs](https://www.npmjs.com/package/@webcomponents/webcomponentsjs)

## Performance

- **Lazy Loading**: Components only load when needed
- **No Framework Overhead**: Pure Web Components
- **Small Bundle Size**: Individual component files
- **CSS Variables**: Efficient theming without rebuilds

## Contributing

1. Follow existing component patterns
2. Use semantic design tokens
3. Ensure accessibility compliance
4. Add comprehensive event handling
5. Test across different contexts
6. Update documentation and demos