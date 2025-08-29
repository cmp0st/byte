import React from 'react';
import Svg, { Path, Circle, Rect } from 'react-native-svg';
import { tokens, rgb, rgba } from '../design/tokens';

interface IconProps {
  size?: number;
  color?: string;
  opacity?: number;
}

const defaultProps: IconProps = {
  size: 24,
  color: rgb(tokens.colors.interactive.primary),
  opacity: 0.9,
};

export const FolderIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M10 4H4C2.9 4 2 4.9 2 6V18C2 19.1 2.9 20 4 20H20C21.1 20 22 19.1 22 18V8C22 6.9 21.1 6 20 6H12L10 4Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.1)}
      opacity={opacity}
    />
  </Svg>
);

export const FileIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M14 2H6C4.9 2 4 2.9 4 4V20C4 21.1 4.9 22 6 22H18C19.1 22 20 21.1 20 20V8L14 2Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.05)}
      opacity={opacity}
    />
    <Path
      d="M14 2V8H20"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const CodeIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M16 18L22 12L16 6"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
    <Path
      d="M8 6L2 12L8 18"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const WebIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Circle
      cx="12"
      cy="12"
      r="10"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.05)}
      opacity={opacity}
    />
    <Path
      d="M2 12H22"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
    <Path
      d="M12 2C14.5 4.5 16 8.5 16 12S14.5 19.5 12 22C9.5 19.5 8 15.5 8 12S9.5 4.5 12 2Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const ImageIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Rect
      x="3"
      y="3"
      width="18"
      height="18"
      rx="2"
      ry="2"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.05)}
      opacity={opacity}
    />
    <Circle
      cx="8.5"
      cy="8.5"
      r="1.5"
      fill={color}
      opacity={opacity * 0.7}
    />
    <Path
      d="M21 15L16 10L5 21"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const DocumentIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M14 2H6C4.9 2 4 2.9 4 4V20C4 21.1 4.9 22 6 22H18C19.1 22 20 21.1 20 20V8L14 2Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.05)}
      opacity={opacity}
    />
    <Path
      d="M14 2V8H20"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
    <Path
      d="M16 13H8"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity * 0.6}
    />
    <Path
      d="M16 17H8"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity * 0.6}
    />
    <Path
      d="M10 9H8"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity * 0.6}
    />
  </Svg>
);

export const GitIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M9 19C-2 22 -2 14 -6 13M15 22V18.13C15.14 16.92 14.76 15.69 13.96 14.73C17.03 14.39 20.28 13.16 20.28 7.5C20.28 5.95 19.73 4.53 18.72 3.47C19.25 2.16 19.21 0.68 18.72 -0.6C18.72 -0.6 17.26 -0.94 14.72 0.57C12.5 0.04 10.22 0.04 8 0.57C5.46 -0.94 4 -0.6 4 -0.6C3.51 0.68 3.47 2.16 4 3.47C2.99 4.53 2.44 5.95 2.44 7.5C2.44 13.15 5.69 14.39 8.76 14.73C7.96 15.69 7.58 16.92 7.72 18.13V22"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const SettingsIcon: React.FC<IconProps> = ({ size = 24, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Circle
      cx="12"
      cy="12"
      r="3"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.1)}
      opacity={opacity}
    />
    <Path
      d="M19.4 15C19.25 15.28 19.06 15.54 18.82 15.77C18.32 16.25 17.65 16.5 17 16.5H16.74C16.24 16.9 15.66 17.25 15 17.47V18C15 18.55 14.78 19.05 14.39 19.39C14 19.78 13.55 20 13 20H11C10.45 20 9.95 19.78 9.56 19.39C9.22 19.05 9 18.55 9 18V17.47C8.34 17.25 7.76 16.9 7.26 16.5H7C6.35 16.5 5.68 16.25 5.18 15.77C4.94 15.54 4.75 15.28 4.6 15C4.4 14.65 4.25 14.25 4.25 13.82V10.18C4.25 9.75 4.4 9.35 4.6 9C4.75 8.72 4.94 8.46 5.18 8.23C5.68 7.75 6.35 7.5 7 7.5H7.26C7.76 7.1 8.34 6.75 9 6.53V6C9 5.45 9.22 4.95 9.56 4.61C9.95 4.22 10.45 4 11 4H13C13.55 4 14.05 4.22 14.44 4.61C14.78 4.95 15 5.45 15 6V6.53C15.66 6.75 16.24 7.1 16.74 7.5H17C17.65 7.5 18.32 7.75 18.82 8.23C19.06 8.46 19.25 8.72 19.4 9C19.6 9.35 19.75 9.75 19.75 10.18V13.82C19.75 14.25 19.6 14.65 19.4 15Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const HomeIcon: React.FC<IconProps> = ({ size = 20, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M3 9L12 2L21 9V20C21 20.5304 20.7893 21.0391 20.4142 21.4142C20.0391 21.7893 19.5304 22 19 22H5C4.46957 22 3.96086 21.7893 3.58579 21.4142C3.21071 21.0391 3 20.5304 3 20V9Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.08)}
      opacity={opacity}
    />
    <Path
      d="M9 22V12H15V22"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity * 0.7}
    />
  </Svg>
);

