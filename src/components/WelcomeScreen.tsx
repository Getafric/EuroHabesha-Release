import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { translations, SupportedLanguage } from "../translations";
import { UserRole } from "../types";
import { Check, Shield, User, Briefcase, Phone, MessageSquare, Key } from "lucide-react";
import BrandLogo from "./BrandLogo";

interface WelcomeScreenProps {
  onAuthSuccess: (user: any, selectedLanguage: SupportedLanguage) => void;
}

const COUNTRIES = [
  { name: "France", code: "FR", prefix: "+33", flag: "🇫🇷" },
  { name: "Belgique", code: "BE", prefix: "+32", flag: "🇧🇪" },
  { name: "Allemagne", code: "DE", prefix: "+49", flag: "🇩🇪" },
  { name: "Italie", code: "IT", prefix: "+39", flag: "🇮🇹" },
  { name: "Suisse", code: "CH", prefix: "+41", flag: "🇨🇭" },
  { name: "Royaume-Uni", code: "GB", prefix: "+44", flag: "🇬🇧" },
  { name: "Pays-Bas", code: "NL", prefix: "+31", flag: "🇳🇱" },
  { name: "Espagne", code: "ES", prefix: "+34", flag: "🇪🇸" },
  { name: "Suède", code: "SE", prefix: "+46", flag: "🇸🇪" },
  { name: "Norvège", code: "NO", prefix: "+47", flag: "🇳🇴" },
];

const LANGUAGES = [
  { id: "fr", name: "Français", native: "Français" },
  { id: "en", name: "English", native: "English" },
  { id: "am", name: "Amharique", native: "አማርኛ" },
  { id: "ti", name: "Tigrinya", native: "ትግርኛ" },
  { id: "de", name: "Deutsch", native: "Deutsch" },
  { id: "it", name: "Italiano", native: "Italiano" },
  { id: "es", name: "Español", native: "Español" },
  { id: "nl", name: "Nederlands", native: "Nederlands" },
];

