import React, { useState, useEffect, useRef } from "react";
import { ChatMessage, User } from "../types";
import { SupportedLanguage, translations } from "../translations";
import { MessageSquare, Send, Award, Shield, User as UserIcon, RefreshCw } from "lucide-react";

interface ChatViewProps {
  messages: ChatMessage[];
  currentUser: User;
  language: SupportedLanguage;
  onRefresh: () => void;
  initialActiveChannel?: string;
  recipientName?: string;
}

const CHANNELS = [
  { id: "general", label: "💬 Général", desc: "Discussion libre entre membres Habesha d'Europe" },
  { id: "jobs", label: "👷 Emploi & Entraide", desc: "Conseils, recommandations et opportunités de travail" },
  { id: "marketplace", label: "🛒 Marketplace", desc: "Discussions autour des ventes, voitures et affaires" },
  { id: "events", label: "📅 Événements", desc: "Partage et organisation de mariages, concerts, football..." }
];

export default function ChatView({ messages, currentUser, language, onRefresh, initialActiveChannel, recipientName }: ChatViewProps) {
  const t = translations[language];
  const [activeChannel, setActiveChannel] = useState(initialActiveChannel || "general");
  const [typedMessage, setTypedMessage] = useState("");
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Sync active channel from props (e.g. when opening a listing contact chat)
  useEffect(() => {
    if (initialActiveChannel) {
      setActiveChannel(initialActiveChannel);
    }
  }, [initialActiveChannel]);

  // Auto-scroll to bottom of messages
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, activeChannel]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!typedMessage.trim() || sending) return;

    setSending(true);
    try {
      const res = await fetch("/api/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          channel: activeChannel,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderRole: currentUser.role,
          senderIsVerified: currentUser.verificationStatus === "verified",
          content: typedMessage
        })
      });

      if (!res.ok) throw new Error();
      
      setTypedMessage("");
      onRefresh();
    } catch (err) {
      console.error("Failed to send message", err);
    } finally {
      setSending(false);
    }
  };

  // 1. Dynamic DM Discoveries from messages
  const dmChannels = Array.from(new Set(
    messages
      .filter(m => m.channel.startsWith("dm_") && m.channel.includes(currentUser.id))
      .map(m => m.channel)
  )).map(chId => {
    const chMsgs = messages.filter(m => m.channel === chId);
    const lastMsg = chMsgs[chMsgs.length - 1];
    
    // Find who the other participant is
    const parts = chId.replace("dm_", "").split("_");
    const otherUserId = parts.find(p => p !== currentUser.id) || "unknown";
    
    const otherMsg = chMsgs.find(m => m.senderId === otherUserId);
    const otherName = otherMsg ? otherMsg.senderName : "Membre Habesha";
    const otherRole = otherMsg ? otherMsg.senderRole : "user";
    const otherIsVerified = otherMsg ? otherMsg.senderIsVerified : false;

    return {
      id: chId,
      otherUserId,
      otherName,
      otherRole,
      otherIsVerified,
      lastText: lastMsg ? lastMsg.content : "Début de la discussion",
      lastTime: lastMsg ? new Date(lastMsg.createdAt) : new Date()
    };
  }).sort((a, b) => b.lastTime.getTime() - a.lastTime.getTime());

  // Support empty initialized DM channel if clicked from listing details
  const isCurrentEmptyDm = activeChannel.startsWith("dm_") && !dmChannels.some(d => d.id === activeChannel);
  const displayedDms = [...dmChannels];
  if (isCurrentEmptyDm) {
    const parts = activeChannel.replace("dm_", "").split("_");
    const otherUserId = parts.find(p => p !== currentUser.id) || "unknown";
    displayedDms.push({
      id: activeChannel,
      otherUserId,
      otherName: recipientName || "Auteur de l'annonce",
      otherRole: "user",
      otherIsVerified: false,
      lastText: "Discuter en toute sécurité...",
      lastTime: new Date()
    });
  }

  // Filter messages for current active channel
  const filteredMessages = messages.filter(m => m.channel === activeChannel);

  // Setup header info
  const isDm = activeChannel.startsWith("dm_");
  const currentDm = displayedDms.find(d => d.id === activeChannel);
  const channelTitle = isDm ? `✉️ Message avec ${currentDm?.otherName || recipientName || "Membre"}` : CHANNELS.find(c => c.id === activeChannel)?.label;
  const channelDesc = isDm ? "Canal de discussion privé • Les numéros de téléphone s'échangent d'un commun accord." : CHANNELS.find(c => c.id === activeChannel)?.desc;

  return (
    <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 min-h-[500px] h-[calc(100vh-180px)]">
      
      {/* CHANNELS PANEL */}
      <div className="lg:col-span-1 bg-white p-5 rounded-3xl border border-stone-100 shadow-sm flex flex-col justify-between overflow-y-auto max-h-[calc(100vh-180px)]">
        <div className="space-y-6">
          
          {/* Public Channels */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="text-[10px] font-black text-stone-400 uppercase tracking-wider">Salons Publics</h2>
              <button onClick={onRefresh} className="p-1 text-stone-400 hover:text-stone-700 transition-colors">
                <RefreshCw className="w-3.5 h-3.5" />
              </button>
            </div>
            
            <div className="space-y-1.5">
              {CHANNELS.map(ch => (
                <button
                  key={ch.id}
                  onClick={() => setActiveChannel(ch.id)}
                  className={`w-full text-left p-3 rounded-2xl text-xs font-bold transition-all flex flex-col gap-0.5 border ${
                    activeChannel === ch.id
                      ? "bg-[#0C3823] text-white border-[#0C3823] shadow-md shadow-[#0C3823]/10"
                      : "bg-stone-50 text-stone-700 border-stone-100 hover:bg-stone-100"
                  }`}
                >
                  <span>{ch.label}</span>
                  <span className={`text-[9px] font-medium leading-tight ${
                    activeChannel === ch.id ? "text-stone-300" : "text-stone-400"
                  }`}>
                    {ch.desc}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Private DMs list */}
          <div className="space-y-3">
            <h2 className="text-[10px] font-black text-stone-400 uppercase tracking-wider">📬 Inquiries & DMs</h2>
            
            {displayedDms.length === 0 ? (
              <div className="text-[11px] text-stone-400 bg-stone-50/50 p-4 rounded-2xl border border-stone-100 text-center">
                Aucune discussion privée en cours. Cliquez sur "Discuter" sur une annonce pour commencer !
              </div>
            ) : (
              <div className="space-y-1.5">
                {displayedDms.map(d => (
                  <button
                    key={d.id}
                    onClick={() => setActiveChannel(d.id)}
                    className={`w-full text-left p-3 rounded-2xl transition-all border flex flex-col gap-1 ${
                      activeChannel === d.id
                        ? "bg-[#5C131E] text-white border-[#5C131E] shadow-md shadow-[#5C131E]/10"
                        : "bg-stone-50 text-stone-700 border-stone-100 hover:bg-stone-100"
                    }`}
                  >
                    <div className="flex items-center justify-between w-full">
                      <span className="text-xs font-bold truncate pr-2">{d.otherName}</span>
                      {d.otherRole === "professional" && (
                        <span className="text-[7px] font-extrabold uppercase bg-amber-500 text-stone-950 px-1 py-0.2 rounded scale-90 shrink-0">PRO</span>
                      )}
                    </div>
                    <span className={`text-[9px] truncate max-w-full block leading-tight ${
                      activeChannel === d.id ? "text-stone-200" : "text-stone-400 font-medium"
                    }`}>
                      {d.lastText}
                    </span>
                  </button>
                ))}
              </div>
            )}
          </div>

        </div>

        <div className="pt-4 mt-6 border-t border-stone-100 text-[10px] text-stone-400 font-medium">
          Respectez les règles de courtoisie de la communauté Habesha.
        </div>
      </div>

      {/* CHAT MESSAGES PANEL */}
      <div className="lg:col-span-3 bg-white rounded-3xl border border-stone-100 shadow-sm flex flex-col overflow-hidden relative">
        
        {/* Channel Header Info */}
        <div className="p-4 border-b border-stone-100 bg-stone-50/50 flex justify-between items-center">
          <div>
            <h3 className="text-xs font-black text-stone-800 uppercase tracking-wider">
              {channelTitle}
            </h3>
            <p className="text-[10px] text-stone-400 mt-0.5">
              {channelDesc}
            </p>
          </div>
          <span className="text-[10px] font-mono bg-stone-100 text-stone-600 px-2 py-0.5 rounded font-bold">
            {filteredMessages.length} msg
          </span>
        </div>

        {/* Message scroll list */}
        <div className="flex-1 p-5 overflow-y-auto space-y-4 max-h-[calc(100vh-320px)] bg-[#FAF9F6]/20">
          {filteredMessages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-center p-8 text-stone-400 gap-2">
              <MessageSquare className="w-8 h-8 text-stone-300" />
              <p className="text-xs">Aucun message pour l'instant dans ce salon. Commencez la discussion !</p>
            </div>
          ) : (
            filteredMessages.map(msg => {
              const isMe = msg.senderId === currentUser.id;
              
              return (
                <div key={msg.id} className={`flex gap-2.5 max-w-[85%] ${isMe ? "ml-auto flex-row-reverse" : ""}`}>
                  
                  {/* Avatar */}
                  <div className={`w-8 h-8 rounded-full shrink-0 flex items-center justify-center text-xs font-bold text-white uppercase ${
                    msg.senderRole === "admin"
                      ? "bg-[#5C131E]"
                      : msg.senderRole === "professional"
                      ? "bg-[#0C3823]"
                      : "bg-stone-400"
                  }`}>
                    {msg.senderName[0]}
                  </div>

                  {/* Message Bubble Container */}
                  <div className="space-y-1">
                    
                    {/* Header line: name, role badge, timestamp */}
                    <div className={`flex items-center gap-1.5 text-[9px] ${isMe ? "justify-end" : ""}`}>
                      <span className="font-bold text-stone-600">{msg.senderName}</span>
                      
                      {msg.senderRole === "admin" && (
                        <span className="bg-red-50 text-red-700 font-extrabold px-1.5 py-0.2 rounded border border-red-100 flex items-center gap-0.5 text-[7px] uppercase tracking-wider scale-95">
                          <Shield className="w-2 h-2" /> Admin
                        </span>
                      )}

                      {msg.senderRole === "professional" && (
                        <span className="bg-[#0C3823]/10 text-[#0C3823] font-bold px-1.5 py-0.2 rounded flex items-center gap-0.5 text-[7px] uppercase tracking-wider scale-95">
                          Pro
                        </span>
                      )}

                      {msg.senderIsVerified && (
                        <span className="text-emerald-600" title="Utilisateur vérifié">✅</span>
                      )}

                      <span className="text-stone-400 font-mono font-medium">
                        • {new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>

                    {/* Bubble */}
                    <div className={`p-3.5 rounded-2xl text-xs leading-relaxed ${
                      isMe
                        ? "bg-[#0C3823] text-stone-100 rounded-tr-none shadow-sm"
                        : "bg-stone-50 text-stone-800 rounded-tl-none border border-stone-200"
                    }`}>
                      {msg.content}
                    </div>

                  </div>

                </div>
              );
            })
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Text Form */}
        <form onSubmit={handleSendMessage} className="p-4 border-t border-stone-100 bg-white flex gap-2">
          <input
            type="text"
            placeholder="Écrivez votre message ici..."
            value={typedMessage}
            onChange={(e) => setTypedMessage(e.target.value)}
            className="flex-1 px-4 py-3 bg-stone-50 rounded-2xl border border-stone-200 text-xs focus:outline-none focus:border-[#0C3823] font-medium"
          />
          <button
            type="submit"
            disabled={!typedMessage.trim() || sending}
            className="p-3 bg-[#0C3823] hover:bg-[#09291a] disabled:opacity-50 text-[#D4AF37] rounded-2xl transition-colors flex items-center justify-center"
          >
            <Send className="w-4 h-4" />
          </button>
        </form>

      </div>

    </div>
  );
}
