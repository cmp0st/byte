import React from 'react';
import { Stack } from 'expo-router';
import { Platform, View, Text, StyleSheet } from 'react-native';
import { tokens, rgb, rgba } from '../design/tokens';
import { ByteLogo } from '../components/Icons';

const HeaderTitle = () => (
  <View style={styles.headerTitle}>
    <ByteLogo size={28} />
    <Text style={styles.headerTitleText}>Byte</Text>
  </View>
);

export default function RootLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: rgba(tokens.colors.bg.secondary, 0.95),
          height: tokens.components.header.height,
        },
        headerTintColor: rgb(tokens.colors.text.primary),
        headerTitleAlign: 'center',
        headerShadowVisible: false,
        headerBorderVisible: true,
      }}
    >
      <Stack.Screen
        name="index"
        options={{
          headerTitle: () => <HeaderTitle />,
        }}
      />
    </Stack>
  );
}

const styles = StyleSheet.create({
  headerTitle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: tokens.space[2],
  },
  headerTitleText: {
    color: rgb(tokens.colors.text.primary),
    fontSize: tokens.fontSize.xl,
    fontWeight: tokens.fontWeight.light,
    fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
    letterSpacing: 1.5,
  },
});