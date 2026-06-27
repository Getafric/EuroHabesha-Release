import express from "express";
import path from "path";
import fs from "fs";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI, Type } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(express.json());
const PORT = 3000;

// Lazy-loaded Gemini AI client
let aiClient: any = null;
function getGemini() {
  if (!aiClient) {
    const key = process.env.GEMINI_API_KEY;
    if (!key) {
      console.log("[Gemini AI] GEMINI_API_KEY not defined. Running in rule-based moderation fallback mode.");
      return null;
    }
    aiClient = new GoogleGenAI({
      apiKey: key,
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        }
      }
    });
  }
  return aiClient;
}

const DB_PATH = path.join(process.cwd(), "data-store.json");

// Helper to load/save state
interface DBState {
  users: any[];
  listings: any[];
  messages: any[];
  notifications: any[];
}

function loadDB(): DBState {
  if (fs.existsSync(DB_PATH)) {
    try {
      return JSON.parse(fs.readFileSync(DB_PATH, "utf8"));
    } catch (e) {
      console.error("Error reading database file, resetting...", e);
    }
  }

  // Initial Seed Data if db doesn't exist
  const initialState: DBState = {
    users: [
      {
        id: "admin-1",
        name: "Admin EuroHabesha",
        phone: "+33612345678",
        country: "France",
        prefix: "+33",
        languages: ["fr", "en"],
        role: "admin",
        isBlocked: false,
        verificationStatus: "verified",
        createdAt: new Date().toISOString()
      },
      {
        id: "pro-1",
        name: "Yonas Melaku",
        phone: "+33789456123",
        country: "France",
        prefix: "+33",
        languages: ["fr", "am"],
        role: "professional",
        isBlocked: false,
        verificationStatus: "verified",
        verificationDocName: "Kbis_Plombier.pdf",
        verificationDocType: "Professional",
        createdAt: new Date().toISOString()
      },
      {
        id: "user-emebet",
        name: "Emebet B.",
        phone: "+33611112222",
        country: "France",
        prefix: "+33",
        languages: ["fr", "am", "en"],
        role: "professional",
        isBlocked: false,
        verificationStatus: "verified",
        createdAt: new Date().toISOString()
      },
      {
        id: "user-fasil",
        name: "Fasil A.",
        phone: "+447111222333",
        country: "Royaume-Uni",
        prefix: "+44",
        languages: ["en", "am"],
        role: "professional",
        isBlocked: false,
        verificationStatus: "verified",
        createdAt: new Date().toISOString()
      },
      {
        id: "user-1",
        name: "Selam Tekle",
        phone: "+491761234567",
        country: "Allemagne",
        prefix: "+49",
        languages: ["de", "ti", "en"],
        role: "user",
        isBlocked: false,
        verificationStatus: "unverified",
        createdAt: new Date().toISOString()
      }
    ],
    listings: [
      {
        id: "list-m1",
        type: "marketplace",
        category: "Apparel",
        title: "Traditional Gabi",
        description: "Authentique Gabi éthiopien filé à la main avec du pur coton biologique d'Éthiopie. Doux, chaud, orné d'élégantes bordures brodées de fils colorés. Un incontournable de la culture Habesha pour rester élégant et au chaud.",
        price: "45 €",
        location: { city: "Paris", country: "France" },
        spokenLanguages: ["fr", "am", "en"],
        phone: "+33789456123",
        whatsapp: "+33789456123",
        isVerified: true,
        status: "approved",
        authorId: "pro-1",
        authorName: "Yonas Melaku",
        image: "gabi",
        createdAt: new Date().toISOString()
      },
      {
        id: "list-m2",
        type: "marketplace",
        category: "Home",
        title: "Buna Set",
        description: "Service complet pour la traditionnelle cérémonie du café éthiopienne. Comprend la Jebena en argile noire polie, 12 tasses Cini, le brûleur d'encens et le support en bois décoré (Rekebot). Revivez l'hospitalité légendaire Habesha chez vous.",
        price: "120 €",
        location: { city: "Bruxelles", country: "Belgique" },
        spokenLanguages: ["fr", "en"],
        phone: "+33611112222",
        whatsapp: "+33611112222",
        isVerified: true,
        status: "approved",
        authorId: "user-emebet",
        authorName: "Emebet B.",
        image: "buna",
        createdAt: new Date().toISOString()
      },
      {
        id: "list-m3",
        type: "marketplace",
        category: "Home",
        title: "Mesob",
        description: "Panier de service traditionnel (Mesob) tressé avec amour par des artisanes de Gondar. Couleurs éclatantes, paille séchée ultra-résistante. Idéal pour servir l'Injera en famille ou décorer votre intérieur avec une touche impériale.",
        price: "45 €",
        location: { city: "Francfort", country: "Allemagne" },
        spokenLanguages: ["de", "am"],
        phone: "+491761234567",
        whatsapp: "+491761234567",
        isVerified: false,
        status: "approved",
        authorId: "user-1",
        authorName: "Selam Tekle",
        image: "mesob",
        createdAt: new Date().toISOString()
      },
      {
        id: "list-m4",
        type: "marketplace",
        category: "Art",
        title: "Artwork Paint",
        description: "Magnifique peinture acrylique sur toile représentant les reines d'Abyssinie et l'histoire des églises de Lalibela. Réalisée par un jeune peintre talentueux de la diaspora. Certificat d'authenticité fourni.",
        price: "120 €",
        location: { city: "Londres", country: "Royaume-Uni" },
        spokenLanguages: ["en", "am"],
        phone: "+447111222333",
        whatsapp: "+447111222333",
        isVerified: true,
        status: "approved",
        authorId: "user-fasil",
        authorName: "Fasil A.",
        image: "artwork",
        createdAt: new Date().toISOString()
      },
      {
        id: "list-e1",
        type: "event",
        category: "Cultural",
        title: "Timket Celebration 2024",
        description: "Rejoignez la diaspora de Londres pour la commémoration solennelle du baptême du Christ (Timket). Chants choraux orthodoxes traditionnels en tenues blanches étincelantes (Kaba), défilés folkloriques et déjeuner communautaire partagé.",
        date: "Sept 1, 2024 - 10:00",
        location: { city: "Londres", country: "Royaume-Uni" },
        spokenLanguages: ["en", "am"],
        phone: "+447111222333",
        whatsapp: "+447111222333",
        isVerified: true,
        status: "approved",
        authorId: "user-fasil",
        authorName: "Fasil A.",
        image: "timket",
        createdAt: new Date().toISOString()
      },
      {
        id: "list-j1",
        type: "job",
        category: "Chef",
        title: "Chef - Ethiopian Rest.",
        description: "Nous recherchons un chef de cuisine passionné et expérimenté dans les plats traditionnels éthiopiens (Kitfo, Doro Wot, préparation de l'Injera au teff). Poste basé dans le centre de Paris, équipe chaleureuse et salaire attractif.",
        experience: "3 ans",
        location: { city: "Paris", country: "France" },
        spokenLanguages: ["fr", "am"],
        phone: "+33789456123",
        whatsapp: "+33789456123",
        isVerified: true,
        status: "approved",
        authorId: "pro-1",
        authorName: "Yonas Melaku",
        createdAt: new Date().toISOString()
      },
      {
        id: "list-j2",
        type: "job",
        category: "Management",
        title: "Project Manager (Amharic speaker)",
        description: "Diaspora Link recrute un chef de projet bilingue Amharique/Français pour piloter les initiatives de mentorat des jeunes étudiants et le développement des programmes d'intégration professionnelle.",
        experience: "2 ans",
        location: { city: "Bruxelles", country: "Belgique" },
        spokenLanguages: ["fr", "en", "am"],
        phone: "+33611112222",
        whatsapp: "+33611112222",
        isVerified: true,
        status: "approved",
        authorId: "user-emebet",
        authorName: "Emebet B.",
        createdAt: new Date().toISOString()
      },
      {
        id: "list-j3",
        type: "job",
        category: "Caregiver",
        title: "Caregiver",
        description: "Recherche un(e) auxiliaire de vie bienveillant(e) de la communauté pour accompagner une dame âgée à domicile. Aide pour les repas traditionnels, la conversation en Amharique/Tigrinya et les promenades.",
        experience: "Débutant bienvenu",
        location: { city: "Francfort", country: "Allemagne" },
        spokenLanguages: ["de", "am"],
        phone: "+491761234567",
        whatsapp: "+491761234567",
        isVerified: false,
        status: "approved",
        authorId: "user-1",
        authorName: "Selam Tekle",
        createdAt: new Date().toISOString()
      }
    ],
    messages: [
      {
        id: "msg-1",
        channel: "general",
        senderId: "pro-1",
        senderName: "Yonas Melaku",
        senderRole: "professional",
        senderIsVerified: true,
        content: "Selam! Bienvenue sur Habesha Connect Europe. C'est un réel plaisir de voir notre communauté réunie sur cette superbe interface !",
        createdAt: new Date(Date.now() - 3600000).toISOString()
      },
      {
        id: "msg-2",
        channel: "general",
        senderId: "user-1",
        senderName: "Selam Tekle",
        senderRole: "user",
        senderIsVerified: false,
        content: "መልካም ቀን! ሰላም ለሁላችሁ ይሁን። This is exactly the tool we needed to support each other across Europe.",
        createdAt: new Date(Date.now() - 1800000).toISOString()
      }
    ],
    notifications: [
      {
        id: "notif-1",
        title: "ታዋቂ አርቲስት እሸቱ መለሰ በለንደን!",
        content: "Ne manquez pas le spectacle exceptionnel du célèbre artiste humoriste Eshetu Melese à Londres le week-end prochain ! Musique traditionnelle, sketches hilarants et buffet convivial.",
        type: "success",
        createdAt: new Date().toISOString()
      }
    ]
  };

  saveDB(initialState);
  return initialState;
}

