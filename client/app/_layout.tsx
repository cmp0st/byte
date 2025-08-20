import React from 'react';
import { Stack } from 'expo-router';
import { Platform } from 'react-native';
import { tokens, rgb } from '../design/tokens';

export default function RootLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: rgb(tokens.colors.bg.secondary),
          height: tokens.components.header.height,
        },
        headerTintColor: rgb(tokens.colors.text.primary),
        headerTitleStyle: {
          fontWeight: tokens.fontWeight.medium,
          fontSize: tokens.fontSize.lg,
          fontFamily: Platform.OS === 'web' ? tokens.fonts.mono : undefined,
        },
        headerShadowVisible: false,
        headerBorderVisible: true,
      }}
    >
      <Stack.Screen
        name="index"
        options={{
          title: 'Byte File Browser',
        }}
      />
    </Stack>
  );
}