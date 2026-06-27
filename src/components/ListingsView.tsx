import React, { useState } from "react";
import { Listing, User } from "../types";
import { SupportedLanguage, translations } from "../translations";
import { Search, MapPin, Phone, MessageSquare, Plus, Check, Languages, HelpCircle, Briefcase, Calendar, ShoppingBag, Sparkles, Filter, ShieldAlert, Heart } from "lucide-react";

interface ListingsViewProps {
  type: "job" | "marketplace" | "event" | "professional";
  listings: Listing[];
  currentUser: User;
  language: SupportedLanguage;
  onRefresh: () => void;
  onStartPrivateChat?: (recipientId: string, recipientName: string) => void;
  selectedCategory?: string;
  onCategoryChange?: (category: string) => void;
}

// Category lists based on mockup requirements
export const JOB_CATEGORIES = [
  "Électricité / Electrical",
  "Lavage auto / Car Wash",
  "Mécanique / Car Mécanicien",
  "Peinture / Color Paint",
  "Photo & Vidéo / Photographer & Videographer",
  "Traduction / Translater",
  "DJ",
  "Service Traiteur / Catering",
  "Médecine / Doctoring",
  "Chauffeur / Driver",
  "Déménagement",
  "Coiffeur / Hair Stylist",
  "ጠበቃ (Avocat / Lawyer)",
  "Chef",
  "Caregiver",
  "Management",
  "Autre"
];

const MARKETPLACE_CATEGORIES = [
  "Apparel", "Art", "Food", "Home"
];

const EVENT_CATEGORIES = [
  "Cultural", "Music", "Social", "Tradition"
];

const COUNTRIES = ["France", "Belgique", "Allemagne", "Italie", "Suisse", "Royaume-Uni", "Pays-Bas", "Espagne", "Suède", "Norvège"];

const LANGUAGES_LIST = [
  { code: "fr", label: "Français" },
  { code: "en", label: "English" },
  { code: "am", label: "አማርኛ" },
  { code: "ti", label: "ትግርኛ" },
  { code: "de", label: "Deutsch" },
  { code: "it", label: "Italiano" },
  { code: "es", label: "Español" },
  { code: "nl", label: "Nederlands" }
];

// High-fidelity vector illustrations depicting traditional Habesha items
export function CulturalGraphic({ name, className = "w-full h-44" }: { name: string; className?: string }) {
  if (name === "gabi") {
    return (
      <svg className={className} viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="200" height="160" rx="20" fill="#F4F2EC"/>
        <path d="M40 30 C 70 25, 130 25, 160 30 L 160 130 C 130 135, 70 135, 40 130 Z" fill="#FFFFFF" stroke="#E1DED5" strokeWidth="2"/>
        <path d="M60 30 C 80 27, 120 27, 140 30 L 140 130 C 120 133, 80 133, 60 130 Z" fill="#FBFBFA" />
        <line x1="50" y1="110" x2="150" y2="110" stroke="#D4AF37" strokeWidth="6" />
        <line x1="50" y1="115" x2="150" y2="115" stroke="#0C3823" strokeWidth="3" />
        <line x1="50" y1="105" x2="150" y2="105" stroke="#5C131E" strokeWidth="3" />
        <path d="M50 120 L50 128 M60 120 L60 128 M70 120 L70 128 M80 120 L80 128 M90 120 L90 128 M100 120 L100 128 M110 120 L110 128 M120 120 L120 128 M130 120 L130 128 M140 120 L140 128 M150 120 L150 128" stroke="#D4AF37" strokeWidth="2" strokeLinecap="round"/>
        <rect x="75" y="45" width="50" height="15" rx="4" fill="#0C3823" fillOpacity="0.1" />
        <text x="100" y="55" fill="#0C3823" fontSize="8" fontWeight="bold" textAnchor="middle">100% COTTON</text>
      </svg>
    );
  }
  if (name === "buna") {
    return (
      <svg className={className} viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="200" height="160" rx="20" fill="#F4F2EC"/>
        <ellipse cx="100" cy="135" rx="60" ry="12" fill="#E1DED5"/>
        <rect x="50" y="125" width="100" height="8" rx="2" fill="#D4AF37"/>
        <circle cx="100" cy="100" r="24" fill="#3D2B1F" stroke="#2B1E16" strokeWidth="1.5"/>
        <path d="M92 76 L94 45 L106 45 L108 76 Z" fill="#3D2B1F" stroke="#2B1E16" strokeWidth="1.5"/>
        <path d="M106 55 L122 62 L120 66 L106 59 Z" fill="#3D2B1F" stroke="#2B1E16" strokeWidth="1.5"/>
        <path d="M92 60 C 72 65, 72 95, 90 100" fill="none" stroke="#3D2B1F" strokeWidth="4" strokeLinecap="round"/>
        <path d="M135 120 L145 120 L147 112 L133 112 Z" fill="#FFFFFF" stroke="#0C3823" strokeWidth="1"/>
        <ellipse cx="140" cy="112" rx="7" ry="2" fill="#FFFFFF" stroke="#0C3823" strokeWidth="1"/>
        <line x1="135" y1="116" x2="145" y2="116" stroke="#5C131E" strokeWidth="1"/>
        <path d="M65 120 L75 120 L77 112 L63 112 Z" fill="#FFFFFF" stroke="#0C3823" strokeWidth="1"/>
        <ellipse cx="70" cy="112" rx="7" ry="2" fill="#FFFFFF" stroke="#0C3823" strokeWidth="1"/>
        <line x1="65" y1="116" x2="75" y2="116" stroke="#D4AF37" strokeWidth="1"/>
        <path d="M98 35 Q 94 25, 98 15 T 98 5" fill="none" stroke="#D4AF37" strokeWidth="2" strokeLinecap="round" opacity="0.6"/>
        <path d="M104 38 Q 100 28, 104 18 T 104 8" fill="none" stroke="#D4AF37" strokeWidth="2" strokeLinecap="round" opacity="0.4"/>
      </svg>
    );
  }
  if (name === "mesob") {
    return (
      <svg className={className} viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="200" height="160" rx="20" fill="#F4F2EC"/>
        <ellipse cx="100" cy="142" rx="50" ry="10" fill="#E1DED5"/>
        <path d="M70 95 L75 135 C 75 140, 125 140, 125 135 L130 95 Z" fill="#D4AF37" stroke="#9A7B1C" strokeWidth="1.5"/>
        <path d="M72 105 L80 115 L90 105 L100 115 L110 105 L120 115 L128 105" fill="none" stroke="#5C131E" strokeWidth="2.5" strokeLinecap="round"/>
        <path d="M73 115 L81 125 L91 115 L101 125 L111 115 L121 125 L127 115" fill="none" stroke="#0C3823" strokeWidth="2.5" strokeLinecap="round"/>
        <path d="M60 70 C 60 95, 140 95, 140 70 L145 55 C 145 50, 55 50, 55 55 Z" fill="#D4AF37" stroke="#9A7B1C" strokeWidth="1.5"/>
        <path d="M58 62 L68 72 L78 62 L88 72 L98 62 L108 72 L118 62 L128 72 L138 62" fill="none" stroke="#0C3823" strokeWidth="2" strokeLinecap="round"/>
        <path d="M62 55 L72 65 L82 55 L92 65 L102 55 L112 65 L122 55 L132 65 L142 55" fill="none" stroke="#5C131E" strokeWidth="2" strokeLinecap="round"/>
        <path d="M100 15 L58 55 C 58 58, 142 58, 142 55 Z" fill="#D4AF37" stroke="#9A7B1C" strokeWidth="1.5"/>
        <path d="M70 45 L100 15 L130 45" fill="none" stroke="#5C131E" strokeWidth="3" strokeLinecap="round"/>
        <path d="M80 48 L100 28 L120 48" fill="none" stroke="#0C3823" strokeWidth="3" strokeLinecap="round"/>
        <circle cx="100" cy="12" r="5" fill="#5C131E" stroke="#D4AF37" strokeWidth="1"/>
      </svg>
    );
  }
  if (name === "artwork") {
    return (
      <svg className={className} viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="200" height="160" rx="20" fill="#F4F2EC"/>
        <rect x="35" y="20" width="130" height="120" rx="4" fill="#3D2B1F" stroke="#D4AF37" strokeWidth="4"/>
        <rect x="43" y="28" width="114" height="104" fill="#EAE5D9"/>
        <path d="M43 28 L157 110 L157 132 L43 132 Z" fill="#0C3823" fillOpacity="0.15"/>
        <path d="M43 28 L157 28 L157 90 Z" fill="#D4AF37" fillOpacity="0.2"/>
        <path d="M100 50 C 110 50, 115 58, 115 65 C 115 75, 100 85, 100 90 C 100 85, 85 75, 85 65 C 85 58, 90 50, 100 50 Z" fill="#2B1E16"/>
        <path d="M100 90 L85 125 L115 125 Z" fill="#FFFFFF" stroke="#5C131E" strokeWidth="1.5"/>
        <ellipse cx="100" cy="92" rx="8" ry="3" fill="none" stroke="#D4AF37" strokeWidth="2"/>
        <path d="M85 100 C 95 102, 105 102, 115 100" fill="none" stroke="#D4AF37" strokeWidth="3"/>
        <circle cx="130" cy="45" r="8" fill="#D4AF37" fillOpacity="0.8"/>
        <line x1="130" y1="33" x2="130" y2="57" stroke="#D4AF37" strokeWidth="1" />
        <line x1="118" y1="45" x2="142" y2="45" stroke="#D4AF37" strokeWidth="1" />
      </svg>
    );
  }
  if (name === "timket" || name === "event") {
    return (
      <svg className={className} viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="200" height="160" rx="20" fill="#F4F2EC"/>
        <rect x="20" y="20" width="160" height="120" rx="10" fill="url(#skyGradient)"/>
        <path d="M100 35 L100 115 M80 55 L120 55 M85 90 L115 90" stroke="#D4AF37" strokeWidth="6" strokeLinecap="round"/>
        <path d="M100 40 L100 110 M85 55 L115 55 M90 90 L110 90" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round"/>
        <circle cx="100" cy="55" r="4" fill="#5C131E"/>
        <circle cx="100" cy="90" r="3" fill="#0C3823"/>
        <circle cx="50" cy="50" r="2" fill="#D4AF37"/>
        <circle cx="150" cy="60" r="3" fill="#D4AF37"/>
        <circle cx="140" cy="110" r="2.5" fill="#D4AF37"/>
        <circle cx="60" cy="100" r="2" fill="#D4AF37"/>
        <defs>
          <linearGradient id="skyGradient" x1="100" y1="20" x2="100" y2="140" gradientUnits="userSpaceOnUse">
            <stop stopColor="#0C3823" />
            <stop offset="1" stopColor="#1E5C3D" />
          </linearGradient>
        </defs>
      </svg>
    );
  }
  return (
    <div className={`${className} bg-stone-100 rounded-3xl flex items-center justify-center`}>
      <ShoppingBag className="w-8 h-8 text-[#0C3823]/30" />
    </div>
  );
}

