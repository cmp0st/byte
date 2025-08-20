import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  FlatList, 
  TouchableOpacity, 
  StyleSheet, 
  Platform,
  ActivityIndicator 
} from 'react-native';
import { fileServiceClient, FileInfo, DirectoryEntry } from '../design/api';
import { tokens, rgb } from '../design/tokens';

interface FileBrowserProps {
  initialPath?: string;
}

export function FileBrowser({ initialPath = '/' }: FileBrowserProps) {
  const [currentPath, setCurrentPath] = useState(initialPath);
  const [files, setFiles] = useState<DirectoryEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadDirectory = async (path: string) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fileServiceClient.listDirectory({ path });
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
      // Handle file selection (for now, just log)
      console.log('Selected file:', file.name);
    }
  };

  const handleBackPress = () => {
    if (currentPath !== '/') {
      const parentPath = currentPath.split('/').slice(0, -1).join('/') || '/';
      loadDirectory(parentPath);
    }
  };

  const renderFileItem = ({ item }: { item: DirectoryEntry }) => {
    const file = item.fileInfo!;
    
    return (
      <TouchableOpacity 
        style={styles.fileItem} 
        onPress={() => handleFilePress(file)}
      >
        <View style={styles.fileIcon}>
          <Text style={styles.iconText}>
            {file.isDir ? '📁' : '📄'}
          </Text>
        </View>
        <View style={styles.fileInfo}>
          <Text style={styles.fileName}>{file.name}</Text>
          <Text style={styles.fileDetails}>
            {file.isDir ? 'Directory' : `${Math.round(Number(file.size) / 1024)} KB`}
          </Text>
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.container}>
      {/* Header with current path */}
      <View style={styles.header}>
        {currentPath !== '/' && (
          <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
            <Text style={styles.backButtonText}>← Back</Text>
          </TouchableOpacity>
        )}
        <Text style={styles.pathText}>{currentPath}</Text>
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

      {/* File list */}
      {!loading && !error && (
        <FlatList
          data={files}
          renderItem={renderFileItem}
          keyExtractor={(item, index) => `${item.fileInfo?.path}-${index}`}
          style={styles.fileList}
          contentContainerStyle={styles.fileListContent}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: rgb(tokens.colors.bg.primary),
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: tokens.space[4],
    borderBottomWidth: tokens.borderWidth[1],
    borderBottomColor: rgb(tokens.colors.border.primary),
    minHeight: tokens.components.header.height,
  },
  backButton: {
    marginRight: tokens.space[3],
    padding: tokens.space[2],
  },
  backButtonText: {
    color: rgb(tokens.colors.interactive.primary),
    fontSize: tokens.fontSize.sm,
    fontWeight: tokens.fontWeight.medium,
  },
  pathText: {
    color: rgb(tokens.colors.text.primary),
    fontSize: tokens.fontSize.base,
    fontWeight: tokens.fontWeight.medium,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
  },
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
  fileList: {
    flex: 1,
  },
  fileListContent: {
    padding: tokens.space[2],
  },
  fileItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: tokens.space[3],
    marginVertical: tokens.space[1],
    backgroundColor: rgb(tokens.colors.bg.secondary),
    borderRadius: tokens.borderRadius.base,
    borderWidth: tokens.borderWidth[1],
    borderColor: rgb(tokens.colors.border.primary),
  },
  fileIcon: {
    marginRight: tokens.space[3],
    width: 32,
    height: 32,
    justifyContent: 'center',
    alignItems: 'center',
  },
  iconText: {
    fontSize: 20,
  },
  fileInfo: {
    flex: 1,
  },
  fileName: {
    color: rgb(tokens.colors.text.primary),
    fontSize: tokens.fontSize.base,
    fontWeight: tokens.fontWeight.medium,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
  },
  fileDetails: {
    color: rgb(tokens.colors.text.muted),
    fontSize: tokens.fontSize.sm,
    marginTop: tokens.space[1],
  },
});
