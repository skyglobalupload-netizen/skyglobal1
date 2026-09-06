/* =====================================================================
   SKY GLOBAL — shared behaviour  (no external libraries)
   i18n · header state · mobile menu · nav dropdown · scroll reveals ·
   counters · subtle parallax
   Progressive enhancement: all content is visible and usable without JS.
   ?nofx  — disables motion (used for static review of hidden panes)
   ===================================================================== */
(function () {
  var docEl = document.documentElement;
  var NOFX = /(?:\?|&)nofx\b/.test(location.search);
  var reduce = NOFX || window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  docEl.classList.add('js');
  if (!reduce) docEl.classList.add('fx');         /* gates the hide-then-reveal + hero load-in */
  else docEl.style.scrollBehavior = 'auto';

  /* ---------- i18n ---------- */
  var DEFAULT_TITLES = window.SG_TITLES || {
    en: document.title,
    ar: (document.querySelector('meta[name="title-ar"]') || {}).content || document.title
  };
  function setLang(l) {
    var rtl = l === 'ar';
    docEl.lang = l;
    docEl.dir = rtl ? 'rtl' : 'ltr';
    if (DEFAULT_TITLES[l]) document.title = DEFAULT_TITLES[l];
    var lbl = document.getElementById('langLabel');
    if (lbl) lbl.textContent = rtl ? 'English' : 'العربية';
    document.querySelectorAll('[data-en]').forEach(function (el) {
      var v = el.getAttribute('data-' + l);
      if (v == null) return;
      if (/[<&]/.test(v)) el.innerHTML = v; else el.textContent = v;
    });
    document.querySelectorAll('[data-en-placeholder]').forEach(function (el) {
      var v = el.getAttribute('data-' + l + '-placeholder');
      if (v != null) el.setAttribute('placeholder', v);
    });
    try { localStorage.setItem('sg_lang', l); } catch (e) {}
  }
  var saved = null;
  try { saved = localStorage.getItem('sg_lang'); } catch (e) {}
  setLang(saved || ((navigator.language || 'en').toLowerCase().indexOf('ar') === 0 ? 'ar' : 'en'));
  var langBtn = document.getElementById('langBtn');
  if (langBtn) langBtn.addEventListener('click', function () { setLang(docEl.dir === 'rtl' ? 'en' : 'ar'); });

  /* ---------- header state ---------- */
  var hdr = document.getElementById('hdr');
  if (hdr) {
    var onScroll = function () { hdr.classList.toggle('scrolled', window.scrollY > 60); };
    onScroll();
    addEventListener('scroll', onScroll, { passive: true });
  }

  /* ---------- nav dropdown (hover is CSS; JS adds click + keyboard) ---------- */
  document.querySelectorAll('[data-subtoggle]').forEach(function (btn) {
    var wrap = btn.parentElement;
    var close = function () { btn.setAttribute('aria-expanded', 'false'); wrap.classList.remove('open'); };
    btn.addEventListener('click', function (e) {
      e.preventDefault();
      var open = wrap.classList.toggle('open');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    document.addEventListener('click', function (e) { if (!wrap.contains(e.target)) close(); });
    wrap.addEventListener('keydown', function (e) { if (e.key === 'Escape') { close(); btn.focus(); } });
  });

  /* ---------- mobile menu ---------- */
  var mt = document.getElementById('menuToggle'), mm = document.getElementById('mobileMenu');
  if (mt && mm) {
    var closeMenu = function () {
      mm.classList.remove('open'); mt.setAttribute('aria-expanded', 'false'); document.body.style.overflow = '';
    };
    mt.addEventListener('click', function () {
      var open = mm.classList.toggle('open');
      mt.setAttribute('aria-expanded', open ? 'true' : 'false');
      document.body.style.overflow = open ? 'hidden' : '';
    });
    mm.querySelectorAll('a').forEach(function (a) { a.addEventListener('click', closeMenu); });
    addEventListener('keydown', function (e) { if (e.key === 'Escape') closeMenu(); });
  }

  /* ---------- leadership cards: bio reveal ---------- */
  document.querySelectorAll('[data-bio-toggle]').forEach(function (btn) {
    var card = btn.closest('.pcard');
    if (!card) return;
    var panel = card.querySelector('[data-bio]');
    var closeBtn = card.querySelector('[data-bio-close]');
    var supportsInert = 'inert' in HTMLElement.prototype;
    function set(open) {
      card.classList.toggle('bio-open', open);
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      if (panel) {
        panel.setAttribute('aria-hidden', open ? 'false' : 'true');
        if (supportsInert) panel.inert = !open;
      }
      if (open && closeBtn) closeBtn.focus();
    }
    set(false);
    btn.addEventListener('click', function () { set(!card.classList.contains('bio-open')); });
    if (closeBtn) closeBtn.addEventListener('click', function () { set(false); btn.focus(); });
    card.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && card.classList.contains('bio-open')) { set(false); btn.focus(); }
    });
  });

  /* ---------- footer newsletter (no backend yet — inline acknowledgement) ---------- */
  document.querySelectorAll('[data-newsletter]').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var input = form.querySelector('input[type="email"]');
      if (input && !input.checkValidity()) { input.reportValidity(); return; }
      form.classList.add('done');
    });
  });

  /* ---------- count up ---------- */
  function fmt(v, plain) { try { return plain ? String(v) : v.toLocaleString('en-US'); } catch (e) { return String(v); } }
  function countUp(el) {
    if (el.dataset.done) return; el.dataset.done = '1';
    var target = parseFloat(el.getAttribute('data-count'));
    var suffix = el.getAttribute('data-suffix') || '';
    var plain = el.getAttribute('data-plain');
    var final = fmt(target, plain) + suffix;
    if (reduce || isNaN(target)) { el.textContent = final; return; }
    var dur = 1400, t0 = Date.now();
    (function step() {
      var p = Math.min(1, (Date.now() - t0) / dur), e = 1 - Math.pow(1 - p, 3);
      el.textContent = fmt(Math.round(target * e), plain) + suffix;
      if (p < 1) requestAnimationFrame(step); else el.textContent = final;
    })();
  }

  /* ---------- scroll reveals + counters (IntersectionObserver) ---------- */
  document.querySelectorAll('[data-stagger]').forEach(function (group) {
    [].slice.call(group.children).forEach(function (c, i) { c.style.setProperty('--d', i * 70); });
  });

  var reveals = [].slice.call(document.querySelectorAll('.reveal'));
  var counters = [].slice.call(document.querySelectorAll('[data-count]'));

  if (reduce || !('IntersectionObserver' in window)) {
    reveals.forEach(function (el) { el.classList.add('in'); });
    counters.forEach(countUp);
  } else {
    var io = new IntersectionObserver(function (ents) {
      ents.forEach(function (en) {
        if (!en.isIntersecting) return;
        en.target.classList.add('in');
        io.unobserve(en.target);
      });
    }, { rootMargin: '0px 0px -10% 0px', threshold: 0.12 });
    reveals.forEach(function (el) { io.observe(el); });

    var cio = new IntersectionObserver(function (ents) {
      ents.forEach(function (en) { if (en.isIntersecting) { countUp(en.target); cio.unobserve(en.target); } });
    }, { threshold: 0.5 });
    counters.forEach(function (el) { cio.observe(el); });

    /* failsafe: never leave anything hidden (e.g. a frozen preview pane) */
    setTimeout(function () { reveals.forEach(function (el) { el.classList.add('in'); }); }, 2600);
  }

  /* ---------- subtle parallax (transform only; opt-out on touch / reduced) ---------- */
  var coarse = window.matchMedia('(pointer: coarse)').matches;
  if (!reduce && !coarse) {
    var layers = [].slice.call(document.querySelectorAll('[data-parallax-bg]'));
    if (layers.length) {
      var ticking = false;
      var apply = function () {
        var vh = window.innerHeight;
        layers.forEach(function (el) {
          var box = el.parentElement.getBoundingClientRect();
          var mid = box.top + box.height / 2;
          var shift = ((mid - vh / 2) / vh) * -22;   /* px, gentle */
          el.style.transform = 'translate3d(0,' + shift.toFixed(1) + 'px,0)';
        });
        ticking = false;
      };
      var onMove = function () { if (!ticking) { ticking = true; requestAnimationFrame(apply); } };
      addEventListener('scroll', onMove, { passive: true });
      addEventListener('resize', onMove, { passive: true });
      apply();
    }
  }
})();
