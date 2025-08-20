import React from 'react';
import { View, StyleSheet, Platform } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { FileBrowser } from '../components/FileBrowser';
import { tokens, rgb } from '../design/tokens';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <StatusBar style="light" backgroundColor={rgb(tokens.colors.bg.primary)} />
      <FileBrowser initialPath="/" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: rgb(tokens.colors.bg.primary),
  },
});