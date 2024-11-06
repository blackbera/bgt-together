interface NavbarProps {
  children?: React.ReactNode;
}

export function Navbar({ children }: NavbarProps) {
  return (
    <nav className="sticky top-0 z-50 backdrop-blur-xl bg-white/[0.02]">
      <div className="max-w-7xl mx-auto">
        <div className="flex items-center justify-between h-16">
          <div className="w-[120px]" />
          
          <div className="flex items-center gap-2">
            <img src="/bgt.png" alt="BGT Together" className="h-8 w-8" />
            <span className="text-xl font-bold text-white">BGT Together</span>
          </div>
          
          <div className="pr-2">
            {children}
          </div>
        </div>
      </div>
    </nav>
  );
} 