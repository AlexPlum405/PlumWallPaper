import React, { useState } from 'react';
import HomePage from './components/HomePage';
import SettingsPage from './components/SettingsPage';
import ColorPage from './components/ColorPage';
import LibraryPage from './components/LibraryPage';
import ImportModal from './components/ImportModal';
import { Search, Plus, Settings, Library, Home } from 'lucide-react';

// --- Global Styles ---
const GLOBAL_STYLE = `
  @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@1,300;1,700&family=Inter:wght@300;400;600;700;800&display=swap');
  
  :root {
    --accent: #E03E3E;
    --font-display: 'Cormorant Garamond', serif;
    --font-ui: 'Inter', sans-serif;
  }

  body {
    margin: 0;
    background: #0d0e12;
    color: #fff;
    font-family: var(--font-ui);
    -webkit-font-smoothing: antialiased;
    overflow-x: hidden;
  }

  .no-scrollbar::-webkit-scrollbar { display: none; }
  
  @keyframes fadeInUp {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .animate-in {
    animation: fadeInUp 0.8s cubic-bezier(0.2, 1, 0.3, 1) forwards;
  }

  .nav-tool-btn:hover {
    background: rgba(255,255,255,0.08) !important;
    transform: translateY(-2px);
  }

  .nav-tool-btn-primary:hover {
    background: var(--accent) !important;
    color: #fff !important;
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(224, 62, 62, 0.3);
  }

  /* 适配 Pill 切换器的滑块效果（模拟） */
  .pill-active {
    background: rgba(255,255,255,0.08) !important;
    color: #fff !important;
  }
`;

const App = () => {
  const [currentPage, setCurrentPage] = useState<'home' | 'library' | 'settings' | 'color'>('home');
  const [isImportOpen, setIsImportOpen] = useState(false);

  return (
    <div style={{ minHeight: '100vh', position: 'relative' }}>
      <style>{GLOBAL_STYLE}</style>

      {/* TopNav - macOS 沉浸式设计 */}
      <nav style={{ 
        position: 'fixed', top: 0, left: 0, width: '100%', height: 80, 
        padding: '0 80px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        zIndex: 1000, pointerEvents: 'none'
      }}>
        {/* Branding (左侧) */}
        <div 
          onClick={() => setCurrentPage('home')}
          style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer', pointerEvents: 'auto' }}
        >
          <div style={{ 
            width: 32, height: 32, background: 'var(--accent)', borderRadius: 8,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 15px rgba(224, 62, 62, 0.3)'
          }}>
            <div style={{ width: 12, height: 12, background: '#fff', borderRadius: 2 }} />
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <span style={{ fontSize: 28, fontFamily: 'var(--font-display)', fontStyle: 'italic', fontWeight: 700 }}>Plum</span>
            <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.4em', opacity: 0.4, textTransform: 'uppercase' }}>WallPaper</span>
          </div>
        </div>

        {/* View Switcher (中间 Pill) */}
        <div style={{ 
          background: 'rgba(255,255,255,0.04)', backdropFilter: 'blur(20px)', 
          padding: '4px', borderRadius: 14, display: 'flex', gap: 4, 
          border: '1px solid rgba(255,255,255,0.05)', pointerEvents: 'auto'
        }}>
          {[
            { id: 'home', label: '首页', icon: Home },
            { id: 'library', label: '壁纸库', icon: Library }
          ].map(view => (
            <div 
              key={view.id}
              onClick={() => setCurrentPage(view.id as any)}
              className={currentPage === view.id ? 'pill-active' : ''}
              style={{ 
                padding: '8px 24px', borderRadius: 10, cursor: 'pointer',
                display: 'flex', alignItems: 'center', gap: 10, transition: '0.3s cubic-bezier(0.2, 1, 0.3, 1)',
                color: currentPage === view.id ? '#fff' : 'rgba(255,255,255,0.4)',
                background: 'transparent'
              }}
            >
              <view.icon size={16} />
              <span style={{ fontSize: 13, fontWeight: 700 }}>{view.label}</span>
            </div>
          ))}
        </div>

        {/* Actions (右侧) */}
        <div style={{ display: 'flex', gap: 16, pointerEvents: 'auto' }}>
          <div 
            style={{ 
              width: 44, height: 44, borderRadius: '50%', background: 'rgba(255,255,255,0.04)',
              color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
              border: '1px solid rgba(255,255,255,0.05)', transition: '0.3s', cursor: 'pointer'
            }}
            className="nav-tool-btn"
          >
            <Search size={20} />
          </div>
          <div 
            onClick={() => setIsImportOpen(true)}
            style={{ 
              width: 44, height: 44, borderRadius: '50%', background: '#fff',
              color: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: '0.3s', cursor: 'pointer'
            }}
            className="nav-tool-btn nav-tool-btn-primary"
          >
            <Plus size={20} />
          </div>
          <div 
            onClick={() => setCurrentPage('settings')}
            style={{ 
              width: 44, height: 44, borderRadius: '50%', background: 'rgba(255,255,255,0.04)',
              color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
              border: '1px solid rgba(255,255,255,0.05)', transition: '0.3s', cursor: 'pointer'
            }}
            className="nav-tool-btn"
          >
            <Settings size={20} />
          </div>
        </div>
      </nav>

      {/* Page Router */}
      <main style={{ minHeight: '100vh' }}>
        {currentPage === 'home' && <HomePage />}
        {currentPage === 'library' && <LibraryPage />}
        {currentPage === 'settings' && <SettingsPage />}
        {currentPage === 'color' && <ColorPage onBack={() => setCurrentPage('home')} />}
      </main>

      {/* Modals & Overlays */}
      <ImportModal isOpen={isImportOpen} onClose={() => setIsImportOpen(false)} />

      {/* 全局悬浮演示: 进入 ColorPage (Demo Only) */}
      {currentPage === 'home' && (
        <div 
          onClick={() => setCurrentPage('color')}
          style={{ 
            position: 'fixed', bottom: 40, right: 40, padding: '16px 24px', 
            background: 'var(--accent)', borderRadius: 16, cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 12, fontWeight: 800, fontSize: 13,
            boxShadow: '0 10px 30px rgba(224, 62, 62, 0.4)', zIndex: 100,
            transition: '0.3s'
          }}
          className="nav-tool-btn-primary"
        >
          <Plus size={18} /> 进入调色演示 (Demo)
        </div>
      )}
    </div>
  );
};

export default App;