export const PlusIcon: React.FC<IconProps> = ({ size = 20, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M12 5V19M5 12H19"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const EditIcon: React.FC<IconProps> = ({ size = 20, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M11 4H4C2.9 4 2 4.9 2 6V18C2 19.1 2.9 20 4 20H16C17.1 20 18 19.1 18 18V11"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
    <Path
      d="M18.5 2.5C19.33 1.67 20.67 1.67 21.5 2.5C22.33 3.33 22.33 4.67 21.5 5.5L12 15L8 16L9 12L18.5 2.5Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const DeleteIcon: React.FC<IconProps> = ({ size = 20, color = rgb(tokens.colors.status.error), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M3 6H5H21"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
    <Path
      d="M8 6V4C8 3.45 8.22 2.95 8.61 2.61C8.95 2.22 9.45 2 10 2H14C14.55 2 15.05 2.22 15.39 2.61C15.78 2.95 16 3.45 16 4V6M19 6V20C19 20.55 18.78 21.05 18.39 21.39C18.05 21.78 17.55 22 17 22H7C6.45 22 5.95 21.78 5.61 21.39C5.22 21.05 5 20.55 5 20V6H19Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const MoreIcon: React.FC<IconProps> = ({ size = 20, color = rgb(tokens.colors.text.muted), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Circle cx="12" cy="12" r="1" fill={color} opacity={opacity} />
    <Circle cx="19" cy="12" r="1" fill={color} opacity={opacity} />
    <Circle cx="5" cy="12" r="1" fill={color} opacity={opacity} />
  </Svg>
);

export const EyeIcon: React.FC<IconProps> = ({ size = 20, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <Path
      d="M1 12S5 4 12 4S23 12 23 12S19 20 12 20S1 12 1 12Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
    <Circle
      cx="12"
      cy="12"
      r="3"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity={opacity}
    />
  </Svg>
);

export const ByteLogo: React.FC<IconProps> = ({ size = 32, color = rgb(tokens.colors.interactive.primary), opacity = 0.9 }) => (
  <Svg width={size} height={size} viewBox="0 0 32 32" fill="none">
    {/* Outer hexagonal frame */}
    <Path
      d="M16 2L26 8V24L16 30L6 24V8L16 2Z"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={rgba(tokens.colors.interactive.primary, 0.05)}
      opacity={opacity}
    />
    
    {/* Inner circuit-like pattern */}
    <Path
      d="M16 8V12M16 20V24"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      opacity={opacity * 0.8}
    />
    <Path
      d="M12 10H20M12 22H20"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      opacity={opacity * 0.8}
    />
    
    {/* Central data node */}
    <Circle
      cx="16"
      cy="16"
      r="3"
      stroke={color}
      strokeWidth="1.5"
      fill={rgba(tokens.colors.interactive.primary, 0.2)}
      opacity={opacity}
    />
    
    {/* Data connection lines */}
    <Path
      d="M13 16H10M22 16H19"
      stroke={color}
      strokeWidth="1.5"
      strokeLinecap="round"
      opacity={opacity * 0.6}
    />
    
    {/* Corner connection nodes */}
    <Circle cx="10" cy="12" r="1" fill={color} opacity={opacity * 0.7} />
    <Circle cx="22" cy="12" r="1" fill={color} opacity={opacity * 0.7} />
    <Circle cx="10" cy="20" r="1" fill={color} opacity={opacity * 0.7} />
    <Circle cx="22" cy="20" r="1" fill={color} opacity={opacity * 0.7} />
  </Svg>
);