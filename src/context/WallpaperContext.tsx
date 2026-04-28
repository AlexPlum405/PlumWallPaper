import React, { createContext, useContext, useState, ReactNode } from 'react';
import { Wallpaper, AppSettings, Display } from '../types';

interface WallpaperContextType {
  // 壁纸数据
  wallpapers: Wallpaper[];
  activeWallpaperId: string;
  setActiveWallpaperId: (id: string) => void;
  
  // 收藏与管理
  toggleFavorite: (id: string) => void;
  deleteWallpaper: (id: string) => void;
  addWallpapers: (newFiles: any[]) => void;
  
  // 弹窗状态
  isImportModalOpen: boolean;
  setImportModalOpen: (open: boolean) => void;
  isMonitorSelectorOpen: boolean;
  setMonitorSelectorOpen: (open: boolean) => void;
  
  // 显示器与设置
  displays: Display[];
  applyWallpaperToDisplay: (wallpaperId: string, displayIds: string[]) => void;
  settings: AppSettings;
  updateSettings: (newSettings: Partial<AppSettings>) => void;
}

const WallpaperContext = createContext<WallpaperContextType | undefined>(undefined);

// --- 初始 Mock 数据 ---
const INITIAL_WALLPAPERS: Wallpaper[] = [
  { id: '1', name: 'Deep Space Nebula', filePath: '', type: 'video', res: '8K', size: '1.2GB', duration: '00:45', tags: ['Sci-Fi', 'Space'], isFavorite: true, thumb: 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=800&q=80', importDate: '2026-04-28' },
  { id: '2', name: 'Minimalist Peak', filePath: '', type: 'heic', res: '6K', size: '45MB', tags: ['Nature', 'Minimal'], isFavorite: false, thumb: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80', importDate: '2026-04-28' },
  { id: '3', name: 'Cyberpunk Rain', filePath: '', type: 'video', res: '4K', size: '850MB', duration: '01:20', tags: ['City', 'Cyber'], isFavorite: true, thumb: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=800&q=80', importDate: '2026-04-28' },
];

const INITIAL_SETTINGS: AppSettings = {
  slideshowEnabled: false,
  slideshowInterval: 30,
  slideshowOrder: 'sequential',
  transitionEffect: 'fade',
  vSyncEnabled: true,
  preDecodeEnabled: true,
  audioDuckingEnabled: false,
  smartPause: {
    onBattery: true,
    onFullscreen: true,
    onOcclusion: true,
    onLowBattery: true,
    onScreenSharing: false,
    onLidClosed: false,
    onHighLoad: false,
    onLostFocus: false,
    beforeSleep: true,
  },
  themeMode: 'dark',
  accentColor: '#E03E3E',
  thumbnailSize: 'medium',
  animationsEnabled: true,
};

export const WallpaperProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [wallpapers, setWallpapers] = useState<Wallpaper[]>(INITIAL_WALLPAPERS);
  const [activeWallpaperId, setActiveWallpaperId] = useState<string>(INITIAL_WALLPAPERS[0].id);
  const [settings, setSettings] = useState<AppSettings>(INITIAL_SETTINGS);
  
  const [isImportModalOpen, setImportModalOpen] = useState(false);
  const [isMonitorSelectorOpen, setMonitorSelectorOpen] = useState(false);
  
  const [displays] = useState<Display[]>([
    { id: '1', name: 'Studio Display', res: '5120×2880', isMain: true, colorSpace: 'P3' },
    { id: '2', name: 'MacBook Built-in', res: '3456×2234', isMain: false, colorSpace: 'P3' },
  ]);

  const toggleFavorite = (id: string) => {
    setWallpapers(prev => prev.map(w => w.id === id ? { ...w, isFavorite: !w.isFavorite } : w));
  };

  const deleteWallpaper = (id: string) => {
    setWallpapers(prev => prev.filter(w => w.id !== id));
  };

  const addWallpapers = (newFiles: any[]) => {
    // 模拟导入逻辑
    console.log('Adding wallpapers:', newFiles);
  };

  const applyWallpaperToDisplay = (wallpaperId: string, displayIds: string[]) => {
    console.log(`Applying wallpaper ${wallpaperId} to displays: ${displayIds.join(', ')}`);
    setMonitorSelectorOpen(false);
  };

  const updateSettings = (newSettings: Partial<AppSettings>) => {
    setSettings(prev => ({ ...prev, ...newSettings }));
  };

  return (
    <WallpaperContext.Provider value={{
      wallpapers, activeWallpaperId, setActiveWallpaperId,
      toggleFavorite, deleteWallpaper, addWallpapers,
      isImportModalOpen, setImportModalOpen,
      isMonitorSelectorOpen, setMonitorSelectorOpen,
      displays, applyWallpaperToDisplay,
      settings, updateSettings
    }}>
      {children}
    </WallpaperContext.Provider>
  );
};

export const useWallpaper = () => {
  const context = useContext(WallpaperContext);
  if (!context) throw new Error('useWallpaper must be used within a WallpaperProvider');
  return context;
};