const PROFESSIONAL_CATEGORIES = [
  "Médecins", "Pharmacies", "Avocats", "Traducteurs", "Comptables", 
  "Restaurants", "Cafés", "Églises", "Associations", 
  "Agences de voyage", "Garages", "Salons de coiffure"
];

export default function ListingsView({ 
  type, 
  listings, 
  currentUser, 
  language, 
  onRefresh, 
  onStartPrivateChat,
  selectedCategory: outerSelectedCategory,
  onCategoryChange: outerOnCategoryChange
}: ListingsViewProps) {
  const t = translations[language];

  // Interactive UI states for favorites, cart, and feedback toast
  const [toast, setToast] = useState<string | null>(null);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [cart, setCart] = useState<string[]>([]);

  // Reviews system states
  const [activeReviewListing, setActiveReviewListing] = useState<Listing | null>(null);
  const [newReviewRating, setNewReviewRating] = useState<number>(5);
  const [newReviewComment, setNewReviewComment] = useState("");
  const [submittingReview, setSubmittingReview] = useState(false);

  const triggerToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => {
      setToast(null);
    }, 2500);
  };

  // Search & Filters
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCountry, setSelectedCountry] = useState("");
  const [selectedCity, setSelectedCity] = useState("");
  const [selectedCategoryState, setSelectedCategoryState] = useState("");
  
  const selectedCategory = outerSelectedCategory !== undefined ? outerSelectedCategory : selectedCategoryState;
  const setSelectedCategory = (cat: string) => {
    setSelectedCategoryState(cat);
    if (outerOnCategoryChange) {
      outerOnCategoryChange(cat);
    }
  };

  const [selectedLanguage, setSelectedLanguage] = useState("");
  
  // AI Smart Search states
  const [isAiSearching, setIsAiSearching] = useState(false);
  const [aiSearchExplanation, setAiSearchExplanation] = useState<string | null>(null);
  const [aiMatchedIds, setAiMatchedIds] = useState<string[] | null>(null);

  // Form Submission
  const [showAddForm, setShowAddForm] = useState(false);
  const [formCategory, setFormCategory] = useState("");
  const [formTitle, setFormTitle] = useState("");
  const [formDescription, setFormDescription] = useState("");
  const [formPrice, setFormPrice] = useState("");
  const [formDate, setFormDate] = useState("");
  const [formCity, setFormCity] = useState("");
  const [formCountry, setFormCountry] = useState(currentUser.country);
  const [formExperience, setFormExperience] = useState("");
  const [formSpokenLangs, setFormSpokenLangs] = useState<string[]>(currentUser.languages);
  const [formPhone, setFormPhone] = useState(currentUser.phone || "Secure Chat");
  const [formWhatsapp, setFormWhatsapp] = useState(currentUser.phone || "Secure Chat");

  const [formLoading, setFormLoading] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [formSuccess, setFormSuccess] = useState(false);

  const getCategories = () => {
    switch (type) {
      case "job": return JOB_CATEGORIES;
      case "marketplace": return MARKETPLACE_CATEGORIES;
      case "event": return EVENT_CATEGORIES;
      case "professional": return PROFESSIONAL_CATEGORIES;
    }
  };

  const resetForm = () => {
    setFormCategory("");
    setFormTitle("");
    setFormDescription("");
    setFormPrice("");
    setFormDate("");
    setFormCity("");
    setFormExperience("");
    setFormSpokenLangs(currentUser.languages);
    setFormPhone(currentUser.phone || "Secure Chat");
    setFormWhatsapp(currentUser.phone || "Secure Chat");
    setFormError(null);
    setFormSuccess(false);
  };

  const handleCreateListing = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formCategory || !formTitle || !formDescription || !formCity || !formCountry || !formPhone || !formWhatsapp) {
      setFormError("Veuillez remplir tous les champs obligatoires.");
      return;
    }

    setFormLoading(true);
    setFormError(null);

    try {
      const res = await fetch("/api/listings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          type,
          category: formCategory,
          title: formTitle,
          description: formDescription,
          price: type === "marketplace" ? formPrice : undefined,
          date: type === "event" ? formDate : undefined,
          location: { city: formCity, country: formCountry },
          experience: type === "job" ? formExperience : undefined,
          spokenLanguages: formSpokenLangs,
          phone: formPhone,
          whatsapp: formWhatsapp,
          authorId: currentUser.id,
          authorName: currentUser.name,
          isVerified: currentUser.verificationStatus === "verified"
        })
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || "Erreur lors de la création.");
      }

      setFormSuccess(true);
      setTimeout(() => {
        setShowAddForm(false);
        resetForm();
      }, 3000);
      onRefresh();
    } catch (err: any) {
      setFormError(err.message);
    } finally {
      setFormLoading(false);
    }
  };

  const handleAddReview = async (listingId: string) => {
    if (!newReviewComment.trim()) return;
    setSubmittingReview(true);
    try {
      const res = await fetch(`/api/listings/${listingId}/reviews`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          authorId: currentUser.id,
          authorName: currentUser.name,
          rating: newReviewRating,
          comment: newReviewComment
        })
      });

      if (!res.ok) throw new Error("Erreur de publication");
      
      const data = await res.json();
      triggerToast("Avis publié avec succès ! ⭐");
      setNewReviewComment("");
      setNewReviewRating(5);
      
      onRefresh();
      setActiveReviewListing(data.listing);
    } catch (err) {
      console.error("Failed to add review", err);
      triggerToast("Erreur lors de la publication de l'avis");
    } finally {
      setSubmittingReview(false);
    }
  };

  const toggleSpokenLang = (code: string) => {
    if (formSpokenLangs.includes(code)) {
      setFormSpokenLangs(formSpokenLangs.filter(c => c !== code));
    } else {
      setFormSpokenLangs([...formSpokenLangs, code]);
    }
  };

  // Run AI smart search parsing
  const triggerAiSmartSearch = async () => {
    if (!searchQuery.trim()) return;
    setIsAiSearching(true);
    setAiSearchExplanation(null);
    setAiMatchedIds(null);

    // Get active approved listings of the current tab type
    const typedListings = listings.filter(l => l.type === type && l.status === "approved");

    try {
      const res = await fetch("/api/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: searchQuery,
          listings: typedListings
        })
      });

      const data = await res.json();
      if (data.success) {
        setAiMatchedIds(data.matchedIds);
        setAiSearchExplanation(data.explanation);
      } else {
        // Fallback or alert
        setAiSearchExplanation("Désolé, l'analyse intelligente a échoué. Utilisation des filtres standards.");
      }
    } catch (e) {
      setAiSearchExplanation("Erreur de connexion avec l'IA modératrice.");
    } finally {
      setIsAiSearching(false);
    }
  };

  const clearAiSearch = () => {
    setAiSearchExplanation(null);
    setAiMatchedIds(null);
    setSearchQuery("");
  };

  // Filter listings based on standard criteria OR AI matches
  const filteredListings = listings.filter(l => {
    // 1. Must match current section type
    if (l.type !== type) return false;

    // 2. Standard user only sees approved listings. Author can see their own pending/rejected. Admin can see all.
    const isAuthor = l.authorId === currentUser.id;
    const isAdmin = currentUser.role === "admin";
    if (l.status !== "approved" && !isAuthor && !isAdmin) return false;

    // 3. If AI Search results exist, we restrict strictly to matches
    if (aiMatchedIds !== null) {
      return aiMatchedIds.includes(l.id);
    }

    // 4. Standard filters
    if (selectedCountry && l.location.country !== selectedCountry) return false;
    if (selectedCity && !l.location.city.toLowerCase().includes(selectedCity.toLowerCase())) return false;
    if (selectedCategory && l.category !== selectedCategory) return false;
    if (selectedLanguage && l.spokenLanguages && !l.spokenLanguages.includes(selectedLanguage)) return false;

    // Standard Query keyword search matching (case-insensitive)
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      const matchTitle = l.title.toLowerCase().includes(query);
      const matchDesc = l.description.toLowerCase().includes(query);
      const matchCat = l.category.toLowerCase().includes(query);
      const matchCity = l.location.city.toLowerCase().includes(query);
      return matchTitle || matchDesc || matchCat || matchCity;
    }

    return true;
  });

  return (
    <div className="space-y-6">
      
      {/* SECTION BANNER HERO */}
      <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-3.5 bg-[#0C3823]/5 text-[#0C3823] rounded-2xl">
            {type === "job" && <Briefcase className="w-6 h-6" />}
            {type === "marketplace" && <ShoppingBag className="w-6 h-6" />}
            {type === "event" && <Calendar className="w-6 h-6" />}
            {type === "professional" && <MapPin className="w-6 h-6" />}
          </div>
          <div>
            <h1 className="text-xl font-black text-stone-900 tracking-tight">
              {type === "job" && t.navJobs}
              {type === "marketplace" && t.navMarket}
              {type === "event" && t.navEvents}
              {type === "professional" && t.navPro}
            </h1>
            <p className="text-xs text-stone-400">
              {type === "job" && "Trouvez ou proposez des services de proximité au sein de la communauté."}
              {type === "marketplace" && "Achetez, vendez ou louez des objets et véhicules en Europe."}
              {type === "event" && "Découvrez les concerts, soirées, matchs et réunions Habesha."}
              {type === "professional" && "Annuaire des médecins, avocats, églises et commerces vérifiés."}
            </p>
          </div>
        </div>

        {/* Create announcement button (For Jobs, Market, Events; Professionals require admin signup approval) */}
        {type !== "professional" && (
          <button
            onClick={() => {
              resetForm();
              setShowAddForm(!showAddForm);
            }}
            className="px-4 py-3 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-bold text-xs tracking-wider uppercase rounded-2xl transition-all flex items-center gap-2 self-start md:self-center shadow-lg shadow-[#0C3823]/10"
          >
            <Plus className="w-4 h-4" />
            {t.createListing}
          </button>
        )}
      </div>

      {/* FORM TO CREATE LISTING */}
      {showAddForm && (
        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-md relative">
          <div className="absolute top-0 left-0 right-0 h-1 bg-[#D4AF37]" />
          <h2 className="text-sm font-black text-stone-900 mb-4">{t.createListing}</h2>
          
          {formError && (
            <div className="mb-4 p-3 bg-red-50 border border-red-100 text-red-700 text-xs font-semibold rounded-xl">
              ⚠️ {formError}
            </div>
          )}

          {formSuccess ? (
            <div className="p-8 text-center flex flex-col items-center gap-3">
              <div className="w-12 h-12 bg-green-50 text-green-600 rounded-full flex items-center justify-center">
                <Check className="w-6 h-6" />
              </div>
              <h3 className="text-sm font-bold text-stone-800">{t.addSuccess}</h3>
              <p className="text-xs text-stone-500 max-w-xs">{t.addPending}</p>
            </div>
          ) : (
            <form onSubmit={handleCreateListing} className="space-y-4 text-xs">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Category Selector */}
                <div>
                  <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                    Catégorie *
                  </label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium"
                  >
                    <option value="">-- Sélectionner une catégorie --</option>
                    {getCategories()?.map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>

                {/* Title */}
                <div>
                  <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                    Titre de l'annonce *
                  </label>
                  <input
                    type="text"
                    placeholder="Ex: Électricien disponible ce weekend"
                    value={formTitle}
                    onChange={(e) => setFormTitle(e.target.value)}
                    className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium"
                  />
                </div>
              </div>

              {/* Description */}
              <div>
                <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                  Description détaillée *
                </label>
                <textarea
                  rows={4}
                  placeholder="Expliquez clairement votre offre, services, conditions et tarifs..."
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium leading-relaxed"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {/* Price (Marketplace) */}
                {type === "marketplace" && (
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                      {t.price}
                    </label>
                    <input
                      type="text"
                      placeholder="Ex: 50 € ou Location 400 € / mois"
                      value={formPrice}
                      onChange={(e) => setFormPrice(e.target.value)}
                      className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium font-mono"
                    />
                  </div>
                )}

                {/* Date (Event) */}
                {type === "event" && (
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                      {t.date} *
                    </label>
                    <input
                      type="text"
                      placeholder="Ex: Samedi 18 Juillet à 20h00"
                      value={formDate}
                      onChange={(e) => setFormDate(e.target.value)}
                      className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium"
                    />
                  </div>
                )}

                {/* Experience (Job) */}
                {type === "job" && (
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                      {t.experience}
                    </label>
                    <input
                      type="text"
                      placeholder="Ex: 3 ans, Débutant..."
                      value={formExperience}
                      onChange={(e) => setFormExperience(e.target.value)}
                      className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium"
                    />
                  </div>
                )}

                {/* City */}
                <div>
                  <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                    Ville / Code Postal *
                  </label>
                  <input
                    type="text"
                    placeholder="Ex: Paris 15"
                    value={formCity}
                    onChange={(e) => setFormCity(e.target.value)}
                    className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium"
                  />
                </div>

                {/* Country */}
                <div>
                  <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                    {t.filterCountry} *
                  </label>
                  <select
                    value={formCountry}
                    onChange={(e) => setFormCountry(e.target.value)}
                    className="w-full p-3 bg-stone-50 rounded-xl border border-stone-200 text-stone-800 focus:outline-none focus:border-[#0C3823] font-medium"
                  >
                    {COUNTRIES.map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Spoken Languages Selectors */}
              <div>
                <label className="block text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                  {t.languages}
                </label>
                <div className="flex flex-wrap gap-1.5 bg-stone-50 p-2 rounded-xl border border-stone-200">
                  {LANGUAGES_LIST.map(langItem => {
                    const isSel = formSpokenLangs.includes(langItem.code);
                    return (
                      <button
                        key={langItem.code}
                        type="button"
                        onClick={() => toggleSpokenLang(langItem.code)}
                        className={`px-2.5 py-1 rounded-lg text-[10px] font-bold transition-all ${
                          isSel ? "bg-[#0C3823] text-white" : "bg-white text-stone-500 border border-stone-200 hover:bg-stone-100"
                        }`}
                      >
                        {langItem.label}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-stone-100">
                <button
                  type="button"
                  onClick={() => setShowAddForm(false)}
                  className="px-4 py-2.5 bg-stone-100 hover:bg-stone-200 text-stone-600 font-bold rounded-xl uppercase transition-colors"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={formLoading}
                  className="px-5 py-2.5 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-bold rounded-xl uppercase transition-colors flex items-center gap-1.5"
                >
                  {formLoading ? (
                    <div className="w-3.5 h-3.5 border-2 border-[#D4AF37] border-t-transparent rounded-full animate-spin" />
                  ) : (
                    t.publish
                  )}
                </button>
              </div>
            </form>
          )}
        </div>
      )}

      {/* ANIMATED SECULAR HABESHA CATEGORY SELECTOR */}
      <div className="mb-6 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xs font-black text-stone-900 uppercase tracking-widest flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-[#D4AF37] animate-pulse" />
              Catégories de la Communauté
            </h2>
            <p className="text-[10px] text-stone-400">Cliquez pour filtrer les annonces de manière interactive</p>
          </div>
          {selectedCategory && (
            <button
              onClick={() => setSelectedCategory("")}
              className="text-[10px] font-bold text-[#5C131E] hover:underline"
            >
              Réinitialiser le filtre
            </button>
          )}
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {getCategories()?.map(cat => {
            const count = listings.filter(l => l.type === type && l.category === cat && l.status === "approved").length;
            const isSelected = selectedCategory === cat;
            
            // Helper for category custom illustrations
            const getIllustration = (categoryName: string) => {
              const nameLower = categoryName.toLowerCase();
              if (nameLower === "apparel") return <CulturalGraphic name="gabi" className="w-8 h-8 shrink-0 opacity-80" />;
              if (nameLower === "art") return <CulturalGraphic name="artwork" className="w-8 h-8 shrink-0 opacity-80" />;
              if (nameLower === "food") return <CulturalGraphic name="buna" className="w-8 h-8 shrink-0 opacity-80" />;
              if (nameLower === "home") return <CulturalGraphic name="mesob" className="w-8 h-8 shrink-0 opacity-80" />;
              if (nameLower === "cultural") return <CulturalGraphic name="timket" className="w-8 h-8 shrink-0 opacity-80" />;
              
              if (nameLower.includes("électric") || nameLower.includes("electric")) return <span className="text-xl">⚡</span>;
              if (nameLower.includes("lavage") || nameLower.includes("wash")) return <span className="text-xl">🧽</span>;
              if (nameLower.includes("mécan") || nameLower.includes("mecan")) return <span className="text-xl">🔧</span>;
              if (nameLower.includes("peint") || nameLower.includes("paint")) return <span className="text-xl">🎨</span>;
              if (nameLower.includes("photo") || nameLower.includes("vidé") || nameLower.includes("video")) return <span className="text-xl">📸</span>;
              if (nameLower.includes("traduc") || nameLower.includes("transla")) return <span className="text-xl">🗣️</span>;
              if (nameLower.includes("dj")) return <span className="text-xl">🎧</span>;
              if (nameLower.includes("traiteur") || nameLower.includes("catering")) return <span className="text-xl">🍽️</span>;
              if (nameLower.includes("médec") || nameLower.includes("doctor")) return <span className="text-xl">🩺</span>;
              if (nameLower.includes("chauffeur") || nameLower.includes("driver")) return <span className="text-xl">🚗</span>;
              if (nameLower.includes("déménagement") || nameLower.includes("move")) return <span className="text-xl">📦</span>;
              if (nameLower.includes("coiff") || nameLower.includes("hair")) return <span className="text-xl">✂️</span>;
              if (nameLower.includes("ጠበቃ") || nameLower.includes("avocat") || nameLower.includes("lawyer")) return <span className="text-xl">⚖️</span>;
              
              if (nameLower.includes("chef")) return <span className="text-xl">🍳</span>;
              if (nameLower.includes("management")) return <span className="text-xl">💼</span>;
              if (nameLower.includes("caregiver")) return <span className="text-xl">❤️</span>;
              if (nameLower.includes("technicien")) return <span className="text-xl">🛠️</span>;
              
              return <span className="text-xl">✨</span>;
            };

            return (
              <button
                key={cat}
                onClick={() => setSelectedCategory(isSelected ? "" : cat)}
                className={`group relative overflow-hidden rounded-2xl p-3 border text-left transition-all duration-300 transform hover:-translate-y-0.5 hover:shadow-md active:scale-95 flex flex-col justify-between h-24 ${
                  isSelected
                    ? "bg-[#0C3823] border-[#D4AF37] text-white ring-2 ring-[#D4AF37]/30 shadow-lg shadow-[#0C3823]/10"
                    : "bg-white border-stone-150 text-stone-800 hover:border-stone-300 hover:bg-stone-50/50"
                }`}
              >
                <div className="flex justify-between items-start w-full">
                  {getIllustration(cat)}
                  <span className={`text-[8px] font-mono font-bold px-1 py-0.2 rounded-full ${
                    isSelected ? "bg-[#D4AF37]/20 text-[#D4AF37]" : "bg-stone-100 text-stone-500"
                  }`}>
                    {count}
                  </span>
                </div>

                <div className="space-y-0.5 mt-2">
                  <h3 className="text-[11px] font-bold leading-tight truncate group-hover:text-[#D4AF37] transition-colors">
                    {cat}
                  </h3>
                  <p className={`text-[8px] ${isSelected ? "text-stone-300" : "text-stone-400"}`}>
                    Explorer
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* SEARCH BOX & FILTERS */}
      <div className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm space-y-4">
        
        {/* Keyword Search Row */}
        <div className="flex gap-2 relative">
          <div className="relative flex-1">
            <Search className="absolute left-4 top-3.5 w-4 h-4 text-stone-400" />
            <input
              type="text"
              placeholder={t.searchPlaceholder}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-11 pr-4 py-3 bg-stone-50 rounded-2xl border border-stone-200 text-xs focus:outline-none focus:border-[#0C3823] font-medium"
            />
          </div>

          {/* AI Search button */}
          <button
            onClick={triggerAiSmartSearch}
            disabled={isAiSearching || !searchQuery.trim()}
            className="px-4 py-3 bg-gradient-to-r from-[#0C3823] to-[#5C131E] hover:brightness-110 disabled:opacity-50 text-[#D4AF37] font-bold text-xs rounded-2xl transition-all flex items-center gap-1.5 shadow-md"
            title="Analyser intelligemment avec Gemini AI"
          >
            {isAiSearching ? (
              <div className="w-4 h-4 border-2 border-[#D4AF37] border-t-transparent rounded-full animate-spin" />
            ) : (
              <Sparkles className="w-4 h-4 text-[#D4AF37]" />
            )}
            <span className="hidden sm:inline">{t.searchQueryLabel}</span>
          </button>
        </div>

        {/* AI SEARCH EXPLANATION CARD (Only shows if smart-search is active) */}
        {aiSearchExplanation && (
          <div className="p-4 bg-stone-900 text-stone-100 rounded-2xl border border-stone-800 space-y-2 relative">
            <button
              onClick={clearAiSearch}
              className="absolute top-3 right-3 text-[10px] font-bold text-stone-400 hover:text-[#D4AF37]"
            >
              Réinitialiser
            </button>
            <div className="flex items-center gap-2 border-b border-stone-800 pb-2">
              <Sparkles className="w-4 h-4 text-[#D4AF37] animate-pulse" />
              <span className="text-[10px] font-black uppercase tracking-widest text-[#D4AF37]">{t.searchQueryLabel}</span>
            </div>
            <p className="text-xs text-stone-300 leading-relaxed font-sans font-medium italic">
              " {aiSearchExplanation} "
            </p>
            <div className="text-[9px] font-mono text-stone-500">
              Matches found: {filteredListings.length}
            </div>
          </div>
        )}

        {/* Standard Select Filters Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 pt-2">
          
          {/* Category Dropdown */}
          <div className="space-y-1">
            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-wider">{t.filterCategory}</label>
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="w-full p-2.5 bg-stone-50 border border-stone-200 text-stone-700 rounded-xl focus:outline-none text-[11px] font-medium"
            >
              <option value="">Tous</option>
              {getCategories()?.map(c => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </div>

          {/* Country Dropdown */}
          <div className="space-y-1">
            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-wider">{t.filterCountry}</label>
            <select
              value={selectedCountry}
              onChange={(e) => setSelectedCountry(e.target.value)}
              className="w-full p-2.5 bg-stone-50 border border-stone-200 text-stone-700 rounded-xl focus:outline-none text-[11px] font-medium"
            >
              <option value="">Tous</option>
              {COUNTRIES.map(c => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </div>

          {/* City Input */}
          <div className="space-y-1">
            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-wider">{t.filterCity}</label>
            <input
              type="text"
              placeholder="Ex: Paris, Lyon..."
              value={selectedCity}
              onChange={(e) => setSelectedCity(e.target.value)}
              className="w-full p-2 bg-stone-50 border border-stone-200 text-stone-700 rounded-xl focus:outline-none text-[11px] font-medium px-2.5"
            />
          </div>

          {/* Language Dropdown */}
          <div className="space-y-1">
            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-wider">{t.filterLanguage}</label>
            <select
              value={selectedLanguage}
              onChange={(e) => setSelectedLanguage(e.target.value)}
              className="w-full p-2.5 bg-stone-50 border border-stone-200 text-stone-700 rounded-xl focus:outline-none text-[11px] font-medium"
            >
              <option value="">Tous</option>
              {LANGUAGES_LIST.map(l => (
                <option key={l.code} value={l.code}>{l.label}</option>
              ))}
            </select>
          </div>

        </div>

      </div>

      {/* INTERACTIVE TOAST SYSTEM */}
      {toast && (
        <div className="fixed bottom-20 md:bottom-6 right-6 z-50 bg-[#0C3823] text-[#D4AF37] border-2 border-[#D4AF37] px-5 py-3 rounded-2xl shadow-2xl flex items-center gap-3 animate-bounce font-sans text-xs font-bold">
          <Sparkles className="w-4 h-4 text-[#D4AF37]" />
          <span>{toast}</span>
        </div>
      )}

      {/* LISTINGS RESULTS */}
      <div className="space-y-6">
        
        {/* TAB SPECIFIC REDESIGNS */}
        {type === "marketplace" ? (
          // ==================== HABESHA MARKET GRID ====================
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-black text-stone-900 uppercase tracking-widest flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[#5C131E]" />
                <span>Habesha Products</span>
              </h2>
              <span className="text-[10px] font-mono text-stone-400 font-bold uppercase">
                {filteredListings.length} Products Available
              </span>
            </div>

            {filteredListings.length === 0 ? (
              <div className="bg-[#FBFBFA] p-12 text-center rounded-3xl border border-stone-100 text-stone-400 text-xs">
                Aucun produit ne correspond aux filtres.
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {filteredListings.map(listing => {
                  const isFav = favorites.includes(listing.id);
                  const isAdded = cart.includes(listing.id);
                  const imageKey = listing.image || "gabi";

                  return (
                    <div 
                      key={listing.id} 
                      className="bg-white rounded-3xl border border-stone-150 shadow-sm flex flex-col justify-between overflow-hidden hover:shadow-md hover:border-[#0C3823]/20 transition-all duration-300 relative group"
                    >
                      {/* Product Header image box */}
                      <div className="p-3 relative bg-[#F9F8F6]">
                        <CulturalGraphic name={imageKey} className="w-full h-44 rounded-2xl shadow-inner object-contain" />
                        
                        {/* Heart Favorite Trigger */}
                        <button 
                          onClick={() => {
                            if (isFav) {
                              setFavorites(favorites.filter(id => id !== listing.id));
                              triggerToast("Retiré des favoris 💔");
                            } else {
                              setFavorites([...favorites, listing.id]);
                              triggerToast("Ajouté aux favoris ! ❤️");
                            }
                          }}
                          className="absolute top-5 right-5 p-2 rounded-full bg-white/80 hover:bg-white text-stone-600 hover:text-red-500 shadow transition-all duration-200"
                        >
                          <Heart className={`w-4 h-4 transition-colors ${isFav ? "fill-red-500 text-red-500" : ""}`} />
                        </button>

                        {/* Traditional Hand-made Label */}
                        <span className="absolute bottom-5 left-5 px-2 py-0.5 bg-[#0C3823] text-[#D4AF37] font-mono text-[8px] font-black uppercase rounded-md tracking-wider">
                          Abyssinian Craft
                        </span>
                      </div>

                      {/* Info body */}
                      <div className="p-4 space-y-2.5 flex-1 flex flex-col justify-between">
                        <div>
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-1.5">
                              <span className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">
                                {listing.category}
                              </span>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setActiveReviewListing(listing);
                                }}
                                className="flex items-center gap-1 bg-amber-50 hover:bg-amber-100 border border-amber-100 text-amber-700 font-extrabold px-1.5 py-0.5 rounded text-[8px] transition-colors"
                              >
                                ⭐ {listing.averageRating || "N/A"} ({listing.reviews?.length || 0})
                              </button>
                            </div>
                            {listing.isVerified && (
                              <span className="text-[9px] font-bold text-[#D4AF37] bg-[#0C3823]/10 px-1.5 py-0.5 rounded-md">
                                Genuine ✅
                              </span>
                            )}
                          </div>
                          
                          <h3 className="text-xs font-black text-stone-900 mt-1 hover:text-[#0C3823] transition-colors line-clamp-1">
                            {listing.title}
                          </h3>
                          
                          <p className="text-[11px] text-stone-500 leading-relaxed line-clamp-2 mt-1">
                            {listing.description}
                          </p>
                        </div>

                        <div className="pt-3 border-t border-stone-50">
                          <div className="flex items-center justify-between gap-2">
                            <div>
                              <span className="text-[9px] font-mono uppercase text-stone-400 block">Price</span>
                              <span className="text-sm font-black text-[#0C3823] font-mono">{listing.price}</span>
                            </div>

                            <div className="flex items-center gap-1">
                              {/* Add to Cart button */}
                              <button
                                onClick={() => {
                                  if (isAdded) {
                                    setCart(cart.filter(id => id !== listing.id));
                                    triggerToast("Retiré du panier 🛒");
                                  } else {
                                    setCart([...cart, listing.id]);
                                    triggerToast(`Traditional ${listing.title} ajouté au panier ! 🛒`);
                                  }
                                }}
                                className={`px-2.5 py-1.5 rounded-xl text-[9px] font-bold uppercase tracking-wider transition-all duration-300 ${
                                  isAdded 
                                    ? "bg-[#5C131E] text-[#D4AF37]" 
                                    : "bg-stone-150 hover:bg-stone-200 text-stone-700"
                                }`}
                              >
                                {isAdded ? "Panier" : "Acheter"}
                              </button>

                              {/* Secure Chat button */}
                              {listing.authorId !== currentUser.id ? (
                                <button
                                  onClick={() => onStartPrivateChat?.(listing.authorId, listing.authorName)}
                                  className="px-2.5 py-1.5 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-bold text-[9px] uppercase tracking-wider rounded-xl transition-all"
                                >
                                  Discuter
                                </button>
                              ) : (
                                <span className="text-[9px] font-mono bg-stone-50 text-stone-400 px-2 py-1 rounded">Moi</span>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>

                    </div>
                  );
                })}
              </div>
            )}
          </div>
        ) : type === "job" ? (
          // ==================== CONNECTIONS & JOBS (Combined Split Feed) ====================
          <div className="space-y-8">
            
            {/* Split Section 1: Connections / Events */}
            <div className="space-y-4">
              <div className="flex items-center justify-between border-b border-stone-100 pb-2">
                <h2 className="text-sm font-black text-stone-900 uppercase tracking-widest flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#D4AF37]" />
                  <span>Featured Connections & Celebrations</span>
                </h2>
                <span className="text-[10px] font-mono text-emerald-600 font-bold uppercase bg-emerald-50 px-2 py-0.5 rounded">
                  DIASPORA EVENTS
                </span>
              </div>

              {listings.filter(l => l.type === "event" && l.status === "approved").length === 0 ? (
                <p className="text-xs text-stone-400">Aucun événement à afficher.</p>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {listings
                    .filter(l => l.type === "event" && l.status === "approved")
                    .map(event => {
                      const isFav = favorites.includes(event.id);
                      return (
                        <div 
                          key={event.id}
                          className="bg-[#0C3823] text-stone-100 rounded-3xl p-5 border border-[#09291a] shadow-lg relative overflow-hidden group flex flex-col justify-between min-h-[220px]"
                        >
                          {/* Background Accent */}
                          <div className="absolute right-0 bottom-0 opacity-10 pointer-events-none transform translate-y-10 translate-x-10">
                            <Calendar className="w-56 h-56 text-[#D4AF37]" />
                          </div>

                          <div className="space-y-3 relative z-10">
                            <div className="flex items-center justify-between">
                              <span className="px-2.5 py-0.5 bg-[#D4AF37] text-[#0C3823] font-mono font-black uppercase text-[8px] rounded-md tracking-wider">
                                {event.category}
                              </span>
                              
                              <button 
                                onClick={() => {
                                  if (isFav) {
                                    setFavorites(favorites.filter(id => id !== event.id));
                                    triggerToast("Retiré des favoris 💔");
                                  } else {
                                    setFavorites([...favorites, event.id]);
                                    triggerToast("Intérêt enregistré ! ❤️");
                                  }
                                }}
                                className="text-stone-300 hover:text-[#D4AF37] transition-all"
                              >
                                <Heart className={`w-4 h-4 ${isFav ? "fill-[#D4AF37] text-[#D4AF37]" : ""}`} />
                              </button>
                            </div>

                            <h3 className="text-sm font-black text-[#D4AF37] tracking-tight line-clamp-2">
                              {event.title}
                            </h3>

                            <p className="text-xs text-emerald-100/80 leading-relaxed line-clamp-3 font-sans">
                              {event.description}
                            </p>
                          </div>

                          <div className="pt-4 mt-4 border-t border-emerald-900/50 flex flex-wrap items-center justify-between gap-2 relative z-10">
                            <div className="space-y-0.5">
                              <p className="text-[9px] font-mono text-[#D4AF37] uppercase tracking-wider">{event.date}</p>
                              <p className="text-[10px] text-stone-300 font-bold">{event.location.city}, {event.location.country}</p>
                            </div>

                            <div className="flex gap-2">
                              <button
                                onClick={() => triggerToast(`Ticket réservé avec succès pour ${event.title}! 🎟️`)}
                                className="px-4 py-2 bg-[#D4AF37] hover:bg-[#b8952a] text-[#0C3823] font-black text-[10px] uppercase rounded-xl tracking-wider shadow transition-all duration-200"
                              >
                                Book Now
                              </button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                </div>
              )}
            </div>

            {/* Split Section 2: Job Opportunities */}
            <div className="space-y-4">
              <div className="flex items-center justify-between border-b border-stone-100 pb-2">
                <h2 className="text-sm font-black text-stone-900 uppercase tracking-widest flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#5C131E]" />
                  <span>Job Opportunities & Services</span>
                </h2>
                <span className="text-[10px] font-mono text-stone-400 font-bold uppercase">
                  Employment Feed
                </span>
              </div>

              {filteredListings.length === 0 ? (
                <div className="bg-[#FBFBFA] p-8 text-center rounded-2xl border text-stone-400 text-xs">
                  Aucune offre d'emploi disponible.
                </div>
              ) : (
                <div className="space-y-4">
                  {filteredListings.map(job => {
                    const isFav = favorites.includes(job.id);
                    return (
                      <div 
                        key={job.id}
                        className="bg-white rounded-2xl border border-stone-150 p-4 hover:border-[#0C3823]/30 transition-all duration-200 flex flex-col md:flex-row md:items-center justify-between gap-4"
                      >
                        <div className="flex items-start gap-3 min-w-0">
                          <div className="p-3 bg-[#0C3823]/5 rounded-xl text-[#0C3823] shrink-0">
                            <Briefcase className="w-5 h-5" />
                          </div>
                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="px-2 py-0.5 bg-[#5C131E]/5 text-[#5C131E] font-mono font-black text-[8px] uppercase rounded">
                                {job.category}
                              </span>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setActiveReviewListing(job);
                                }}
                                className="flex items-center gap-1 bg-amber-50 hover:bg-amber-100 border border-amber-100 text-amber-700 font-extrabold px-1.5 py-0.5 rounded text-[8px] transition-colors"
                              >
                                ⭐ {job.averageRating || "N/A"} ({job.reviews?.length || 0})
                              </button>
                              {job.experience && (
                                <span className="text-[9px] font-bold text-stone-500">
                                  Exp: {job.experience}
                                </span>
                              )}
                            </div>
                            <h3 className="text-xs font-black text-stone-900 mt-1 truncate">
                              {job.title}
                            </h3>
                            <p className="text-[11px] text-stone-500 mt-0.5 line-clamp-1">
                              {job.description}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center justify-between md:justify-end gap-3 border-t md:border-t-0 pt-3 md:pt-0 border-stone-50">
                          <div className="text-left md:text-right">
                            <p className="text-[9px] text-stone-400 font-mono uppercase">Location</p>
                            <p className="text-[10px] font-bold text-stone-800">{job.location.city}, {job.location.country}</p>
                          </div>

                          <div className="flex items-center gap-1.5">
                            <button 
                              onClick={() => {
                                if (isFav) {
                                  setFavorites(favorites.filter(id => id !== job.id));
                                  triggerToast("Retiré des favoris 💔");
                                } else {
                                  setFavorites([...favorites, job.id]);
                                  triggerToast("Offre ajoutée aux favoris ! ❤️");
                                }
                              }}
                              className="p-2 rounded-xl border border-stone-200 text-stone-400 hover:text-red-500 hover:bg-red-50/50 transition-colors"
                            >
                              <Heart className={`w-3.5 h-3.5 ${isFav ? "fill-red-500 text-red-500" : ""}`} />
                            </button>

                            {/* Starr Rating and Work Evaluation button */}
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setActiveReviewListing(job);
                              }}
                              className="px-2.5 py-2 bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-200 font-extrabold text-[9px] uppercase tracking-wider rounded-xl transition-all flex items-center gap-1"
                              title="Évaluer l'expérience et le travail"
                            >
                              ⭐ Évaluer ({job.reviews?.length || 0})
                            </button>
                            
                            {job.authorId !== currentUser.id ? (
                              <button
                                onClick={() => onStartPrivateChat?.(job.authorId, job.authorName)}
                                className="px-3 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-black text-[9px] uppercase tracking-wider rounded-xl transition-all"
                              >
                                Discuter
                              </button>
                            ) : (
                              <span className="text-[9px] font-mono bg-stone-100 text-stone-500 px-2 py-1 rounded">Moi</span>
                            )}

                            <button
                              onClick={() => triggerToast(`Candidature envoyée avec succès pour ${job.title}! 🚀`)}
                              className="px-3.5 py-2 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] font-black text-[9px] uppercase tracking-wider rounded-xl transition-all"
                            >
                              Application
                            </button>
                          </div>
                        </div>

                      </div>
                    );
                  })}
                </div>
              )}
            </div>

          </div>
        ) : (
          // ==================== OTHER STANDARD SECTION LISTINGS (Professionals, Events standard) ====================
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {filteredListings.map(listing => {
              const textMsg = encodeURIComponent(t.whatsAppMsg + listing.title);
              const whatsappLink = `https://wa.me/${listing.whatsapp.replace("+", "")}?text=${textMsg}`;
              
              return (
                <div key={listing.id} className="bg-white p-5 rounded-3xl border border-stone-100 shadow-sm flex flex-col justify-between hover:border-[#0C3823]/30 transition-all group relative overflow-hidden">
                  
                  {/* Decorative cultural tag for verified listings */}
                  {listing.isVerified && (
                    <div className="absolute top-0 right-0 w-2 h-full bg-[#D4AF37]" title="Profil Professionnel Vérifié" />
                  )}

                  <div className="space-y-3">
                    
                    {/* Header: Title / Category / Verification Badge */}
                    <div>
                      <div className="flex flex-wrap items-center justify-between gap-1.5 mb-1.5">
                        <div className="flex items-center gap-1.5">
                          <span className="px-2 py-0.5 bg-[#0C3823]/5 text-[#0C3823] text-[9px] font-black uppercase tracking-wider rounded">
                            {listing.category}
                          </span>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setActiveReviewListing(listing);
                            }}
                            className="flex items-center gap-1 bg-amber-50 hover:bg-amber-100 border border-amber-100 text-amber-700 font-extrabold px-1.5 py-0.5 rounded text-[8px] transition-colors"
                          >
                            ⭐ {listing.averageRating || "N/A"} ({listing.reviews?.length || 0} avis)
                          </button>
                        </div>

                        <div className="flex items-center gap-1">
                          {listing.isVerified && (
                            <span className="bg-emerald-50 text-emerald-700 text-[9px] font-black px-1.5 py-0.5 rounded flex items-center gap-0.5" title="Vérifié par l'administration">
                              Vérifié ✅
                            </span>
                          )}
                          
                          {/* Owner/Admin Listing Status indicators */}
                          {listing.status === "pending" && (
                            <span className="bg-amber-50 text-amber-700 text-[9px] font-black px-1.5 py-0.5 rounded flex items-center gap-0.5">
                              En attente ⏳
                            </span>
                          )}
                          {listing.status === "rejected" && (
                            <span className="bg-red-50 text-red-700 text-[9px] font-black px-1.5 py-0.5 rounded flex items-center gap-0.5">
                              Refusé ❌
                            </span>
                          )}
                        </div>
                      </div>

                      <h3 className="text-sm font-bold text-stone-900 group-hover:text-[#0C3823] transition-colors leading-snug">
                        {listing.title}
                      </h3>
                      
                      <div className="flex items-center gap-1.5 text-[10px] text-stone-400 mt-1">
                        <MapPin className="w-3.5 h-3.5 text-stone-400" />
                        <span>{listing.location.city}, {listing.location.country}</span>
                      </div>
                    </div>

                    {/* Body text */}
                    <p className="text-xs text-stone-500 leading-relaxed line-clamp-4">
                      {listing.description}
                    </p>

                    {/* Metadata details (Languages, Experience, Price, Date) */}
                    <div className="pt-2 border-t border-stone-50 text-[10px] space-y-1.5">
                      {listing.experience && (
                        <div className="flex justify-between text-stone-500">
                          <span className="font-semibold">{t.experience}</span>
                          <span className="font-medium text-stone-800">{listing.experience}</span>
                        </div>
                      )}

                      {listing.price && (
                        <div className="flex justify-between text-stone-500">
                          <span className="font-semibold">{t.price}</span>
                          <span className="font-black text-[#0C3823] font-mono">{listing.price}</span>
                        </div>
                      )}

                      {listing.date && (
                        <div className="flex justify-between text-stone-500">
                          <span className="font-semibold">{t.date}</span>
                          <span className="font-bold text-[#5C131E]">{listing.date}</span>
                        </div>
                      )}

                      {listing.spokenLanguages && (
                        <div className="flex justify-between text-stone-500">
                          <span className="font-semibold">{t.languages}</span>
                          <span className="font-bold text-stone-700 uppercase tracking-wider">
                            {listing.spokenLanguages.join(" / ")}
                          </span>
                        </div>
                      )}
                    </div>

                  </div>

                  {/* Footer: User Identity & Action buttons */}
                  <div className="pt-4 mt-4 border-t border-stone-100 flex items-center justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-[10px] text-stone-400">Publié par</p>
                      <p className="text-[11px] font-bold text-stone-700 truncate">{listing.authorName}</p>
                    </div>

                    <div className="flex gap-1.5 shrink-0">
                      {/* Starr Rating and Work Evaluation button */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setActiveReviewListing(listing);
                        }}
                        className="px-2.5 py-2 bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-200 font-extrabold text-[9px] uppercase tracking-wider rounded-xl transition-all flex items-center gap-1"
                        title="Évaluer l'expérience et le travail"
                      >
                        ⭐ Évaluer ({listing.reviews?.length || 0})
                      </button>

                      {listing.authorId !== currentUser.id ? (
                        <button
                          onClick={() => onStartPrivateChat?.(listing.authorId, listing.authorName)}
                          className="px-3.5 py-2 bg-[#0C3823] hover:bg-[#09291a] text-[#D4AF37] text-[11px] font-bold rounded-xl transition-all flex items-center gap-1 shadow-sm"
                        >
                          <MessageSquare className="w-3.5 h-3.5 text-[#D4AF37]" />
                          <span>Discuter</span>
                        </button>
                      ) : (
                        <span className="text-[10px] font-medium bg-stone-100 text-stone-500 px-2.5 py-1 rounded-lg">
                          Votre annonce
                        </span>
                      )}
                    </div>
                  </div>

                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* REVIEWS & STAR COMMENTS SYSTEM MODAL */}
      {(() => {
        const modalListing = activeReviewListing ? listings.find(l => l.id === activeReviewListing.id) || activeReviewListing : null;
        if (!modalListing) return null;

        return (
          <div className="fixed inset-0 bg-stone-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-lg w-full max-h-[85vh] flex flex-col overflow-hidden shadow-2xl border border-stone-100 animate-in fade-in zoom-in duration-200">
              
              {/* Header */}
              <div className="p-5 border-b border-stone-100 bg-stone-50/50 flex justify-between items-center">
                <div>
                  <span className="text-[9px] font-mono font-black text-amber-600 bg-amber-50 px-2 py-0.5 rounded uppercase tracking-wider">
                    ⭐ Avis & Évaluations
                  </span>
                  <h3 className="text-xs font-black text-stone-900 uppercase mt-1 leading-snug">
                    {modalListing.title}
                  </h3>
                </div>
                <button
                  onClick={() => setActiveReviewListing(null)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 text-stone-500 flex items-center justify-center transition-colors font-bold text-sm"
                >
                  ✕
                </button>
              </div>

              {/* Scrollable Content */}
              <div className="flex-1 p-6 overflow-y-auto space-y-6">
                
                {/* Average Summary Card */}
                <div className="bg-[#FAF9F6] p-4 rounded-2xl border border-stone-150 flex items-center justify-between">
                  <div>
                    <p className="text-[10px] text-stone-400 font-bold uppercase tracking-wide">Note Globale</p>
                    <p className="text-3xl font-black text-stone-900 mt-1">
                      {modalListing.averageRating || "0.0"}{" "}
                      <span className="text-xs font-medium text-stone-400">/ 5</span>
                    </p>
                  </div>
                  <div className="text-right">
                    <div className="flex gap-0.5 justify-end">
                      {[1, 2, 3, 4, 5].map((star) => (
                        <span key={star} className="text-lg">
                          {star <= (modalListing.averageRating || 0) ? "⭐" : "☆"}
                        </span>
                      ))}
                    </div>
                    <p className="text-[10px] text-stone-400 mt-1 font-semibold">
                      {modalListing.reviews?.length || 0} avis vérifiés
                    </p>
                  </div>
                </div>

                {/* List of comments */}
                <div className="space-y-4">
                  <h4 className="text-[10px] font-black text-stone-400 uppercase tracking-widest">Commentaires récents</h4>
                  
                  {!modalListing.reviews || modalListing.reviews.length === 0 ? (
                    <div className="text-center p-6 text-stone-400 border border-dashed border-stone-200 rounded-2xl bg-stone-50/30">
                      <p className="text-xs">Aucun avis rédigé pour le moment.</p>
                      <p className="text-[10px] text-stone-400 mt-1">Soyez le premier à partager votre expérience !</p>
                    </div>
                  ) : (
                    <div className="space-y-3.5">
                      {modalListing.reviews.map((rev) => (
                        <div key={rev.id} className="p-4 bg-white rounded-2xl border border-stone-100 shadow-sm space-y-1.5">
                          <div className="flex justify-between items-center">
                            <span className="text-xs font-black text-stone-800">{rev.authorName}</span>
                            <div className="flex gap-0.5 text-xs">
                              {[1, 2, 3, 4, 5].map((s) => (
                                <span key={s}>{s <= rev.rating ? "⭐" : "☆"}</span>
                              ))}
                            </div>
                          </div>
                          <p className="text-xs text-stone-600 leading-relaxed font-medium">
                            {rev.comment}
                          </p>
                          <p className="text-[8px] font-mono text-stone-400 text-right">
                            {new Date(rev.createdAt).toLocaleDateString([], { day: 'numeric', month: 'short', year: 'numeric' })}
                          </p>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Write a comment form */}
                <div className="pt-4 border-t border-stone-100 space-y-4">
                  <h4 className="text-[10px] font-black text-stone-400 uppercase tracking-widest">Écrire un Avis</h4>
                  
                  <div className="space-y-3">
                    {/* Rating Selector */}
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-bold text-stone-500 uppercase tracking-wide">Sélectionnez la note :</span>
                      <div className="flex gap-1.5">
                        {[1, 2, 3, 4, 5].map((star) => (
                          <button
                            key={star}
                            onClick={() => setNewReviewRating(star)}
                            className="text-xl hover:scale-125 transition-transform"
                            type="button"
                          >
                            {star <= newReviewRating ? "⭐" : "☆"}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Comment Input */}
                    <textarea
                      rows={3}
                      placeholder="Laissez votre commentaire constructif ici..."
                      value={newReviewComment}
                      onChange={(e) => setNewReviewComment(e.target.value)}
                      className="w-full p-3 bg-stone-50 border border-stone-200 rounded-2xl text-xs focus:outline-none focus:border-[#0C3823] font-medium leading-relaxed"
                    />

                    {/* Submit review */}
                    <button
                      onClick={() => handleAddReview(modalListing.id)}
                      disabled={!newReviewComment.trim() || submittingReview}
                      className="w-full py-2.5 bg-[#0C3823] hover:bg-[#09291a] disabled:opacity-50 text-[#D4AF37] font-bold text-xs rounded-xl uppercase transition-colors"
                    >
                      {submittingReview ? "Publication..." : "Publier mon avis"}
                    </button>
                  </div>
                </div>

              </div>

            </div>
          </div>
        );
      })()}

    </div>
  );
}
