import React, { useState } from "react";
import { Sparkles, Play, Pause, Music, Volume2, User, Heart, Share2, Award } from "lucide-react";

interface Track {
  id: string;
  title: string;
  artist: string;
  duration: string;
  genre: string;
  plays: string;
}

export default function ShowcaseView() {
  const [activeTrack, setActiveTrack] = useState<Track | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(35);
  const [volume, setVolume] = useState(80);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [toast, setToast] = useState<string | null>(null);

  const triggerToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => {
      setToast(null);
    }, 2500);
  };

  const tracks: Track[] = [
    {
      id: "t1",
      title: "Guragigna Vibes",
      artist: "Diaspora Mix (Yared N. & Traditional)",
      duration: "3:45",
      genre: "Folk-Pop",
      plays: "1.2K"
    },
    {
      id: "t2",
      title: "Ethio-Jazz Classic",
      artist: "Abyssinia Quartet",
      duration: "5:20",
      genre: "Jazz",
      plays: "4.8K"
    },
    {
      id: "t3",
      title: "Tigrigna Dance Rhythm",
      artist: "Selamawit & Hermon",
      duration: "4:12",
      genre: "Traditional",
      plays: "920"
    },
    {
      id: "t4",
      title: "Spiritual Tselot Hymn",
      artist: "Orthodox Choir London",
      duration: "6:05",
      genre: "Chant",
      plays: "2.3K"
    }
  ];

  const artists = [
    {
      name: "Fasil A.",
      role: "Fine Art Painter",
      avatarBg: "bg-amber-600 text-white",
      avatarInit: "FA",
      work: "Artwork Paint",
      description: "Splendors of Abyssinia and historical Lalibela churches painted on pure organic cotton canvases. Capturing centuries of imperial wisdom with gold highlights."
    },
    {
      name: "Emebet B.",
      role: "Traditional Artisan",
      avatarBg: "bg-[#0C3823] text-[#D4AF37]",
      avatarInit: "EB",
      work: "Buna Set Craft",
      description: "Traditional Rekebot set custom built with the finest olive wood and high-gloss ceramic tiles. Keeping the hospitality flame alive across Europe."
    },
    {
      name: "Yonas Melaku",
      role: "Gabi Weaver",
      avatarBg: "bg-[#5C131E] text-stone-100",
      avatarInit: "YM",
      work: "Organic Gabi weave",
      description: "Spun from raw Ethiopian highland cotton. Hand-crafted using traditional patterns that protect from the European winter with genuine Abyssinian warmth."
    }
  ];

  return (
    <div className="space-y-6">
      {/* HEADER BANNER */}
      <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-3.5 bg-[#5C131E]/5 text-[#5C131E] rounded-2xl">
            <Music className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-black text-stone-900 tracking-tight uppercase flex items-center gap-1.5">
              <span>Arts & Music Showcase</span>
              <span className="text-[10px] font-mono font-bold tracking-widest text-[#D4AF37] bg-[#0C3823] px-2 py-0.5 rounded-full">KINE-TIBEB</span>
            </h1>
            <p className="text-xs text-stone-400">
              Célébration du patrimoine et de la créativité de la diaspora Habesha. Écoutez, regardez et connectez-vous.
            </p>
          </div>
        </div>
      </div>

      {/* QUICK ARTIST RAIL */}
      <div className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm space-y-3">
        <span className="block text-[9px] font-black tracking-widest text-[#5C131E] uppercase">Arts and Creative Minds</span>
        
        <div className="flex gap-6 overflow-x-auto pb-2 scrollbar-none">
          {artists.map((artist, idx) => (
            <div key={idx} className="flex flex-col items-center gap-1.5 min-w-[70px] text-center">
              <div className={`w-14 h-14 rounded-full ${artist.avatarBg} flex items-center justify-center font-black text-sm shadow-md relative group cursor-pointer hover:scale-105 transition-all`}>
                <span>{artist.avatarInit}</span>
                <button 
                  onClick={() => triggerToast(`Visualisation du profil de ${artist.name} 🎨`)}
                  className="absolute -bottom-1 -right-1 w-5 h-5 bg-[#D4AF37] text-[#0C3823] rounded-full flex items-center justify-center shadow"
                >
                  <Play className="w-2.5 h-2.5 fill-current ml-0.5" />
                </button>
              </div>
              <span className="text-[10px] font-bold text-stone-700">{artist.name}</span>
              <span className="text-[8px] font-medium text-stone-400 uppercase tracking-tight truncate max-w-[64px]">{artist.role}</span>
            </div>
          ))}
        </div>
      </div>

      {/* FEATURED ART EXHIBITION */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {artists.slice(0, 2).map((artist, idx) => (
          <div 
            key={idx}
            className="bg-white rounded-3xl border border-stone-150 p-5 shadow-sm relative overflow-hidden flex flex-col justify-between group hover:border-[#0C3823]/30 transition-all duration-300"
          >
            {/* Elegant Background Accent */}
            <div className="absolute top-0 right-0 w-24 h-24 bg-[#D4AF37]/5 rounded-bl-full pointer-events-none" />

            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="px-2.5 py-0.5 bg-[#5C131E]/5 text-[#5C131E] font-mono font-black uppercase text-[8px] rounded-md tracking-wider">
                  {artist.role}
                </span>
                
                <span className="text-[9px] font-mono text-stone-400 flex items-center gap-1">
                  <Award className="w-3.5 h-3.5 text-[#D4AF37]" />
                  Featured Artist
                </span>
              </div>

              <h3 className="text-sm font-black text-stone-900 group-hover:text-[#0C3823] transition-colors">
                {artist.work} by {artist.name}
              </h3>

              <p className="text-xs text-stone-500 leading-relaxed font-sans">
                {artist.description}
              </p>
            </div>

            <div className="pt-4 mt-4 border-t border-stone-50 flex items-center justify-between gap-2">
              <span className="text-[10px] font-mono text-[#0C3823] font-bold uppercase">Crafted with pride</span>
              
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    const nextFavs = favorites.includes(artist.name) 
                      ? favorites.filter(n => n !== artist.name)
                      : [...favorites, artist.name];
                    setFavorites(nextFavs);
                    triggerToast(favorites.includes(artist.name) ? "Retiré de vos favoris 💔" : `Soutien envoyé à ${artist.name}! ❤️`);
                  }}
                  className="p-2 rounded-xl bg-stone-50 hover:bg-red-50 text-stone-400 hover:text-red-500 transition-colors border border-stone-100"
                >
                  <Heart className={`w-3.5 h-3.5 ${favorites.includes(artist.name) ? "fill-red-500 text-red-500" : ""}`} />
                </button>

                <button
                  onClick={() => triggerToast(`Partage de l'oeuvre de ${artist.name} 🔗`)}
                  className="p-2 rounded-xl bg-stone-50 hover:bg-stone-100 text-stone-500 transition-colors border border-stone-100"
                >
                  <Share2 className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* MUSIC PLAYLISTS SECTION */}
      <div className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm space-y-4">
        <div className="flex items-center justify-between border-b border-stone-100 pb-2">
          <h2 className="text-sm font-black text-stone-900 uppercase tracking-widest flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-[#0C3823]" />
            <span>Habesha Soundscapes</span>
          </h2>
          <span className="text-[10px] font-mono text-[#D4AF37] font-black uppercase bg-[#0C3823] px-2 py-0.5 rounded">
            Diaspora Radio
          </span>
        </div>

        <div className="space-y-2">
          {tracks.map((track) => {
            const isCurrent = activeTrack?.id === track.id;
            return (
              <div 
                key={track.id}
                onClick={() => {
                  setActiveTrack(track);
                  setIsPlaying(true);
                  triggerToast(`Playing ${track.title} 🎵`);
                }}
                className={`p-3.5 rounded-2xl border transition-all duration-200 flex items-center justify-between gap-4 cursor-pointer ${
                  isCurrent 
                    ? "bg-[#0C3823]/5 border-[#0C3823]/30 shadow-sm" 
                    : "bg-[#FBFBFA] border-stone-150 hover:border-stone-300"
                }`}
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-all ${
                    isCurrent ? "bg-[#0C3823] text-[#D4AF37] scale-105" : "bg-stone-100 text-stone-500"
                  }`}>
                    {isCurrent && isPlaying ? (
                      <div className="flex items-end gap-0.5 h-4">
                        <div className="w-0.5 h-3 bg-[#D4AF37] animate-pulse" />
                        <div className="w-0.5 h-4 bg-[#D4AF37] animate-pulse delay-75" />
                        <div className="w-0.5 h-2 bg-[#D4AF37] animate-pulse delay-150" />
                      </div>
                    ) : (
                      <Play className="w-4 h-4 fill-current ml-0.5" />
                    )}
                  </div>

                  <div className="min-w-0">
                    <h4 className="text-xs font-black text-stone-900 truncate">
                      {track.title}
                    </h4>
                    <p className="text-[10px] text-stone-500 truncate mt-0.5">
                      {track.artist}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-4 shrink-0 font-mono text-[10px]">
                  <span className="text-stone-400 font-bold uppercase hidden sm:inline-block tracking-wider">
                    {track.genre}
                  </span>
                  <span className="text-[#D4AF37] font-black bg-[#0C3823]/5 px-2 py-0.5 rounded-full">
                    {track.plays}
                  </span>
                  <span className="text-stone-500 font-bold">
                    {track.duration}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* AUDIO PLAYER BAR OVERLAY */}
      {activeTrack && (
        <div className="fixed bottom-16 md:bottom-6 left-1/2 -translate-x-1/2 w-[90%] max-w-lg bg-[#0C3823] border-2 border-[#D4AF37] rounded-2xl shadow-2xl p-4 z-50 text-stone-100 flex flex-col gap-3 font-sans transition-all duration-300 transform scale-100">
          
          <div className="flex items-center justify-between gap-3">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-10 h-10 rounded-xl bg-[#D4AF37] text-[#0C3823] flex items-center justify-center font-black">
                <Music className="w-5 h-5" />
              </div>
              <div className="min-w-0">
                <h4 className="text-xs font-black text-[#D4AF37] truncate">{activeTrack.title}</h4>
                <p className="text-[10px] text-stone-300 truncate">{activeTrack.artist}</p>
              </div>
            </div>

            {/* Close trigger */}
            <button 
              onClick={() => {
                setActiveTrack(null);
                setIsPlaying(false);
              }}
              className="text-stone-400 hover:text-white text-xs font-mono"
            >
              ✕ Close
            </button>
          </div>

          {/* Progress bar slider */}
          <div className="space-y-1">
            <div className="relative w-full h-1 bg-[#09291a] rounded-full overflow-hidden">
              <div 
                className="absolute left-0 top-0 h-full bg-[#D4AF37] transition-all"
                style={{ width: `${progress}%` }}
              />
              <input 
                type="range" 
                min="0" 
                max="100" 
                value={progress}
                onChange={(e) => setProgress(Number(e.target.value))}
                className="absolute left-0 top-0 w-full h-full opacity-0 cursor-pointer"
              />
            </div>
            <div className="flex justify-between text-[8px] font-mono text-emerald-400/80">
              <span>0:45</span>
              <span>{activeTrack.duration}</span>
            </div>
          </div>

          {/* Control bar triggers */}
          <div className="flex items-center justify-between pt-1">
            <div className="flex items-center gap-4">
              <button 
                onClick={() => setIsPlaying(!isPlaying)}
                className="w-8 h-8 rounded-full bg-[#D4AF37] text-[#0C3823] flex items-center justify-center hover:scale-105 transition-all shadow"
              >
                {isPlaying ? <Pause className="w-4 h-4 fill-current" /> : <Play className="w-4 h-4 fill-current ml-0.5" />}
              </button>

              <button 
                onClick={() => triggerToast("Piste précédente ⏮️")}
                className="text-stone-300 hover:text-white font-mono text-[10px]"
              >
                Prev
              </button>
              <button 
                onClick={() => triggerToast("Piste suivante ⏭️")}
                className="text-stone-300 hover:text-white font-mono text-[10px]"
              >
                Next
              </button>
            </div>

            {/* Volume controller */}
            <div className="flex items-center gap-2">
              <Volume2 className="w-3.5 h-3.5 text-stone-400" />
              <input 
                type="range" 
                min="0" 
                max="100" 
                value={volume}
                onChange={(e) => setVolume(Number(e.target.value))}
                className="w-16 h-1 bg-[#09291a] accent-[#D4AF37] rounded-lg cursor-pointer scale-90"
              />
            </div>
          </div>

        </div>
      )}

      {/* FLOATING TOAST */}
      {toast && (
        <div className="fixed bottom-20 md:bottom-6 right-6 z-50 bg-[#0C3823] text-[#D4AF37] border-2 border-[#D4AF37] px-5 py-3 rounded-2xl shadow-2xl flex items-center gap-3 animate-bounce font-sans text-xs font-bold">
          <Sparkles className="w-4 h-4 text-[#D4AF37]" />
          <span>{toast}</span>
        </div>
      )}

    </div>
  );
}
