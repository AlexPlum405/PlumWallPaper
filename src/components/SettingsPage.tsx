import React, { useState, useEffect } from 'react';
import { 
  Monitor, Play, Pause, Heart, Settings, Layout, Layers, 
  Trash2, Sliders, Info, Zap, Battery, Maximize, Shield, 
  EyeOff, Coffee, Lock, Check, ChevronRight, Search, Plus
} from 'lucide-react';

// --- Types & Interfaces ---

interface Wallpaper {
  id: string;
  name: string;
  type: 'video' | 'heic';
  res: string;
  size: string;
  duration?: string;
  tags: string[];
  isFavorite: boolean;
  thumb: string;
}

interface SmartPauseStrategy {
  id: string;
  label: string;
  desc: string;
  active: boolean;
}

// --- Styles & Constants ---

const COLORS = {
  bg: '#0d0e12',
  fg: '#ffffff',
  accent: '#E03E3E',
  glass: 'rgba(255,255,255,0.02)',
  glassHeavy: 'rgba(255,255,255,0.06)',
  border: 'rgba(255,255,255,0.05)',
};

const ANIMATIONS = {
  standard: 'all 0.6s cubic-bezier(0.2, 1, 0.3, 1)',
  hover: 'all 0.3s cubic-bezier(0.2, 1, 0.3, 1)',
};

// --- Components ---

const Icon = ({ name: IconComponent, size = 18, className = "", style = {} }) => (
  <IconComponent size={size} className={className} style={style} />
);

const Switch = ({ active, onChange }: { active: boolean, onChange?: () => void }) => (
  <div 
    onClick={onChange}
    style={{ 
      width: 42, height: 24, borderRadius: 12, background: active ? COLORS.accent : 'rgba(255,255,255,0.1)',
      position: 'relative', cursor: 'pointer', transition: '0.3s',
      boxShadow: active ? `0 0 15px ${COLORS.accent}44` : 'none'
    }}>
    <div style={{ 
      position: 'absolute', top: 3, left: active ? 21 : 3, width: 18, height: 18, 
      borderRadius: '50%', background: '#fff', transition: '0.3s cubic-bezier(0.2, 1, 0.3, 1)',
      boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
    }} />
  </div>
);

const SettingRow = ({ title, desc, children }: { title: string, desc: string, children: React.ReactNode }) => (
  <div style={{ 
    display: 'flex', justifyContent: 'space-between', alignItems: 'center', 
    padding: '24px 0', borderBottom: `1px solid ${COLORS.border}` 
  }}>
    <div style={{ flex: 1, paddingRight: 40 }}>
      <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{title}</div>
      <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.35)', lineHeight: 1.5 }}>{desc}</div>
    </div>
    {children}
  </div>
);

// --- Pages ---

