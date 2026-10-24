// =====================================================================
//  #AanshKiShaadi — EDIT THIS FILE ONLY.
//  Everything the site shows (NGO, UPI, goal, sponsors, tiers) is here.
// =====================================================================
window.CONFIG = {
  // 1) NGO + UPI — where the shagun goes
  ngo: {
    name: 'Your NGO Name',                 // e.g. "Helping Hands Foundation, Chandrapur"
    about: 'Har ek rupaya seedha NGO ke account mein jaata hai. Hum sirf shaadi fake karte hain, hisaab nahi.',
    link: '',                               // optional: NGO website / Insta link
  },
  upi: {
    id: 'yourngo@upi',                      // NGO's UPI ID (VPA)
    payeeName: 'Your NGO Name',             // name shown in the UPI app
    note: 'Shagun AanshKiShaadi',           // payment note (keep it short, no emojis)
  },
  goal: 51000,                              // ₹ target for the progress bar

  // 2) Supabase — paste from Supabase → Project Settings → API
  supabase: {
    url: 'https://YOUR-PROJECT.supabase.co',
    anonKey: 'YOUR-ANON-PUBLIC-KEY',
  },

  // 3) Event details
  event: {
    hashtag: '#AanshKiShaadi',
    presents: 'Communite × Imperial',
    date: '25 October',
    venue: 'Imperial Palace',
    city: 'Chandrapur',
    tagline: 'Fake shaadi. Real shagun.',
    insta: 'communite_chandrapur',
  },

  // 4) Sponsors — drop logo files in public/logos/ with these names.
  //    Missing file? The name shows as text instead. No stress.
  sponsors: {
    title: { name: 'Aansh Hospital & IVF Centre', logo: '/logos/aansh.png' },
    presentedBy: [
      { name: 'Imperial', logo: '/logos/imperial.png' },
      { name: 'Communite CP', logo: '/logos/communite.png' },
      { name: "Palangwar's Music", logo: '/logos/palangwars.png' },
    ],
    coSponsors: [
      { name: 'Ravista Backyard', logo: '/logos/ravista.png' },
      { name: 'Kiyaanz', logo: '/logos/kiyaanz.png' },
      { name: 'Elevate', logo: '/logos/elevate.png' },
      { name: 'Obsess', logo: '/logos/obsess.png' },
    ],
  },

  // 5) Shagun tiers
  tiers: [
    { amount: 51,   title: 'Chai pe charcha',          emoji: '☕', sub: 'Small sip, big dil' },
    { amount: 101,  title: 'Rishta Aunty approved',    emoji: '👵', sub: 'Aunty ne nod kar diya' },
    { amount: 251,  title: 'Phoopha ji finally khush', emoji: '😤', sub: 'Pehli baar in history' },
    { amount: 501,  title: 'Main character shagun',    emoji: '💅', sub: 'Spotlight is yours' },
    { amount: 1100, title: 'Dulhe se zyada famous',    emoji: '🕺', sub: 'Baraat tumhe dekhegi' },
    { amount: 2100, title: 'Baraat ka sponsor',        emoji: '🐎', sub: 'Ghodi bhi tumhari' },
  ],

  // Shown on /stage when nobody has sent an aashirwad yet
  defaultAashirwads: [
    'Fake shaadi, real dil. Khush raho! — Team Communite',
    'Rishta fake ho sakta hai, shagun nahi 💸',
    'Phoopha ji ne bhi shagun diya. Ab tumhari baari.',
  ],
};
