/* =====================================================================
   SKY GLOBAL — shared site footer (single source for every page)
   Builds the exact footer used on the Sky Global Holding home page
   (same markup, same .ft* classes from theme.css, same hover/focus
   micro-animations) from a small per-page config, so a future design
   change here updates every page at once.

   Per page, add:
     <div id="ft-mount"></div>
     <script type="application/json" id="ft-config">{ ... }</script>
     <script src="../assets/footer.js"></script>   (before app.js)

   Config shape (all fields optional except noted):
     isHome     bool   true only on index.html (skips the "back to home" link
                        and the Companies list doesn't need a "current" page)
     base       str    "" on the home page, "" on company pages too — company
                        links are built from `companiesBase` below
     accentVar  omit   accent theming is done with a tiny CSS override on
                        `footer.ft{--sky-400:…}` in the page itself, not here
     nameEn/nameAr           required — company (or "Sky Global Holding") name
     taglineEn/taglineAr     required — one-line description
     logoHTML                required — ready-to-use logo markup (each page
                              already defines its own <symbol>/icon, so the
                              page supplies the small markup that references it)
     explore    [{href,en,ar}]   this page's own section links
     contact    { email, phone, phoneHref, phone2, phone2Href,
                  locationEn, locationAr, hoursEn, hoursAr }
                — any field left out falls back to Sky Global Holding's own info
     companyId  str    matches one entry's id in COMPANIES, to mark "current"
   ===================================================================== */
