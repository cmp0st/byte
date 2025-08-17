# Byte - Requirements

## What We're Building

A file server that adapts its interface based on folder content. Same files, different views:
- **Web UI**: Context-aware interfaces (photo albums, git repos, websites)  
- **SFTP**: Standard file access for tools/automation
- **SSH Terminal**: Interactive file browser using Bubble Tea
- **Git SSH**: Standard git operations

## Core Features

### Multi-Protocol Access
- **Web Interface**: Modern file browser that adapts based on folder type
- **SFTP Server**: Standard protocol for file operations and mounting
- **SSH Terminal**: Interactive TUI file browser (Bubble Tea)
- **Git SSH**: Standard git clone/push/pull operations

### Contextual Folder Types
- **Photo Albums**: Folders with mostly images → grid view, lightbox, slideshow
- **Git Repos**: Folders with `.git` → commit history, file browser with git context
- **Websites**: Folders with `index.html` → live preview, file browser
- **Regular Folders**: Standard file browser interface

### Real-Time Sync
- Changes via any interface immediately show in all others
- File uploads via SFTP instantly appear in web UI
- Git pushes trigger web interface updates

## Technical Stack

### Backend
- **Language**: Go (for SSH performance) or Node.js
- **SSH/SFTP**: Custom SSH server with command routing
- **Database**: SQLite for metadata
- **Real-time**: WebSockets for live updates

### Frontend
- **Web**: React/Vue + Tailwind CSS
- **Terminal**: Bubble Tea (Go TUI framework)
- **Styling**: Dark theme, monospace fonts, minimal aesthetic

### Architecture
```
SSH Connection → Route by command:
├── git-* → Git handlers
├── sftp → File system access  
├── shell → Bubble Tea interface
└── web → HTTP API
```

## User Flows

### Developer Workflow
```bash
git push ssh://user@server/repo.git    # Push code
ssh user@server                        # Browse via terminal
# Check web UI for visual review
```

### File Management
```bash
sftp user@server                       # Upload files
# Files auto-organized in web UI by type
# Browse contextually via web or terminal
```

## Implementation Plan

### Phase 1: Foundation (2-3 weeks)
- Basic web file browser
- SFTP server
- Simple folder detection
- Authentication system

### Phase 2: Context Views (2-3 weeks)  
- Photo album interface
- Git repository interface
- Website preview interface
- Real-time sync between interfaces

### Phase 3: Terminal Interface (1-2 weeks)
- Bubble Tea SSH interface
- Interactive file browser
- Context-aware terminal views

### Phase 4: Git Integration (1-2 weeks)
- Git SSH operations
- Web interface git features
- Terminal git integration

## Requirements

### Performance
- File listing <200ms for <1000 files
- Real-time sync <1s between interfaces
- SFTP performance near-native

### Security
- SSH key authentication
- HTTPS for web interface
- File permissions enforced across all access methods

### Compatibility
- Standard SFTP clients (OpenSSH, FileZilla, etc.)
- Standard Git clients (git CLI, VS Code, etc.)
- Modern web browsers

## Success Criteria

- All three access methods work with same file structure
- Context detection works for 3+ folder types
- Real-time changes sync between interfaces
- No data corruption across access methods
- 5+ users can complete full workflows

## Design Notes

- **Terminal-first aesthetic**: Dark theme, monospace fonts
- **Minimal UI**: Clean, functional, developer-focused
- **Consistent navigation**: Same breadcrumbs/structure across interfaces
- **Smooth transitions**: Context switching feels natural
- **Keyboard-driven**: Efficient navigation patterns
