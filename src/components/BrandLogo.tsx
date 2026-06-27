import React from "react";

interface BrandLogoProps {
  className?: string;
  showText?: boolean;
  textColor?: string;
  variant?: "light" | "dark" | "gold";
}

export default function BrandLogo({
  className = "w-12 h-12",
  showText = false,
  textColor = "text-stone-900",
  variant = "gold"
}: BrandLogoProps) {
  return (
    <div className="flex items-center gap-3">
      <div className={`relative shrink-0 ${className}`}>
        <svg
          viewBox="0 0 320 320"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="w-full h-full drop-shadow-[0_4px_12px_rgba(12,56,35,0.18)] filter"
        >
          {/* DEFINITIONS FOR GRADIENTS AND METALLIC SHINES */}
          <defs>
            {/* Rich Gold Metal Gradient */}
            <linearGradient id="goldMetal" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#FFF2C2" />
              <stop offset="30%" stopColor="#E9C155" />
              <stop offset="60%" stopColor="#AF8312" />
              <stop offset="100%" stopColor="#FFF2C2" />
            </linearGradient>

            {/* Silver Metal Gradient */}
            <linearGradient id="silverMetal" x1="0%" y1="100%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#FFFFFF" />
              <stop offset="50%" stopColor="#D8D8D8" />
              <stop offset="100%" stopColor="#9C9C9C" />
            </linearGradient>

            {/* Traditional Ethiopian Green */}
            <linearGradient id="ethiopianGreen" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#078930" />
              <stop offset="100%" stopColor="#04591E" />
            </linearGradient>

            {/* Traditional Ethiopian Yellow */}
            <linearGradient id="ethiopianYellow" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#FCD116" />
              <stop offset="100%" stopColor="#C6A10C" />
            </linearGradient>

            {/* Traditional Ethiopian Red */}
            <linearGradient id="ethiopianRed" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#EF3340" />
              <stop offset="100%" stopColor="#A8111B" />
            </linearGradient>

            {/* Traditional Dress Cream Fabric (Shemma / Netela cotton) */}
            <linearGradient id="habeshaCream" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#FDFCF7" />
              <stop offset="100%" stopColor="#FAF5EA" />
            </linearGradient>

            {/* Subtle Inner Glow Shadow */}
            <filter id="logoShadow" x="-10%" y="-10%" width="130%" height="130%">
              <feDropShadow dx="2" dy="4" stdDeviation="4" floodColor="#000000" floodOpacity="0.25" />
            </filter>

            {/* Soft blurring filter for the Europe map backdrop */}
            <filter id="blurFilter" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation="3.5" />
            </filter>
          </defs>

          {/* Background Ring Shield (Transparent background to make it overlay smoothly) */}
          <circle cx="160" cy="160" r="148" fill="transparent" />

          {/* BLURRED EUROPE MAP SILHOUETTE (Non-bright, blurred, placed in the center-left) */}
          <g filter="url(#blurFilter)" transform="translate(-22, 10)" opacity="0.32">
            <path
              d="M100 135 C105 120, 115 110, 125 105 C135 100, 145 105, 155 100 
                 C165 95, 170 85, 180 80 C190 75, 205 70, 215 85 C220 90, 210 100, 220 110 
                 C228 118, 235 110, 240 120 C245 130, 235 145, 225 155 C215 165, 205 170, 200 180 
                 C195 190, 205 200, 195 210 C185 220, 175 210, 165 225 C155 240, 140 235, 130 220 
                 C120 205, 110 200, 115 185 C120 170, 105 165, 100 155 Z"
              fill="url(#ethiopianYellow)"
              stroke="url(#goldMetal)"
              strokeWidth="3.5"
              strokeLinejoin="round"
            />
          </g>

          {/* TRADITIONAL ETHIOPIAN MESOB (BASKET) ON THE RIGHT */}
          <g filter="url(#logoShadow)">
            {/* 1. Conical Lid (Cream fabric base with red and green woven triangles) */}
            <path
              d="M254 94 L204 142 C204 142, 254 155, 304 142 Z"
              fill="url(#habeshaCream)"
              stroke="url(#goldMetal)"
              strokeWidth="3.5"
            />
            {/* Lid colorful weave segments */}
            <path
              d="M254 94 L212 142 L230 142 Z"
              fill="url(#ethiopianGreen)"
              opacity="0.95"
            />
            <path
              d="M254 94 L230 142 L248 142 Z"
              fill="url(#ethiopianYellow)"
              opacity="0.95"
            />
            <path
              d="M254 94 L248 142 L266 142 Z"
              fill="url(#ethiopianRed)"
              opacity="0.95"
            />
            <path
              d="M254 94 L266 142 L284 142 Z"
              fill="url(#ethiopianGreen)"
              opacity="0.95"
            />
            <path
              d="M254 94 L284 142 L302 142 Z"
              fill="url(#ethiopianRed)"
              opacity="0.95"
            />

            {/* Elegant lid chevrons matching the handwoven patterns */}
            <path
              d="M214 135 L254 98 L294 135"
              fill="none"
              stroke="url(#goldMetal)"
              strokeWidth="3.5"
              strokeLinecap="round"
            />
            <path
              d="M228 138 L254 112 L280 138"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="2.5"
              strokeLinecap="round"
              opacity="0.9"
            />
            <path
              d="M240 140 L254 125 L268 140"
              fill="none"
              stroke="url(#ethiopianRed)"
              strokeWidth="2"
              strokeLinecap="round"
            />

            {/* Top crown handle knob of Mesob */}
            <path
              d="M254 94 C254 94, 250 82, 254 78 C258 74, 262 78, 262 82 Z"
              fill="url(#goldMetal)"
              stroke="#A37E1C"
              strokeWidth="1.5"
            />
            <ellipse cx="256" cy="76" rx="5.5" ry="3.5" fill="url(#ethiopianRed)" stroke="url(#goldMetal)" strokeWidth="1" />

            {/* 2. Neck/Rim of Mesob (Striped horizontal band) */}
            <rect x="202" y="142" width="104" height="10" rx="3" fill="url(#goldMetal)" stroke="url(#goldMetal)" strokeWidth="1.5" />
            <path d="M206 142 L206 152 M216 142 L216 152 M226 142 L226 152 M236 142 L236 152 M246 142 L246 152 M256 142 L256 152 M266 142 L266 152 M276 142 L276 152 M286 142 L286 152 M296 142 L296 152 M302 142 L302 152" stroke="url(#ethiopianGreen)" strokeWidth="2.5" />
            <path d="M211 142 L211 152 M221 142 L221 152 M231 142 L231 152 M241 142 L241 152 M251 142 L251 152 M261 142 L261 152 M271 142 L271 152 M281 142 L281 152 M291 142 L291 152 M299 142 L299 152" stroke="url(#ethiopianRed)" strokeWidth="2.5" />

            {/* 3. Bowl / Middle Drum Body (Cream cotton fabric base with gorgeous traditional patterns) */}
            <path
              d="M196 152 C196 152, 222 180, 258 180 C294 180, 312 152, 312 152 C312 152, 305 187, 290 207 C275 227, 245 227, 225 220 Z"
              fill="url(#habeshaCream)"
              stroke="url(#goldMetal)"
              strokeWidth="3.5"
            />

            {/* Drum Middle Traditional Geometric Zig-Zag Patterns (Emulating local handwoven "Tibeb" crafts) */}
            <path
              d="M198 157 L218 177 L236 157 L254 177 L272 157 L290 177 L308 157"
              fill="none"
              stroke="url(#ethiopianRed)"
              strokeWidth="3.5"
              strokeLinecap="round"
            />
            <path
              d="M198 172 L218 152 L236 172 L254 152 L272 172 L290 152 L308 172"
              fill="none"
              stroke="url(#ethiopianGreen)"
              strokeWidth="3"
              strokeLinecap="round"
            />
            <path
              d="M208 165 L226 182 L244 165 L262 182 L280 165 L298 182"
              fill="none"
              stroke="url(#ethiopianYellow)"
              strokeWidth="2.5"
              strokeLinecap="round"
            />

            {/* 4. Base Pedestal (Flared bottom) */}
            <path
              d="M232 230 L284 230 C284 230, 276 200, 269 180 L245 180 Z"
              fill="url(#habeshaCream)"
              stroke="url(#goldMetal)"
              strokeWidth="2.5"
            />
            {/* Base weave textures */}
            <path d="M238 220 L278 190" stroke="url(#ethiopianRed)" strokeWidth="2.5" />
            <path d="M236 195 L276 225" stroke="url(#ethiopianGreen)" strokeWidth="2.5" />
            <path d="M245 185 L271 215" stroke="url(#ethiopianYellow)" strokeWidth="2" />
            <path d="M251 225 L251 185" stroke="url(#goldMetal)" strokeWidth="1.5" />
          </g>

          {/* GRAND CONTINUOUS TILET LOOP (Intertwined traditional country dress embroidery) */}
          {/* Starts from the top edge of the Mesob, sweeps beautifully to the left, and connects at the bottom pedestal of the Mesob */}
          <g filter="url(#logoShadow)">
            {/* Layer 1: Habesha Cream Fabric Base */}
            <path
              d="M 254 94 C 150 25, 35 70, 35 160 C 35 250, 150 295, 258 230"
              fill="none"
              stroke="url(#habeshaCream)"
              strokeWidth="20"
              strokeLinecap="round"
            />
            {/* Layer 2: Ethiopian Green Stripe */}
            <path
              d="M 254 94 C 150 25, 35 70, 35 160 C 35 250, 150 295, 258 230"
              fill="none"
              stroke="url(#ethiopianGreen)"
              strokeWidth="14"
              strokeLinecap="round"
            />
            {/* Layer 3: Ethiopian Yellow Stripe */}
            <path
              d="M 254 94 C 150 25, 35 70, 35 160 C 35 250, 150 295, 258 230"
              fill="none"
              stroke="url(#ethiopianYellow)"
              strokeWidth="8"
              strokeLinecap="round"
            />
            {/* Layer 4: Ethiopian Red Core */}
            <path
              d="M 254 94 C 150 25, 35 70, 35 160 C 35 250, 150 295, 258 230"
              fill="none"
              stroke="url(#ethiopianRed)"
              strokeWidth="4"
              strokeLinecap="round"
            />
            {/* Layer 5: Gold Metallic Stitching/Thread embroidery detail */}
            <path
              d="M 254 94 C 150 25, 35 70, 35 160 C 35 250, 150 295, 258 230"
              fill="none"
              stroke="url(#goldMetal)"
              strokeWidth="1.2"
              strokeDasharray="4 4"
              strokeLinecap="round"
            />
          </g>

          {/* SPARKLE ACCENT (In Top Right) */}
          <path
            d="M298 102 L302 108 L308 112 L302 116 L298 122 L294 116 L288 112 L294 108 Z"
            fill="url(#goldMetal)"
            className="animate-pulse"
          />
        </svg>
      </div>

      {showText && (
        <div className="flex flex-col">
          <span
            className={`font-unique font-black tracking-tight text-base sm:text-lg leading-none ${
              variant === "gold" ? "text-[#D4AF37]" : textColor
            }`}
          >
            EURO<span className={variant === "gold" ? "text-white" : "text-[#0C3823]"}>Habesha</span>
          </span>
          <span className="text-[8px] font-unique font-bold uppercase tracking-[0.25em] text-emerald-500 leading-none mt-1">
            Diaspora Link
          </span>
        </div>
      )}
    </div>
  );
}

