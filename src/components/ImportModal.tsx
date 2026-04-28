import React, { useState, useCallback } from 'react';
import { X, Upload, FileVideo, Image, AlertCircle, CheckCircle2, Loader2, Info } from 'lucide-react';

// --- Types ---
interface ImportModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const COLORS = {
  bg: '#14151a',
  accent: '#E03E3E',
  glass: 'rgba(255,255,255,0.04)',
  border: 'rgba(255,255,255,0.08)',
};

const ImportModal: React.FC<ImportModalProps> = ({ isOpen, onClose }) => {
  const [isDragging, setIsDragging] = useState(false);
  const [status, setStatus] = useState<'idle' | 'analyzing' | 'success'>('idle');
  const [progress, setProgress] = useState(0);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    startMockImport();
  }, []);

  const startMockImport = () => {
    setStatus('analyzing');
    let p = 0;
    const interval = setInterval(() => {
      p += Math.random() * 15;
      if (p >= 100) {
        p = 100;
        clearInterval(interval);
        setTimeout(() => setStatus('success'), 500);
      }
      setProgress(p);
    }, 200);
  };

  if (!isOpen) return null;

  return (
    <div style={{ 
      position: 'fixed', inset: 0, zIndex: 2000, display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'rgba(0,0,0,0.8)', backdropFilter: 'blur(20px)'
    }}>
      {/* Modal Container */}
      <div 
        className="animate-in"
        style={{ 
          width: 640, background: COLORS.bg, borderRadius: 28, border: `1px solid ${COLORS.border}`,
          boxShadow: '0 40px 100px rgba(0,0,0,0.6)', overflow: 'hidden', position: 'relative'
        }}
      >
        {/* Header */}
        <div style={{ padding: '32px 40px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 style={{ fontSize: 28, fontFamily: "'Cormorant Garamond', serif", fontStyle: 'italic', margin: 0 }}>导入资源</h2>
            <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.3)', marginTop: 4 }}>支持视频 (MP4/MOV) 与动态照片 (HEIC)</p>
          </div>
          <div 
            onClick={onClose}
            style={{ 
              width: 36, height: 36, borderRadius: '50%', background: 'rgba(255,255,255,0.04)', 
              display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', transition: '0.3s'
            }}
          >
            <X size={18} />
          </div>
        </div>

        {/* Body */}
        <div style={{ padding: 40 }}>
          {status === 'idle' && (
            <div 
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              style={{ 
                height: 280, borderRadius: 24, border: `2px dashed ${isDragging ? COLORS.accent : 'rgba(255,255,255,0.1)'}`,
                background: isDragging ? 'rgba(224, 62, 62, 0.05)' : 'rgba(255,255,255,0.02)',
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                transition: '0.4s cubic-bezier(0.2, 1, 0.3, 1)', cursor: 'pointer'
              }}
            >
              <div style={{ 
                width: 64, height: 64, borderRadius: '50%', background: isDragging ? COLORS.accent : 'rgba(255,255,255,0.05)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 20, transition: '0.4s'
              }}>
                <Upload size={28} style={{ color: isDragging ? '#fff' : 'rgba(255,255,255,0.4)' }} />
              </div>
              <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 8 }}>拖拽文件到此处</div>
              <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.3)' }}>或者点击浏览本地库</div>
              
              {/* Format Tags */}
              <div style={{ display: 'flex', gap: 8, marginTop: 32 }}>
                {['VIDEO', '8K+', 'HEIC', 'ProRAW'].map(tag => (
                  <div key={tag} style={{ 
                    fontSize: 9, fontWeight: 800, padding: '4px 10px', borderRadius: 6, 
                    background: 'rgba(255,255,255,0.04)', color: 'rgba(255,255,255,0.4)', letterSpacing: '0.1em'
                  }}>{tag}</div>
                ))}
              </div>
            </div>
          )}

          {status === 'analyzing' && (
            <div style={{ height: 280, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ position: 'relative', width: 80, height: 80, marginBottom: 32 }}>
                <Loader2 size={80} className="animate-spin" style={{ color: COLORS.accent, opacity: 0.2 }} />
                <div style={{ 
                  position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 16, fontWeight: 800, fontFamily: 'monospace'
                }}>
                  {Math.round(progress)}%
                </div>
              </div>
              <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 12 }}>正在重建视频索引...</div>
              <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.3)', display: 'flex', alignItems: 'center', gap: 6 }}>
                <AlertCircle size={14} /> 请勿关闭应用，分析过程中将提取色彩元数据
              </div>
              
              {/* Progress Bar Container */}
              <div style={{ width: '100%', maxWidth: 400, height: 4, background: 'rgba(255,255,255,0.05)', borderRadius: 2, marginTop: 40, overflow: 'hidden' }}>
                <div style={{ width: `${progress}%`, height: '100%', background: COLORS.accent, transition: '0.3s' }} />
              </div>
            </div>
          )}

          {status === 'success' && (
            <div style={{ height: 280, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ 
                width: 80, height: 80, borderRadius: '50%', background: 'rgba(46, 204, 113, 0.1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 24
              }}>
                <CheckCircle2 size={40} style={{ color: '#2ECC71' }} />
              </div>
              <div style={{ fontSize: 20, fontWeight: 700, marginBottom: 12 }}>成功导入 12 项资源</div>
              <div style={{ fontSize: 14, color: 'rgba(255,255,255,0.3)', marginBottom: 32 }}>资源已自动归类到“最近添加”</div>
              <button 
                onClick={onClose}
                style={{ 
                  background: '#fff', color: '#000', border: 'none', padding: '12px 32px', 
                  borderRadius: 12, fontSize: 14, fontWeight: 700, cursor: 'pointer'
                }}>
                完成
              </button>
            </div>
          )}
        </div>

        {/* Footer Hint */}
        {status === 'idle' && (
          <div style={{ 
            padding: '24px 40px', background: 'rgba(255,255,255,0.02)', borderTop: `1px solid ${COLORS.border}`,
            display: 'flex', alignItems: 'center', gap: 12, color: 'rgba(255,255,255,0.3)', fontSize: 12
          }}>
            <Info size={14} /> 导入的资源将自动复制到应用管理的库路径中 (Managed Mode)
          </div>
        )}
      </div>
    </div>
  );
};

export default ImportModal;
