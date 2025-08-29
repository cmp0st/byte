import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  Modal,
  StyleSheet,
  Platform,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { tokens, rgb, rgba } from '../design/tokens';
import { fileServiceClient, FileInfo } from '../design/api';
import { EyeIcon, EditIcon } from './Icons';

interface FileViewerProps {
  visible: boolean;
  onClose: () => void;
  file: FileInfo | null;
  onRefresh: () => void;
}

export function FileViewer({ visible, onClose, file, onRefresh }: FileViewerProps) {
  const [content, setContent] = useState('');
  const [editedContent, setEditedContent] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (visible && file && !file.isDir) {
      loadFileContent();
    }
  }, [visible, file]);

  const loadFileContent = async () => {
    if (!file || file.isDir) return;
    
    setLoading(true);
    setError(null);

    try {
      if (fileServiceClient.isTextFile(file.name)) {
        const fileContent = await fileServiceClient.readFile(file.path);
        setContent(fileContent);
        setEditedContent(fileContent);
      } else {
        setContent('[Binary file - cannot display content]');
        setEditedContent('');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load file');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!file) return;

    setSaving(true);
    setError(null);

    try {
      await fileServiceClient.writeFile(file.path, editedContent);
      setContent(editedContent);
      setIsEditing(false);
      onRefresh();
      
      Alert.alert('Success', 'File saved successfully');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save file');
    } finally {
      setSaving(false);
    }
  };

  const handleStartEdit = () => {
    if (fileServiceClient.isTextFile(file?.name || '')) {
      setIsEditing(true);
    } else {
      Alert.alert('Error', 'Cannot edit binary files');
    }
  };

  const handleCancelEdit = () => {
    setEditedContent(content);
    setIsEditing(false);
  };

  const handleClose = () => {
    if (isEditing && editedContent !== content) {
      Alert.alert(
        'Unsaved Changes',
        'You have unsaved changes. Are you sure you want to close?',
        [
          { text: 'Cancel', style: 'cancel' },
          { 
            text: 'Discard', 
            style: 'destructive', 
            onPress: () => {
              setIsEditing(false);
              setEditedContent(content);
              onClose();
            }
          }
        ]
      );
    } else {
      onClose();
    }
  };

  if (!file || file.isDir) {
    return null;
  }

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={handleClose}
    >
      <View style={styles.overlay}>
        <View style={styles.modal}>
          <View style={styles.header}>
            <View style={styles.titleContainer}>
              <Text style={styles.fileName}>{file.name}</Text>
              <Text style={styles.filePath}>{file.path}</Text>
            </View>
            
            <View style={styles.actions}>
              {!isEditing && fileServiceClient.isTextFile(file.name) && (
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={handleStartEdit}
                >
                  <EditIcon size={18} />
                </TouchableOpacity>
              )}
              
              <TouchableOpacity
                style={styles.closeButton}
                onPress={handleClose}
              >
                <Text style={styles.closeButtonText}>×</Text>
              </TouchableOpacity>
            </View>
          </View>

          {loading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={rgb(tokens.colors.interactive.primary)} />
              <Text style={styles.loadingText}>Loading file...</Text>
            </View>
          ) : error ? (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>{error}</Text>
              <TouchableOpacity
                style={styles.retryButton}
                onPress={loadFileContent}
              >
                <Text style={styles.retryButtonText}>Retry</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.contentContainer}>
              {isEditing ? (
                <TextInput
                  style={styles.editor}
                  value={editedContent}
                  onChangeText={setEditedContent}
                  multiline
                  textAlignVertical="top"
                  placeholder="File content..."
                  placeholderTextColor={rgba(tokens.colors.text.muted, 0.5)}
                />
              ) : (
                <ScrollView style={styles.viewer}>
                  <Text style={styles.content}>{content}</Text>
                </ScrollView>
              )}
            </View>
          )}

          {isEditing && (
            <View style={styles.editActions}>
              <TouchableOpacity
                style={[styles.button, styles.cancelButton]}
                onPress={handleCancelEdit}
                disabled={saving}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.button, styles.saveButton]}
                onPress={handleSave}
                disabled={saving}
              >
                <Text style={styles.saveButtonText}>
                  {saving ? 'Saving...' : 'Save'}
                </Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: rgba(tokens.colors.bg.primary, 0.9),
    padding: tokens.space[4],
  },
  modal: {
    flex: 1,
    backgroundColor: rgb(tokens.colors.bg.secondary),
    borderRadius: tokens.borderRadius.lg,
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.primary, 0.3),
    overflow: 'hidden',
    ...tokens.shadows.lg,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: tokens.space[4],
    borderBottomWidth: tokens.borderWidth[1],
    borderBottomColor: rgba(tokens.colors.border.primary, 0.3),
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.6),
  },
  titleContainer: {
    flex: 1,
  },
  fileName: {
    fontSize: tokens.fontSize.lg,
    fontWeight: tokens.fontWeight.medium,
    color: rgb(tokens.colors.text.primary),
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
  },
  filePath: {
    fontSize: tokens.fontSize.sm,
    color: rgba(tokens.colors.text.muted, 0.8),
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    marginTop: tokens.space[1],
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: tokens.space[2],
  },
  actionButton: {
    padding: tokens.space[2],
    borderRadius: tokens.borderRadius.sm,
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.1),
  },
  closeButton: {
    width: 32,
    height: 32,
    borderRadius: tokens.borderRadius.sm,
    backgroundColor: rgba(tokens.colors.status.error, 0.1),
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeButtonText: {
    fontSize: 24,
    color: rgb(tokens.colors.status.error),
    fontWeight: tokens.fontWeight.light,
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
    gap: tokens.space[4],
    padding: tokens.space[4],
  },
  errorText: {
    color: rgb(tokens.colors.status.error),
    fontSize: tokens.fontSize.base,
    textAlign: 'center',
  },
  retryButton: {
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.2),
    paddingHorizontal: tokens.space[4],
    paddingVertical: tokens.space[2],
    borderRadius: tokens.borderRadius.base,
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.interactive.primary, 0.4),
  },
  retryButtonText: {
    color: rgb(tokens.colors.interactive.primary),
    fontSize: tokens.fontSize.sm,
    fontWeight: tokens.fontWeight.medium,
  },
  contentContainer: {
    flex: 1,
  },
  viewer: {
    flex: 1,
    padding: tokens.space[4],
  },
  content: {
    fontSize: tokens.fontSize.sm,
    color: rgb(tokens.colors.text.primary),
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    lineHeight: tokens.lineHeight.relaxed * tokens.fontSize.sm,
  },
  editor: {
    flex: 1,
    padding: tokens.space[4],
    fontSize: tokens.fontSize.sm,
    color: rgb(tokens.colors.text.primary),
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.3),
  },
  editActions: {
    flexDirection: 'row',
    gap: tokens.space[3],
    padding: tokens.space[4],
    borderTopWidth: tokens.borderWidth[1],
    borderTopColor: rgba(tokens.colors.border.primary, 0.3),
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.6),
  },
  button: {
    flex: 1,
    paddingVertical: tokens.space[3],
    paddingHorizontal: tokens.space[4],
    borderRadius: tokens.borderRadius.md,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.6),
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.secondary, 0.3),
  },
  saveButton: {
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.2),
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.interactive.primary, 0.4),
  },
  cancelButtonText: {
    color: rgba(tokens.colors.text.secondary, 0.8),
    fontSize: tokens.fontSize.sm,
    fontWeight: tokens.fontWeight.medium,
  },
  saveButtonText: {
    color: rgb(tokens.colors.interactive.primary),
    fontSize: tokens.fontSize.sm,
    fontWeight: tokens.fontWeight.medium,
  },
});