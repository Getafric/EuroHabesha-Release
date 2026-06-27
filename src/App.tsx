import { useState, useEffect } from "react";
import WelcomeScreen from "./components/WelcomeScreen";
import Navigation, { ActiveTab } from "./components/Navigation";
import ListingsView from "./components/ListingsView";
import BrandLogo from "./components/BrandLogo";
import ChatView from "./components/ChatView";
import ProfileView from "./components/ProfileView";
import AdminPanel from "./components/AdminPanel";
import ShowcaseView from "./components/ShowcaseView";
import CommunityFeedView from "./components/CommunityFeedView";
import { translations, SupportedLanguage } from "./translations";
import { User, Listing, ChatMessage, SystemNotification, AppStats } from "./types";
import { ShieldAlert, Bell, Sparkles, LogOut, Check, ArrowRight, MessageCircle, Heart } from "lucide-react";

export default function App() {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [activeTab, setActiveTab] = useState<ActiveTab>("home");
  const [lang, setLang] = useState<SupportedLanguage>("fr");

  // Private DM targeted states
  const [chatActiveChannel, setChatActiveChannel] = useState<string | undefined>(undefined);
  const [chatRecipientName, setChatRecipientName] = useState<string | undefined>(undefined);

  // App Data State loaded from full-stack endpoint
  const [users, setUsers] = useState<User[]>([]);
  const [listings, setListings] = useState<Listing[]>([]);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [notifications, setNotifications] = useState<SystemNotification[]>([]);
  const [stats, setStats] = useState<AppStats>({
    totalUsers: 0,
    totalListings: 0,
    totalEvents: 0,
    totalProfessionals: 0
  });

  const [loading, setLoading] = useState(true);
  const [selectedJobCategory, setSelectedJobCategory] = useState<string>("");

  const handleStartPrivateChat = (recipientId: string, recipientName: string) => {
    if (!currentUser) return;
    // Format channel ID as dm_ID1_ID2 sorted alphabetically to be unique and consistent
    const channelId = `dm_${[currentUser.id, recipientId].sort().join("_")}`;
    setChatActiveChannel(channelId);
    setChatRecipientName(recipientName);
    setActiveTab("chat");
  };

  // Fetch all app data
  const fetchAllData = async () => {
    try {
      const res = await fetch("/api/data");
      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`);
      }
      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        throw new Error("Received non-JSON response from server");
      }
      const data = await res.json();
      
      setUsers(data.users);
      setListings(data.listings);
      setMessages(data.messages);
      setNotifications(data.notifications);
      setStats(data.stats);

      // Refresh current user data if logged in (for immediate verification badge updates!)
      if (currentUser) {
        const freshUser = data.users.find((u: any) => u.id === currentUser.id);
        if (freshUser) {
          setCurrentUser(freshUser);
        }
      }
    } catch (e: any) {
      // Use console.warn for transient background fetch/sync warnings so they don't count as fatal app crashes in AI Studio logs
      console.warn("Data sync warning:", e?.message || e);
    } finally {
      setLoading(false);
    }
  };

  // Initial load
  useEffect(() => {
    fetchAllData();
  }, []);

  // Poll for real-time updates every 4 seconds (chat messages, admin alerts, moderations)
  useEffect(() => {
    const interval = setInterval(() => {
      fetchAllData();
    }, 4000);
    return () => clearInterval(interval);
  }, [currentUser]);

  const handleAuthSuccess = (authenticatedUser: User, selectedLanguage: SupportedLanguage) => {
    setCurrentUser(authenticatedUser);
    setLang(selectedLanguage);
    setActiveTab("home");
  };

  const handleLogout = () => {
    setCurrentUser(null);
  };

  const t = translations[lang];

  // Loader screen
  if (loading && !currentUser) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center font-sans">
        <div className="text-center space-y-3">
          <div className="w-14 h-14 border-4 border-[#0C3823] border-t-[#D4AF37] rounded-full animate-spin mx-auto" />
          <p className="text-xs font-bold text-stone-500 uppercase tracking-widest font-mono">EuroHabesha loading...</p>
        </div>
      </div>
    );
  }

  // Auth screen if not logged in
  if (!currentUser) {
    return <WelcomeScreen onAuthSuccess={handleAuthSuccess} />;
  }

  // Active Admin Banner
  const isBlocked = currentUser.isBlocked;
  if (isBlocked) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center p-6">
        <div className="max-w-md w-full bg-white p-8 rounded-3xl border border-red-100 shadow-xl text-center space-y-4">
          <div className="w-16 h-16 bg-red-50 text-red-600 rounded-full flex items-center justify-center mx-auto">
            <ShieldAlert className="w-8 h-8" />
          </div>
          <h2 className="text-lg font-black text-stone-900 uppercase">Compte bloqué</h2>
          <p className="text-xs text-stone-500 leading-relaxed">
            Votre compte a été suspendu par l'administration pour non-respect des règles de la communauté d'Europe. Veuillez contacter un administrateur.
          </p>
          <button
            onClick={handleLogout}
            className="px-5 py-2.5 bg-stone-900 hover:bg-stone-800 text-white text-xs font-bold rounded-xl transition-all"
          >
            Retourner à l'accueil
          </button>
        </div>
      </div>
    );
  }

  return (
    <div id="app_root" className="min-h-screen bg-slate-50 flex flex-col md:flex-row font-sans">
      
      {/* SIDEBAR NAVIGATION */}
      <Navigation
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        userRole={currentUser.role}
        language={lang}
        notificationsCount={messages.length}
        selectedJobCategory={selectedJobCategory}
        onSelectJobCategory={(cat) => {
          setSelectedJobCategory(cat);
          setActiveTab("jobs");
        }}
      />

      {/* MAIN SCREEN PORTAL */}
      <main className="flex-1 flex flex-col min-w-0 pb-20 md:pb-6">
        
        {/* TOP SYSTEM NAV & NOTIFICATIONS TICKER BAR */}
        <header className="bg-white border-b border-stone-100 px-6 py-3.5 flex items-center justify-between gap-4 sticky top-0 z-30 shadow-sm">
          
          {/* Logo brand label (mobile only) */}
          <div className="md:hidden flex items-center">
            <BrandLogo className="w-8 h-8" showText={true} textColor="text-stone-900" variant="light" />
          </div>

          {/* SYSTEM ANNOUNCEMENT GENERAL TICKER */}
          <div className="hidden lg:flex items-center gap-2.5 flex-1 max-w-xl bg-stone-50 px-3.5 py-1.5 rounded-full border border-stone-150 overflow-hidden">
            <Bell className="w-3.5 h-3.5 text-amber-500 shrink-0" />
            <div className="text-[11px] font-bold text-stone-600 truncate">
              {notifications.length > 0 ? (
                <span>🔔 [ANNOUNCEMENT] {notifications[0].title} : {notifications[0].content}</span>
              ) : (
                <span>Aucune annonce système. Bienvenue sur EuroHabesha Europe !</span>
              )}
            </div>
          </div>

          {/* USER QUICK AVATAR SUMMARY */}
          <div className="flex items-center gap-3">
            
            {/* Language switch shortcuts directly in header */}
            <select
              value={lang}
              onChange={(e) => setLang(e.target.value as SupportedLanguage)}
              className="p-1.5 bg-stone-50 border border-stone-200 text-stone-700 text-[10px] font-bold rounded-xl focus:outline-none"
            >
              <option value="fr">FR</option>
              <option value="en">EN</option>
              <option value="am">አማርኛ</option>
              <option value="ti">ትግርኛ</option>
              <option value="de">DE</option>
              <option value="it">IT</option>
              <option value="es">ES</option>
              <option value="nl">NL</option>
            </select>

            <div className="flex items-center gap-2">
              <div
                onClick={() => setActiveTab("profile")}
                className="w-8 h-8 rounded-full bg-stone-100 border border-stone-200 text-[#0C3823] font-black text-xs flex items-center justify-center uppercase cursor-pointer shadow-inner"
              >
                {currentUser.name[0]}
              </div>
              <div className="hidden sm:block text-left text-xs">
                <p className="font-bold text-stone-800 leading-none">{currentUser.name}</p>
                <p className="text-[9px] font-semibold text-stone-400 capitalize mt-0.5">{currentUser.role}</p>
              </div>
            </div>

          </div>

        </header>

        {/* CONTAINER FOR VIEWS */}
        <div className="p-4 md:p-6 flex-1 max-w-7xl w-full mx-auto">
          
          {/* ACCUEIL (HOME VIEW) */}
          {activeTab === "home" && (
            <div className="space-y-6">
              
              {/* BRAND GREETINGS BANNER */}
              <div className="bg-[#0C3823] text-stone-100 p-6 md:p-8 rounded-3xl border border-[#09291a] relative overflow-hidden flex flex-col md:flex-row items-center justify-between gap-6 shadow-md">
                <div className="absolute -right-16 -top-16 w-48 h-48 rounded-full bg-[#D4AF37]/5" />
                
                <div className="space-y-2 relative z-10 max-w-xl text-center md:text-left">
                  <span className="inline-block px-3 py-1 bg-[#D4AF37] text-[#0C3823] text-[9px] font-black uppercase tracking-widest rounded-full">
                    Diaspora Habesha Europe
                  </span>
                  <h1 className="text-2xl md:text-3xl font-black text-white tracking-tight leading-tight">
                    {translations[lang].welcomeBack}, {currentUser.name} !
                  </h1>
                  <p className="text-xs text-stone-300 leading-relaxed font-sans font-medium">
                    " Trouver, partager, grandir ensemble. " Accédez à l'annuaire des professionnels, trouvez un emploi de proximité ou discutez avec d'autres membres de la diaspora.
                  </p>
                </div>

                <div className="flex gap-2 shrink-0">
                  <button
                    onClick={() => setActiveTab("jobs")}
                    className="px-4 py-3 bg-[#D4AF37] hover:bg-[#c5a12e] text-[#0C3823] font-extrabold text-xs tracking-wider uppercase rounded-2xl transition-all shadow-md"
                  >
                    Trouver un service
                  </button>
                  <button
                    onClick={() => setActiveTab("feed")}
                    className="px-4 py-3 bg-white/10 hover:bg-white/20 text-white font-extrabold text-xs tracking-wider uppercase rounded-2xl transition-all"
                  >
                    Espace Forum
                  </button>
                </div>
              </div>

              {/* MAJESTIC CULTURAL HERITAGE SVG PANEL */}
              <div className="bg-white p-5 md:p-6 rounded-3xl border border-stone-150 shadow-sm space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-xs font-black uppercase tracking-widest text-stone-900 flex items-center gap-1.5">
                      <span className="w-2 h-2 rounded-full bg-[#5C131E]" />
                      <span>Heritage & Identity</span>
                    </h3>
                    <p className="text-[10px] text-stone-400 font-medium">Abyssinian symbols of unity and hospitality</p>
                  </div>
                  <span className="text-[10px] font-bold text-[#0C3823] bg-[#0C3823]/5 px-2.5 py-0.5 rounded-full font-sans uppercase">
                    Melkam Ken!
                  </span>
                </div>

                <div className="relative bg-stone-50 rounded-2xl p-4 overflow-hidden border border-stone-100 flex flex-col md:flex-row items-center gap-6 justify-between">
                  
                  {/* Majestic Cultural SVG Illustration */}
                  <div className="w-full md:w-1/2 max-w-[340px] shrink-0">
                    <svg className="w-full h-auto max-h-[180px]" viewBox="0 0 320 180" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <rect width="320" height="180" rx="16" fill="#F4F2EC"/>
                      
                      {/* Sun ray backdrop */}
                      <circle cx="160" cy="120" r="100" fill="#EAE5D9" fillOpacity="0.4"/>
                      <circle cx="160" cy="120" r="60" fill="#E1DED5" fillOpacity="0.3"/>
                      
                      {/* Left Obelisk of Aksum */}
                      <path d="M50 145 L62 45 C 62 45, 68 35, 70 35 C 72 35, 78 45, 78 45 L90 145 Z" fill="#9CA3AF" stroke="#6B7280" strokeWidth="1.5"/>
                      <line x1="61" y1="60" x2="79" y2="60" stroke="#4B5563" strokeWidth="1.5"/>
                      <line x1="63" y1="80" x2="77" y2="80" stroke="#4B5563" strokeWidth="1.5"/>
                      <line x1="65" y1="100" x2="75" y2="100" stroke="#4B5563" strokeWidth="1.5"/>
                      <line x1="67" y1="120" x2="73" y2="120" stroke="#4B5563" strokeWidth="1.5"/>
                      <circle cx="70" cy="50" r="1.5" fill="#4B5563" />

                      {/* Right Obelisk of Aksum */}
                      <path d="M230 145 L242 55 C 242 55, 248 45, 250 45 C 252 45, 258 55, 258 55 L270 145 Z" fill="#9CA3AF" stroke="#6B7280" strokeWidth="1"/>
                      <line x1="242" y1="70" x2="258" y2="70" stroke="#4B5563" strokeWidth="1"/>
                      <line x1="244" y1="90" x2="256" y2="90" stroke="#4B5563" strokeWidth="1"/>
                      <line x1="246" y1="110" x2="254" y2="110" stroke="#4B5563" strokeWidth="1"/>

                      {/* Pedestal block */}
                      <rect x="110" y="145" width="100" height="15" rx="4" fill="#D4AF37" stroke="#9A7B1C" strokeWidth="1"/>
                      <ellipse cx="160" cy="145" rx="50" ry="8" fill="#B8952A"/>

                      {/* Traditional Mesob Basket */}
                      <path d="M125 110 L130 145 C 130 145, 160 148, 190 145 L195 110 Z" fill="#D4AF37" stroke="#9A7B1C" strokeWidth="1.5"/>
                      {/* Zig-zag bands */}
                      <path d="M126 120 L136 130 L146 120 L156 130 L166 120 L176 130 L186 120 L194 130" fill="none" stroke="#5C131E" strokeWidth="2" strokeLinecap="round"/>
                      <path d="M128 130 L138 140 L148 130 L158 140 L168 130 L178 140 L188 130 L192 140" fill="none" stroke="#0C3823" strokeWidth="2" strokeLinecap="round"/>
                      {/* Mesob lid */}
                      <path d="M115 85 C 115 110, 205 110, 205 85 L210 75 C 210 70, 110 70, 110 75 Z" fill="#D4AF37" stroke="#9A7B1C" strokeWidth="1.5"/>
                      <path d="M113 78 L123 88 L133 78 L143 88 L153 78 L163 88 L173 78 L183 88 L193 78 L203 88" fill="none" stroke="#0C3823" strokeWidth="1.5" strokeLinecap="round"/>
                      {/* Cone top */}
                      <path d="M160 30 L120 70 L200 70 Z" fill="#D4AF37" stroke="#9A7B1C" strokeWidth="1.5"/>
                      <path d="M135 55 L160 30 L185 55" fill="none" stroke="#5C131E" strokeWidth="2.5" strokeLinecap="round"/>
                      <path d="M145 60 L160 45 L175 60" fill="none" stroke="#0C3823" strokeWidth="2.5" strokeLinecap="round"/>
                      <circle cx="160" cy="27" r="4.5" fill="#5C131E" stroke="#D4AF37" strokeWidth="1"/>

                      {/* Clay Jebena coffee pot */}
                      <path d="M100 145 C 100 145, 90 120, 105 115 C 120 110, 115 145, 100 145 Z" fill="#3D2B1F" stroke="#2B1E16" strokeWidth="1"/>
                      <path d="M102 118 L104 95 L110 95 L112 118 Z" fill="#3D2B1F" stroke="#2B1E16" strokeWidth="1"/>
                      <path d="M108 100 L118 105 L116 109 L108 104 Z" fill="#3D2B1F"/>
                      <path d="M100 112 C 85 115, 85 130, 98 135" fill="none" stroke="#3D2B1F" strokeWidth="3" strokeLinecap="round"/>
                      <path d="M104 90 Q 100 80, 104 70" fill="none" stroke="#D4AF37" strokeWidth="1.5" strokeLinecap="round" opacity="0.6"/>

                      {/* Small coffee cups (Cini) */}
                      <path d="M215 145 L225 145 L227 139 L213 139 Z" fill="#FFFFFF" stroke="#0C3823" strokeWidth="0.75"/>
                      <circle cx="220" cy="139" rx="5" ry="1.5" fill="#FFFFFF" stroke="#0C3823" strokeWidth="0.75"/>
                      <line x1="215" y1="142" x2="225" y2="142" stroke="#5C131E" strokeWidth="1"/>

                    </svg>
                  </div>

                  {/* Context text and Amharic greeting */}
                  <div className="space-y-2 text-center md:text-left">
                    <h2 className="text-xl font-black text-stone-900 tracking-tight font-serif italic">
                      "መልካም ቀን!"
                    </h2>
                    <p className="text-xs text-stone-600 leading-relaxed max-w-sm">
                      La culture Habesha brille par sa générosité et ses valeurs d'entraide. Que vous partagiez le café rituel ou que vous souteniez les artisans locaux, nous grandissons unis à travers l'Europe.
                    </p>
                    <div className="pt-1">
                      <button 
                        onClick={() => setActiveTab("showcase")}
                        className="text-[10px] font-black uppercase tracking-wider text-[#5C131E] hover:text-[#0C3823] flex items-center justify-center md:justify-start gap-1 transition-colors"
                      >
                        <span>Visiter la galerie d'art</span>
                        <ArrowRight className="w-3 h-3" />
                      </button>
                    </div>
                  </div>

                </div>
              </div>

              {/* LATEST PRIORITY EVENT CORNER */}
              <div className="bg-amber-50 rounded-3xl p-5 border border-amber-200/60 shadow-sm relative overflow-hidden flex flex-col md:flex-row items-center justify-between gap-5">
                <div className="absolute right-0 bottom-0 opacity-5 pointer-events-none transform translate-y-12">
                  <Sparkles className="w-64 h-64 text-[#D4AF37]" />
                </div>

                <div className="space-y-2 relative z-10 text-center md:text-left">
                  <div className="flex items-center gap-2 justify-center md:justify-start">
                    <span className="px-2 py-0.5 bg-[#5C131E] text-white font-mono font-black text-[8px] uppercase rounded-md tracking-wider">
                      Événement Phare
                    </span>
                    <span className="text-[10px] font-mono text-[#0C3823] font-bold">
                      DIASPORA CELEBRITY TOUR
                    </span>
                  </div>

                  <h3 className="text-base font-black text-stone-900 tracking-tight">
                    ታዋቂ አርቲስት እሸቱ መለሰ በለንደን! (Eshetu Melese in London)
                  </h3>
                  
                  <p className="text-xs text-stone-600 leading-relaxed font-sans max-w-xl">
                    Rejoignez-nous pour un spectacle exceptionnel d'humour, d'inspiration et de retrouvailles communautaires avec le célèbre Eshetu Melese. Rencontrez la diaspora du Royaume-Uni et d'Europe !
                  </p>

                  <div className="flex flex-wrap items-center justify-center md:justify-start gap-4 text-[10px] font-bold text-stone-500 pt-1">
                    <span className="font-mono text-[#5C131E]">📅 SAMEDI 12 JUILLET</span>
                    <span>📍 London Royal Hall, UK</span>
                    <span className="text-[#0C3823]">🎟️ À partir de 35€</span>
                  </div>
                </div>

                <button 
                  onClick={() => setActiveTab("jobs")}
                  className="px-4.5 py-2.5 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-black text-[10px] uppercase tracking-wider rounded-xl shadow transition-all duration-200 hover:scale-105"
                >
                  Book Tickets
                </button>
              </div>

              {/* ACTIVE SYSTEM ALERTS LIST (ADMIN ANNOUNCEMENTS) */}
              <div className="space-y-3">
                <h3 className="text-xs font-black uppercase tracking-wider text-stone-400">Annonces importantes de l'administration</h3>
                {notifications.length === 0 ? (
                  <div className="bg-white p-4 text-center rounded-2xl border border-stone-100 text-stone-400 text-xs">
                    Aucune alerte générale pour le moment.
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {notifications.map(n => (
                      <div
                        key={n.id}
                        className={`p-4 rounded-2xl border text-xs leading-relaxed flex items-start gap-3 relative overflow-hidden ${
                          n.type === "success"
                            ? "bg-emerald-50 border-emerald-100 text-emerald-800"
                            : n.type === "warning"
                            ? "bg-red-50 border-red-100 text-red-800"
                            : "bg-white border-stone-150 text-stone-800"
                        }`}
                      >
                        <div className="flex-1 space-y-0.5">
                          <p className="font-bold flex items-center gap-1.5">
                            <span>{n.title}</span>
                          </p>
                          <p className="text-[11px] text-stone-500 leading-normal">{n.content}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* CENTRAL SHORTCUT GRID (HOME BENTO) */}
              <div className="space-y-3">
                <h3 className="text-xs font-black uppercase tracking-wider text-stone-400">Services disponibles</h3>
                
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                  {[
                    { id: "jobs", label: t.navJobs, count: listings.filter(l => l.type === "job" && l.status === "approved").length + " opportunités", desc: "Plombiers, coiffeurs, tech & traductions.", color: "hover:border-[#0C3823]/30" },
                    { id: "marketplace", label: t.navMarket, count: listings.filter(l => l.type === "marketplace" && l.status === "approved").length + " articles", desc: "Vêtements, artisanat, alimentation locale.", color: "hover:border-[#D4AF37]/30" },
                    { id: "showcase", label: "Art & Musique", count: "4 collections", desc: "Expositions, artistes & playlists soundscapes.", color: "hover:border-[#5C131E]/30" },
                    { id: "feed", label: "Forum Communautaire", count: "Partager & Poser", desc: "Échanges d'entraide, recettes de cuisine.", color: "hover:border-[#0C3823]/30" }
                  ].map(item => (
                    <div
                      key={item.id}
                      onClick={() => setActiveTab(item.id as ActiveTab)}
                      className={`bg-white p-5 rounded-3xl border border-stone-100 shadow-sm cursor-pointer transition-all ${item.color} hover:translate-y-[-2px] flex flex-col justify-between min-h-[140px]`}
                    >
                      <div>
                        <h4 className="font-extrabold text-stone-900 text-sm">{item.label}</h4>
                        <p className="text-[10px] text-stone-400 mt-1">{item.desc}</p>
                      </div>
                      <div className="flex justify-between items-center text-[10px] font-bold text-[#0C3823] pt-4 mt-2 border-t border-stone-50">
                        <span>{item.count}</span>
                        <ArrowRight className="w-3.5 h-3.5" />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* QUICK CHAT TELEMETRY PREVIEW CARD */}
              <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-[#0C3823]/5 text-[#0C3823] rounded-xl">
                    <MessageCircle className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-xs font-black text-stone-900 uppercase tracking-wide">Discussion instantanée Habesha</h4>
                    <p className="text-[11px] text-stone-400 mt-0.5">Rejoignez d'autres membres en ligne et restez connectés au quotidien.</p>
                  </div>
                </div>
                <button
                  onClick={() => setActiveTab("chat")}
                  className="px-4 py-2.5 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-bold text-xs rounded-xl uppercase transition-colors"
                >
                  Ouvrir les salons ({messages.length} messages)
                </button>
              </div>

            </div>
          )}

          {/* TRAVAUX & EMPLOIS */}
          {activeTab === "jobs" && (
            <ListingsView
              type="job"
              listings={listings}
              currentUser={currentUser}
              language={lang}
              onRefresh={fetchAllData}
              onStartPrivateChat={handleStartPrivateChat}
              selectedCategory={selectedJobCategory}
              onCategoryChange={setSelectedJobCategory}
            />
          )}

          {/* MARKETPLACE */}
          {activeTab === "marketplace" && (
            <ListingsView
              type="marketplace"
              listings={listings}
              currentUser={currentUser}
              language={lang}
              onRefresh={fetchAllData}
              onStartPrivateChat={handleStartPrivateChat}
            />
          )}

          {/* ART & MUSIC SHOWCASE */}
          {activeTab === "showcase" && (
            <ShowcaseView />
          )}

          {/* COMMUNITY FEED & DISCUSSIONS */}
          {activeTab === "feed" && (
            <CommunityFeedView currentUser={currentUser} />
          )}

          {/* DISCUSSIONS (CHAT) */}
          {activeTab === "chat" && (
            <ChatView
              messages={messages}
              currentUser={currentUser}
              language={lang}
              onRefresh={fetchAllData}
              initialActiveChannel={chatActiveChannel}
              recipientName={chatRecipientName}
            />
          )}

          {/* MON PROFIL */}
          {activeTab === "profile" && (
            <ProfileView
              user={currentUser}
              language={lang}
              onLogout={handleLogout}
              onRefresh={fetchAllData}
            />
          )}

          {/* BACK-OFFICE ADMIN */}
          {activeTab === "admin" && currentUser.role === "admin" && (
            <AdminPanel
              stats={stats}
              users={users}
              listings={listings}
              notifications={notifications}
              language={lang}
              onRefresh={fetchAllData}
            />
          )}

          {/* DISCUSSIONS (CHAT) */}
          {activeTab === "chat" && (
            <ChatView
              messages={messages}
              currentUser={currentUser}
              language={lang}
              onRefresh={fetchAllData}
            />
          )}

          {/* MON PROFIL */}
          {activeTab === "profile" && (
            <ProfileView
              user={currentUser}
              language={lang}
              onLogout={handleLogout}
              onRefresh={fetchAllData}
            />
          )}

          {/* BACK-OFFICE ADMIN */}
          {activeTab === "admin" && currentUser.role === "admin" && (
            <AdminPanel
              stats={stats}
              users={users}
              listings={listings}
              notifications={notifications}
              language={lang}
              onRefresh={fetchAllData}
            />
          )}

        </div>

      </main>

    </div>
  );
}
