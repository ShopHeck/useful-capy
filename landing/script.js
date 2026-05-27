/* ═══════════════════════════════════════════════════════════
   InterfaceForge Landing — Interactions
   ═══════════════════════════════════════════════════════════ */

(function () {
  "use strict";

  // ── Nav scroll state ────────────────────────────────────
  const nav = document.getElementById("nav");
  let lastScroll = 0;
  function onScroll() {
    const y = window.scrollY;
    if (y > 40) {
      nav.classList.add("scrolled");
    } else {
      nav.classList.remove("scrolled");
    }
    lastScroll = y;
  }
  window.addEventListener("scroll", onScroll, { passive: true });

  // ── Intersection Observer for scroll-reveal ─────────────
  const revealTargets = document.querySelectorAll(
    ".feature-card, .step-card, .pricing-card, .faq-item"
  );

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.1, rootMargin: "0px 0px -40px 0px" }
    );

    revealTargets.forEach((el) => observer.observe(el));
  } else {
    // Fallback: show everything
    revealTargets.forEach((el) => el.classList.add("visible"));
  }

  // ── Typing animation in device mockup ───────────────────
  const typingEl = document.querySelector(".typing-text");
  if (typingEl) {
    const fullText = typingEl.textContent;
    typingEl.textContent = "";
    let charIndex = 0;
    let startDelay = 1200;

    setTimeout(function typeChar() {
      if (charIndex < fullText.length) {
        typingEl.textContent = fullText.slice(0, charIndex + 1);
        charIndex++;
        const delay = 30 + Math.random() * 40;
        setTimeout(typeChar, delay);
      }
    }, startDelay);
  }

  // ── Smooth anchor scroll with offset ────────────────────
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener("click", function (e) {
      const target = document.querySelector(this.getAttribute("href"));
      if (target) {
        e.preventDefault();
        const navHeight = nav.offsetHeight;
        const top = target.getBoundingClientRect().top + window.scrollY - navHeight - 20;
        window.scrollTo({ top, behavior: "smooth" });
      }
    });
  });
})();
