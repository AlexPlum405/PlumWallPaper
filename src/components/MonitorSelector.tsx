import React, { useState } from 'react';
import { X, Monitor, Check, Layers, MonitorOff } from 'lucide-react';

interface Display {
  id: string;
  name: string;
  res: string;
  isMain: boolean;
  currentWallpaper?: string;
}

interface MonitorSelectorProps {
  isOpen: boolean;
  onClose: () => void;
  wallpaperName: string;
}

const COLORS = {
  bg: '#14151a',
  accent: '#E03E3E',
  border: 'rgba(255,255,255,0.08)',
};

const MonitorSelector: React.FC<MonitorSelectorProps> = ({ isOpen, onClose, wallpaperName }) => {
  const [selectedDisplays, setSelectedDisplays] = useState<string[]>(['1']);
  
  const displays: Display[] = [
    { id: '1', name: 'Studio Display', res: '5120×2880', isMain: true, currentWallpaper: 'Deep Space' },
    { id: '2', name: 'Built-in Liquid Retina', res: '3456×2234', isMain: false, currentWallpaper: 'Minimal Peak' },
  ];

  const toggleDisplay = (id: string) => {
    setSelectedDisplays(prev => 
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  if (!isOpen) return null;

  return (
    <div style={{ 
      position: 'fixed', inset: 0, zIndex: 3000, display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(30px)'
    }}>
      <div 
        className="animate-in"
        style={{ 
          width: 560, background: COLORS.bg, borderRadius: 24, border: `1px solid ${COLORS.border}`,
          boxShadow: '0 40px 120px rgba(0,0,0,0.8)', overflow: 'hidden'
        }}
      >
        {/* Header */}
        <div style={{ padding: '32px 32px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 style={{ fontSize: 22, fontWeight: 700, margin: 0 }}>应用壁纸到显示器</h2>
            <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.3)', marginTop: 4 }}>
              正在处理: <span style={{ color: COLORS.accent, fontWeight: 700 }}>{wallpaperName}</span>
            </p>
          </div>
          <div onClick={onClose} style={{ cursor: 'pointer', opacity: 0.4 }}><X size={20} /></div>
        </div>

        {/* Display List */}
        <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 16 }}>
          {displays.map(d => (
            <div 
              key={d.id}
              onClick={() => toggleDisplay(d.id)}
              style={{ 
                padding: 20, borderRadius: 16, border: `1px solid ${selectedDisplays.includes(d.id) ? COLORS.accent : 'rgba(255,255,255,0.05)'}`,
                background: selectedDisplays.includes(d.id) ? 'rgba(224, 62, 62, 0.05)' : 'rgba(255,255,255,0.02)',
                display: 'flex', alignItems: 'center', gap: 20, cursor: 'pointer', transition: '0.3s'
              }}
            >
              <div style={{ 
                width: 48, height: 48, borderRadius: 10, background: selectedDisplays.includes(d.id) ? COLORS.accent : 'rgba(255,255,255,0.05)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', transition: '0.3s'
              }}>
                <Monitor size={24} style={{ color: selectedDisplays.includes(d.id) ? '#fff' : 'rgba(255,255,255,0.2)' }} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 8 }}>
                  {d.name}
                  {d.isMain && <span style={{ fontSize: 10, background: 'rgba(255,255,255,0.06)', padding: '2px 6px', borderRadius: 4, fontWeight: 800, opacity: 0.5 }}>MAIN</span>}
                </div>
                <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.3)', marginTop: 4 }}>
                  {d.res} · 当前: {d.currentWallpaper}
                </div>
              </div>
              <div style={{ 
                width: 24, height: 24, borderRadius: '50%', border: `2px solid ${selectedDisplays.includes(d.id) ? COLORS.accent : 'rgba(255,255,255,0.1)'}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', transition: '0.3s',
                background: selectedDisplays.includes(d.id) ? COLORS.accent : 'transparent'
              }}>
                {selectedDisplays.includes(d.id) && <Check size={14} strokeWidth={3} />}
              </div>
            </div>
          ))}
        </div>

        {/* Footer Actions */}
        <div style={{ 
          padding: '24px 32px', background: 'rgba(255,255,255,0.02)', borderTop: `1px solid ${COLORS.border}`,
          display: 'flex', justifyContent: 'flex-end', gap: 12
        }}>
          <button 
            onClick={() => setSelectedDisplays(displays.map(d => d.id))}
            style={{ 
              background: 'transparent', border: 'none', color: 'rgba(255,255,255,0.4)', 
              fontSize: 13, fontWeight: 600, cursor: 'pointer', padding: '0 12px' 
            }}
          >
            全选显示器
          </button>
          <button 
            onClick={onClose}
            style={{ 
              background: '#fff', color: '#000', border: 'none', padding: '12px 28px', 
              borderRadius: 12, fontSize: 14, fontWeight: 700, cursor: 'pointer',
              boxShadow: '0 10px 20px rgba(0,0,0,0.2)'
            }}
          >
            确认应用
          </button>
        </div>
      </div>
    </div>
  );
};

export default MonitorSelector;
