import React, { useState } from "react";
import { User, Listing, SystemNotification, AppStats } from "../types";
import { SupportedLanguage, translations } from "../translations";
import { Shield, Users, FileText, Check, X, Ban, Radio, BarChart3, Clock, AlertTriangle, Eye, Trash2, Send } from "lucide-react";

interface AdminPanelProps {
  stats: AppStats;
  users: User[];
  listings: Listing[];
  notifications: SystemNotification[];
  language: SupportedLanguage;
  onRefresh: () => void;
}

export default function AdminPanel({ stats, users, listings, notifications, language, onRefresh }: AdminPanelProps) {
  const t = translations[language];

  // Forms states
  const [notifTitle, setNotifTitle] = useState("");
  const [notifContent, setNotifContent] = useState("");
  const [notifType, setNotifType] = useState<"info" | "success" | "warning">("info");
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Filters inside Admin Panel
  const [activeSubTab, setActiveSubTab] = useState<"stats" | "verifications" | "listings" | "users" | "notifications">("stats");

  const sendNotification = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!notifTitle || !notifContent) return;

    setActionLoading("notif");
    setErrorMsg(null);
    try {
      const res = await fetch("/api/notifications", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: notifTitle,
          content: notifContent,
          type: notifType
        })
      });

      if (!res.ok) throw new Error("Erreur d'envoi");
      
      setNotifTitle("");
      setNotifContent("");
      setSuccessMsg("Annonce générale publiée avec succès !");
      setTimeout(() => setSuccessMsg(null), 4000);
      onRefresh();
    } catch (err) {
      setErrorMsg("Impossible de publier l'annonce générale.");
    } finally {
      setActionLoading(null);
    }
  };

  const handleModerateUser = async (userId: string, status: "verified" | "unverified") => {
    setActionLoading(userId);
    try {
      const res = await fetch("/api/users/moderate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, status })
      });
      if (!res.ok) throw new Error();
      onRefresh();
    } catch (e) {
      setErrorMsg("Échec de la modération de l'utilisateur.");
    } finally {
      setActionLoading(null);
    }
  };

  const handleBlockUser = async (userId: string, isBlocked: boolean) => {
    setActionLoading(userId);
    try {
      const res = await fetch("/api/users/block", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, isBlocked })
      });
      if (!res.ok) throw new Error();
      onRefresh();
    } catch (e) {
      setErrorMsg("Impossible de modifier le statut de l'utilisateur.");
    } finally {
      setActionLoading(null);
    }
  };

  const handleModerateListing = async (listingId: string, status: "approved" | "rejected") => {
    setActionLoading(listingId);
    try {
      const res = await fetch("/api/listings/moderate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ listingId, status })
      });
      if (!res.ok) throw new Error();
      onRefresh();
    } catch (e) {
      setErrorMsg("Échec de la validation de l'annonce.");
    } finally {
      setActionLoading(null);
    }
  };

  const handleDeleteListing = async (listingId: string) => {
    if (!confirm("Voulez-vous vraiment supprimer définitivement cette annonce ?")) return;
    setActionLoading(listingId);
    try {
      const res = await fetch("/api/listings/delete", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ listingId })
      });
      if (!res.ok) throw new Error();
      onRefresh();
    } catch (e) {
      setErrorMsg("Échec de la suppression.");
    } finally {
      setActionLoading(null);
    }
  };

  // Filter pending data for dashboard badges
  const pendingUsers = users.filter(u => u.verificationStatus === "pending");
  const pendingListings = listings.filter(l => l.status === "pending");

  return (
    <div className="space-y-6">
      
      {/* HEADER BAR */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-red-50 text-[#5C131E] rounded-2xl">
            <Shield className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-black text-stone-900 tracking-tight">{t.navAdmin}</h1>
            <p className="text-xs text-stone-500">EuroHabesha European Operations Dashboard</p>
          </div>
        </div>

        {/* Quick Tabs */}
        <div className="flex flex-wrap gap-1.5 bg-stone-50 p-1.5 rounded-2xl border border-stone-150">
          {[
            { id: "stats", label: "Stats", count: undefined },
            { id: "verifications", label: "Vérifications", count: pendingUsers.length },
            { id: "listings", label: "Annonces", count: pendingListings.length },
            { id: "users", label: "Utilisateurs", count: undefined },
            { id: "notifications", label: "Notifications", count: undefined }
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveSubTab(tab.id as any)}
              className={`px-3 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                activeSubTab === tab.id
                  ? "bg-[#5C131E] text-white shadow-sm"
                  : "text-stone-500 hover:text-stone-800"
              }`}
            >
              <span>{tab.label}</span>
              {tab.count !== undefined && tab.count > 0 && (
                <span className="bg-red-500 text-white font-mono text-[9px] font-bold px-1.5 py-0.5 rounded-full">
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {errorMsg && (
        <div className="p-4 bg-red-50 border border-red-100 rounded-2xl text-red-700 text-xs font-semibold">
          ⚠️ {errorMsg}
        </div>
      )}

      {successMsg && (
        <div className="p-4 bg-green-50 border border-green-100 rounded-2xl text-green-700 text-xs font-semibold">
          ✅ {successMsg}
        </div>
      )}

      {/* SUB-TABS VIEWS */}
      {activeSubTab === "stats" && (
        <div className="space-y-6">
          
          {/* Bento Stats Grid */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            
            <div className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm flex flex-col justify-between">
              <div className="flex justify-between items-start mb-4">
                <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t.users}</span>
                <span className="p-1.5 bg-emerald-50 text-emerald-700 rounded-lg"><Users className="w-4 h-4" /></span>
              </div>
              <div>
                <span className="text-3xl font-black text-stone-900 tracking-tight font-mono">{stats.totalUsers}</span>
                <p className="text-[10px] text-emerald-600 font-semibold mt-1">▲ Actifs en Europe</p>
              </div>
            </div>

            <div className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm flex flex-col justify-between">
              <div className="flex justify-between items-start mb-4">
                <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t.listings}</span>
                <span className="p-1.5 bg-amber-50 text-amber-700 rounded-lg"><FileText className="w-4 h-4" /></span>
              </div>
              <div>
                <span className="text-3xl font-black text-stone-900 tracking-tight font-mono">{stats.totalListings}</span>
                <p className="text-[10px] text-amber-600 font-semibold mt-1">▲ Annonces validées</p>
              </div>
            </div>

            <div className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm flex flex-col justify-between">
              <div className="flex justify-between items-start mb-4">
                <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t.events}</span>
                <span className="p-1.5 bg-red-50 text-red-700 rounded-lg"><BarChart3 className="w-4 h-4" /></span>
              </div>
              <div>
                <span className="text-3xl font-black text-stone-900 tracking-tight font-mono">{stats.totalEvents}</span>
                <p className="text-[10px] text-red-600 font-semibold mt-1">Concerts, mariages, etc.</p>
              </div>
            </div>

            <div className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm flex flex-col justify-between">
              <div className="flex justify-between items-start mb-4">
                <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{t.pros}</span>
                <span className="p-1.5 bg-[#0C3823]/10 text-[#0C3823] rounded-lg"><Check className="w-4 h-4" /></span>
              </div>
              <div>
                <span className="text-3xl font-black text-stone-900 tracking-tight font-mono">{stats.totalProfessionals}</span>
                <p className="text-[10px] text-[#0C3823] font-semibold mt-1">Badge Vérifié ✅</p>
              </div>
            </div>

          </div>

          {/* Quick Tasks Summary */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
              <h3 className="text-sm font-black text-stone-900 mb-4 flex items-center gap-2">
                <Clock className="w-4 h-4 text-amber-500" />
                Actions immédiates requises
              </h3>
              <div className="space-y-3">
                
                <div className="flex justify-between items-center p-3.5 bg-stone-50 rounded-2xl text-xs">
                  <div>
                    <p className="font-bold text-stone-800">Vérification d'identité</p>
                    <p className="text-stone-400 mt-0.5">Professionnels Habesha en attente de badge</p>
                  </div>
                  <button
                    onClick={() => setActiveSubTab("verifications")}
                    className={`px-3 py-1.5 rounded-lg text-[10px] font-black uppercase tracking-wider ${
                      pendingUsers.length > 0 ? "bg-[#5C131E] text-white" : "bg-stone-200 text-stone-500"
                    }`}
                  >
                    {pendingUsers.length} En attente
                  </button>
                </div>

                <div className="flex justify-between items-center p-3.5 bg-stone-50 rounded-2xl text-xs">
                  <div>
                    <p className="font-bold text-stone-800">Modération d'annonces</p>
                    <p className="text-stone-400 mt-0.5">Annonces à approuver ou rejeter</p>
                  </div>
                  <button
                    onClick={() => setActiveSubTab("listings")}
                    className={`px-3 py-1.5 rounded-lg text-[10px] font-black uppercase tracking-wider ${
                      pendingListings.length > 0 ? "bg-[#5C131E] text-white" : "bg-stone-200 text-stone-500"
                    }`}
                  >
                    {pendingListings.length} En attente
                  </button>
                </div>

              </div>
            </div>

            {/* Platform System Info */}
            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm text-xs space-y-3 flex flex-col justify-between">
              <div>
                <h3 className="text-sm font-black text-stone-900 mb-4">Système d'exploitation EuroHabesha</h3>
                <p className="text-stone-500 leading-relaxed">
                  Cette interface vous permet d'administrer de manière centralisée les fiches professionnelles, les événements culturels et les annonces de marketplace d'Europe.
                  L'IA Gemini analyse automatiquement les textes soumis pour accélérer la validation et détecter les spams.
                </p>
              </div>
              <div className="pt-4 border-t border-stone-100 flex justify-between items-center text-stone-400 font-mono text-[10px]">
                <span>DATABASE STATUS: ONLINE</span>
                <span>V1.2 PROTOTYPE</span>
              </div>
            </div>

          </div>

        </div>
      )}

      {/* VERIFICATIONS SUB-TAB */}
      {activeSubTab === "verifications" && (
        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm space-y-4">
          <h2 className="text-base font-black text-stone-900 mb-2">{t.pendingVerifications}</h2>
          
          {pendingUsers.length === 0 ? (
            <div className="p-8 text-center text-stone-400 text-xs">
              Aucune demande de vérification de profil en cours.
            </div>
          ) : (
            <div className="divide-y divide-stone-100">
              {pendingUsers.map(user => (
                <div key={user.id} className="py-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-stone-800 text-sm">{user.name}</span>
                      <span className="px-2 py-0.5 bg-[#0C3823]/10 text-[#0C3823] text-[9px] font-bold rounded-md">
                        {user.role}
                      </span>
                    </div>
                    <p className="text-xs text-stone-500">
                      🌍 {user.country} • 📞 {user.phone} • Spoken: {user.languages.join(", ").toUpperCase()}
                    </p>
                    <div className="mt-2 p-2.5 bg-stone-50 rounded-xl border border-stone-150 inline-flex items-center gap-2 text-[10px]">
                      <span className="text-amber-600 font-bold uppercase tracking-wider">Document fourni :</span>
                      <span className="font-mono text-stone-600 font-semibold underline">{user.verificationDocName || "Justificatif_Habesha_Pro.pdf"}</span>
                    </div>
                  </div>

                  <div className="flex gap-2">
                    <button
                      onClick={() => handleModerateUser(user.id, "unverified")}
                      disabled={actionLoading === user.id}
                      className="px-3 py-2 bg-red-50 hover:bg-red-100 text-red-700 text-xs font-bold rounded-xl transition-all flex items-center gap-1"
                    >
                      <X className="w-4 h-4" /> Rejeter
                    </button>
                    <button
                      onClick={() => handleModerateUser(user.id, "verified")}
                      disabled={actionLoading === user.id}
                      className="px-3 py-2 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] text-xs font-bold rounded-xl transition-all flex items-center gap-1"
                    >
                      <Check className="w-4 h-4" /> Approuver (Vérifier)
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* LISTINGS SUB-TAB */}
      {activeSubTab === "listings" && (
        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm space-y-6">
          <div className="flex justify-between items-center">
            <h2 className="text-base font-black text-stone-900">Modération des annonces</h2>
            <span className="text-xs text-stone-400 font-mono font-bold">{pendingListings.length} en attente</span>
          </div>

          {pendingListings.length === 0 ? (
            <div className="p-12 text-center text-stone-400 text-xs">
              Toutes les annonces soumises ont été validées ou rejetées.
            </div>
          ) : (
            <div className="space-y-6">
              {pendingListings.map(listing => (
                <div key={listing.id} className="p-5 bg-stone-50 rounded-3xl border border-stone-200 space-y-4">
                  
                  {/* Listing Title / Category / Author bar */}
                  <div className="flex flex-wrap justify-between items-start gap-2">
                    <div>
                      <span className="px-2 py-0.5 bg-stone-200 text-stone-600 text-[9px] font-black uppercase tracking-wider rounded-md mr-2">
                        {listing.type} • {listing.category}
                      </span>
                      <h3 className="text-sm font-bold text-stone-900 inline">{listing.title}</h3>
                      <p className="text-[10px] text-stone-400 mt-0.5">
                        Soumis par <span className="font-semibold text-stone-600">{listing.authorName}</span> • {listing.location.city}, {listing.location.country}
                      </p>
                    </div>

                    {/* Price / Date */}
                    {listing.price && <span className="text-xs font-black text-[#0C3823] font-mono">{listing.price}</span>}
                    {listing.date && <span className="text-[10px] font-bold text-[#5C131E]">{listing.date}</span>}
                  </div>

                  {/* Body Content */}
                  <p className="text-xs text-stone-600 leading-relaxed bg-white p-3 rounded-2xl border border-stone-100">
                    {listing.description}
                  </p>

                  {/* AUTOMATED GEMINI AI REPORT PANEL */}
                  {listing.aiReview && (
                    <div className="p-4 bg-stone-900 text-stone-100 rounded-2xl border border-stone-800 space-y-2.5">
                      <div className="flex items-center justify-between border-b border-stone-800 pb-2">
                        <span className="text-[9px] font-black tracking-widest text-[#D4AF37] uppercase flex items-center gap-1.5">
                          <Radio className="w-3.5 h-3.5 text-emerald-400 animate-pulse" />
                          {t.aiValidationLabel}
                        </span>
                        <div className="flex items-center gap-2">
                          <span className="text-[9px] text-stone-400">{t.aiScore}:</span>
                          <span className={`text-[10px] font-black font-mono px-1.5 py-0.5 rounded ${
                            listing.aiReview.score >= 80 ? "bg-emerald-950 text-emerald-400" : "bg-amber-950 text-amber-400"
                          }`}>
                            {listing.aiReview.score}/100
                          </span>
                        </div>
                      </div>

                      <p className="text-[10px] text-stone-300 font-medium">
                        <span className="font-bold text-[#D4AF37] mr-1">Avis IA:</span>
                        {listing.aiReview.reason}
                      </p>

                      {listing.aiReview.improvements && (
                        <p className="text-[10px] text-stone-400 italic">
                          💡 <span className="font-bold text-stone-300 not-italic mr-1">{t.aiSuggestion}:</span>
                          {listing.aiReview.improvements}
                        </p>
                      )}
                    </div>
                  )}

                  {/* Actions Bar */}
                  <div className="flex justify-end gap-2 pt-1 border-t border-stone-150">
                    <button
                      onClick={() => handleDeleteListing(listing.id)}
                      disabled={actionLoading === listing.id}
                      className="px-3 py-2 bg-red-50 hover:bg-red-100 text-red-700 text-xs font-bold rounded-xl transition-all flex items-center gap-1 mr-auto"
                    >
                      <Trash2 className="w-4 h-4" /> Supprimer
                    </button>
                    <button
                      onClick={() => handleModerateListing(listing.id, "rejected")}
                      disabled={actionLoading === listing.id}
                      className="px-4 py-2 bg-stone-200 hover:bg-stone-300 text-stone-700 text-xs font-bold rounded-xl transition-all flex items-center gap-1"
                    >
                      <X className="w-4 h-4" /> Rejeter
                    </button>
                    <button
                      onClick={() => handleModerateListing(listing.id, "approved")}
                      disabled={actionLoading === listing.id}
                      className="px-4 py-2 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] text-xs font-bold rounded-xl transition-all flex items-center gap-1"
                    >
                      <Check className="w-4 h-4" /> Valider & Publier
                    </button>
                  </div>

                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* USERS MANAGEMENT SUB-TAB */}
      {activeSubTab === "users" && (
        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm space-y-4">
          <h2 className="text-base font-black text-stone-900 mb-2">Comptes utilisateurs enregistrés</h2>
          <div className="divide-y divide-stone-150">
            {users.map(user => (
              <div key={user.id} className="py-3.5 flex items-center justify-between gap-4">
                <div className="space-y-0.5">
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-stone-800 text-xs">{user.name}</span>
                    <span className="px-2 py-0.5 bg-stone-100 text-stone-500 text-[8px] font-black uppercase tracking-wider rounded">
                      {user.role}
                    </span>
                    {user.verificationStatus === "verified" && (
                      <span className="text-[10px] text-emerald-600 font-bold">✅ Vérifié</span>
                    )}
                    {user.isBlocked && (
                      <span className="text-[10px] text-red-600 font-bold bg-red-50 px-1.5 py-0.5 rounded">🔒 BLOQUÉ</span>
                    )}
                  </div>
                  <p className="text-[10px] text-stone-400 font-mono">
                    {user.phone} • {user.country}
                  </p>
                </div>

                {user.role !== "admin" && (
                  <button
                    onClick={() => handleBlockUser(user.id, !user.isBlocked)}
                    disabled={actionLoading === user.id}
                    className={`px-3 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-wider transition-all flex items-center gap-1 ${
                      user.isBlocked
                        ? "bg-green-50 hover:bg-green-100 text-green-700"
                        : "bg-red-50 hover:bg-red-100 text-red-700"
                    }`}
                  >
                    <Ban className="w-3.5 h-3.5" />
                    {user.isBlocked ? "Débloquer" : "Bloquer"}
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* NOTIFICATIONS SUB-TAB */}
      {activeSubTab === "notifications" && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* Send Announcement Form */}
          <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm space-y-4">
            <h3 className="text-sm font-black text-stone-900 mb-2 flex items-center gap-1.5">
              <Radio className="w-4 h-4 text-[#5C131E]" />
              Diffuser une notification générale
            </h3>

            <form onSubmit={sendNotification} className="space-y-4">
              <div>
                <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                  Titre du message
                </label>
                <input
                  type="text"
                  placeholder="Ex: Maintenance du serveur"
                  value={notifTitle}
                  onChange={(e) => setNotifTitle(e.target.value)}
                  className="w-full px-4 py-2.5 bg-stone-50 rounded-xl border border-stone-200 text-xs focus:outline-none focus:border-[#5C131E]"
                />
              </div>

              <div>
                <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                  Type de message
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {[
                    { id: "info", label: "Information", color: "bg-stone-100 border-stone-200 text-stone-700" },
                    { id: "success", label: "Succès", color: "bg-green-50 border-green-100 text-green-700" },
                    { id: "warning", label: "Alerte", color: "bg-red-50 border-red-100 text-red-700" }
                  ].map(t => (
                    <button
                      key={t.id}
                      type="button"
                      onClick={() => setNotifType(t.id as any)}
                      className={`p-2 rounded-xl text-[10px] font-bold border text-center transition-all ${
                        notifType === t.id ? t.color : "bg-stone-50 text-stone-400 border-stone-200 hover:bg-stone-100"
                      }`}
                    >
                      {t.label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                  Contenu de l'annonce
                </label>
                <textarea
                  rows={4}
                  placeholder="Écrivez le message de notification générale pour tous les membres européens..."
                  value={notifContent}
                  onChange={(e) => setNotifContent(e.target.value)}
                  className="w-full px-4 py-2.5 bg-stone-50 rounded-xl border border-stone-200 text-xs focus:outline-none focus:border-[#5C131E] leading-relaxed resize-none"
                />
              </div>

              <button
                type="submit"
                disabled={actionLoading === "notif" || !notifTitle || !notifContent}
                className="w-full py-3 rounded-2xl bg-[#5C131E] hover:bg-[#4A0E17] text-white font-extrabold text-xs tracking-wider uppercase transition-colors flex items-center justify-center gap-1.5"
              >
                <Send className="w-4 h-4" /> Envoyer à tous les Habeshas
              </button>
            </form>
          </div>

          {/* Past Alerts */}
          <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm space-y-4">
            <h3 className="text-sm font-black text-stone-900 mb-2">Historique des annonces</h3>
            
            <div className="space-y-3.5 max-h-[360px] overflow-y-auto pr-1">
              {notifications.map(notif => (
                <div
                  key={notif.id}
                  className={`p-4 rounded-2xl border text-xs leading-relaxed space-y-1 ${
                    notif.type === "success"
                      ? "bg-green-50/50 border-green-100 text-green-800"
                      : notif.type === "warning"
                      ? "bg-red-50/50 border-red-100 text-red-800"
                      : "bg-slate-50 border-stone-200 text-stone-800"
                  }`}
                >
                  <p className="font-bold">{notif.title}</p>
                  <p className="text-[11px] text-stone-500">{notif.content}</p>
                  <span className="block text-[9px] text-stone-400 font-mono mt-2">
                    Publié le {new Date(notif.createdAt).toLocaleDateString()}
                  </span>
                </div>
              ))}
            </div>
          </div>

        </div>
      )}

    </div>
  );
}
