import React, { useState } from 'react';
import { Sliders, Sun, Contrast, Droplets, Palette, Wind, Zap, Check, RotateCcw, X, Save } from 'lucide-react';

// --- Types ---
interface FilterState {
  exposure: number;
  contrast: number;
  saturation: number;
  hue: number;
  blur: number;
  grain: number;
  vignette: number;
  grayscale: number;
  invert: number;
}

const DEFAULT_FILTERS: FilterState = {
  exposure: 100,
  contrast: 100,
  saturation: 100,
  hue: 0,
  blur: 0,
  grain: 0,
  vignette: 0,
  grayscale: 0,
  invert: 0,
};

const ColorPage = ({ onBack }: { onBack: () => void }) => {
  const [filters, setFilters] = useState<FilterState>(DEFAULT_FILTERS);

  const updateFilter = (key: keyof FilterState, val: number) => {
    setFilters(prev => ({ ...prev, [key]: val }));
  };

  // 生成 CSS Filter 字符串
  const filterString = `
    brightness(${filters.exposure}%)
    contrast(${filters.contrast}%)
    saturate(${filters.saturation}%)
    hue-rotate(${filters.hue}deg)
    blur(${filters.blur}px)
    grayscale(${filters.grayscale}%)
    invert(${filters.invert}%)
  `;

  return (
    <div style={{ height: '100vh', background: '#000', color: '#fff', display: 'flex', overflow: 'hidden' }}>
      {/* 全屏预览区 */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <img 
          src="https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=1600&q=80" 
          style={{ width: '100%', height: '100%', objectFit: 'cover', filter: filterString }}
        />
        
        {/* 暗角层 */}
        <div style={{ 
          position: 'absolute', inset: 0, pointerEvents: 'none',
          background: `radial-gradient(circle, transparent 40%, rgba(0,0,0,${filters.vignette / 100}))`
        }} />

        {/* 动态颗粒层 (SVG Filter) */}
        <div style={{ 
          position: 'absolute', inset: 0, pointerEvents: 'none', opacity: filters.grain / 100,
          background: `url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`
        }} />

        {/* 顶部退出按钮 */}
        <div 
          onClick={onBack}
          style={{ 
            position: 'absolute', top: 32, left: 32, padding: '12px', 
            borderRadius: '50%', background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(10px)',
            cursor: 'pointer', border: '1px solid rgba(255,255,255,0.1)'
          }}>
          <X size={20} />
        </div>
      </div>

      {/* 右侧调节面板 (360px) */}
      <div style={{ 
        width: 360, height: '100%', background: '#111216', borderLeft: '1px solid rgba(255,255,255,0.05)',
        padding: '40px 32px', display: 'flex', flexDirection: 'column', gap: 40, overflowY: 'auto'
      }} className="no-scrollbar">
        <div>
          <h2 style={{ fontSize: 24, fontFamily: "'Cormorant Garamond', serif", fontStyle: 'italic', marginBottom: 8 }}>色彩调节</h2>
          <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.3)' }}>实时调整渲染引擎输出</p>
        </div>

        {/* 调节组: 基础校正 */}
        <ControlGroup label="基础校正">
          <SliderRow icon={Sun} label="曝光度" value={filters.exposure} min={0} max={200} onChange={v => updateFilter('exposure', v)} />
          <SliderRow icon={Contrast} label="对比度" value={filters.contrast} min={0} max={200} onChange={v => updateFilter('contrast', v)} />
          <SliderRow icon={Droplets} label="饱和度" value={filters.saturation} min={0} max={200} onChange={v => updateFilter('saturation', v)} />
          <SliderRow icon={Palette} label="色调" value={filters.hue} min={-180} max={180} onChange={v => updateFilter('hue', v)} />
        </ControlGroup>

        {/* 调节组: 艺术效果 */}
        <ControlGroup label="艺术效果">
          <SliderRow icon={Wind} label="模糊" value={filters.blur} min={0} max={20} onChange={v => updateFilter('blur', v)} />
          <SliderRow icon={Zap} label="颗粒感" value={filters.grain} min={0} max={100} onChange={v => updateFilter('grain', v)} />
          <SliderRow icon={Sliders} label="暗角" value={filters.vignette} min={0} max={100} onChange={v => updateFilter('vignette', v)} />
        </ControlGroup>

        {/* 操作底栏 */}
        <div style={{ marginTop: 'auto', display: 'flex', gap: 12 }}>
          <button 
            onClick={() => setFilters(DEFAULT_FILTERS)}
            style={{ 
              flex: 1, padding: '14px', borderRadius: 12, background: 'rgba(255,255,255,0.05)',
              border: '1px solid rgba(255,255,255,0.1)', color: '#fff', fontSize: 13, fontWeight: 700,
              cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8
            }}>
            <RotateCcw size={16} /> 重置
          </button>
          <button style={{ 
            flex: 1, padding: '14px', borderRadius: 12, background: '#fff',
            border: 'none', color: '#000', fontSize: 13, fontWeight: 700,
            cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8
          }}>
            <Check size={16} /> 应用
          </button>
        </div>
      </div>
    </div>
  );
};

// --- Subcomponents ---

const ControlGroup = ({ label, children }: { label: string, children: React.ReactNode }) => (
  <div>
    <div style={{ fontSize: 11, fontWeight: 800, color: 'rgba(255,255,255,0.2)', textTransform: 'uppercase', letterSpacing: '0.15em', marginBottom: 20 }}>{label}</div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>{children}</div>
  </div>
);

const SliderRow = ({ icon: Icon, label, value, min, max, onChange }: any) => (
  <div>
    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12, fontSize: 13, fontWeight: 600 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Icon size={14} style={{ opacity: 0.5 }} />
        <span>{label}</span>
      </div>
      <span style={{ color: '#E03E3E', fontFamily: 'monospace' }}>{Math.round(value)}</span>
    </div>
    <input 
      type="range" min={min} max={max} value={value} 
      onChange={e => onChange(Number(e.target.value))}
      style={{ 
        width: '100%', accentColor: '#E03E3E', height: 4, background: 'rgba(255,255,255,0.1)', 
        borderRadius: 2, appearance: 'none', cursor: 'pointer' 
      }}
    />
  </div>
);

export default ColorPage;
