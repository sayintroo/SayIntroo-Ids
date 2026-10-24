# #AanshKiShaadi — Fake shaadi. Real shagun.

Event web apps for **Communite × Imperial presents Fake Shaadi** (25 Oct, Imperial Palace, Chandrapur).
Plain HTML + JS, so there's no build step: Vercel serves the `public/` folder as-is. One free Supabase project powers all the live parts.

| URL | What | Who |
|---|---|---|
| `/` | **Real Shagun**: tiers, UPI pay, live counter, leaderboard, shagun story card, FAQ | Everyone (Insta link) |
| `/admin` | Volunteer desk: add donations, approve aashirwads | Volunteers (password) |
| `/stage` | Projector: big counter, top 5, rotating aashirwad, UPI QR | Projector |
| `/party` | Guest app: join → team, live polls, gossip, Rishta Pakka | Guests (via QR) |
| `/party/qr` | Printable join QR | Print it |
| `/party/admin` | Host panel: polls, gossip, aura, 7 phere, Rishta Pakka, guests | Host (password) |
| `/party/stage` | Projector: team score, poll bars, top 10 aura, Breaking News ticker | Projector |
| `/party/report` | Guest count, team split, votes, top aura, shagun → WhatsApp | Club |
| `/kundli` | Red Flag Kundli Milan booth (works offline after first load) | Booth device |
| `/pitch` | SayIntro pitch deck (6 slides, swipe) | Club |
| `/hub` | All links in one place | Volunteers |

---

## ⚡ Setup (about 15 min)

### 1. Supabase (free): the live database
1. Go to **supabase.com** → sign in with GitHub → **New project**. Name: `aanshkishaadi`, region: **Mumbai (ap-south-1)**, set any DB password → Create. Wait about 2 minutes.
2. Left sidebar → **SQL Editor** → **New query**.
3. Open `supabase/setup.sql` from this repo and copy all of it.
4. **Change the two passwords** near the top (`change-me-shagun` = volunteers, `change-me-host` = host).
5. Paste into the SQL editor → **Run**. You should see "Success". (Notices in yellow are fine.)
6. Left sidebar → **Project Settings → API**. Copy:
   - **Project URL** (`https://xxxx.supabase.co`)
   - **anon public** key (the long `eyJ...` one. Do NOT use `service_role`)

> To change a password later, edit it in `setup.sql` and run the file again. Your data stays.

### 2. Edit `public/config.js` (the only file you need to touch)
- `ngo.name`, `ngo.about`, `ngo.link`
- `upi.id` (the NGO's UPI ID), `upi.payeeName`
- `goal` (₹ target)
- `supabase.url` and `supabase.anonKey` from step 1

### 3. Logos (optional, can do later)
Drop PNGs into `public/logos/` using the names in `public/logos/LOGOS.txt`. A missing logo shows as text.

---

## 🚀 Deploy on Vercel (step by step)

1. Commit + push your `config.js` changes to GitHub. (The anon key is meant to be public; the database rules protect everything.)
2. Go to **vercel.com** → sign in with GitHub → **Add New… → Project**.
3. Pick the repo **SayIntroo-Ids** → **Import**.
4. On the configure screen:
   - **Root Directory** → click *Edit* → choose **`fake-shaadi`** ← important
   - **Framework Preset** → **Other**
   - Leave Build Command and Output Directory as they are (`vercel.json` already sets output to `public`)
5. **Deploy**. About 30 seconds later you get `https://something.vercel.app`.
6. Optional: Project → Settings → **Domains** → add a nicer name, e.g. `aanshkishaadi.vercel.app`.
7. Every later `git push` redeploys automatically.

> Deploying from a branch other than `main`? In Vercel → Project → Settings → Git, set the **Production Branch** to that branch, or merge it into `main`.

### Test before the event (10 min, do it today)
1. Open `/hub` on your phone.
2. `/admin` → log in → add a ₹51 test donation → check that `/` and `/stage` update live.
3. `/party` on 2 phones → join → check that they land in different teams.
4. `/party/admin` → create a poll → vote from the phones → watch `/party/stage`.
5. Send a gossip → approve it → it scrolls on the stage ticker.
6. Rishta tab → **Open** → both phones pick each other → **Reveal** → both see "Rishta pakka 🔥".
7. Pay ₹1 using the UPI button to confirm the NGO's UPI ID works.
8. **Clean up:** `/admin` → Danger zone → Reset, and `/party/admin` → Guests → Reset. Type `RESET`.
9. Open `/kundli` once on the booth device while online. After that it works offline.

---

## Event-day cheat sheet
- **Projector 1:** `/party/stage` → press ⛶ for fullscreen. **Projector 2 (or switch later):** `/stage`.
- **Entry gate:** print `/party/qr` (it also shows the shagun QR).
- **Volunteers:** `/admin` on 1–2 phones. A guest shows their payment screenshot → you type their name/handle and amount → it shows on the leaderboard instantly.
- **Host:** `/party/admin` on a phone. Aura buttons: +50 / +100 / +500 / −100, plus a reason. Made a mistake? Hit ↩️ undo.
- **Rishta Pakka finale:** Host → Rishta tab → **Open** (or schedule a time) → give people about 10 min → **Band karo + Reveal**. The stage only ever shows the count.
- **After the party:** `/party/report` → add the Kundli pair count (shown on the booth's home screen) → **WhatsApp pe bhejo**.

## Privacy, honestly
- Guests' names and handles are visible to other guests (the consent line on the join screen says so).
- **Rishta picks** are stored in a table the website can never read. Guests only ever see their *own* mutual matches, and only after the reveal. The host panel and stage show counts only.
- Gossip is stored without the sender's ID.
- Note: anyone with access to your **Supabase dashboard** can see raw tables. Keep that login to yourself.

## Limits to know
- Supabase free tier allows ~200 simultaneous live connections. Above that, pages fall back to refreshing every 10–20 s automatically, so nothing breaks.
- Some in-app browsers (Instagram) block `upi://` links. The page tells people to copy the UPI ID or open it in Chrome.
- One guest = one Insta handle. If someone switches phones, the host can remove them under **Guests** so they can rejoin.

---
Built by **SayIntro**
