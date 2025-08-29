import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  FlatList, 
  TouchableOpacity, 
  StyleSheet, 
  Platform,
  ActivityIndicator,
  Dimensions,
  Alert
} from 'react-native';
import { fileServiceClient, FileInfo, DirectoryEntry } from '../design/api';
import { tokens, rgb, rgba } from '../design/tokens';
import { 
  FolderIcon, 
  FileIcon, 
  CodeIcon, 
  WebIcon, 
  ImageIcon, 
  DocumentIcon, 
  GitIcon, 
  SettingsIcon,
  HomeIcon,
  PlusIcon,
  EditIcon,
  DeleteIcon,
  EyeIcon,
  MoreIcon
} from './Icons';
import { CreateModal } from './CreateModal';
import { FileViewer } from './FileViewer';

interface FileBrowserProps {
  initialPath?: string;
}

type ViewMode = 'grid' | 'list';

export function FileBrowser({ initialPath = '/' }: FileBrowserProps) {
  const [currentPath, setCurrentPath] = useState(initialPath);
  const [files, setFiles] = useState<DirectoryEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<ViewMode>('grid');
  
  // Modal states
  const [createModalVisible, setCreateModalVisible] = useState(false);
  const [createModalType, setCreateModalType] = useState<'file' | 'folder'>('file');
  const [fileViewerVisible, setFileViewerVisible] = useState(false);
  const [selectedFile, setSelectedFile] = useState<FileInfo | null>(null);

  const loadDirectory = async (path: string) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fileServiceClient.listDirectory(path);
      setFiles(response.entries);
      setCurrentPath(path);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load directory');
      console.error('Failed to load directory:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDirectory(currentPath);
  }, []);

  const handleFilePress = (file: FileInfo) => {
    if (file.isDir) {
      // Navigate to directory
      const newPath = file.path;
      loadDirectory(newPath);
    } else {
      // Open file viewer
      setSelectedFile(file);
      setFileViewerVisible(true);
    }
  };

  const handleCreateFile = () => {
    setCreateModalType('file');
    setCreateModalVisible(true);
  };

  const handleCreateFolder = () => {
    setCreateModalType('folder');
    setCreateModalVisible(true);
  };

  const handleDeleteFile = (file: FileInfo) => {
    Alert.alert(
      'Delete Item',
      `Are you sure you want to delete "${file.name}"?${file.isDir ? ' This will delete all contents.' : ''}`,
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Delete', 
          style: 'destructive',
          onPress: async () => {
            try {
              await fileServiceClient.deletePath(file.path, file.isDir);
              loadDirectory(currentPath); // Refresh
            } catch (err) {
              Alert.alert('Error', err instanceof Error ? err.message : 'Failed to delete item');
            }
          }
        }
      ]
    );
  };

  const handleBackPress = () => {
    if (currentPath !== '/') {
      const parentPath = currentPath.split('/').slice(0, -1).join('/') || '/';
      loadDirectory(parentPath);
    }
  };

  const handleBreadcrumbPress = (path: string) => {
    if (path !== currentPath) {
      loadDirectory(path);
    }
  };

  const getBreadcrumbs = () => {
    if (currentPath === '/') return [{ name: 'home', path: '/', isHome: true }];
    
    const parts = currentPath.split('/').filter(Boolean);
    const breadcrumbs = [{ name: 'home', path: '/', isHome: true }];
    
    let accPath = '';
    parts.forEach((part) => {
      accPath += `/${part}`;
      breadcrumbs.push({ name: part, path: accPath, isHome: false });
    });
    
    return breadcrumbs;
  };

  const getFileIcon = (file: FileInfo, size: number = 32) => {
    const iconProps = {
      size,
      color: rgb(tokens.colors.interactive.primary),
      opacity: 0.9,
    };
    
    if (file.isDir) return <FolderIcon {...iconProps} />;
    
    const ext = file.name.split('.').pop()?.toLowerCase();
    switch (ext) {
      case 'js':
      case 'jsx':
      case 'ts':
      case 'tsx':
        return <CodeIcon {...iconProps} />;
      case 'html':
      case 'css':
        return <WebIcon {...iconProps} />;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'svg':
        return <ImageIcon {...iconProps} />;
      case 'md':
      case 'txt':
      case 'doc':
      case 'docx':
        return <DocumentIcon {...iconProps} />;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
        return <SettingsIcon {...iconProps} />;
      case 'git':
        return <GitIcon {...iconProps} />;
      default:
        return <FileIcon {...iconProps} />;
    }
  };

  const getFileTypeLabel = (file: FileInfo) => {
    if (!file.isDir) return null;
    
    // Simple heuristic to detect special folder types
    const name = file.name.toLowerCase();
    if (name.includes('photo') || name.includes('image') || name.includes('pic')) return 'ALBUM';
    if (name.includes('web') || name.includes('site') || name.includes('www')) return 'WEB';
    if (name === '.git' || name.includes('repo')) return 'GIT';
    
    return null;
  };

  const renderGridItem = ({ item }: { item: DirectoryEntry }) => {
    const file = item.fileInfo!;
    const typeLabel = getFileTypeLabel(file);
    
    return (
      <View style={styles.gridItemContainer}>
        <TouchableOpacity 
          style={styles.gridItem} 
          onPress={() => handleFilePress(file)}
        >
          {typeLabel && <View style={styles.typeLabel}><Text style={styles.typeLabelText}>{typeLabel}</Text></View>}
          <View style={styles.gridIcon}>
            {getFileIcon(file, 32)}
          </View>
          <Text style={styles.gridFileName} numberOfLines={2}>{file.name}</Text>
        </TouchableOpacity>
        
        <View style={styles.gridActions}>
          {!file.isDir && (
            <TouchableOpacity
              style={styles.gridActionButton}
              onPress={() => {
                setSelectedFile(file);
                setFileViewerVisible(true);
              }}
            >
              <EyeIcon size={14} />
            </TouchableOpacity>
          )}
          <TouchableOpacity
            style={styles.gridActionButton}
            onPress={() => handleDeleteFile(file)}
          >
            <DeleteIcon size={14} />
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const renderListItem = ({ item }: { item: DirectoryEntry }) => {
    const file = item.fileInfo!;
    
    return (
      <TouchableOpacity 
        style={styles.listItem} 
        onPress={() => handleFilePress(file)}
      >
        <View style={styles.listIcon}>
          {getFileIcon(file, 24)}
        </View>
        <View style={styles.listFileInfo}>
          <Text style={styles.listFileName}>{file.name}</Text>
          <Text style={styles.listFileDetails}>
            {file.isDir ? 'Directory' : `${Math.round(Number(file.size) / 1024)} KB`}
          </Text>
        </View>
        
        <View style={styles.listActions}>
          {!file.isDir && (
            <TouchableOpacity
              style={styles.listActionButton}
              onPress={(e) => {
                e.stopPropagation();
                setSelectedFile(file);
                setFileViewerVisible(true);
              }}
            >
              <EyeIcon size={16} />
            </TouchableOpacity>
          )}
          <TouchableOpacity
            style={styles.listActionButton}
            onPress={(e) => {
              e.stopPropagation();
              handleDeleteFile(file);
            }}
          >
            <DeleteIcon size={16} />
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    );
  };

  const screenWidth = Dimensions.get('window').width;
  const itemWidth = 120; // Larger, more spacious items
  const padding = 24; // More generous padding
  const numColumns = Math.max(2, Math.floor((screenWidth - padding * 2) / (itemWidth + 16)));

  return (
    <View style={styles.container}>
      {/* Navigation Bar with breadcrumbs and view toggle */}
      <View style={styles.navBar}>
        <View style={styles.breadcrumbs}>
          {getBreadcrumbs().map((crumb, index) => (
            <View key={crumb.path} style={styles.breadcrumbContainer}>
              <TouchableOpacity 
                style={styles.breadcrumbButton}
                onPress={() => handleBreadcrumbPress(crumb.path)}
              >
                {crumb.isHome ? (
                  <HomeIcon 
                    size={16} 
                    color={index === getBreadcrumbs().length - 1 
                      ? rgb(tokens.colors.text.muted) 
                      : rgba(tokens.colors.text.muted, 0.7)
                    }
                    opacity={index === getBreadcrumbs().length - 1 ? 0.8 : 0.6}
                  />
                ) : (
                  <Text style={[
                    styles.breadcrumbText,
                    index === getBreadcrumbs().length - 1 && styles.currentBreadcrumb
                  ]}>
                    {crumb.name}
                  </Text>
                )}
              </TouchableOpacity>
              <Text style={styles.breadcrumbSeparator}>/</Text>
              {index < getBreadcrumbs().length - 1 && (
                <Text style={styles.breadcrumbSpace}> </Text>
              )}
            </View>
          ))}
        </View>
        
        <View style={styles.rightControls}>
          <View style={styles.createButtons}>
            <TouchableOpacity
              style={styles.createButton}
              onPress={handleCreateFolder}
            >
              <FolderIcon size={16} />
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.createButton}
              onPress={handleCreateFile}
            >
              <PlusIcon size={16} />
            </TouchableOpacity>
          </View>
          
          <View style={styles.viewToggle}>
            <TouchableOpacity 
              style={[styles.toggleButton, viewMode === 'grid' && styles.activeToggle]}
              onPress={() => setViewMode('grid')}
            >
              <Text style={[styles.toggleText, viewMode === 'grid' && styles.activeToggleText]}>
                grid
              </Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={[styles.toggleButton, viewMode === 'list' && styles.activeToggle]}
              onPress={() => setViewMode('list')}
            >
              <Text style={[styles.toggleText, viewMode === 'list' && styles.activeToggleText]}>
                list
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>

      {/* Loading indicator */}
      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={rgb(tokens.colors.interactive.primary)} />
          <Text style={styles.loadingText}>Loading directory...</Text>
        </View>
      )}

      {/* Error message */}
      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Error: {error}</Text>
          <TouchableOpacity 
            style={styles.retryButton} 
            onPress={() => loadDirectory(currentPath)}
          >
            <Text style={styles.retryButtonText}>Retry</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* File grid/list */}
      {!loading && !error && (
        <FlatList
          data={files}
          renderItem={viewMode === 'grid' ? renderGridItem : renderListItem}
          keyExtractor={(item, index) => `${item.fileInfo?.path}-${index}`}
          style={styles.fileList}
          contentContainerStyle={styles.fileListContent}
          numColumns={viewMode === 'grid' ? numColumns : 1}
          key={`${viewMode}-${numColumns}`} // Force re-render when switching modes
        />
      )}

      {/* Modals */}
      <CreateModal
        visible={createModalVisible}
        onClose={() => setCreateModalVisible(false)}
        currentPath={currentPath}
        onRefresh={() => loadDirectory(currentPath)}
        type={createModalType}
      />

      <FileViewer
        visible={fileViewerVisible}
        onClose={() => setFileViewerVisible(false)}
        file={selectedFile}
        onRefresh={() => loadDirectory(currentPath)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: rgb(tokens.colors.bg.primary),
  },
  
  // Navigation Bar - glassmorphism effect
  navBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.8),
    paddingHorizontal: tokens.space[6],
    paddingVertical: tokens.space[4],
    borderBottomWidth: tokens.borderWidth[1],
    borderBottomColor: rgba(tokens.colors.border.primary, 0.3),
    minHeight: 64,
  },
  
  // Breadcrumbs - better typography
  breadcrumbs: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  breadcrumbContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  breadcrumbButton: {
    paddingHorizontal: tokens.space[1],
    paddingVertical: tokens.space[1],
    borderRadius: tokens.borderRadius.sm,
  },
  breadcrumbText: {
    color: rgba(tokens.colors.text.muted, 0.7),
    fontSize: tokens.fontSize.base,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    fontWeight: tokens.fontWeight.light,
  },
  currentBreadcrumb: {
    color: rgba(tokens.colors.text.muted, 0.8),
    fontWeight: tokens.fontWeight.light,
  },
  breadcrumbSeparator: {
    color: rgba(tokens.colors.text.muted, 0.6),
    fontSize: tokens.fontSize.base,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    fontWeight: tokens.fontWeight.light,
    marginLeft: tokens.space[1],
  },
  breadcrumbSpace: {
    color: rgba(tokens.colors.text.muted, 0.6),
    fontSize: tokens.fontSize.base,
  },
  
  // Right controls container
  rightControls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: tokens.space[4],
  },
  
  // Create buttons
  createButtons: {
    flexDirection: 'row',
    gap: tokens.space[2],
  },
  createButton: {
    width: 32,
    height: 32,
    borderRadius: tokens.borderRadius.md,
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.1),
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.interactive.primary, 0.3),
    alignItems: 'center',
    justifyContent: 'center',
  },
  
  // View Toggle - glassmorphic design
  viewToggle: {
    flexDirection: 'row',
    backgroundColor: rgba(tokens.colors.bg.secondary, 0.6),
    borderRadius: tokens.borderRadius.base,
    padding: 2,
    gap: 0,
  },
  toggleButton: {
    paddingHorizontal: tokens.space[3],
    paddingVertical: tokens.space[2],
    backgroundColor: 'transparent',
    borderRadius: tokens.borderRadius.sm,
    minWidth: 48,
    alignItems: 'center',
  },
  activeToggle: {
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.2),
    borderWidth: 1,
    borderColor: rgba(tokens.colors.interactive.primary, 0.4),
  },
  toggleText: {
    color: rgba(tokens.colors.text.secondary, 0.9),
    fontSize: tokens.fontSize.sm,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    fontWeight: tokens.fontWeight.light,
  },
  activeToggleText: {
    color: rgb(tokens.colors.interactive.primary),
    fontWeight: tokens.fontWeight.normal,
  },
  
  // Loading and Error States
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: tokens.space[4],
  },
  loadingText: {
    color: rgb(tokens.colors.text.secondary),
    fontSize: tokens.fontSize.sm,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: tokens.space[4],
    gap: tokens.space[4],
  },
  errorText: {
    color: rgb(tokens.colors.status.error),
    fontSize: tokens.fontSize.base,
    textAlign: 'center',
  },
  retryButton: {
    backgroundColor: rgb(tokens.colors.interactive.primary),
    paddingHorizontal: tokens.space[4],
    paddingVertical: tokens.space[2],
    borderRadius: tokens.borderRadius.base,
  },
  retryButtonText: {
    color: rgb(tokens.colors.text.inverse),
    fontSize: tokens.fontSize.sm,
    fontWeight: tokens.fontWeight.medium,
  },
  
  // File List
  fileList: {
    flex: 1,
  },
  fileListContent: {
    padding: tokens.space[6],
    paddingTop: tokens.space[4],
  },
  
  // Grid Items - glassmorphic design
  gridItemContainer: {
    position: 'relative',
  },
  gridItem: {
    flex: 1,
    aspectRatio: 1,
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.6),
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.primary, 0.3),
    borderRadius: tokens.borderRadius.lg,
    margin: tokens.space[2],
    padding: tokens.space[4],
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    ...tokens.shadows.sm,
    maxWidth: 120,
    minHeight: 120,
  },
  gridActions: {
    position: 'absolute',
    top: tokens.space[1],
    right: tokens.space[1],
    flexDirection: 'row',
    gap: tokens.space[1],
  },
  gridActionButton: {
    width: 24,
    height: 24,
    borderRadius: tokens.borderRadius.sm,
    backgroundColor: rgba(tokens.colors.bg.primary, 0.8),
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.primary, 0.3),
  },
  typeLabel: {
    position: 'absolute',
    top: tokens.space[2],
    right: tokens.space[2],
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.2),
    borderWidth: 1,
    borderColor: rgba(tokens.colors.interactive.primary, 0.4),
    borderRadius: tokens.borderRadius.sm,
    paddingHorizontal: tokens.space[1],
    paddingVertical: 2,
  },
  typeLabelText: {
    color: rgb(tokens.colors.interactive.primary),
    fontSize: 10,
    fontWeight: tokens.fontWeight.medium,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    letterSpacing: 0.5,
  },
  gridIcon: {
    marginBottom: tokens.space[3],
    alignItems: 'center',
    justifyContent: 'center',
  },
  gridFileName: {
    color: rgba(tokens.colors.text.secondary, 0.9),
    fontSize: tokens.fontSize.sm,
    textAlign: 'center',
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    fontWeight: tokens.fontWeight.light,
    lineHeight: tokens.lineHeight.tight * tokens.fontSize.sm,
  },
  
  // List Items - glassmorphic design
  listItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: tokens.space[4],
    marginVertical: tokens.space[1],
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.6),
    borderRadius: tokens.borderRadius.lg,
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.primary, 0.3),
    ...tokens.shadows.sm,
  },
  listIcon: {
    marginRight: tokens.space[4],
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.1),
    borderRadius: tokens.borderRadius.md,
  },
  listFileInfo: {
    flex: 1,
  },
  listFileName: {
    color: rgb(tokens.colors.text.primary),
    fontSize: tokens.fontSize.lg,
    fontWeight: tokens.fontWeight.light,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    marginBottom: tokens.space[1],
  },
  listFileDetails: {
    color: rgba(tokens.colors.text.muted, 0.8),
    fontSize: tokens.fontSize.sm,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    fontWeight: tokens.fontWeight.light,
  },
  listActions: {
    flexDirection: 'row',
    gap: tokens.space[2],
    marginLeft: tokens.space[2],
  },
  listActionButton: {
    width: 32,
    height: 32,
    borderRadius: tokens.borderRadius.sm,
    backgroundColor: rgba(tokens.colors.bg.primary, 0.6),
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.primary, 0.3),
  },
});
