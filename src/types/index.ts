/**
 * PlumWallPaper 全局数据模型定义
 * 基于 MVP v2 实施规格与 v5 原型视觉标准
 */

export type WallpaperType = 'video' | 'heic';

export interface Wallpaper {
  id: string;
  name: string;
  filePath: string;
  type: WallpaperType;
  res: string; // 如 "5120×2880"
  size: string; // 如 "1.2GB"
  duration?: string; // 视频时长，如 "00:45"
  thumb: string; // 缩略图路径或 URL
  tags: string[];
  isFavorite: boolean;
  importDate: string;
  lastUsedDate?: string;
  filterPreset?: FilterPreset;
}

export interface FilterPreset {
  id: string;
  name: string;
  exposure: number; // 0-200, 默认 100
  contrast: number; // 0-200, 默认 100
  saturation: number; // 0-200, 默认 100
  hue: number; // -180 to 180, 默认 0
  blur: number; // 0-20, 默认 0
  grain: number; // 0-100, 默认 0
  vignette: number; // 0-100, 默认 0
  grayscale: number; // 0-100, 默认 0
  invert: number; // 0-100, 默认 0
}

export interface SmartPauseStrategy {
  id: string;
  label: string;
  desc: string;
  active: boolean;
}

export interface Display {
  id: string;
  name: string;
  res: string;
  isMain: boolean;
  currentWallpaperId?: string;
  colorSpace: 'P3' | 'sRGB' | 'AdobeRGB';
}

export type SlideshowOrder = 'sequential' | 'random' | 'favoritesFirst';
export type TransitionEffect = 'fade' | 'kenBurns' | 'none';

export interface AppSettings {
  // 轮播设置
  slideshowEnabled: boolean;
  slideshowInterval: number; // 单位：分钟
  slideshowOrder: SlideshowOrder;
  transitionEffect: TransitionEffect;
  
  // 性能与引擎
  vSyncEnabled: boolean;
  preDecodeEnabled: boolean;
  audioDuckingEnabled: boolean;
  
  // 智能暂停策略
  smartPause: {
    onBattery: boolean;
    onFullscreen: boolean;
    onOcclusion: boolean;
    onLowBattery: boolean;
    onScreenSharing: boolean;
    onLidClosed: boolean;
    onHighLoad: boolean;
    onLostFocus: boolean;
    beforeSleep: boolean;
  };
  
  // 外观
  themeMode: 'auto' | 'light' | 'dark';
  accentColor: string;
  thumbnailSize: 'small' | 'medium' | 'large';
  animationsEnabled: boolean;
}

export interface LibraryStats {
  videoSize: string;
  imageSize: string;
  cacheSize: string;
  totalWallpapers: number;
}