(function () {
  var mount = document.getElementById('ft-mount');
  var cfgEl = document.getElementById('ft-config');
  if (!mount || !cfgEl) return;
  var cfg = {};
  try { cfg = JSON.parse(cfgEl.textContent); } catch (e) { cfg = {}; }

  var SKY = {
    email: 'info@skyglobalworld.com',
    phone: '+966 12 206 8728', phoneHref: 'tel:+966122068728',
    locationEn: 'Jeddah, Saudi Arabia', locationAr: 'جدة، المملكة العربية السعودية',
    hoursEn: 'Sun–Thu · 12:00–20:00', hoursAr: 'الأحد–الخميس · 12:00–20:00'
  };
  var c = cfg.contact || {};
  var contact = {
    email: c.email || SKY.email,
    phone: c.phone || SKY.phone, phoneHref: c.phoneHref || SKY.phoneHref,
    phone2: c.phone2 || null, phone2Href: c.phone2Href || null,
    locationEn: c.locationEn || SKY.locationEn, locationAr: c.locationAr || SKY.locationAr,
    hoursEn: c.hoursEn || SKY.hoursEn, hoursAr: c.hoursAr || SKY.hoursAr
  };

  var COMPANIES = [
    { id: 'fluiday', file: 'fluiday-auto.html', en: 'Fluiday Auto', ar: 'فلودي أوتو' },
    { id: 'nheroes', file: 'nheroes.html', en: 'NHeroes', ar: 'إن هيروز' },
    { id: 'talawin', file: 'talawin-marha.html', en: 'Talawin Marha', ar: 'تلاوين مرحة' },
    { id: 'sgc', file: 'sky-global-contracting.html', en: 'Sky Global Real Estate', ar: 'سكاي جلوبال العقارية' },
    { id: 'fc', file: 'sky-global-financial-consulting.html', en: 'Financial Consulting', ar: 'الاستشارات المالية' }
  ];
  var companiesBase = cfg.companiesBase != null ? cfg.companiesBase : (cfg.isHome ? 'companies/' : '');
  var homeHref = cfg.isHome ? '#companies' : '../index.html#companies';

  function esc(s) { return String(s == null ? '' : s).replace(/"/g, '&quot;'); }
  function dd(en, ar) { return 'data-en="' + esc(en) + '" data-ar="' + esc(ar) + '"'; }

  var explore = cfg.explore || [];
  var exploreLis = explore.map(function (x) {
    return '<li><a href="' + x.href + '" ' + dd(x.en, x.ar) + '>' + esc(x.en) + '</a></li>';
  }).join('');

  var companyLis = COMPANIES.map(function (co) {
    var current = cfg.companyId === co.id;
    return '<li><a href="' + companiesBase + co.file + '" ' + dd(co.en, co.ar) +
      (current ? ' aria-current="page"' : '') + '>' + esc(co.en) + '</a></li>';
  }).join('');
  var homeLi = cfg.isHome ? '' :
    '<li><a href="../index.html" ' + dd('Sky Global Holding', 'سكاي جلوبال القابضة') + '>' + 'Sky Global Holding' + '</a></li>';

  var phone2Li = contact.phone2 ?
    '<li><a href="' + contact.phone2Href + '" class="tnum">' + contact.phone2 + '</a></li>' : '';

  var newsLabelEn = cfg.isHome ? 'Group updates' : (cfg.nameEn + ' updates');
  var newsLabelAr = cfg.isHome ? 'مستجدات المجموعة' : ('مستجدات ' + cfg.nameAr);

  var copyEn = cfg.copyrightEn || ('© 2026 ' + cfg.nameEn + (cfg.isHome ? '. All rights reserved.' : ' — a Sky Global company. All rights reserved.'));
  var copyAr = cfg.copyrightAr || ('© 2026 ' + cfg.nameAr + (cfg.isHome ? '. جميع الحقوق محفوظة.' : ' — شركة من سكاي جلوبال. جميع الحقوق محفوظة.'));

  var html = ''
    + '<div class="wrap">'
    + '  <div class="ft-top">'
    + '    <div class="ft-col">'
    + '      <span class="ft-glow" aria-hidden="true"></span>'
    + '      <div class="brand">' + cfg.logoHTML + '</div>'
    + '      <p class="ft-intro" ' + dd(cfg.taglineEn, cfg.taglineAr) + '>' + esc(cfg.taglineEn) + '</p>'
    + '      <a href="#" class="ft-dl" ' + dd('Download company profile', 'تحميل ملف الشركة') + '>'
    + '        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M12 3v12m0 0 4-4m-4 4-4-4M5 21h14" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>'
    + '        <span ' + dd('Download company profile', 'تحميل ملف الشركة') + '>Download company profile</span>'
    + '      </a>'
    + '      <form class="ft-news" data-newsletter>'
    + '        <span class="lbl" ' + dd(newsLabelEn, newsLabelAr) + '>' + esc(newsLabelEn) + '</span>'
    + '        <div class="ft-news-field">'
    + '          <input type="email" name="email" autocomplete="email" required'
    + '                 data-en-placeholder="Your email" data-ar-placeholder="بريدك الإلكتروني"'
    + '                 placeholder="Your email" aria-label="Email address" />'
    + '          <button type="submit" aria-label="Subscribe">'
    + '            <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 12h15m-6-6 6 6-6 6M4 5v14" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>'
    + '          </button>'
    + '        </div>'
    + '        <p class="ft-news-note" ' + dd('Occasional news. Sign-up connects to the CMS in a later phase.', 'أخبار غير منتظمة. سيُربط الاشتراك بلوحة التحكم في مرحلة لاحقة.') + '>Occasional news. Sign-up connects to the CMS in a later phase.</p>'
    + '        <p class="ft-news-ok" role="status">'
    + '          <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="m5 13 4 4L19 7" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>'
    + '          <span ' + dd("Thank you — we'll be in touch.", 'شكرًا لك — سنكون على تواصل.') + '>' + "Thank you — we'll be in touch." + '</span>'
    + '        </p>'
    + '      </form>'
    + '    </div>'

    + '    <div class="ft-col">'
    + '      <h5 ' + dd('Explore', 'استكشف') + '>Explore</h5>'
    + '      <ul>' + exploreLis + '</ul>'
    + '    </div>'

    + '    <div class="ft-col">'
    + '      <h5 ' + dd('Companies', 'الشركات') + '>Companies</h5>'
    + '      <ul>' + homeLi + companyLis + '</ul>'
    + '    </div>'

    + '    <div class="ft-col">'
    + '      <h5 ' + dd('Contact', 'تواصل') + '>Contact</h5>'
    + '      <ul>'
    + '        <li><a href="mailto:' + contact.email + '">' + contact.email + '</a></li>'
    + '        <li><a href="' + contact.phoneHref + '" class="tnum">' + contact.phone + '</a></li>'
    +          phone2Li
    + '        <li><span ' + dd(contact.locationEn, contact.locationAr) + '>' + esc(contact.locationEn) + '</span></li>'
    + '        <li><span ' + dd(contact.hoursEn, contact.hoursAr) + '>' + esc(contact.hoursEn) + '</span></li>'
    + '      </ul>'
    + '      <div class="ft-social">'
    + '        <a href="#" aria-label="' + esc(cfg.nameEn) + ' on LinkedIn" data-tip="LinkedIn" rel="noopener">'
    + '          <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M6.94 5a2 2 0 1 1-4 0 2 2 0 0 1 4 0ZM3.3 8.5h3.3V21H3.3V8.5Zm5.6 0h3.16v1.7h.05c.44-.83 1.5-1.7 3.1-1.7 3.3 0 3.9 2.17 3.9 5V21h-3.3v-5.5c0-1.3 0-3-1.84-3s-2.12 1.43-2.12 2.9V21H8.9V8.5Z"/></svg>'
    + '        </a>'
    + '        <a href="#" aria-label="' + esc(cfg.nameEn) + ' on X" data-tip="X (Twitter)" rel="noopener">'
    + '          <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M18.24 2.25h3.31l-7.23 8.26 8.5 11.24h-6.65l-5.2-6.8-5.96 6.8H1.7l7.73-8.84L1.25 2.25h6.82l4.71 6.23 5.46-6.23Zm-1.16 17.52h1.83L7.02 4.13H5.05L17.08 19.77Z"/></svg>'
    + '        </a>'
    + '        <a href="#" aria-label="' + esc(cfg.nameEn) + ' on Instagram" data-tip="Instagram" rel="noopener">'
    + '          <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5" stroke="currentColor" stroke-width="1.7"/><circle cx="12" cy="12" r="4" stroke="currentColor" stroke-width="1.7"/><circle cx="17.5" cy="6.5" r="1.2" fill="currentColor"/></svg>'
    + '        </a>'
    + '      </div>'
    + '    </div>'
    + '  </div>'

    + '  <div class="ft-bot">'
    + '    <span ' + dd(copyEn, copyAr) + '>' + esc(copyEn) + '</span>'
    + '    <nav aria-label="Legal">'
    + '      <a href="#" ' + dd('Privacy Policy', 'سياسة الخصوصية') + '>Privacy Policy</a>'
    + '      <a href="#" ' + dd('Terms of Use', 'شروط الاستخدام') + '>Terms of Use</a>'
    + '      <a href="#" ' + dd('Cookie Settings', 'إعدادات الكوكيز') + '>Cookie Settings</a>'
    + '    </nav>'
    + '  </div>'
    + '</div>';

  var footer = document.createElement('footer');
  footer.className = 'ft';
  footer.innerHTML = html;
  mount.replaceWith(footer);
})();