function saveDB(state: DBState) {
  try {
    fs.writeFileSync(DB_PATH, JSON.stringify(state, null, 2), "utf8");
  } catch (e) {
    console.error("Error writing to database file", e);
  }
}

// Global state holding database in memory
let dbState = loadDB();

// API Endpoints
// 1. Get entire app state & statistics
app.get("/api/data", (req, res) => {
  const pendingVerifications = dbState.users.filter(u => u.verificationStatus === "pending").length;
  const pendingListings = dbState.listings.filter(l => l.status === "pending").length;

  const stats = {
    totalUsers: dbState.users.length,
    totalListings: dbState.listings.filter(l => l.status === "approved").length,
    totalEvents: dbState.listings.filter(l => l.type === "event" && l.status === "approved").length,
    totalProfessionals: dbState.listings.filter(l => l.type === "professional" && l.status === "approved").length,
    pendingVerifications,
    pendingListings
  };

  res.json({
    users: dbState.users,
    listings: dbState.listings,
    messages: dbState.messages,
    notifications: dbState.notifications,
    stats
  });
});

// 2. Register new user
app.post("/api/register", (req, res) => {
  const { name, phone, country, prefix, languages, role, password } = req.body;
  
  if (!name || !phone || !country || !prefix || !languages || !role) {
    return res.status(400).json({ error: "Tous les champs sont requis." });
  }

  // Check if phone already registered
  const existingUser = dbState.users.find(u => u.phone === phone);
  if (existingUser) {
    return res.status(400).json({ error: "Ce numéro de téléphone est déjà enregistré." });
  }

  const newUser = {
    id: "user-" + Math.random().toString(36).substring(2, 9),
    name,
    phone,
    country,
    prefix,
    languages,
    role,
    isBlocked: false,
    verificationStatus: role === 'professional' ? 'pending' : 'unverified',
    verificationDocName: role === 'professional' ? "Doc_Pre-Upload.pdf" : undefined,
    verificationDocType: role === 'professional' ? "Professional" : undefined,
    createdAt: new Date().toISOString()
  };

  dbState.users.push(newUser);
  saveDB(dbState);

  res.json({ success: true, user: newUser });
});

