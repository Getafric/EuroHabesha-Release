import React, { useState } from "react";
import { Sparkles, MessageCircle, Heart, Share2, Send, Search, Users, Award, HelpCircle, BookOpen } from "lucide-react";
import { User } from "../types";

interface Post {
  id: string;
  authorName: string;
  authorAvatar: string;
  authorRole: string;
  isVerified: boolean;
  time: string;
  category: string;
  content: string;
  likes: number;
  commentsCount: number;
  liked?: boolean;
}

interface FeedMessage {
  id: string;
  senderName: string;
  senderInit: string;
  content: string;
  time: string;
}

export default function CommunityFeedView({ currentUser }: { currentUser: User }) {
  const [posts, setPosts] = useState<Post[]>([
    {
      id: "p1",
      authorName: "Yonas Melaku",
      authorAvatar: "YM",
      authorRole: "Professional Weaver",
      isVerified: true,
      time: "0h",
      category: "Culture",
      content: "Selam family! Blessed new month to all. We are excited to launch the new traditional clothing collection in Paris this Saturday. Let's preserve contemporary and traditional Habesha clothing together!",
      likes: 24,
      commentsCount: 48,
      liked: false
    },
    {
      id: "p2",
      authorName: "Emebet B.",
      authorAvatar: "EB",
      authorRole: "Culinary Chef",
      isVerified: true,
      time: "2h",
      category: "Recipes & Food",
      content: "Many of you asked about the secret recipe for the perfect spongy sourdough Injera with 100% pure teff. Tip of the day: Let the batter ferment for exactly 4 days, then skim off the top water before baking on an active Mitad clay pan!",
      likes: 56,
      commentsCount: 12,
      liked: true
    },
    {
      id: "p3",
      authorName: "Selam Tekle",
      authorAvatar: "ST",
      authorRole: "Community Student",
      isVerified: false,
      time: "1d",
      category: "Associations",
      content: "Hello! Does anyone know of active Habesha cultural associations in Munich? We are looking to organize weekend Amharic classes for children born in Germany. Let's collaborate!",
      likes: 18,
      commentsCount: 9,
      liked: false
    }
  ]);

  const [chatMessages, setChatMessages] = useState<FeedMessage[]>([
    {
      id: "m1",
      senderName: "Fasil A.",
      senderInit: "FA",
      content: "መልካም ቀን! Melkam Ken to everyone in Europe!",
      time: "10:12"
    },
    {
      id: "m2",
      senderName: "Emebet B.",
      senderInit: "EB",
      content: "Bonjour ! J'espère que vous appréciez l'application.",
      time: "10:14"
    },
    {
      id: "m3",
      senderName: "Yonas Melaku",
      senderInit: "YM",
      content: "The live community feed is amazing for fast interactions.",
      time: "10:15"
    }
  ]);

  const [newChatText, setNewChatText] = useState("");
  const [newPostText, setNewPostText] = useState("");
  const [newPostCat, setNewPostCat] = useState("General");
  const [searchQuery, setSearchQuery] = useState("");
  const [toast, setToast] = useState<string | null>(null);

  const triggerToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => {
      setToast(null);
    }, 2500);
  };

  const handleLike = (id: string) => {
    setPosts(posts.map(p => {
      if (p.id === id) {
        return {
          ...p,
          likes: p.liked ? p.likes - 1 : p.likes + 1,
          liked: !p.liked
        };
      }
      return p;
    }));
    const post = posts.find(p => p.id === id);
    if (post && !post.liked) {
      triggerToast("Merci pour votre soutien ! ❤️");
    }
  };

  const handleAddPost = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPostText.trim()) return;

    const newPost: Post = {
      id: `p-${Date.now()}`,
      authorName: currentUser.name,
      authorAvatar: currentUser.name.split(" ").map(n => n[0]).join(""),
      authorRole: currentUser.role === "admin" ? "Platform Admin" : currentUser.role === "professional" ? "Verified Specialist" : "Community Member",
      isVerified: currentUser.verificationStatus === "verified",
      time: "Just now",
      category: newPostCat,
      content: newPostText,
      likes: 0,
      commentsCount: 0,
      liked: false
    };

    setPosts([newPost, ...posts]);
    setNewPostText("");
    triggerToast("Discussion publiée avec succès ! 📣");
  };

  const handleSendChatMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newChatText.trim()) return;

    const newMsg: FeedMessage = {
      id: `m-${Date.now()}`,
      senderName: currentUser.name,
      senderInit: currentUser.name.split(" ").map(n => n[0]).join(""),
      content: newChatText,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setChatMessages([...chatMessages, newMsg]);
    setNewChatText("");
  };

  const filteredPosts = posts.filter(p => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return p.content.toLowerCase().includes(q) || p.category.toLowerCase().includes(q) || p.authorName.toLowerCase().includes(q);
  });

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      
      {/* LEFT & CENTER PANEL: POST FEED (2/3 width) */}
      <div className="lg:col-span-2 space-y-6">
        
        {/* HERO HEADER */}
        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="p-3.5 bg-[#0C3823]/5 text-[#0C3823] rounded-2xl">
              <Users className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-xl font-black text-stone-900 tracking-tight uppercase flex items-center gap-1.5">
                <span>Community Feed</span>
                <span className="text-[10px] font-mono font-bold tracking-widest text-[#D4AF37] bg-[#5C131E] px-2 py-0.5 rounded-full">MAHIBER</span>
              </h1>
              <p className="text-xs text-stone-400">
                Partagez des récits, des conseils et posez des questions à la communauté d'Europe.
              </p>
            </div>
          </div>
        </div>

        {/* SEARCH BAR */}
        <div className="relative">
          <Search className="absolute left-4 top-3.5 w-4 h-4 text-stone-400" />
          <input
            type="text"
            placeholder="Search discussions, recipes, or diaspora guidelines..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-11 pr-4 py-3 bg-white rounded-2xl border border-stone-150 text-xs focus:outline-none focus:border-[#0C3823] font-medium shadow-sm"
          />
        </div>

        {/* PERSISTENT HIGHLIGHTED BANNER BUTTONS */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <button 
            onClick={() => triggerToast("Redirection vers l'annuaire des associations 🇪🇺")}
            className="p-5 rounded-2xl bg-[#0C3823] text-stone-100 text-left relative overflow-hidden group hover:scale-[1.02] transition-all border border-[#09291a] shadow-md flex items-center gap-4"
          >
            <div className="p-3 bg-white/10 text-[#D4AF37] rounded-xl">
              <BookOpen className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-xs font-black text-[#D4AF37] uppercase tracking-wider">Diaspora Associations</h4>
              <p className="text-[10px] text-stone-300 mt-0.5">Accompagnement, églises & consulats.</p>
            </div>
          </button>

          <button 
            onClick={() => triggerToast("Ouverture de l'espace mentorat jeune 🎓")}
            className="p-5 rounded-2xl bg-[#5C131E] text-stone-100 text-left relative overflow-hidden group hover:scale-[1.02] transition-all border border-red-950 shadow-md flex items-center gap-4"
          >
            <div className="p-3 bg-white/10 text-[#D4AF37] rounded-xl">
              <Award className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-xs font-black text-[#D4AF37] uppercase tracking-wider">Youth Mentorship</h4>
              <p className="text-[10px] text-stone-300 mt-0.5">Conseils d'intégration & bourses d'études.</p>
            </div>
          </button>
        </div>

        {/* POST CREATION FORM */}
        <form onSubmit={handleAddPost} className="bg-white p-4 rounded-3xl border border-stone-150 shadow-sm space-y-3">
          <textarea
            placeholder="De quoi aimeriez-vous discuter aujourd'hui ?"
            value={newPostText}
            onChange={(e) => setNewPostText(e.target.value)}
            rows={3}
            className="w-full p-3 bg-stone-50 rounded-2xl border border-stone-150 text-xs focus:outline-none focus:border-[#0C3823] font-medium"
          />
          <div className="flex items-center justify-between gap-2 flex-wrap">
            <div className="flex items-center gap-2">
              <span className="text-[10px] text-stone-400 font-bold uppercase">Catégorie :</span>
              <select
                value={newPostCat}
                onChange={(e) => setNewPostCat(e.target.value)}
                className="bg-stone-50 border border-stone-200 text-[10px] font-bold text-stone-700 px-2 py-1 rounded-lg"
              >
                <option value="General">General Discussion</option>
                <option value="Recipes & Food">Recipes & Food</option>
                <option value="Associations">Associations</option>
                <option value="Culture & Art">Culture & Art</option>
              </select>
            </div>
            
            <button
              type="submit"
              className="px-4 py-2 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-black text-[10px] uppercase tracking-wider rounded-xl transition-all"
            >
              Post Topic
            </button>
          </div>
        </form>

        {/* MAIN POST FEED */}
        <div className="space-y-4">
          {filteredPosts.map(post => (
            <div key={post.id} className="bg-white p-5 rounded-3xl border border-stone-150 shadow-sm space-y-3">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-[#0C3823]/5 border border-[#0C3823]/25 flex items-center justify-center text-[#0C3823] font-black text-xs">
                    {post.authorAvatar}
                  </div>
                  <div>
                    <h3 className="text-xs font-black text-stone-900 flex items-center gap-1">
                      <span>{post.authorName}</span>
                      {post.isVerified && <span className="text-emerald-500 text-[10px]">✅</span>}
                    </h3>
                    <p className="text-[9px] text-stone-400">{post.authorRole} • {post.time}</p>
                  </div>
                </div>

                <span className="px-2.5 py-0.5 bg-[#5C131E]/5 text-[#5C131E] font-mono font-black uppercase text-[8px] rounded-md tracking-wider">
                  {post.category}
                </span>
              </div>

              <p className="text-xs text-stone-700 leading-relaxed font-sans">
                {post.content}
              </p>

              <div className="pt-3 border-t border-stone-50 flex items-center gap-6 text-[10px] font-bold text-stone-500">
                <button 
                  onClick={() => handleLike(post.id)}
                  className={`flex items-center gap-1 transition-colors hover:text-red-500 ${post.liked ? "text-red-500" : ""}`}
                >
                  <Heart className={`w-4 h-4 ${post.liked ? "fill-red-500" : ""}`} />
                  <span>{post.likes} likes</span>
                </button>

                <button 
                  onClick={() => triggerToast("Chargement des réponses... 💬")}
                  className="flex items-center gap-1 transition-colors hover:text-[#0C3823]"
                >
                  <MessageCircle className="w-4 h-4" />
                  <span>{post.commentsCount} comments</span>
                </button>

                <button 
                  onClick={() => triggerToast("Lien copié dans le presse-papiers 🔗")}
                  className="flex items-center gap-1 transition-colors hover:text-stone-700 ml-auto"
                >
                  <Share2 className="w-4 h-4" />
                  <span className="hidden sm:inline">Share</span>
                </button>
              </div>
            </div>
          ))}
        </div>

      </div>

      {/* RIGHT PANEL: LIVE CHAT ROOM (1/3 width) */}
      <div className="bg-white rounded-3xl border border-stone-150 p-4 shadow-sm flex flex-col h-[520px] justify-between lg:sticky lg:top-6">
        
        {/* Chat Header */}
        <div className="border-b border-stone-150 pb-3">
          <div className="flex items-center gap-2">
            <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-ping" />
            <span className="text-xs font-black text-stone-900 uppercase tracking-widest">Habesha Live Chat</span>
          </div>
          <p className="text-[10px] text-stone-400 mt-0.5 font-medium">Discutez en temps réel avec la diaspora.</p>
        </div>

        {/* Chat message list area */}
        <div className="flex-1 overflow-y-auto py-3 space-y-3 scrollbar-none">
          {chatMessages.map(msg => (
            <div key={msg.id} className="flex gap-2.5 items-start">
              <div className="w-7 h-7 rounded-full bg-[#0C3823] text-[#D4AF37] text-[10px] font-black flex items-center justify-center shrink-0 shadow-inner">
                {msg.senderInit}
              </div>
              <div className="bg-stone-50 rounded-2xl p-2.5 border border-stone-100 max-w-[85%]">
                <div className="flex items-baseline justify-between gap-2">
                  <span className="text-[9px] font-black text-stone-700">{msg.senderName}</span>
                  <span className="text-[8px] font-mono text-stone-400">{msg.time}</span>
                </div>
                <p className="text-[11px] text-stone-600 mt-0.5 font-sans leading-normal">{msg.content}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Message Input form */}
        <form onSubmit={handleSendChatMessage} className="border-t border-stone-150 pt-3 flex gap-2">
          <input
            type="text"
            placeholder="Type your message..."
            value={newChatText}
            onChange={(e) => setNewChatText(e.target.value)}
            className="flex-1 bg-stone-50 border border-stone-150 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-[#0C3823] font-medium"
          />
          <button
            type="submit"
            className="p-2.5 bg-[#0C3823] text-[#D4AF37] hover:bg-[#09291a] rounded-xl transition-all shadow shrink-0"
          >
            <Send className="w-3.5 h-3.5" />
          </button>
        </form>

      </div>

      {/* FLOATING TOAST SYSTEM */}
      {toast && (
        <div className="fixed bottom-20 md:bottom-6 right-6 z-50 bg-[#0C3823] text-[#D4AF37] border-2 border-[#D4AF37] px-5 py-3 rounded-2xl shadow-2xl flex items-center gap-3 animate-bounce font-sans text-xs font-bold">
          <Sparkles className="w-4 h-4 text-[#D4AF37]" />
          <span>{toast}</span>
        </div>
      )}

    </div>
  );
}
