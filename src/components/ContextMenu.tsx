import React, { useEffect, useRef } from 'react';
import { Monitor, Sliders, Heart, Trash2, Copy, Share2, Info } from 'lucide-react';

interface ContextMenuProps {
  x: number;
  y: number;
  isOpen: boolean;
  onClose: () => void;
  onAction: (action: string) => void;
  isFavorite?: boolean;
}

const COLORS = {
  bg: 'rgba(28, 28, 32, 0.85)',
  border: 'rgba(255, 255, 255, 0.1)',
  hover: 'rgba(255, 255, 255, 0.1)',
  danger: '#E03E3E'
};

const ContextMenu: React.FC<ContextMenuProps> = ({ x, y, isOpen, onClose, onAction, isFavorite }) => {
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        onClose();
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  // 确保菜单不超出屏幕边界
  const menuWidth = 220;
  const menuHeight = 320;
  const adjustedX = x + menuWidth > window.innerWidth ? x - menuWidth : x;
  const adjustedY = y + menuHeight > window.innerHeight ? y - menuHeight : y;

  return (
    <div 
      ref={menuRef}
      style={{ 
        position: 'fixed', top: adjustedY, left: adjustedX, width: menuWidth,
        background: COLORS.bg, backdropFilter: 'blur(30px) saturate(180%)',
        borderRadius: 14, border: `1px solid ${COLORS.border}`,
        boxShadow: '0 20px 50px rgba(0,0,0,0.5)', zIndex: 5000,
        padding: '6px', display: 'flex', flexDirection: 'column', gap: 2,
        animation: 'fadeIn 0.15s ease-out'
      }}
    >
      <MenuItem icon={Monitor} label="设为壁纸" onClick={() => onAction('apply')} />
      <MenuItem icon={Sliders} label="色彩调节" onClick={() => onAction('color')} />
      <MenuItem 
        icon={Heart} 
        label={isFavorite ? "取消收藏" : "加入收藏"} 
        onClick={() => onAction('favorite')}
        iconColor={isFavorite ? COLORS.danger : undefined}
      />
      
      <div style={{ height: 1, background: 'rgba(255,255,255,0.06)', margin: '4px 8px' }} />
      
      <MenuItem icon={Copy} label="复制资源路径" onClick={() => onAction('copy')} />
      <MenuItem icon={Share2} label="分享到 AirDrop" onClick={() => onAction('share')} />
      <MenuItem icon={Info} label="查看详细信息" onClick={() => onAction('info')} />
      
      <div style={{ height: 1, background: 'rgba(255,255,255,0.06)', margin: '4px 8px' }} />
      
      <MenuItem 
        icon={Trash2} 
        label="删除壁纸" 
        onClick={() => onAction('delete')} 
        danger 
      />
    </div>
  );
};

const MenuItem = ({ 
  icon: Icon, label, onClick, danger, iconColor 
}: { 
  icon: any, label: string, onClick: () => void, danger?: boolean, iconColor?: string 
}) => {
  const [isHovered, setIsHovered] = React.useState(false);

  return (
    <div 
      onClick={(e) => { e.stopPropagation(); onClick(); }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={{ 
        padding: '8px 12px', borderRadius: 8, cursor: 'pointer',
        display: 'flex', alignItems: 'center', gap: 10,
        background: isHovered ? (danger ? 'rgba(224, 62, 62, 0.15)' : COLORS.hover) : 'transparent',
        transition: '0.2s',
        color: danger ? COLORS.danger : (isHovered ? '#fff' : 'rgba(255,255,255,0.8)')
      }}
    >
      <Icon size={16} style={{ color: iconColor || (danger ? COLORS.danger : 'currentColor'), opacity: isHovered ? 1 : 0.6 }} />
      <span style={{ fontSize: 13, fontWeight: 500 }}>{label}</span>
    </div>
  );
};

export default ContextMenu;