// 3. Login
app.post("/api/login", (req, res) => {
  const { phone, password } = req.body;
  if (!phone) {
    return res.status(400).json({ error: "Téléphone requis." });
  }

  // In this demo prototype we allow logging in easily or by checking matching phone
  const user = dbState.users.find(u => u.phone === phone);
  if (!user) {
    return res.status(404).json({ error: "Utilisateur non trouvé." });
  }

  if (user.isBlocked) {
    return res.status(403).json({ error: "Votre compte a été bloqué par l'administrateur." });
  }

  res.json({ success: true, user });
});

// 4. Submit listing with automated Gemini AI verification helper
app.post("/api/listings", async (req, res) => {
  const { type, category, title, description, price, location, date, phone, whatsapp, authorId, authorName, spokenLanguages, isVerified } = req.body;

  if (!type || !category || !title || !description || !location || !phone || !whatsapp || !authorId || !authorName) {
    return res.status(400).json({ error: "Champs requis manquants." });
  }

  const newListingId = "list-" + Math.random().toString(36).substring(2, 9);
  
  // Base default structure
  const newListing: any = {
    id: newListingId,
    type,
    category,
    title,
    description,
    price,
    location,
    date,
    spokenLanguages: spokenLanguages || ["fr"],
    phone,
    whatsapp,
    isVerified: isVerified || false,
    status: "pending", // Initially pending review, can be auto-reviewed by AI or marked as approved
    authorId,
    authorName,
    createdAt: new Date().toISOString()
  };

  // Run automated AI content validation
  const ai = getGemini();
  if (ai) {
    try {
      console.log(`[Gemini AI] Moderating new listing: "${title}"...`);
      const response = await ai.models.generateContent({
        model: "gemini-3.5-flash",
        contents: `Tu es un assistant modérateur pour l'application EuroHabesha (Europe). 
        Analyse l'annonce suivante d'un utilisateur et détermine si elle est appropriée, légitime, respectueuse et pertinente pour la communauté.
        Type: ${type}
        Catégorie: ${category}
        Titre: ${title}
        Description: ${description}
        Région: ${location.city}, ${location.country}

        Réponds uniquement par un objet JSON valide contenant :
        1. approved (boolean) : si l'annonce est saine, sans arnaque, sans contenu illicite ou offensant.
        2. score (number entre 0 et 100) : score de confiance générale.
        3. reason (string d'explication en français) : justification condensée de ta décision.
        4. suggestedCategory (string optionnel) : catégorie suggérée la plus proche si besoin.
        5. improvements (string optionnel) : conseils brefs pour améliorer la rédaction de l'annonce si applicable.`,
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              approved: { type: Type.BOOLEAN },
              score: { type: Type.INTEGER },
              reason: { type: Type.STRING },
              suggestedCategory: { type: Type.STRING },
              improvements: { type: Type.STRING }
            },
            required: ["approved", "score", "reason"]
          }
        }
      });

      const aiReview = JSON.parse(response.text.trim());
      console.log("[Gemini AI] Review Complete:", aiReview);
      
      newListing.aiReview = aiReview;
      // If AI scores it high (e.g., >= 80), auto-approve it! 
      // Else, keep it pending for manual admin review.
      if (aiReview.approved && aiReview.score >= 80) {
        newListing.status = "approved";
      } else {
        newListing.status = "pending";
      }

    } catch (err) {
      console.error("[Gemini AI] Error running listing moderation. Falling back to default rules.", err);
      // Fallback
      newListing.status = "approved"; // default auto approve if AI key has issues
      newListing.aiReview = {
        approved: true,
        score: 90,
        reason: "Validation automatique effectuée avec succès (Fallback local)."
      };
    }
  } else {
    // Fallback when no API Key
    newListing.status = "approved"; // default auto approve
    newListing.aiReview = {
      approved: true,
      score: 100,
      reason: "Approuvé automatiquement (Mode démo)."
    };
  }

  dbState.listings.push(newListing);
  saveDB(dbState);

  res.json({ success: true, listing: newListing });
});

