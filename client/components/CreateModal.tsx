import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  Modal,
  StyleSheet,
  Platform,
} from 'react-native';
import { tokens, rgb, rgba } from '../design/tokens';
import { fileServiceClient } from '../design/api';

interface CreateModalProps {
  visible: boolean;
  onClose: () => void;
  currentPath: string;
  onRefresh: () => void;
  type: 'file' | 'folder';
}

export function CreateModal({ visible, onClose, currentPath, onRefresh, type }: CreateModalProps) {
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleCreate = async () => {
    if (!name.trim()) {
      setError('Name is required');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      if (type === 'folder') {
        await fileServiceClient.createDirectory(currentPath, name.trim());
      } else {
        await fileServiceClient.createFile(currentPath, name.trim());
      }
      
      onRefresh();
      handleClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : `Failed to create ${type}`);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setName('');
    setError(null);
    onClose();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleClose}
    >
      <View style={styles.overlay}>
        <View style={styles.modal}>
          <Text style={styles.title}>
            Create New {type === 'folder' ? 'Folder' : 'File'}
          </Text>

          <TextInput
            style={styles.input}
            placeholder={`Enter ${type} name`}
            placeholderTextColor={rgba(tokens.colors.text.muted, 0.5)}
            value={name}
            onChangeText={setName}
            autoFocus
            editable={!loading}
          />

          {error && (
            <Text style={styles.error}>{error}</Text>
          )}

          <View style={styles.buttons}>
            <TouchableOpacity
              style={[styles.button, styles.cancelButton]}
              onPress={handleClose}
              disabled={loading}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.button, styles.createButton]}
              onPress={handleCreate}
              disabled={loading || !name.trim()}
            >
              <Text style={styles.createButtonText}>
                {loading ? 'Creating...' : 'Create'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: rgba(tokens.colors.bg.primary, 0.8),
    justifyContent: 'center',
    alignItems: 'center',
    padding: tokens.space[4],
  },
  modal: {
    backgroundColor: rgb(tokens.colors.bg.secondary),
    borderRadius: tokens.borderRadius.lg,
    padding: tokens.space[6],
    width: '100%',
    maxWidth: 400,
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.primary, 0.3),
    ...tokens.shadows.lg,
  },
  title: {
    fontSize: tokens.fontSize.lg,
    fontWeight: tokens.fontWeight.medium,
    color: rgb(tokens.colors.text.primary),
    marginBottom: tokens.space[4],
    textAlign: 'center',
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
  },
  input: {
    backgroundColor: rgba(tokens.colors.bg.tertiary, 0.6),
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.border.primary, 0.3),
    borderRadius: tokens.borderRadius.md,
    padding: tokens.space[3],
    fontSize: tokens.fontSize.base,
    color: rgb(tokens.colors.text.primary),
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    marginBottom: tokens.space[4],
  },
  error: {
    color: rgb(tokens.colors.status.error),
    fontSize: tokens.fontSize.sm,
    marginBottom: tokens.space[4],
    textAlign: 'center',
  },
  buttons: {
    flexDirection: 'row',
    gap: tokens.space[3],
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
  createButton: {
    backgroundColor: rgba(tokens.colors.interactive.primary, 0.2),
    borderWidth: tokens.borderWidth[1],
    borderColor: rgba(tokens.colors.interactive.primary, 0.4),
  },
  cancelButtonText: {
    color: rgba(tokens.colors.text.secondary, 0.8),
    fontSize: tokens.fontSize.sm,
    fontWeight: tokens.fontWeight.medium,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
  },
  createButtonText: {
    color: rgb(tokens.colors.interactive.primary),
    fontSize: tokens.fontSize.sm,
    fontWeight: tokens.fontWeight.medium,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
  },
});