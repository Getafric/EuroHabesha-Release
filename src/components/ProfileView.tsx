import React, { useState } from "react";
import { User } from "../types";
import { SupportedLanguage, translations } from "../translations";
import { User as UserIcon, Phone, Globe, Shield, FileText, Check, Upload, Award, LogOut } from "lucide-react";

interface ProfileViewProps {
  user: User;
  language: SupportedLanguage;
  onLogout: () => void;
  onRefresh: () => void;
}

export default function ProfileView({ user, language, onLogout, onRefresh }: ProfileViewProps) {
  const t = translations[language];

  // Drag-and-drop file upload simulator states
  const [dragActive, setDragActive] = useState(false);
  const [selectedFileName, setSelectedFileName] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      setSelectedFileName(file.name);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedFileName(e.target.files[0].name);
    }
  };

  const submitVerification = async () => {
    if (!selectedFileName) return;
    setUploading(true);
    setError(null);

    try {
      // Simulate file upload API request
      const res = await fetch("/api/users/moderate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: user.id,
          status: "pending",
          docName: selectedFileName
        })
      });

      if (!res.ok) throw new Error("Échec de la soumission");

      setSuccess(true);
      setTimeout(() => {
        setSuccess(false);
        setSelectedFileName(null);
      }, 3000);
      onRefresh();
    } catch (err) {
      setError("Impossible d'envoyer la demande de vérification.");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      
      {/* USER CARD SUMMARY */}
      <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm relative overflow-hidden flex flex-col sm:flex-row items-center gap-6">
        
        {/* User avatar representation */}
        <div className="w-20 h-20 rounded-full bg-stone-100 border border-stone-200 text-[#0C3823] font-black text-3xl flex items-center justify-center uppercase shadow-inner shrink-0">
          {user.name[0]}
        </div>

        <div className="flex-1 text-center sm:text-left space-y-2">
          <div>
            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2">
              <h2 className="text-lg font-black text-stone-900 tracking-tight">{user.name}</h2>
              
              {user.verificationStatus === "verified" ? (
                <span className="bg-emerald-50 text-emerald-700 text-[9px] font-black px-2 py-0.5 rounded-full border border-emerald-100 flex items-center gap-0.5">
                  Vérifié ✅
                </span>
              ) : user.verificationStatus === "pending" ? (
                <span className="bg-amber-50 text-amber-700 text-[9px] font-black px-2 py-0.5 rounded-full border border-amber-100 flex items-center gap-0.5 animate-pulse">
                  Attente Validation ⏳
                </span>
              ) : (
                <span className="bg-stone-50 text-stone-500 text-[9px] font-black px-2 py-0.5 rounded-full border border-stone-150">
                  Membre standard
                </span>
              )}
            </div>

            <p className="text-xs text-stone-400 capitalize mt-0.5">Compte {user.role}</p>
          </div>

          <div className="flex flex-wrap justify-center sm:justify-start gap-x-4 gap-y-1.5 text-xs text-stone-500 font-medium">
            <span className="flex items-center gap-1">
              <Phone className="w-3.5 h-3.5 text-stone-400" />
              <span className="font-mono">{user.phone}</span>
            </span>
            <span className="flex items-center gap-1">
              <Globe className="w-3.5 h-3.5 text-stone-400" />
              <span>{user.country}</span>
            </span>
          </div>
        </div>

        {/* Log out Button */}
        <button
          onClick={onLogout}
          className="px-4 py-2.5 bg-red-50 hover:bg-red-100 text-red-700 font-bold text-xs rounded-2xl transition-all uppercase flex items-center gap-1.5 shrink-0 self-center"
        >
          <LogOut className="w-4 h-4" />
          Déconnexion
        </button>
      </div>

      {/* SPOKEN LANGUAGES INFO */}
      <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm space-y-3">
        <h3 className="text-sm font-black text-stone-900">{t.languages}</h3>
        <p className="text-xs text-stone-500">
          Les langues que vous parlez pour faciliter la recherche par d'autres Habesha d'Europe.
        </p>
        <div className="flex flex-wrap gap-2">
          {user.languages.map(l => (
            <span key={l} className="px-3 py-1 bg-stone-50 border border-stone-150 text-stone-700 text-xs font-bold uppercase tracking-wider rounded-xl">
              {l === "fr" && "Français 🇫🇷"}
              {l === "en" && "English 🇬🇧"}
              {l === "am" && "Amharique 🇪🇹"}
              {l === "ti" && "Tigrinya 🇪🇷"}
              {l === "de" && "Deutsch 🇩🇪"}
              {l === "it" && "Italiano 🇮🇹"}
              {l === "es" && "Español 🇪🇸"}
              {l === "nl" && "Nederlands 🇳🇱"}
            </span>
          ))}
        </div>
      </div>

      {/* PROFESSIONAL VERIFICATION REQUEST UPLOADER */}
      {user.role === "professional" && (
        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm space-y-4">
          <div className="flex items-center gap-2">
            <Award className="w-5 h-5 text-[#D4AF37]" />
            <h3 className="text-sm font-black text-stone-900">{t.uploadDocs}</h3>
          </div>

          <p className="text-xs text-stone-500 leading-relaxed">
            Pour obtenir le badge de confiance <span className="font-bold text-emerald-600">Vérifié ✅</span> dans notre annuaire européen, veuillez nous fournir une copie de votre carte d'identité ou justificatif d'activité professionnelle. Notre équipe validera votre dossier sous 24 heures.
          </p>

          {user.verificationStatus === "verified" ? (
            <div className="p-4 bg-emerald-50/50 border border-emerald-100 rounded-2xl text-emerald-800 text-xs font-semibold flex items-center gap-2.5">
              <span className="text-lg">🎉</span>
              <div>
                <p className="font-bold">Votre profil pro est validé !</p>
                <p className="text-emerald-600/80 font-medium text-[11px] mt-0.5">Le badge Vérifié est désormais visible sur toutes vos fiches de l'annuaire.</p>
              </div>
            </div>
          ) : user.verificationStatus === "pending" ? (
            <div className="p-4 bg-amber-50 border border-amber-150 rounded-2xl text-amber-800 text-xs font-semibold space-y-2">
              <div className="flex items-center gap-2">
                <span className="animate-spin text-sm">⏳</span>
                <p className="font-bold">Demande de vérification en cours d'examen</p>
              </div>
              <p className="text-amber-700 font-medium text-[11px] leading-relaxed">
                Justificatif envoyé : <span className="font-mono underline">{user.verificationDocName}</span>.<br/>
                Vous pouvez vous connecter à un <span className="font-bold text-[#5C131E]">compte Administrateur</span> depuis l'écran d'accueil pour valider instantanément cette demande à des fins de test !
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Drag-and-drop file drop zone simulator */}
              <div
                onDragEnter={handleDrag}
                onDragOver={handleDrag}
                onDragLeave={handleDrag}
                onDrop={handleDrop}
                className={`border-2 border-dashed rounded-2xl p-6 text-center transition-all relative ${
                  dragActive
                    ? "border-[#0C3823] bg-[#0C3823]/5"
                    : selectedFileName
                    ? "border-green-300 bg-green-50/10"
                    : "border-stone-200 bg-stone-50 hover:bg-stone-100/50"
                }`}
              >
                <input
                  type="file"
                  id="file-upload-input"
                  onChange={handleFileSelect}
                  className="hidden"
                  accept=".pdf,.png,.jpg,.jpeg"
                />

                <label htmlFor="file-upload-input" className="cursor-pointer flex flex-col items-center gap-2">
                  <div className="p-2.5 bg-white rounded-full shadow-sm text-stone-400">
                    <Upload className="w-5 h-5" />
                  </div>
                  
                  {selectedFileName ? (
                    <div>
                      <p className="text-xs font-bold text-stone-800">{selectedFileName}</p>
                      <p className="text-[10px] text-green-600 font-bold mt-1">Fichier sélectionné avec succès</p>
                    </div>
                  ) : (
                    <div>
                      <p className="text-xs font-bold text-stone-800">Faites glisser votre justificatif ici ou cliquez pour choisir</p>
                      <p className="text-[10px] text-stone-400 mt-1">Formats acceptés : PDF, PNG, JPG (Max 5Mo)</p>
                    </div>
                  )}
                </label>
              </div>

              {selectedFileName && (
                <button
                  type="button"
                  onClick={submitVerification}
                  disabled={uploading}
                  className="w-full py-3 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-extrabold text-xs uppercase rounded-xl tracking-wider transition-all flex items-center justify-center gap-2 shadow-md shadow-[#0C3823]/10"
                >
                  {uploading ? (
                    <div className="w-4 h-4 border-2 border-[#D4AF37] border-t-transparent rounded-full animate-spin" />
                  ) : (
                    "Soumettre le dossier à l'administration"
                  )}
                </button>
              )}
            </div>
          )}

        </div>
      )}

    </div>
  );
}