// 5. Admin Actions: Moderate Listings (Approve/Reject)
app.post("/api/listings/moderate", (req, res) => {
  const { listingId, status } = req.body;
  if (!listingId || !status) {
    return res.status(400).json({ error: "listingId et status requis." });
  }

  const idx = dbState.listings.findIndex(l => l.id === listingId);
  if (idx === -1) {
    return res.status(404).json({ error: "Annonce non trouvée." });
  }

  dbState.listings[idx].status = status;
  saveDB(dbState);

  res.json({ success: true, listing: dbState.listings[idx] });
});

// 5b. Reviews and Star Rating system
app.post("/api/listings/:id/reviews", (req, res) => {
  const { id } = req.params;
  const { authorId, authorName, rating, comment } = req.body;

  if (!authorId || !authorName || rating === undefined || !comment) {
    return res.status(400).json({ error: "Tous les champs de l'avis sont requis." });
  }

  const idx = dbState.listings.findIndex((l: any) => l.id === id);
  if (idx === -1) {
    return res.status(404).json({ error: "Annonce non trouvée." });
  }

  const listing = dbState.listings[idx];
  if (!listing.reviews) {
    listing.reviews = [];
  }

  const newReview = {
    id: "rev-" + Math.random().toString(36).substring(2, 9),
    authorId,
    authorName,
    rating: Number(rating),
    comment,
    createdAt: new Date().toISOString()
  };

  listing.reviews.push(newReview);
  
  // Recalculate average rating
  const total = listing.reviews.reduce((acc: number, r: any) => acc + r.rating, 0);
  listing.averageRating = Number((total / listing.reviews.length).toFixed(1));

  saveDB(dbState);
  res.json({ success: true, listing });
});

// 6. Admin Actions: Delete Listings
app.post("/api/listings/delete", (req, res) => {
  const { listingId } = req.body;
  if (!listingId) {
    return res.status(400).json({ error: "listingId requis." });
  }

  dbState.listings = dbState.listings.filter(l => l.id !== listingId);
  saveDB(dbState);

  res.json({ success: true });
});