export default function WelcomeScreen({ onAuthSuccess }: WelcomeScreenProps) {
  const [lang, setLang] = useState<SupportedLanguage>("fr");
  const [isLogin, setIsLogin] = useState(true);
  
  // Registration Form State
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [selectedCountry, setSelectedCountry] = useState(COUNTRIES[0]);
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [role, setRole] = useState<UserRole>("user");
  const [userLangs, setUserLangs] = useState<string[]>(["fr"]);
  
  // Login Form State
  const [loginPhone, setLoginPhone] = useState("");
  const [loginPassword, setLoginPassword] = useState("");
  
  // OTP State
  const [showOtp, setShowOtp] = useState(false);
  const [otpCode, setOtpCode] = useState("");
  const [generatedOtp, setGeneratedOtp] = useState("");
  const [otpNotification, setOtpNotification] = useState<string | null>(null);

  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // Quick tests accounts
  const handleQuickLogin = async (roleType: 'admin' | 'professional' | 'user') => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch("/api/data");
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const contentType = response.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        throw new Error("La réponse du serveur n'est pas au format JSON valide.");
      }
      const data = await response.json();
      
      let targetUser = null;
      if (roleType === 'admin') {
        targetUser = data.users.find((u: any) => u.role === 'admin');
      } else if (roleType === 'professional') {
        targetUser = data.users.find((u: any) => u.role === 'professional');
      } else {
        targetUser = data.users.find((u: any) => u.role === 'user');
      }

      if (targetUser) {
        onAuthSuccess(targetUser, lang);
      } else {
        setError("Compte de test non trouvé.");
      }
    } catch (e: any) {
      console.warn("Quick login failed:", e?.message || e);
      setError("Erreur de connexion au serveur. Veuillez réessayer.");
    } finally {
      setLoading(false);
    }
  };

  const toggleLanguageSelection = (selected: string) => {
    if (userLangs.includes(selected)) {
      setUserLangs(userLangs.filter(l => l !== selected));
    } else {
      setUserLangs([...userLangs, selected]);
    }
  };

  const handleCountryChange = (countryName: string) => {
    const found = COUNTRIES.find(c => c.name === countryName);
    if (found) {
      setSelectedCountry(found);
    }
  };

  const initiateRegistration = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!name || !phone || !password || !confirmPassword) {
      setError("Veuillez remplir tous les champs.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Les mots de passe ne correspondent pas.");
      return;
    }

    if (userLangs.length === 0) {
      setError("Veuillez choisir au moins une langue parlée.");
      return;
    }

    // Generate random 4-digit OTP
    const code = Math.floor(1000 + Math.random() * 9000).toString();
    setGeneratedOtp(code);
    setShowOtp(true);
    
    // Simulate SMS delivery notification
    setTimeout(() => {
      setOtpNotification(`💬 EuroHabesha OTP: Votre code est ${code}`);
    }, 1200);
  };

  const handleOtpKeypress = (num: string) => {
    if (otpCode.length < 4) {
      setOtpCode(prev => prev + num);
    }
  };

  const handleOtpBackspace = () => {
    setOtpCode(prev => prev.slice(0, -1));
  };

  const verifyOtpAndSubmit = async () => {
    if (otpCode !== generatedOtp) {
      setError("Code OTP incorrect.");
      return;
    }

    setLoading(true);
    setError(null);

    const fullPhone = selectedCountry.prefix + phone.replace(/^0+/, "");

    try {
      const res = await fetch("/api/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          phone: fullPhone,
          country: selectedCountry.name,
          prefix: selectedCountry.prefix,
          languages: userLangs,
          role,
          password
        })
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || "Erreur d'inscription.");
      }

      setShowOtp(false);
      onAuthSuccess(data.user, lang);
    } catch (err: any) {
      setError(err.message);
      setShowOtp(false);
    } finally {
      setLoading(false);
    }
  };

  const handleLoginSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!loginPhone || !loginPassword) {
      setError("Veuillez remplir tous les champs.");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          phone: loginPhone,
          password: loginPassword
        })
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || "Identifiants incorrects.");
      }

      onAuthSuccess(data.user, lang);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const t = translations[lang];

  return (
    <div id="auth_screen" className="min-h-screen bg-slate-50 flex flex-col justify-center items-center p-4">
      
      {/* Simulation OTP floating Banner */}
      <AnimatePresence>
        {otpNotification && (
          <motion.div
            initial={{ y: -60, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -60, opacity: 0 }}
            onClick={() => setOtpNotification(null)}
            className="fixed top-4 left-4 right-4 md:max-w-md md:mx-auto bg-stone-900 text-stone-100 px-5 py-4 rounded-2xl shadow-2xl border border-stone-800 flex items-center gap-3 z-50 cursor-pointer"
          >
            <div className="w-2.5 h-2.5 rounded-full bg-[#D4AF37] animate-ping" />
            <div className="flex-1 text-xs">
              <p className="font-bold text-[#D4AF37] mb-0.5 font-mono">SMS Notification</p>
              <p className="font-mono text-stone-300 tracking-wide text-[11px]">{otpNotification}</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <div className="max-w-md w-full bg-white rounded-3xl p-6 border border-stone-100 shadow-xl relative overflow-hidden">
        
        {/* Main Branding Header */}
        <div className="absolute top-4 right-4 flex items-center gap-1">
          <span className="text-[10px] text-stone-400">🌐</span>
          <select
            value={lang}
            onChange={(e) => setLang(e.target.value as SupportedLanguage)}
            className="bg-transparent text-xs font-semibold text-stone-500 hover:text-[#0C3823] focus:outline-none cursor-pointer border-none p-0"
          >
            {LANGUAGES.map(l => (
              <option key={l.id} value={l.id} className="text-stone-800 bg-white">
                {l.native}
              </option>
            ))}
          </select>
        </div>

        {/* Main Branding Header */}
        <div className="text-center mt-4 mb-6 flex flex-col items-center">
          <BrandLogo className="w-24 h-24 mb-3" showText={false} />
          <h1 className="text-3xl font-black tracking-tight font-brand flex items-center justify-center gap-1">
            <span className="text-[#0C3823]">EURO</span>
            <span className="text-[#D4AF37]">Habesha</span>
          </h1>
          <span className="text-[9px] font-unique font-bold uppercase tracking-[0.25em] text-emerald-600 mt-1 leading-none">
            Diaspora Link
          </span>
          <p className="text-[11px] text-stone-400 font-medium italic mt-2.5 px-4 leading-tight">
            {t.slogan}
          </p>
        </div>

        {/* Errors Box */}
        {error && (
          <div className="mb-4 p-3 rounded-xl bg-red-50 border border-red-100 text-red-700 text-xs font-semibold text-center leading-normal">
            ⚠️ {error}
          </div>
        )}

        {/* OPT VERIFICATION POPUP/SCREEN INSIDE CONTAINER */}
        <AnimatePresence>
          {showOtp ? (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="flex flex-col items-center"
            >
              <div className="w-12 h-12 rounded-full bg-amber-50 flex items-center justify-center mb-4 text-[#D4AF37]">
                <Shield className="w-6 h-6" />
              </div>
              
              <h3 className="text-lg font-bold text-stone-900 mb-1">{t.otpCode}</h3>
              <p className="text-xs text-stone-500 text-center mb-6 px-4">
                {t.verifyOtp}
              </p>

              {/* OTP Dots Code Display */}
              <div className="flex gap-4 mb-8">
                {[0, 1, 2, 3].map((idx) => (
                  <div
                    key={idx}
                    className={`w-12 h-14 rounded-2xl border-2 flex items-center justify-center text-xl font-black font-mono transition-all ${
                      otpCode[idx]
                        ? "border-[#0C3823] bg-[#0C3823]/5 text-stone-800"
                        : "border-stone-200 bg-stone-50 text-stone-400"
                    }`}
                  >
                    {otpCode[idx] ? otpCode[idx] : ""}
                  </div>
                ))}
              </div>

              {/* Custom Numeric Phone Keypad for high-fidelity interactive feeling */}
              <div className="grid grid-cols-3 gap-3 w-full max-w-[280px] mb-6">
                {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((num) => (
                  <button
                    key={num}
                    type="button"
                    onClick={() => handleOtpKeypress(num)}
                    className="h-12 rounded-xl bg-stone-50 hover:bg-stone-100 active:bg-stone-200 text-stone-800 font-bold transition-colors font-mono"
                  >
                    {num}
                  </button>
                ))}
                <button
                  type="button"
                  onClick={() => setOtpCode("")}
                  className="h-12 rounded-xl text-stone-400 text-xs font-semibold uppercase hover:bg-stone-50"
                >
                  Clear
                </button>
                <button
                  type="button"
                  onClick={() => handleOtpKeypress("0")}
                  className="h-12 rounded-xl bg-stone-50 hover:bg-stone-100 active:bg-stone-200 text-stone-800 font-bold transition-colors font-mono"
                >
                  0
                </button>
                <button
                  type="button"
                  onClick={handleOtpBackspace}
                  className="h-12 rounded-xl text-stone-500 hover:bg-stone-50 flex items-center justify-center text-sm"
                >
                  ⌫
                </button>
              </div>

              <div className="flex gap-3 w-full">
                <button
                  type="button"
                  onClick={() => setShowOtp(false)}
                  className="flex-1 py-3.5 rounded-2xl bg-stone-100 hover:bg-stone-200 text-stone-600 font-bold text-xs tracking-wider uppercase transition-colors"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  disabled={otpCode.length < 4 || loading}
                  onClick={verifyOtpAndSubmit}
                  className="flex-1 py-3.5 rounded-2xl bg-[#0C3823] hover:bg-[#09291a] text-white font-bold text-xs tracking-wider uppercase transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {loading ? (
                    <div className="w-4 h-4 rounded-full border-2 border-white border-t-transparent animate-spin" />
                  ) : (
                    t.submit
                  )}
                </button>
              </div>
            </motion.div>
          ) : (
            <>
              {/* TOGGLE TABS */}
              <div className="flex bg-stone-50 rounded-2xl p-1 mb-6 border border-stone-100">
                <button
                  onClick={() => {
                    setIsLogin(true);
                    setError(null);
                  }}
                  className={`flex-1 py-3 text-xs font-bold rounded-xl transition-all ${
                    isLogin ? "bg-white text-[#0C3823] shadow-sm" : "text-stone-400 hover:text-stone-600"
                  }`}
                >
                  {t.signin}
                </button>
                <button
                  onClick={() => {
                    setIsLogin(false);
                    setError(null);
                  }}
                  className={`flex-1 py-3 text-xs font-bold rounded-xl transition-all ${
                    !isLogin ? "bg-white text-[#0C3823] shadow-sm" : "text-stone-400 hover:text-stone-600"
                  }`}
                >
                  {t.signup}
                </button>
              </div>

              {/* LOGIN FORM */}
              {isLogin ? (
                <form onSubmit={handleLoginSubmit} className="space-y-4">
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5 flex items-center gap-1.5">
                      <Phone className="w-3.5 h-3.5 text-stone-400" />
                      {t.enterPhone}
                    </label>
                    <input
                      type="text"
                      placeholder="Ex: +33612345678"
                      value={loginPhone}
                      onChange={(e) => setLoginPhone(e.target.value)}
                      className="w-full px-4 py-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 text-sm focus:outline-none focus:border-[#0C3823] font-mono"
                    />
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5 flex items-center gap-1.5">
                      <Key className="w-3.5 h-3.5 text-stone-400" />
                      {t.enterPassword}
                    </label>
                    <input
                      type="password"
                      placeholder="••••••••"
                      value={loginPassword}
                      onChange={(e) => setLoginPassword(e.target.value)}
                      className="w-full px-4 py-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 text-sm focus:outline-none focus:border-[#0C3823]"
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full py-3.5 rounded-2xl bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-extrabold text-xs tracking-wider uppercase transition-colors flex items-center justify-center gap-2 shadow-lg shadow-[#0C3823]/10"
                  >
                    {loading ? (
                      <div className="w-4 h-4 rounded-full border-2 border-[#D4AF37] border-t-transparent animate-spin" />
                    ) : (
                      t.signin
                    )}
                  </button>
                </form>
              ) : (
                /* REGISTRATION FORM */
                <form onSubmit={initiateRegistration} className="space-y-4">
                  
                  {/* Country Selection -> Phone prefix added automatically */}
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                        {t.chooseCountry}
                      </label>
                      <select
                        value={selectedCountry.name}
                        onChange={(e) => handleCountryChange(e.target.value)}
                        className="w-full px-3 py-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 text-xs focus:outline-none focus:border-[#0C3823] font-medium"
                      >
                        {COUNTRIES.map(c => (
                          <option key={c.code} value={c.name}>
                            {c.flag} {c.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                        {t.phonePrefix}
                      </label>
                      <div className="w-full px-3 py-3 bg-stone-100 rounded-xl border border-stone-200 text-stone-600 text-xs font-mono font-bold flex items-center">
                        📞 {selectedCountry.prefix}
                      </div>
                    </div>
                  </div>

                  {/* Name */}
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                      {t.enterName}
                    </label>
                    <input
                      type="text"
                      placeholder="Selam Tekle"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="w-full px-4 py-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 text-xs focus:outline-none focus:border-[#0C3823]"
                    />
                  </div>

                  {/* Phone */}
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                      {t.enterPhone}
                    </label>
                    <div className="flex items-center">
                      <span className="bg-stone-100 border-y border-l border-stone-200 px-3 py-3 rounded-l-xl text-xs text-stone-500 font-mono font-bold">
                        {selectedCountry.prefix}
                      </span>
                      <input
                        type="tel"
                        placeholder="612345678"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        className="flex-1 px-4 py-3 bg-stone-50 rounded-r-xl border border-stone-200 text-stone-800 text-xs focus:outline-none focus:border-[#0C3823] font-mono"
                      />
                    </div>
                  </div>

                  {/* Role Selection */}
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                      Type de compte
                    </label>
                    <div className="grid grid-cols-2 gap-3">
                      <button
                        type="button"
                        onClick={() => setRole("user")}
                        className={`p-3 rounded-xl border text-center flex flex-col items-center justify-center gap-1 transition-all ${
                          role === "user"
                            ? "border-[#0C3823] bg-[#0C3823]/5 text-[#0C3823]"
                            : "border-stone-200 bg-stone-50 text-stone-500 hover:bg-stone-100"
                        }`}
                      >
                        <User className="w-4 h-4" />
                        <span className="text-[10px] font-bold uppercase tracking-wider">Particulier</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setRole("professional")}
                        className={`p-3 rounded-xl border text-center flex flex-col items-center justify-center gap-1 transition-all ${
                          role === "professional"
                            ? "border-[#0C3823] bg-[#0C3823]/5 text-[#0C3823]"
                            : "border-stone-200 bg-stone-50 text-stone-500 hover:bg-stone-100"
                        }`}
                      >
                        <Briefcase className="w-4 h-4" />
                        <span className="text-[10px] font-bold uppercase tracking-wider">Professionnel</span>
                      </button>
                    </div>
                  </div>

                  {/* Languages Selector */}
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                      {t.languages} (Multi-select)
                    </label>
                    <div className="flex flex-wrap gap-1.5 bg-stone-50 p-2.5 rounded-xl border border-stone-200 max-h-24 overflow-y-auto">
                      {LANGUAGES.map(l => {
                        const isSel = userLangs.includes(l.id);
                        return (
                          <button
                            key={l.id}
                            type="button"
                            onClick={() => toggleLanguageSelection(l.id)}
                            className={`px-2.5 py-1 rounded-lg text-[10px] font-bold transition-all flex items-center gap-1 ${
                              isSel
                                ? "bg-[#0C3823] text-white"
                                : "bg-white text-stone-600 border border-stone-200 hover:bg-stone-100"
                            }`}
                          >
                            {l.native}
                            {isSel && <Check className="w-3 h-3 text-[#D4AF37]" />}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  {/* Passwords */}
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                        {t.enterPassword}
                      </label>
                      <input
                        type="password"
                        placeholder="••••••"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="w-full px-3 py-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 text-xs focus:outline-none focus:border-[#0C3823]"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                        {t.confirmPassword}
                      </label>
                      <input
                        type="password"
                        placeholder="••••••"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        className="w-full px-3 py-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 text-xs focus:outline-none focus:border-[#0C3823]"
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="w-full py-3.5 rounded-2xl bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-extrabold text-xs tracking-wider uppercase transition-colors flex items-center justify-center gap-2"
                  >
                    {t.signup}
                  </button>
                </form>
              )}
            </>
          )}
        </AnimatePresence>

        {/* MOCK ACCOUNTS AUTO-LOGIN FOR EASY TESTING */}
        <div className="mt-8 pt-6 border-t border-stone-100">
          <span className="block text-[9px] font-black uppercase tracking-widest text-stone-400 text-center mb-3">
            Accès d'essai rapide (Testing shortcuts)
          </span>
          <div className="grid grid-cols-3 gap-2">
            <button
              onClick={() => handleQuickLogin("admin")}
              className="px-2 py-2 bg-stone-100 hover:bg-[#5C131E] hover:text-white rounded-xl text-[10px] font-bold transition-all text-center flex flex-col items-center gap-1 text-stone-700"
            >
              <Shield className="w-3.5 h-3.5" />
              <span>Admin</span>
            </button>
            <button
              onClick={() => handleQuickLogin("professional")}
              className="px-2 py-2 bg-stone-100 hover:bg-[#0C3823] hover:text-[#D4AF37] rounded-xl text-[10px] font-bold transition-all text-center flex flex-col items-center gap-1 text-stone-700"
            >
              <Briefcase className="w-3.5 h-3.5" />
              <span>Pro (Vérifié)</span>
            </button>
            <button
              onClick={() => handleQuickLogin("user")}
              className="px-2 py-2 bg-stone-100 hover:bg-stone-200 rounded-xl text-[10px] font-bold transition-all text-center flex flex-col items-center gap-1 text-stone-700"
            >
              <User className="w-3.5 h-3.5" />
              <span>Membre</span>
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
