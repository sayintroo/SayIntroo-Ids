// Shared helpers: Supabase client, live updates, toasts, QR, formatting.
(function () {
  const C = window.CONFIG;

  const configured = !!(C.supabase && C.supabase.url && !C.supabase.url.includes('YOUR-PROJECT') &&
    C.supabase.anonKey && !C.supabase.anonKey.startsWith('YOUR-'));

  const sb = configured && window.supabase
    ? window.supabase.createClient(C.supabase.url, C.supabase.anonKey, { auth: { persistSession: false } })
    : null;

  // Call a database function; throws a readable Error on failure.
  async function rpc(name, args) {
    if (!sb) throw new Error('Supabase set nahi hai — config.js check karo');
    const { data, error } = await sb.rpc(name, args || {});
    if (error) throw new Error(cleanErr(error.message));
    return data;
  }

  async function select(table, build) {
    if (!sb) return [];
    let q = sb.from(table).select('*');
    if (build) q = build(q);
    const { data, error } = await q;
    if (error) throw new Error(cleanErr(error.message));
    return data || [];
  }

  function cleanErr(msg) {
    if (/Failed to fetch|NetworkError/i.test(msg)) return 'Internet slow hai, dobara try karo';
    return msg;
  }

  // Run `refresh` now, whenever any of `tables` changes (realtime), and every
  // `pollMs` as a safety net in case realtime drops at the venue.
  function live(tables, refresh, pollMs) {
    let t = null;
    const kick = () => { clearTimeout(t); t = setTimeout(() => refresh().catch(console.error), 150); };
    refresh().catch(console.error);
    if (!sb) return;
    const ch = sb.channel('live-' + tables.join('-') + '-' + Math.random().toString(36).slice(2, 7));
    tables.forEach((table) => ch.on('postgres_changes', { event: '*', schema: 'public', table }, (payload) => {
      if (live.onEvent) live.onEvent(table, payload);
      kick();
    }));
    ch.subscribe();
    setInterval(kick, pollMs || 15000);
    document.addEventListener('visibilitychange', () => { if (!document.hidden) kick(); });
  }

  function toast(msg, isErr) {
    let el = document.querySelector('.toast');
    if (!el) { el = document.createElement('div'); el.className = 'toast'; document.body.appendChild(el); }
    el.textContent = msg;
    el.classList.toggle('err', !!isErr);
    el.classList.add('show');
    clearTimeout(toast._t);
    toast._t = setTimeout(() => el.classList.remove('show'), 2600);
  }

  const inr = (n) => '₹' + Math.round(Number(n) || 0).toLocaleString('en-IN');
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const $ = (sel, root) => (root || document).querySelector(sel);
  const $$ = (sel, root) => Array.from((root || document).querySelectorAll(sel));

  // Animate a number inside `el` from its current value to `to`.
  function countTo(el, to, fmt, ms) {
    const from = Number(el.dataset.val || 0);
    el.dataset.val = to;
    const start = performance.now();
    const dur = ms || 1200;
    const f = fmt || ((x) => Math.round(x).toLocaleString('en-IN'));
    (function step(now) {
      const p = Math.min(1, (now - start) / dur);
      const e = 1 - Math.pow(1 - p, 3);
      el.textContent = f(from + (to - from) * e);
      if (p < 1) requestAnimationFrame(step);
    })(start);
  }

  // Draw a QR code into a canvas (dark modules in `fg` on `bg`).
  function qrCanvas(text, size, fg, bg) {
    const qr = window.qrcode(0, 'M');
    qr.addData(text);
    qr.make();
    const n = qr.getModuleCount();
    const quiet = 2;
    const cv = document.createElement('canvas');
    cv.width = cv.height = size;
    const ctx = cv.getContext('2d');
    ctx.fillStyle = bg || '#fff';
    ctx.fillRect(0, 0, size, size);
    const cell = size / (n + quiet * 2);
    ctx.fillStyle = fg || '#000';
    for (let r = 0; r < n; r++) for (let c = 0; c < n; c++) {
      if (qr.isDark(r, c)) ctx.fillRect(Math.floor((c + quiet) * cell), Math.floor((r + quiet) * cell), Math.ceil(cell), Math.ceil(cell));
    }
    return cv;
  }

  function upiLink(amount) {
    const p = new URLSearchParams({ pa: C.upi.id, pn: C.upi.payeeName, cu: 'INR', tn: C.upi.note });
    if (amount) p.set('am', String(amount));
    return 'upi://pay?' + p.toString().replace(/\+/g, '%20');
  }

  // Render sponsor logos; falls back to a text badge when the file is missing.
  function logoHTML(s, cls) {
    return `<span class="${cls || 'logo'}"><img src="${esc(s.logo)}" alt="${esc(s.name)}" loading="lazy"
      onerror="this.replaceWith(Object.assign(document.createElement('b'),{textContent:this.alt}))"></span>`;
  }

  function copy(text, okMsg) {
    const done = () => toast(okMsg || 'Copied ✅');
    if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text).then(done, () => fallback());
    fallback();
    function fallback() {
      const ta = document.createElement('textarea');
      ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
      document.body.appendChild(ta); ta.select();
      try { document.execCommand('copy'); done(); } catch (e) { prompt('Copy this:', text); }
      ta.remove();
    }
  }

  // Simple password gate for admin pages. Verifies against the database.
  async function passwordGate(kind, storeKey) {
    const saved = sessionStorage.getItem(storeKey);
    if (saved && await rpc('check_password', { kind, pw: saved }).catch(() => false)) return saved;
    return new Promise((resolve) => {
      const box = document.createElement('div');
      box.className = 'gate';
      box.innerHTML = `<form class="card" style="max-width:360px;margin:18vh auto 0;">
        <div class="mono gold">Sirf volunteers ke liye 🔒</div>
        <h2 style="margin:6px 0 4px;font-size:28px;">Password daalo</h2>
        <input class="input" type="password" autocomplete="current-password" placeholder="••••••" required>
        <button class="btn block" style="margin-top:12px;">Andar aao</button>
        <p class="muted" style="font-size:13px;margin:10px 0 0;">Password Supabase setup.sql mein set kiya tha.</p>
      </form>`;
      box.style.cssText = 'position:fixed;inset:0;z-index:50;background:var(--bg);padding:16px;';
      document.body.appendChild(box);
      box.querySelector('form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const pw = box.querySelector('input').value;
        try {
          if (await rpc('check_password', { kind, pw })) {
            sessionStorage.setItem(storeKey, pw); box.remove(); resolve(pw);
          } else toast('Galat password 🙅', true);
        } catch (err) { toast(err.message, true); }
      });
    });
  }

  function confetti(n, set) {
    const icons = set || ['✨', '🌸', '💛', '🎉', '💸', '🪔'];
    for (let i = 0; i < (n || 40); i++) {
      const s = document.createElement('span');
      s.textContent = icons[i % icons.length];
      s.style.cssText = `position:fixed;top:-40px;left:${Math.random() * 100}vw;font-size:${18 + Math.random() * 22}px;z-index:998;pointer-events:none;
        transition:transform ${2 + Math.random() * 2}s linear, opacity 0.5s ${1.8 + Math.random()}s;`;
      document.body.appendChild(s);
      requestAnimationFrame(() => { s.style.transform = `translate(${(Math.random() - 0.5) * 200}px, ${innerHeight + 80}px) rotate(${Math.random() * 720}deg)`; s.style.opacity = '0'; });
      setTimeout(() => s.remove(), 4500);
    }
  }

  window.App = { C, sb, configured, rpc, select, live, toast, inr, esc, $, $$, countTo, qrCanvas, upiLink, logoHTML, copy, passwordGate, confetti };
})();
