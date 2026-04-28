import React, { useState, useRef, useEffect } from 'react';
import { Play, Heart, Monitor, MoreHorizontal, ChevronRight, Search, Plus } from 'lucide-react';

// --- Types ---
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

// --- Constants ---
const COLORS = {
  bg: '#0d0e12',
  accent: '#E03E3E',
  glass: 'rgba(255,255,255,0.04)',
  glassHeavy: 'rgba(255,255,255,0.08)',
  border: 'rgba(255,255,255,0.1)',
};

// --- Mock Data ---
const MOCK_WALLPAPERS: Wallpaper[] = [
  { id: '1', name: 'Deep Space Nebula', type: 'video', res: '8K', size: '1.2GB', duration: '00:45', tags: ['Sci-Fi', 'Space'], isFavorite: true, thumb: 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=800&q=80' },
  { id: '2', name: 'Minimalist Peak', type: 'heic', res: '6K', size: '45MB', tags: ['Nature', 'Minimal'], isFavorite: false, thumb: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80' },
  { id: '3', name: 'Cyberpunk Rain', type: 'video', res: '4K', size: '850MB', duration: '01:20', tags: ['City', 'Cyber'], isFavorite: true, thumb: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=800&q=80' },
  { id: '4', name: 'Autumn Whisper', type: 'heic', res: '5K', size: '32MB', tags: ['Nature', 'Season'], isFavorite: false, thumb: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80' },
  { id: '5', name: 'Abstract Flow', type: 'video', res: '4K', size: '600MB', duration: '00:30', tags: ['Art', 'Motion'], isFavorite: false, thumb: 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=800&q=80' },
];

const HomePage = () => {
  const [activeId, setActiveId] = useState(MOCK_WALLPAPERS[0].id);
  const activeWallpaper = MOCK_WALLPAPERS.find(w => w.id === activeId) || MOCK_WALLPAPERS[0];
  
  // 滚动与拖拽逻辑
  const scrollRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [startX, setStartX] = useState(0);
  const [scrollLeft, setScrollLeft] = useState(0);
  const [dragDistance, setDragDistance] = useState(0);

  const handleMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true);
    setStartX(e.pageX - (scrollRef.current?.offsetLeft || 0));
    setScrollLeft(scrollRef.current?.scrollLeft || 0);
    setDragDistance(0);
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    e.preventDefault();
    const x = e.pageX - (scrollRef.current?.offsetLeft || 0);
    const walk = (x - startX) * 2;
    if (scrollRef.current) scrollRef.current.scrollLeft = scrollLeft - walk;
    setDragDistance(Math.abs(x - startX));
  };

  const handleMouseUp = (id: string) => {
    setIsDragging(false);
    // 只有当拖拽距离小于 5px 时才判定为点击切换
    if (dragDistance < 5) {
      setActiveId(id);
    }
  };

  return (
    <div style={{ background: COLORS.bg, minHeight: '100vh', color: '#fff', overflowX: 'hidden' }}>
      {/* Hero Section */}
      <div style={{ position: 'relative', height: '85vh', overflow: 'hidden' }}>
        {/* Background Image with Gradient Overlay */}
        <div style={{ 
          position: 'absolute', inset: 0, 
          backgroundImage: `url(${activeWallpaper.thumb})`, 
          backgroundSize: 'cover', backgroundPosition: 'center',
          transition: '1s cubic-bezier(0.2, 1, 0.3, 1)',
          filter: 'brightness(0.7)'
        }} />
        <div style={{ 
          position: 'absolute', inset: 0, 
          background: 'linear-gradient(to bottom, transparent 30%, #0d0e12 100%)' 
        }} />

        {/* Hero Info */}
        <div style={{ 
          position: 'absolute', bottom: '25%', left: 80, maxWidth: 600, zIndex: 10,
          animation: 'fadeInUp 1s cubic-bezier(0.2, 1, 0.3, 1)'
        }}>
          <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
            {activeWallpaper.tags.map(tag => (
              <span key={tag} style={{ fontSize: 11, fontWeight: 800, letterSpacing: '0.2em', color: COLORS.accent, textTransform: 'uppercase' }}>
                {tag}
              </span>
            ))}
          </div>
          <h1 style={{ 
            fontSize: 84, fontFamily: "'Cormorant Garamond', serif", fontStyle: 'italic', 
            margin: '0 0 24px', lineHeight: 0.9, letterSpacing: '-0.03em' 
          }}>
            {activeWallpaper.name}
          </h1>
          <div style={{ display: 'flex', gap: 24, fontSize: 12, color: 'rgba(255,255,255,0.4)', fontWeight: 600, marginBottom: 40 }}>
            <span>{activeWallpaper.type.toUpperCase()}</span>
            <span>{activeWallpaper.res}</span>
            <span>{activeWallpaper.size}</span>
            {activeWallpaper.duration && <span>{activeWallpaper.duration}</span>}
          </div>
          <div style={{ display: 'flex', gap: 16 }}>
            <button style={{ 
              background: '#fff', color: '#000', border: 'none', padding: '14px 32px', 
              borderRadius: 12, fontSize: 14, fontWeight: 700, cursor: 'pointer',
              display: 'flex', alignItems: 'center', gap: 10, transition: '0.3s'
            }} className="btn-primary">
              <Monitor size={18} /> 设为壁纸
            </button>
            <button style={{ 
              background: 'rgba(255,255,255,0.08)', color: '#fff', border: '1px solid rgba(255,255,255,0.1)', 
              padding: '14px 20px', borderRadius: 12, cursor: 'pointer', transition: '0.3s'
            }}>
              <Heart size={20} fill={activeWallpaper.isFavorite ? COLORS.accent : 'none'} stroke={activeWallpaper.isFavorite ? COLORS.accent : 'currentColor'} />
            </button>
          </div>
        </div>

        {/* Thumb Strip */}
        <div 
          ref={scrollRef}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={() => setIsDragging(false)}
          onMouseLeave={() => setIsDragging(false)}
          style={{ 
            position: 'absolute', bottom: 40, left: 0, width: '100%', 
            padding: '0 80px', display: 'flex', gap: 20, overflowX: 'auto',
            cursor: isDragging ? 'grabbing' : 'grab',
            msOverflowStyle: 'none', scrollbarWidth: 'none'
          }}
          className="no-scrollbar"
        >
          {MOCK_WALLPAPERS.map(w => (
            <div 
              key={w.id}
              onMouseUp={() => handleMouseUp(w.id)}
              style={{ 
                flexShrink: 0, width: 220, aspectRatio: '16/9', borderRadius: 12,
                backgroundImage: `url(${w.thumb})`, backgroundSize: 'cover',
                border: activeId === w.id ? '2px solid #fff' : '2px solid transparent',
                opacity: activeId === w.id ? 1 : 0.4,
                transition: '0.4s cubic-bezier(0.2, 1, 0.3, 1)',
                cursor: 'pointer'
              }}
            />
          ))}
        </div>
      </div>

      {/* Grid Section */}
      <div style={{ padding: '80px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 40 }}>
          <h2 style={{ fontSize: 32, fontFamily: "'Cormorant Garamond', serif", fontStyle: 'italic' }}>最近添加</h2>
          <div style={{ display: 'flex', gap: 12, color: 'rgba(255,255,255,0.4)', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
            查看全部 <ChevronRight size={16} />
          </div>
        </div>
        
        <div style={{ 
          display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 32 
        }}>
          {MOCK_WALLPAPERS.map(w => (
            <div key={w.id} className="wallpaper-card" style={{ cursor: 'pointer' }}>
              <div style={{ 
                aspectRatio: '16/9', borderRadius: 16, overflow: 'hidden', marginBottom: 16,
                position: 'relative', border: '1px solid rgba(255,255,255,0.05)'
              }}>
                <img src={w.thumb} style={{ width: '100%', height: '100%', objectFit: 'cover', transition: '0.6s' }} />
                <div className="card-overlay" style={{ 
                  position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', opacity: 0, transition: '0.3s',
                  display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                  <Play size={40} fill="#fff" />
                </div>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>{w.name}</div>
                  <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.3)' }}>{w.res} · {w.type.toUpperCase()}</div>
                </div>
                <MoreHorizontal size={18} style={{ opacity: 0.3 }} />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default HomePage;