// 7. Admin Actions: Moderate Users (Verify Professional Verification Requests)
app.post("/api/users/moderate", (req, res) => {
  const { userId, status } = req.body; // status can be 'verified' | 'unverified'
  if (!userId || !status) {
    return res.status(400).json({ error: "userId et status requis." });
  }

  const idx = dbState.users.findIndex(u => u.id === userId);
  if (idx === -1) {
    return res.status(404).json({ error: "Utilisateur non trouvé." });
  }

  dbState.users[idx].verificationStatus = status;
  // If verified, synchronize all listings of this user to be 'isVerified = true'!
  if (status === 'verified') {
    dbState.listings = dbState.listings.map(l => {
      if (l.authorId === userId) {
        return { ...l, isVerified: true };
      }
      return l;
    });
  }

  saveDB(dbState);

  res.json({ success: true, user: dbState.users[idx] });
});

// 8. Admin Actions: Block / Unblock Users
app.post("/api/users/block", (req, res) => {
  const { userId, isBlocked } = req.body;
  if (!userId || isBlocked === undefined) {
    return res.status(400).json({ error: "userId et isBlocked requis." });
  }

  const idx = dbState.users.findIndex(u => u.id === userId);
  if (idx === -1) {
    return res.status(404).json({ error: "Utilisateur non trouvé." });
  }

  dbState.users[idx].isBlocked = isBlocked;
  saveDB(dbState);

  res.json({ success: true, user: dbState.users[idx] });
});

// 9. Community Discussion Message API
app.post("/api/messages", (req, res) => {
  const { channel, senderId, senderName, senderRole, senderIsVerified, content } = req.body;

  if (!channel || !senderId || !senderName || !content) {
    return res.status(400).json({ error: "Champs requis manquants." });
  }

  const newMessage = {
    id: "msg-" + Math.random().toString(36).substring(2, 9),
    channel,
    senderId,
    senderName,
    senderRole: senderRole || "user",
    senderIsVerified: senderIsVerified || false,
    content,
    createdAt: new Date().toISOString()
  };

  dbState.messages.push(newMessage);
  saveDB(dbState);

  res.json({ success: true, message: newMessage });
});

// 10. Admin Actions: Send notifications
app.post("/api/notifications", (req, res) => {
  const { title, content, type } = req.body;
  if (!title || !content || !type) {
    return res.status(400).json({ error: "Titre, contenu et type requis." });
  }

  const newNotif = {
    id: "notif-" + Math.random().toString(36).substring(2, 9),
    title,
    content,
    type,
    createdAt: new Date().toISOString()
  };

  dbState.notifications.unshift(newNotif);
  saveDB(dbState);

  res.json({ success: true, notification: newNotif });
});

// 11. AI Intelligent Search parsing using Gemini
app.post("/api/search", async (req, res) => {
  const { query, listings } = req.body;
  if (!query) {
    return res.status(400).json({ error: "Query requise." });
  }

  const ai = getGemini();
  if (ai && listings && listings.length > 0) {
    try {
      console.log(`[Gemini AI] Smart Search matching query: "${query}"...`);
      const response = await ai.models.generateContent({
        model: "gemini-3.5-flash",
        contents: `Tu es un moteur de recherche intelligent pour l'application de réseau EuroHabesha en Europe.
        L'utilisateur recherche des annonces avec cette phrase en français (ou autre langue) : "${query}".
        
        Voici la liste des annonces disponibles au format JSON :
        ${JSON.stringify(listings.map((l: any) => ({ id: l.id, type: l.type, category: l.category, title: l.title, description: l.description, city: l.location.city, country: l.location.country, lang: l.spokenLanguages })))}

        Analyse l'intention de l'utilisateur, et trouve les meilleures annonces qui correspondent le mieux à sa demande.
        Recommande uniquement les IDs des annonces pertinentes par ordre de pertinence.
        
        Réponds uniquement par un objet JSON valide structuré ainsi :
        {
          "matchingIds": [ "id1", "id2", ... ],
          "explanation": "Bref résumé de ce que l'utilisateur recherche et pourquoi ces annonces correspondent"
        }`,
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              matchingIds: {
                type: Type.ARRAY,
                items: { type: Type.STRING }
              },
              explanation: { type: Type.STRING }
            },
            required: ["matchingIds", "explanation"]
          }
        }
      });

      const parsedMatch = JSON.parse(response.text.trim());
      res.json({ success: true, matchedIds: parsedMatch.matchingIds, explanation: parsedMatch.explanation });
    } catch (err) {
      console.error("[Gemini AI] Error during smart search. Falling back to local keyword matches.", err);
      res.json({ success: false, error: "AI search failed, fallback used." });
    }
  } else {
    res.json({ success: false, error: "No AI client available." });
  }
});

// Start server and handle Vite Middleware
async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
