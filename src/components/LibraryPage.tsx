import React, { useState } from 'react';
import { Search, Filter, SortDesc, Heart, MoreHorizontal, Play, LayoutGrid, List } from 'lucide-react';

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

const MOCK_DATA: Wallpaper[] = [
  { id: '1', name: 'Deep Space Nebula', type: 'video', res: '8K', size: '1.2GB', duration: '00:45', tags: ['Sci-Fi', 'Space'], isFavorite: true, thumb: 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=800&q=80' },
  { id: '2', name: 'Minimalist Peak', type: 'heic', res: '6K', size: '45MB', tags: ['Nature', 'Minimal'], isFavorite: false, thumb: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80' },
  { id: '3', name: 'Cyberpunk Rain', type: 'video', res: '4K', size: '850MB', duration: '01:20', tags: ['City', 'Cyber'], isFavorite: true, thumb: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=800&q=80' },
  { id: '4', name: 'Autumn Whisper', type: 'heic', res: '5K', size: '32MB', tags: ['Nature', 'Season'], isFavorite: false, thumb: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80' },
  { id: '5', name: 'Abstract Flow', type: 'video', res: '4K', size: '600MB', duration: '00:30', tags: ['Art', 'Motion'], isFavorite: false, thumb: 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=800&q=80' },
  { id: '6', name: 'Forest Path', type: 'heic', res: '8K', size: '52MB', tags: ['Nature'], isFavorite: true, thumb: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=800&q=80' },
];

const LibraryPage = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState('全部');

  const filters = ['全部', '收藏', '视频', '动态照片', '自然', '城市', '艺术'];

  return (
    <div style={{ padding: '120px 80px 80px', minHeight: '100vh', background: '#0d0e12' }}>
      {/* Header & Filters */}
      <div style={{ marginBottom: 48 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 32 }}>
          <div>
            <h1 style={{ fontSize: 48, fontFamily: "'Cormorant Garamond', serif", fontStyle: 'italic', marginBottom: 12 }}>壁纸库</h1>
            <p style={{ color: 'rgba(255,255,255,0.3)', fontSize: 14 }}>共 {MOCK_DATA.length} 项资源已就绪</p>
          </div>
          
          <div style={{ display: 'flex', gap: 16 }}>
            <div style={{ 
              position: 'relative', background: 'rgba(255,255,255,0.04)', borderRadius: 12,
              border: '1px solid rgba(255,255,255,0.05)', padding: '0 16px', display: 'flex', alignItems: 'center',
              width: 300
            }}>
              <Search size={18} style={{ opacity: 0.3, marginRight: 12 }} />
              <input 
                placeholder="搜索名称或标签..." 
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                style={{ 
                  background: 'none', border: 'none', color: '#fff', height: 44, width: '100%',
                  outline: 'none', fontSize: 13
                }}
              />
            </div>
            <button style={{ 
              background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.05)', 
              borderRadius: 12, padding: '0 16px', color: '#fff', display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer'
            }}>
              <SortDesc size={18} /> 排序
            </button>
          </div>
        </div>

        {/* Filter Pills */}
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto' }} className="no-scrollbar">
          {filters.map(f => (
            <div 
              key={f}
              onClick={() => setActiveFilter(f)}
              style={{ 
                padding: '8px 20px', borderRadius: 10, fontSize: 13, fontWeight: 700, cursor: 'pointer',
                transition: '0.3s',
                background: activeFilter === f ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.02)',
                color: activeFilter === f ? '#fff' : 'rgba(255,255,255,0.3)',
                border: `1px solid ${activeFilter === f ? 'rgba(255,255,255,0.1)' : 'transparent'}`
              }}
            >
              {f}
            </div>
          ))}
        </div>
      </div>

      {/* Wallpaper Grid */}
      <div style={{ 
        display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 32 
      }}>
        {MOCK_DATA.map(w => (
          <div key={w.id} className="library-card" style={{ cursor: 'pointer' }}>
            <div style={{ 
              aspectRatio: '16/9', borderRadius: 14, overflow: 'hidden', marginBottom: 16,
              position: 'relative', border: '1px solid rgba(255,255,255,0.05)',
              background: 'rgba(255,255,255,0.02)'
            }}>
              <img 
                src={w.thumb} 
                style={{ width: '100%', height: '100%', objectFit: 'cover', transition: '0.6s cubic-bezier(0.2, 1, 0.3, 1)' }} 
                className="hover-scale"
              />
              
              {/* Card Badges */}
              <div style={{ position: 'absolute', top: 12, left: 12, display: 'flex', gap: 6 }}>
                <div style={{ background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(10px)', padding: '4px 8px', borderRadius: 6, fontSize: 10, fontWeight: 800 }}>
                  {w.res}
                </div>
                {w.type === 'video' && (
                  <div style={{ background: 'rgba(224, 62, 62, 0.8)', padding: '4px 8px', borderRadius: 6, fontSize: 10, fontWeight: 800 }}>
                    VIDEO
                  </div>
                )}
              </div>

              {/* Heart Icon Overlay */}
              <div style={{ position: 'absolute', top: 12, right: 12, opacity: w.isFavorite ? 1 : 0 }} className="heart-badge">
                <Heart size={16} fill="#E03E3E" stroke="#E03E3E" />
              </div>

              {/* Hover Play Button */}
              <div className="card-hover-overlay" style={{ 
                position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)', opacity: 0, transition: '0.3s',
                display: 'flex', alignItems: 'center', justifyContent: 'center'
              }}>
                <div style={{ 
                  width: 48, height: 48, borderRadius: '50%', background: '#fff', color: '#000',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 10px 20px rgba(0,0,0,0.3)'
                }}>
                  <Play size={20} fill="#000" />
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4 }}>{w.name}</div>
                <div style={{ display: 'flex', gap: 8, fontSize: 11, color: 'rgba(255,255,255,0.3)', fontWeight: 600 }}>
                  <span>{w.size}</span>
                  {w.duration && <span>· {w.duration}</span>}
                </div>
              </div>
              <button style={{ 
                background: 'none', border: 'none', color: 'rgba(255,255,255,0.3)', cursor: 'pointer', padding: 4 
              }}>
                <MoreHorizontal size={18} />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default LibraryPage;
