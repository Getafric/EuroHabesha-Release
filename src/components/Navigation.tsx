import { Home, Briefcase, ShoppingBag, Calendar, MapPin, MessageCircle, User, Settings, Shield, Sparkles, Heart } from "lucide-react";
import { SupportedLanguage, translations } from "../translations";
import { UserRole } from "../types";
import BrandLogo from "./BrandLogo";
import { JOB_CATEGORIES } from "./ListingsView";
import { motion } from "motion/react";

export type ActiveTab = "home" | "jobs" | "marketplace" | "showcase" | "feed" | "profile" | "admin" | "settings" | "chat";

interface NavigationProps {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
  userRole: UserRole;
  language: SupportedLanguage;
  notificationsCount?: number;
  selectedJobCategory?: string;
  onSelectJobCategory?: (category: string) => void;
}

export default function Navigation({ 
  activeTab, 
  setActiveTab, 
  userRole, 
  language, 
  notificationsCount = 0,
  selectedJobCategory,
  onSelectJobCategory
}: NavigationProps) {
  const t = translations[language];

  // Map tabs to exact mockup layout
  const mainNavItems = [
    { 
      id: "home", 
      label: language === "am" ? "መነሻ" : language === "ti" ? "መበገሲ" : "Home", 
      icon: Home 
    },
    { 
      id: "marketplace", 
      label: language === "am" ? "ገበያ" : language === "ti" ? "ዕዳጋ" : "Habesha Market", 
      icon: ShoppingBag 
    },
    { 
      id: "jobs", 
      label: language === "am" ? "ግንኙነቶች" : language === "ti" ? "ምትእስሳር" : "Connections", 
      icon: Briefcase 
    },
    { 
      id: "showcase", 
      label: language === "am" ? "ማሳያ" : language === "ti" ? "ኪነ-ጥበብ" : "Showcase", 
      icon: Sparkles 
    },
    { 
      id: "feed", 
      label: language === "am" ? "ማህበራዊ" : language === "ti" ? "ናይ ሓባር" : "Community Feed", 
      icon: MessageCircle, 
    },
    {
      id: "chat",
      label: language === "am" ? "መልዕክት" : language === "ti" ? "መልእኽቲ" : "DMs & Chat",
      icon: MessageCircle,
      badge: notificationsCount > 0 ? notificationsCount : undefined
    },
    { 
      id: "profile", 
      label: t.navProfile, 
      icon: User 
    },
  ];

  return (
    <>
      {/* DESKTOP SIDEBAR */}
      <aside className="hidden md:flex flex-col w-64 bg-[#0C3823] text-stone-100 min-h-screen border-r border-[#09291a] sticky top-0">
        {/* Branding */}
        <div className="p-5 border-b border-[#09291a]">
          <BrandLogo className="w-11 h-11" showText={true} variant="gold" />
        </div>

        {/* Nav list */}
        <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
          <span className="block px-3 text-[9px] font-black tracking-widest text-emerald-300/60 uppercase mb-2">Navigation</span>
          
          {mainNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id as ActiveTab)}
                className={`w-full flex items-center justify-between px-3 py-3 rounded-xl text-xs font-semibold tracking-wide uppercase transition-all duration-200 ${
                  isActive
                    ? "bg-[#D4AF37] text-[#0C3823] shadow-lg shadow-[#D4AF37]/15"
                    : "text-stone-300 hover:bg-[#09291a] hover:text-white"
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className="w-4 h-4" />
                  <span>{item.label}</span>
                </div>
                {item.badge !== undefined && (
                  <span className="bg-[#5C131E] text-[#D4AF37] font-mono font-bold px-1.5 py-0.5 rounded-full text-[9px]">
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}

          {/* JOB CATEGORIES COLLAPSIBLE FILTER SUBMENU */}
          {activeTab === "jobs" && onSelectJobCategory && (
            <div className="pt-4 mt-4 border-t border-[#09291a] space-y-2 animate-in fade-in slide-in-from-left duration-300">
              <span className="block px-3 text-[9px] font-black tracking-widest text-[#D4AF37] uppercase">
                {language === "am" ? "የስራ ዘርፎች" : language === "ti" ? "ዓይነታት ሞያ" : "Job Categories"}
              </span>
              <div className="space-y-1 max-h-[220px] overflow-y-auto px-1 scrollbar-thin scrollbar-thumb-emerald-800 pr-1">
                {JOB_CATEGORIES.map((cat, idx) => {
                  const isSelected = selectedJobCategory === cat;
                  
                  // Helper for category custom emojis in navigation
                  const getEmoji = (cName: string) => {
                    const nameLower = cName.toLowerCase();
                    if (nameLower.includes("électric") || nameLower.includes("electric")) return "⚡";
                    if (nameLower.includes("lavage") || nameLower.includes("wash")) return "🧽";
                    if (nameLower.includes("mécan") || nameLower.includes("mecan")) return "🔧";
                    if (nameLower.includes("peint") || nameLower.includes("paint")) return "🎨";
                    if (nameLower.includes("photo") || nameLower.includes("vidé") || nameLower.includes("video")) return "📸";
                    if (nameLower.includes("traduc") || nameLower.includes("transla")) return "🗣️";
                    if (nameLower.includes("dj")) return "🎧";
                    if (nameLower.includes("traiteur") || nameLower.includes("catering")) return "🍽️";
                    if (nameLower.includes("médec") || nameLower.includes("doctor")) return "🩺";
                    if (nameLower.includes("chauffeur") || nameLower.includes("driver")) return "🚗";
                    if (nameLower.includes("déménagement") || nameLower.includes("move")) return "📦";
                    if (nameLower.includes("coiff") || nameLower.includes("hair")) return "✂️";
                    if (nameLower.includes("ጠበቃ") || nameLower.includes("avocat") || nameLower.includes("lawyer")) return "⚖️";
                    if (nameLower.includes("chef")) return "🍳";
                    if (nameLower.includes("management")) return "💼";
                    if (nameLower.includes("caregiver")) return "❤️";
                    return "✨";
                  };

                  return (
                    <motion.button
                      key={cat}
                      initial={{ opacity: 0, x: -12 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ 
                        type: "spring",
                        stiffness: 260,
                        damping: 20,
                        delay: Math.min(idx * 0.03, 0.4) 
                      }}
                      whileHover={{ 
                        scale: 1.03, 
                        x: 4,
                        transition: { duration: 0.1 }
                      }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => onSelectJobCategory(cat)}
                      className={`w-full flex items-center justify-between px-3 py-1.5 rounded-lg text-[10px] font-bold tracking-wide uppercase transition-all duration-150 cursor-pointer ${
                        isSelected
                          ? "bg-[#D4AF37]/25 text-[#D4AF37] border-l-2 border-[#D4AF37] pl-2 shadow-sm"
                          : "text-stone-300 hover:bg-[#09291a] hover:text-white"
                      }`}
                    >
                      <div className="flex items-center gap-2 truncate">
                        <span className="text-xs shrink-0">{getEmoji(cat)}</span>
                        <span className="truncate">{cat}</span>
                      </div>
                      {isSelected && <span className="text-[9px] text-[#D4AF37]">●</span>}
                    </motion.button>
                  );
                })}
              </div>
            </div>
          )}

          {/* ADMIN LINK (ONLY SHOWN FOR ADMINS) */}
          {userRole === "admin" && (
            <div className="pt-4 mt-4 border-t border-[#09291a] space-y-1">
              <span className="block px-3 text-[9px] font-black tracking-widest text-emerald-300/60 uppercase mb-2">Administration</span>
              <button
                onClick={() => setActiveTab("admin")}
                className={`w-full flex items-center gap-3 px-3 py-3 rounded-xl text-xs font-semibold tracking-wide uppercase transition-all duration-200 ${
                  activeTab === "admin"
                    ? "bg-[#5C131E] text-white shadow-lg shadow-[#5C131E]/20"
                    : "text-stone-300 hover:bg-[#09291a] hover:text-white"
                }`}
              >
                <Shield className="w-4 h-4" />
                <span>{t.navAdmin}</span>
              </button>
            </div>
          )}
        </nav>

        {/* Footer info */}
        <div className="p-4 border-t border-[#09291a] text-center text-[10px] text-emerald-400/50 font-mono">
          © 2026 EuroHabesha
        </div>
      </aside>

      {/* MOBILE BOTTOM NAVIGATION */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-[#0C3823] border-t border-[#09291a] text-stone-100 z-40 flex flex-col pb-safe shadow-2xl">
        
        {/* MOBILE BOTTOM CATEGORY SELECTOR (ONLY SHOWN FOR JOBS TAB) */}
        {activeTab === "jobs" && onSelectJobCategory && (
          <div className="px-3 py-2 border-b border-[#09291a] bg-[#09291a]/30 flex flex-col gap-1.5 max-w-full">
            <div className="flex items-center justify-between px-1">
              <span className="text-[8px] font-black tracking-widest text-[#D4AF37] uppercase">
                {language === "am" ? "የስራ ዘርፎች" : language === "ti" ? "ዓይነታት ሞያ" : "Job Categories"}
              </span>
              {selectedJobCategory && (
                <button
                  onClick={() => onSelectJobCategory("")}
                  className="text-[8px] font-bold text-amber-400 hover:underline"
                >
                  {language === "am" ? "ሁሉንም አሳይ" : language === "ti" ? "ኩሉ አርኢ" : "Reset"}
                </button>
              )}
            </div>
            <div className="flex items-center gap-1.5 overflow-x-auto py-0.5 px-0.5 scrollbar-none scroll-smooth" style={{ WebkitOverflowScrolling: "touch" }}>
              {JOB_CATEGORIES.map((cat, idx) => {
                const isSelected = selectedJobCategory === cat;
                const getEmoji = (cName: string) => {
                  const nameLower = cName.toLowerCase();
                  if (nameLower.includes("électric") || nameLower.includes("electric")) return "⚡";
                  if (nameLower.includes("lavage") || nameLower.includes("wash")) return "🧽";
                  if (nameLower.includes("mécan") || nameLower.includes("mecan")) return "🔧";
                  if (nameLower.includes("peint") || nameLower.includes("paint")) return "🎨";
                  if (nameLower.includes("photo") || nameLower.includes("vidé") || nameLower.includes("video")) return "📸";
                  if (nameLower.includes("traduc") || nameLower.includes("transla")) return "🗣️";
                  if (nameLower.includes("dj")) return "🎧";
                  if (nameLower.includes("traiteur") || nameLower.includes("catering")) return "🍽️";
                  if (nameLower.includes("médec") || nameLower.includes("doctor")) return "🩺";
                  if (nameLower.includes("chauffeur") || nameLower.includes("driver")) return "🚗";
                  if (nameLower.includes("déménagement") || nameLower.includes("move")) return "📦";
                  if (nameLower.includes("coiff") || nameLower.includes("hair")) return "✂️";
                  if (nameLower.includes("ጠበቃ") || nameLower.includes("avocat") || nameLower.includes("lawyer")) return "⚖️";
                  if (nameLower.includes("chef")) return "🍳";
                  if (nameLower.includes("management")) return "💼";
                  if (nameLower.includes("caregiver")) return "❤️";
                  return "✨";
                };

                return (
                  <motion.button
                    key={cat}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{
                      type: "spring",
                      stiffness: 260,
                      damping: 20,
                      delay: Math.min(idx * 0.02, 0.3)
                    }}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => onSelectJobCategory(cat)}
                    className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[9px] font-bold tracking-wide uppercase transition-all duration-150 shrink-0 whitespace-nowrap border cursor-pointer ${
                      isSelected
                        ? "bg-[#D4AF37] text-[#0C3823] border-[#D4AF37] scale-105 shadow-inner"
                        : "bg-[#0C3823] text-stone-300 border-stone-800/40 hover:bg-[#09291a]"
                    }`}
                  >
                    <span className="text-xs shrink-0">{getEmoji(cat)}</span>
                    <span>{cat}</span>
                  </motion.button>
                );
              })}
            </div>
          </div>
        )}

        {/* BOTTOM NAV TABS */}
        <div className="flex justify-around py-2 px-1">
          {[
            mainNavItems.find(i => i.id === "home"),
            mainNavItems.find(i => i.id === "marketplace"),
            mainNavItems.find(i => i.id === "jobs"),
            mainNavItems.find(i => i.id === "chat"),
            mainNavItems.find(i => i.id === "profile")
          ].filter(Boolean).map((item: any) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id as ActiveTab)}
                className="flex flex-col items-center gap-1 flex-1 py-1 transition-all"
              >
                <div className={`p-2 rounded-xl transition-all relative ${
                  isActive ? "bg-[#D4AF37] text-[#0C3823] scale-110 shadow-md shadow-[#D4AF37]/10" : "text-stone-300"
                }`}>
                  <Icon className="w-4 h-4" />
                  {item.badge !== undefined && (
                    <span className="absolute -top-1 -right-1 bg-[#5C131E] text-[#D4AF37] font-mono font-bold px-1 rounded-full text-[7px]">
                      {item.badge}
                    </span>
                  )}
                </div>
                <span className="text-[9px] font-bold tracking-wider uppercase scale-90 truncate max-w-[64px]">
                  {item.id === "marketplace" ? "Market" : item.id === "jobs" ? "Connections" : item.id === "chat" ? "Chat" : item.label}
                </span>
              </button>
            );
          })}

          {/* Admin Tab for mobile if admin */}
          {userRole === 'admin' && (
            <button
              onClick={() => setActiveTab("admin")}
              className="flex flex-col items-center gap-1 flex-1 py-1"
            >
              <div className={`p-2 rounded-xl transition-all ${
                activeTab === "admin"
                  ? "bg-[#D4AF37] text-[#0C3823] scale-110 shadow-md shadow-[#D4AF37]/10"
                  : "text-stone-300"
              }`}>
                <Shield className="w-4 h-4" />
              </div>
              <span className="text-[9px] font-bold tracking-wider uppercase scale-90">
                Admin
              </span>
            </button>
          )}
        </div>
      </div>
    </>
  );
}