const SettingsPage = () => {
  const [activeTab, setActiveTab] = useState('通用');
  const [fitMode, setFitMode] = useState('填充');

  const navItems = [
    { id: '通用', icon: Layout },
    { id: '性能', icon: Zap },
    { id: '库管理', icon: Layers },
    { id: '关于', icon: Info },
  ];

  const smartPauseItems: SmartPauseStrategy[] = [
    { id: 'battery', label: '电池供电时暂停', desc: '切换到电池模式时自动停止动态渲染', active: true },
    { id: 'fullscreen', label: '处于全屏应用时暂停', desc: '当有任何应用处于全屏状态时', active: true },
    { id: 'occlusion', label: '壁纸被完全遮挡时休眠', desc: '当桌面窗口完全覆盖壁纸表面时自动休眠', active: true },
    { id: 'lowpower', label: '低电量模式开启时', desc: '配合 macOS 系统低电量模式自动触发', active: true },
    { id: 'sharing', label: '屏幕共享或录制时暂停', desc: '保护隐私并确保演示流程顺畅', active: false },
    { id: 'clamshell', label: '笔记本盖子关闭时暂停', desc: '在翻盖模式下连接外屏时可选暂停', active: false },
    { id: 'highload', label: '运行高负载应用时暂停', desc: '如 Final Cut Pro, Blender 等开启时', active: false },
    { id: 'focus', label: '失去焦点时自动暂停', desc: '只要当前活跃窗口不是桌面，即停止渲染', active: false },
    { id: 'sleep', label: '系统锁定/进入睡眠前', desc: '提前停止渲染以加快系统待机速度', active: true },
  ];

  return (
    <div style={{ 
      height: '100vh', padding: '0 80px', background: COLORS.bg, 
      display: 'flex', gap: 40, overflow: 'hidden', alignItems: 'flex-start' 
    }}>
      {/* Sidebar - 采用实体材质杜绝分裂 Bug */}
      <div style={{ 
        width: 240, background: '#14151a', borderRight: `1px solid ${COLORS.border}`,
        padding: '140px 12px 32px', display: 'flex', flexDirection: 'column', gap: 4, 
        flexShrink: 0, height: '100%'
      }}>
        {navItems.map(item => (
          <div 
            key={item.id} 
            onClick={() => setActiveTab(item.id)}
            style={{ 
              padding: '12px 16px', borderRadius: 14, cursor: 'pointer', 
              transition: ANIMATIONS.hover, display: 'flex', alignItems: 'center', gap: 14,
              background: activeTab === item.id ? COLORS.glassHeavy : 'transparent',
              color: activeTab === item.id ? '#fff' : 'rgba(255,255,255,0.35)',
            }}
          >
            <Icon name={item.icon} size={18} />
            <span style={{ fontSize: 14, fontWeight: 700 }}>{item.id}</span>
          </div>
        ))}
      </div>

      {/* Main Content Area - 140px 垂直基准线对齐 */}
      <div className="no-scrollbar" style={{ 
        flex: 1, height: '100%', padding: '140px 72px 80px', overflowY: 'auto'
      }}>
        <h2 style={{ 
          fontSize: 42, fontFamily: "'Cormorant Garamond', serif", fontStyle: 'italic', 
          marginBottom: 56, letterSpacing: '-0.02em', marginTop: 0, lineHeight: 1, color: '#fff'
        }}>{activeTab}</h2>

        {activeTab === '通用' && (
          <div className="animate-in">
            <div style={{ fontSize: 13, fontWeight: 700, color: 'rgba(255,255,255,0.3)', marginBottom: 24, textTransform: 'uppercase', letterSpacing: '0.15em' }}>显示器拓扑布局</div>
            <div style={{ 
              background: 'rgba(0,0,0,0.3)', borderRadius: 28, padding: '60px 40px', 
              display: 'flex', alignItems: 'flex-end', justifyContent: 'center', gap: 40,
              border: `1px solid ${COLORS.border}`, position: 'relative', marginBottom: 56
            }}>
              {/* Monitors Visualization Mock */}
              <div style={{ textAlign: 'center' }}>
                <div style={{ 
                  width: 220, aspectRatio: '16/10', background: '#000', borderRadius: 14, 
                  border: `2px solid ${COLORS.accent}`, boxShadow: `0 0 40px ${COLORS.accent}22`,
                  marginBottom: 20, display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                  <Icon name={Monitor} size={48} style={{ opacity: 0.3 }} />
                </div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>Studio Display</div>
                <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', marginTop: 6 }}>5120×2880 · 主屏幕</div>
              </div>
            </div>
            
            <SettingRow title="启动时自动运行" desc="开机即刻呈现沉浸式桌面体验"><Switch active /></SettingRow>
            <SettingRow title="菜单栏快捷入口" desc="在顶部菜单栏显示实时状态图标"><Switch active /></SettingRow>
          </div>
        )}

        {activeTab === '性能' && (
          <div className="animate-in">
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 32, marginBottom: 56 }}>
              {[
                { label: 'GPU 渲染压力', value: '12.4%', color: COLORS.accent, unit: 'LOAD' },
                { label: '动态帧率', value: '120', color: '#2ECC71', unit: 'FPS' },
                { label: '系统内存占用', value: '420', color: '#3498DB', unit: 'MB' }
              ].map(stat => (
                <div key={stat.label} style={{ 
                  background: COLORS.glass, padding: 28, borderRadius: 24, border: `1px solid ${COLORS.border}`
                }}>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', marginBottom: 16, textTransform: 'uppercase', fontWeight: 800, letterSpacing: '0.1em' }}>{stat.label}</div>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                    <div style={{ fontSize: 36, fontWeight: 800, color: stat.color, fontFamily: 'monospace' }}>{stat.value}</div>
                    <div style={{ fontSize: 12, fontWeight: 600, color: 'rgba(255,255,255,0.2)' }}>{stat.unit}</div>
                  </div>
                </div>
              ))}
            </div>

            <div style={{ fontSize: 14, fontWeight: 700, color: 'rgba(255,255,255,0.3)', marginBottom: 24, textTransform: 'uppercase', letterSpacing: '0.1em' }}>智能暂停策略 (Smart Pause)</div>
            {smartPauseItems.map(item => (
              <SettingRow key={item.id} title={item.label} desc={item.desc}>
                <Switch active={item.active} />
              </SettingRow>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default SettingsPage;
