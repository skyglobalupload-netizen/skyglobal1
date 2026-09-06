# Scroll-expand intro hero — reference (removed from the live build)

Kept on file as a Phase-2 upgrade option. This is the vanilla HTML/CSS/JS
implementation of the "media grows on scroll + title splits" opening sequence.
It was built and working, then removed at the client's request for a plain
static hero. Drop it back in by replacing `<section class="hero" id="hero">`
and re-adding the JS/CSS below.

## HTML (replaces the static hero section)

```html
<section class="intro" id="hero">
  <div class="intro-pin">
    <div class="intro-media" data-media aria-hidden="true">
      <div class="hero-canvas"><!-- hc-base, hc-photo, hc-tint, hc-arcs, hc-net, hc-vig, hc-grain --></div>
    </div>
    <h1 class="intro-title" data-title>
      <span class="w w1" data-en="SKY GLOBAL" data-ar="سكاي جلوبال">SKY GLOBAL</span>
      <span class="w w2" data-en="HOLDING" data-ar="القابضة">HOLDING</span>
    </h1>
    <div class="intro-reveal" data-reveal-block>
      <div class="hero-inner"><!-- kicker, hero-tag, sub, hero-cta (each data-anim) --></div>
      <aside class="hero-quote" data-anim><!-- philosophy --></aside>
      <div class="hero-stats"><!-- 4 stat cells --></div>
    </div>
    <div class="scrollhint intro-hint" data-en="Scroll to enter" data-ar="مرّر للدخول">Scroll to enter</div>
  </div>
</section>
```

## CSS

```css
.intro{position:relative;color:#fff}
.intro-pin{position:relative;min-height:100svh;height:100svh;overflow:hidden;background:var(--sky-950);display:grid;place-items:center}
.intro-media{position:absolute;inset:0;z-index:0;overflow:hidden;transform-origin:center;will-change:transform}
.intro.intro-js .intro-media{transform:scale(.44);border-radius:16px}
.intro-title{position:absolute;z-index:4;inset-inline:0;inset-block-start:clamp(120px,20vh,220px);margin:0;
  display:flex;justify-content:center;align-items:baseline;gap:.4em;white-space:nowrap;
  font-weight:800;letter-spacing:.08em;font-size:clamp(1.8rem,1rem+4.4vw,4.9rem);line-height:1;
  color:#fff;text-shadow:0 6px 50px rgba(6,15,26,.55);pointer-events:none}
html[dir="rtl"] .intro-title{letter-spacing:0;font-weight:700}
.intro-title .w{display:inline-block;will-change:transform}
.intro.intro-js .intro-title{inset-block-start:50%}
.intro-reveal{position:absolute;inset:0;z-index:2;display:flex;flex-direction:column;justify-content:center;
  padding-block:clamp(180px,22vh,240px) 150px}
.intro.intro-js .intro-reveal{opacity:0}

@media (max-width:900px){ /* no scroll-expand — stacked hero */
  .intro-pin{height:auto;min-height:100svh;overflow:visible;display:block}
  .intro-title{position:relative;inset:auto;white-space:normal;flex-wrap:wrap;
    padding:clamp(120px,20vh,150px) var(--gutter) 0;justify-content:flex-start;
    font-size:clamp(2rem,8vw,3.2rem);letter-spacing:.04em}
  .intro.intro-js .intro-title{inset:auto;translate:none}
  .intro-reveal{position:relative;inset:auto;padding:2rem var(--gutter) 3.5rem}
  .intro.intro-js .intro-reveal{opacity:1}
}
```

## JS (inside the `if (HAS_GSAP)` block in app.js)

```js
(function () {
  var intro = document.querySelector('.intro');
  if (!intro) return;
  var media  = intro.querySelector('[data-media]');
  var title  = intro.querySelector('[data-title]');
  var w1 = title.querySelector('.w1'), w2 = title.querySelector('.w2');
  var reveal = intro.querySelector('[data-reveal-block]');
  var anims  = reveal.querySelectorAll('[data-anim]');
  var wide = matchMedia('(min-width: 901px)').matches && !matchMedia('(pointer:coarse)').matches;

  if (!wide) {
    gsap.set(reveal, { clearProps: 'all' });
    gsap.from([title].concat([].slice.call(anims)),
      { y: 22, autoAlpha: 0, duration: 0.8, stagger: 0.08, ease: 'power3.out', delay: 0.15 });
    return;
  }

  intro.classList.add('intro-js');
  gsap.set(media,  { scale: 0.44, borderRadius: 16, transformOrigin: 'center' });
  gsap.set(reveal, { autoAlpha: 0 });
  gsap.set([w1, w2], { x: 0 });
  gsap.set(title, { yPercent: -50 });

  var s = document.documentElement.dir === 'rtl' ? -1 : 1, gap = 46;
  var span = function (el) { return innerWidth / 2 - el.offsetWidth / 2 - gap; };

  gsap.timeline({
    scrollTrigger: { trigger: intro, start: 'top top', end: '+=125%',
      pin: '.intro-pin', scrub: 0.6, anticipatePin: 1, invalidateOnRefresh: true }
  })
  .to(media, { scale: 1, borderRadius: 0, ease: 'power2.inOut', duration: 1 }, 0)
  .to(w1, { x: function () { return -s * span(w1); }, ease: 'power2.inOut', duration: 1 }, 0)
  .to(w2, { x: function () { return  s * span(w2); }, ease: 'power2.inOut', duration: 1 }, 0)
  .to(title, { yPercent: -410, scale: 0.5, ease: 'power2.inOut', duration: 1 }, 0)
  .to('.intro-hint', { autoAlpha: 0, duration: 0.15 }, 0.12)
  .to(reveal, { autoAlpha: 1, duration: 0.25 }, 0.68)
  .from(anims, { y: 22, autoAlpha: 0, stagger: 0.06, duration: 0.28, ease: 'power3.out' }, 0.7);
})();
```

## Phase-2 (React / framer-motion) equivalent

`useScroll({ target, offset })` → `scrollYProgress` (0→1).
`useTransform(scrollYProgress, [0, 1], [0.44, 1])` → media `scale`.
`useTransform(scrollYProgress, [0, 1], [0, -splitPx])` / `[0, +splitPx]` → the two words' `x`.
`useTransform(scrollYProgress, [0.68, 1], [0, 1])` → reveal `opacity`.
Pin the stage with `position: sticky; top: 0` on a taller outer wrapper.
