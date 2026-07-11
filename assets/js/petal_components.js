// petal_components JS hooks.
//
// Consumers register these in their LiveSocket. From a Hex install:
//
//   import PetalComponents from "../../deps/petal_components/assets/js/petal_components"
//   const liveSocket = new LiveSocket("/live", Socket, { hooks: { ...PetalComponents } })
//
// (in_umbrella dev uses the relative path to the sibling app instead.)

// Streams assistant tokens into a bubble. The LiveView pushes deltas with
// `push_event(socket, "pc-chat-token", %{id: <element id>, text: <delta>})`.
// The element owns its DOM (phx-update="ignore"), so LiveView never clobbers
// the streamed text. A `data-started` flag flips the typing indicator to live
// text on the first token (driven purely by CSS).
export const PetalChatStream = {
  mounted() {
    this.textEl = this.el.querySelector("[data-pc-stream-text]");
    this.htmlEl = this.el.querySelector("[data-pc-stream-html]");
    const event = this.el.dataset.event || "pc-chat-token";

    // Anchor the new turn near the TOP of the viewport (so the answer starts at
    // the top and there's room to read it), then DON'T auto-follow — the user
    // scrolls down at their own pace. Avoids the "keeps yanking to the bottom"
    // problem. The scroll-to-bottom button handles jumping back down.
    this.anchorTop();

    this.handleEvent(event, (payload) => {
      if (payload.id && payload.id !== this.el.id) return;
      this.el.dataset.started = "";
      // markdown mode: replace innerHTML with pre-rendered HTML.
      // text mode: append the raw token delta.
      if (payload.html !== undefined && this.htmlEl) {
        this.htmlEl.innerHTML = payload.html;
      } else if (payload.text !== undefined && this.textEl) {
        this.textEl.textContent += payload.text;
      }
    });
  },

  anchorTop() {
    const scroller = this.el.closest("[data-pc-scroll]");
    if (!scroller) return;
    // Prefer the user's question (so it sits at the top with the answer below);
    // fall back to this answer's own row.
    const userRows = scroller.querySelectorAll(".pc-chat__row--user");
    const target = userRows[userRows.length - 1] || this.el.closest(".pc-chat__row") || this.el;
    const delta = target.getBoundingClientRect().top - scroller.getBoundingClientRect().top - 12;
    scroller.scrollTop += delta;
  },
};

// Composer: Enter submits, Shift+Enter inserts a newline. Auto-grows the
// textarea up to a max height.
export const PetalChatComposer = {
  mounted() {
    this.textarea = this.el.querySelector("textarea");
    if (!this.textarea) return;

    this.onKeydown = (e) => {
      if (e.key === "Enter" && !e.shiftKey && !this.textarea.disabled) {
        e.preventDefault();
        if (this.textarea.value.trim() !== "") {
          this.el.requestSubmit();
        }
      }
    };
    this.onInput = () => this.autogrow();

    this.textarea.addEventListener("keydown", this.onKeydown);
    this.textarea.addEventListener("input", this.onInput);
  },

  updated() {
    this.autogrow();
  },

  destroyed() {
    if (!this.textarea) return;
    this.textarea.removeEventListener("keydown", this.onKeydown);
    this.textarea.removeEventListener("input", this.onInput);
  },

  autogrow() {
    if (!this.textarea) return;
    this.textarea.style.height = "auto";
    const full = this.textarea.scrollHeight;
    this.textarea.style.height = `${Math.min(full, 160)}px`;
    // Only show a scrollbar once we've hit the max height.
    this.textarea.style.overflowY = full > 160 ? "auto" : "hidden";
  },
};

// Copy arbitrary text (data-copy-text) to the clipboard with brief feedback.
export const PetalCopy = {
  mounted() {
    const label = this.el.querySelector("[data-pc-copy-label]");
    this.el.addEventListener("click", () => {
      navigator.clipboard?.writeText(this.el.dataset.copyText || "");
      if (!label) return;
      const original = label.textContent;
      label.textContent = this.el.dataset.copiedLabel || "Copied!";
      setTimeout(() => {
        label.textContent = original;
      }, 1500);
    });
  },
};

// Inject a "Copy" button into every <pre> code block inside a markdown render.
export const PetalCodeCopy = {
  mounted() {
    this.enhance();
  },
  updated() {
    this.enhance();
  },
  enhance() {
    this.el.querySelectorAll("pre").forEach((pre) => {
      if (pre.querySelector("[data-pc-code-copy]")) return;
      const btn = document.createElement("button");
      btn.type = "button";
      btn.dataset.pcCodeCopy = "";
      btn.className = "pc-chat__code-copy";
      btn.textContent = "Copy";
      btn.addEventListener("click", () => {
        const code = pre.querySelector("code");
        navigator.clipboard?.writeText(code ? code.innerText : pre.innerText);
        btn.textContent = "Copied!";
        setTimeout(() => {
          btn.textContent = "Copy";
        }, 1500);
      });
      pre.appendChild(btn);
    });
  },
};

// Show a "scroll to latest" button when the user has scrolled up.
export const PetalChatScroll = {
  mounted() {
    this.btn = this.el.parentElement?.querySelector("[data-pc-scroll-btn]");
    this.onScroll = () => this.toggle();
    this.el.addEventListener("scroll", this.onScroll, { passive: true });
    if (this.btn) {
      this.btn.addEventListener("click", () => {
        this.el.scrollTop = this.el.scrollHeight;
      });
    }
    this.toggle();
  },
  updated() {
    this.toggle();
  },
  destroyed() {
    this.el.removeEventListener("scroll", this.onScroll);
  },
  toggle() {
    if (!this.btn) return;
    const slack = this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight;
    this.btn.classList.toggle("pc-chat__scroll-btn--hidden", slack < 80);
  },
};

// Password field: toggle the input between password/text and swap the eye icon.
export const PetalPasswordToggle = {
  mounted() {
    const input = this.el.querySelector("[data-pc-password-input]");
    const btn = this.el.querySelector("[data-pc-password-toggle]");
    const eye = this.el.querySelector("[data-pc-icon-show]");
    const eyeOff = this.el.querySelector("[data-pc-icon-hide]");
    if (!input || !btn) return;

    btn.addEventListener("click", () => {
      input.type = input.type === "text" ? "password" : "text";
      const revealed = input.type === "text";
      if (eye) eye.classList.toggle("hidden", revealed);
      if (eyeOff) eyeOff.classList.toggle("hidden", !revealed);
    });
  },
};

// Copyable field: copy the (readonly) input value, flip the icon for 2s.
export const PetalCopyInput = {
  mounted() {
    const input = this.el.querySelector("[data-pc-copy-input]");
    const btn = this.el.querySelector("[data-pc-copy-btn]");
    const def = this.el.querySelector("[data-pc-copy-default]");
    const done = this.el.querySelector("[data-pc-copy-done]");
    if (!input || !btn) return;

    btn.addEventListener("click", () => {
      navigator.clipboard?.writeText(input.value);
      if (def) def.classList.add("hidden");
      if (done) done.classList.remove("hidden");
      setTimeout(() => {
        if (def) def.classList.remove("hidden");
        if (done) done.classList.add("hidden");
      }, 2000);
    });
  },
};

// Clearable field: show the clear button only when there's a value; clear resets
// the input and dispatches an input event so LiveView/forms see the change.
export const PetalClearableInput = {
  mounted() {
    this.input = this.el.querySelector("[data-pc-clear-input]");
    this.btn = this.el.querySelector("[data-pc-clear-btn]");
    if (!this.input || !this.btn) return;

    this.sync = () => this.btn.classList.toggle("hidden", this.input.value.length === 0);
    this.input.addEventListener("input", this.sync);
    this.btn.addEventListener("click", () => {
      this.input.value = "";
      this.input.dispatchEvent(new Event("input", { bubbles: true }));
      this.input.focus();
      this.sync();
    });
    this.sync();
  },
  updated() {
    if (this.sync) this.sync();
  },
};

// Dual range slider: two stacked <input type="range"> thumbs sharing a coloured track.
//
// Attrs read from the container element (set server-side in input.ex):
//   data-range-min / data-range-max  — absolute bounds of the slider
//   data-value-prefix / data-value-suffix — e.g. "$" / "%" for the display label
//
// Inner elements discovered by data-role markers:
//   [data-pc-range-min]     — the minimum range input
//   [data-pc-range-max]     — the maximum range input
//   [data-pc-range-track]   — the primary-coloured highlight div
//   [data-pc-range-display] — the centre label showing current min–max values
export const PetalDualRangeSlider = {
  mounted() {
    this.trackEl = this.el.querySelector("[data-pc-range-track]");
    this.minInput = this.el.querySelector("[data-pc-range-min]");
    this.maxInput = this.el.querySelector("[data-pc-range-max]");
    this.display = this.el.querySelector("[data-pc-range-display]");
    this.rangeMin = parseFloat(this.el.dataset.rangeMin);
    this.rangeMax = parseFloat(this.el.dataset.rangeMax);
    this.prefix = this.el.dataset.valuePrefix || "";
    this.suffix = this.el.dataset.valueSuffix || "";

    this.onMinInput = () => this.handleMin();
    this.onMaxInput = () => this.handleMax();
    this.minInput.addEventListener("input", this.onMinInput);
    this.maxInput.addEventListener("input", this.onMaxInput);

    this.syncTrack();
  },

  destroyed() {
    this.minInput?.removeEventListener("input", this.onMinInput);
    this.maxInput?.removeEventListener("input", this.onMaxInput);
  },

  handleMin() {
    let min = parseFloat(this.minInput.value);
    const max = parseFloat(this.maxInput.value);
    if (min > max) {
      min = max;
      this.minInput.value = min;
    }
    // When thumbs meet, lift the min thumb so the user can drag it left to separate them.
    this.minInput.style.zIndex = min >= max ? "20" : "";
    this.maxInput.style.zIndex = "";
    this.syncTrack(min, max);
    this.syncDisplay(min, max);
  },

  handleMax() {
    let max = parseFloat(this.maxInput.value);
    const min = parseFloat(this.minInput.value);
    if (max < min) {
      max = min;
      this.maxInput.value = max;
    }
    // When thumbs meet, lift the max thumb so the user can drag it right to separate them.
    this.maxInput.style.zIndex = max <= min ? "20" : "";
    this.minInput.style.zIndex = "";
    this.syncTrack(min, max);
    this.syncDisplay(min, max);
  },

  syncTrack(min, max) {
    min = min !== undefined ? min : parseFloat(this.minInput.value);
    max = max !== undefined ? max : parseFloat(this.maxInput.value);
    const span = this.rangeMax - this.rangeMin;
    if (span === 0) {
      this.trackEl.style.left = "0%";
      this.trackEl.style.right = "0%";
      return;
    }
    const left = ((min - this.rangeMin) / span) * 100;
    const right = 100 - ((max - this.rangeMin) / span) * 100;
    this.trackEl.style.left = `${left}%`;
    this.trackEl.style.right = `${right}%`;
  },

  syncDisplay(min, max) {
    if (!this.display) return;
    // parseFloat strips trailing zeros (50.0 → "50"), keeping labels clean.
    const fmt = (v) => parseFloat(v.toFixed(10));
    this.display.textContent =
      `${this.prefix}${fmt(min)}${this.suffix} – ${this.prefix}${fmt(max)}${this.suffix}`;
  },
};

// Number ticker: counts up to data-value when the element scrolls into view,
// and re-animates from the previous value whenever data-value changes (so a
// LiveView assign update animates the delta). Formatting via Intl.NumberFormat.
export const PetalNumberTicker = {
  mounted() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.reducedMotion = true;
      return; // leave the server-rendered final value in place
    }
    this.lastTarget = this.target();
    // Show the start value until the element becomes visible.
    this.render(parseFloat(this.el.dataset.startValue || "0"));
    const start = () => this.animate(parseFloat(this.el.dataset.startValue || "0"));
    if ("IntersectionObserver" in window) {
      this.observer = new IntersectionObserver(
        (entries) => {
          if (entries[0].isIntersecting) {
            this.observer.disconnect();
            this.observer = null;
            start();
          }
        },
        { threshold: 0.3 }
      );
      this.observer.observe(this.el);
    } else {
      start();
    }
  },

  updated() {
    if (this.reducedMotion) return;
    const target = this.target();
    if (target !== this.lastTarget) {
      const from = this.current !== undefined ? this.current : this.lastTarget;
      this.lastTarget = target;
      this.animate(from);
    } else if (this.current !== undefined) {
      // LiveView re-rendered the final value mid/post animation; restore ours.
      this.render(this.current);
    }
  },

  destroyed() {
    this.observer?.disconnect();
    if (this.frame) cancelAnimationFrame(this.frame);
  },

  target() {
    return parseFloat(this.el.dataset.value || "0");
  },

  animate(from) {
    if (this.frame) cancelAnimationFrame(this.frame);
    const target = this.target();
    const duration = parseInt(this.el.dataset.duration || "1500", 10);
    const t0 = performance.now();
    const tick = (now) => {
      const p = Math.min((now - t0) / duration, 1);
      const eased = p === 1 ? 1 : 1 - Math.pow(2, -10 * p); // easeOutExpo
      this.current = from + (target - from) * eased;
      this.render(this.current);
      if (p < 1) {
        this.frame = requestAnimationFrame(tick);
      } else {
        this.frame = null;
        this.current = target;
        this.render(target);
      }
    };
    this.frame = requestAnimationFrame(tick);
  },

  render(value) {
    const decimals = parseInt(this.el.dataset.decimalPlaces || "0", 10);
    const fmt = new Intl.NumberFormat(this.el.dataset.locale || undefined, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });
    this.el.textContent =
      (this.el.dataset.prefix || "") + fmt.format(value) + (this.el.dataset.suffix || "");
  },
};

// Confetti cannon. Zero dependencies — bursts are drawn on a temporary
// full-screen canvas that is removed once every particle has faded.
//
// Fire from the server:  push_event(socket, "pc-confetti", %{id: ..., ...opts})
// Fire from the client:  JS.dispatch("pc:confetti", to: "#my-confetti")
// Options: particle_count, spread, angle, velocity, colors, origin {x, y} (0..1).
export const PetalConfetti = {
  defaultColors: ["#26ccff", "#a25afd", "#ff5e7e", "#88ff5a", "#fcff42", "#ffa62d", "#ff36ff"],

  mounted() {
    this.particles = [];
    this.onDispatch = (e) => this.fire(e.detail || {});
    this.el.addEventListener("pc:confetti", this.onDispatch);
    this.handleEvent("pc-confetti", (payload) => {
      payload = payload || {};
      if (payload.id && payload.id !== this.el.id) return;
      this.fire(payload);
    });
  },

  destroyed() {
    this.el.removeEventListener("pc:confetti", this.onDispatch);
    if (this.frame) cancelAnimationFrame(this.frame);
    this.canvas?.remove();
  },

  fire(opts) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let dataColors = null;
    try {
      dataColors = JSON.parse(this.el.dataset.colors || "null");
    } catch (_e) {}

    const count = opts.particle_count || parseInt(this.el.dataset.particleCount || "100", 10);
    const spread = opts.spread || parseInt(this.el.dataset.spread || "70", 10);
    const angle = opts.angle !== undefined ? opts.angle : 90;
    const velocity = opts.velocity || 45;
    const colors = opts.colors || dataColors || this.defaultColors;
    const origin = opts.origin || { x: 0.5, y: 0.6 };

    const originX = origin.x * window.innerWidth;
    const originY = origin.y * window.innerHeight;
    const radAngle = (angle * Math.PI) / 180;
    const radSpread = (spread * Math.PI) / 180;

    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: originX,
        y: originY,
        angle2D: -radAngle + (0.5 * radSpread - Math.random() * radSpread),
        velocity: velocity * 0.5 + Math.random() * velocity,
        decay: 0.9,
        gravity: 3,
        drift: (Math.random() - 0.5) * 0.6,
        color: colors[Math.floor(Math.random() * colors.length)],
        tick: 0,
        totalTicks: 150 + Math.floor(Math.random() * 60),
        wobble: Math.random() * 10,
        wobbleSpeed: 0.05 + Math.random() * 0.06,
        tiltAngle: Math.random() * Math.PI,
        scalar: 0.8 + Math.random() * 0.6,
      });
    }

    this.ensureCanvas();
    if (!this.frame) this.loop();
  },

  ensureCanvas() {
    if (this.canvas) return;
    const canvas = document.createElement("canvas");
    canvas.setAttribute("aria-hidden", "true");
    canvas.style.cssText =
      "position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:9999;";
    document.body.appendChild(canvas);
    this.canvas = canvas;
    this.resize();
  },

  resize() {
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = window.innerWidth * dpr;
    this.canvas.height = window.innerHeight * dpr;
    this.ctx = this.canvas.getContext("2d");
    this.ctx.scale(dpr, dpr);
  },

  loop() {
    this.frame = requestAnimationFrame(() => {
      this.ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);

      this.particles = this.particles.filter((p) => {
        p.x += Math.cos(p.angle2D) * p.velocity + p.drift;
        p.y += Math.sin(p.angle2D) * p.velocity + p.gravity;
        p.velocity *= p.decay;
        p.wobble += p.wobbleSpeed;
        p.tiltAngle += 0.1;
        p.tick += 1;

        const progress = p.tick / p.totalTicks;
        if (progress >= 1) return false;

        const wobbleX = p.x + 10 * p.scalar * Math.cos(p.wobble);
        const wobbleY = p.y + 10 * p.scalar * Math.sin(p.wobble);
        const tilt = Math.sin(p.tiltAngle) * 6 * p.scalar;

        this.ctx.globalAlpha = 1 - progress;
        this.ctx.fillStyle = p.color;
        this.ctx.beginPath();
        this.ctx.moveTo(p.x, p.y);
        this.ctx.lineTo(wobbleX, p.y + tilt);
        this.ctx.lineTo(wobbleX + tilt, wobbleY);
        this.ctx.lineTo(p.x + tilt, wobbleY);
        this.ctx.closePath();
        this.ctx.fill();
        return true;
      });

      this.ctx.globalAlpha = 1;

      if (this.particles.length > 0) {
        this.loop();
      } else {
        this.frame = null;
        this.canvas?.remove();
        this.canvas = null;
      }
    });
  },
};

// Spotlight card: tracks the cursor into CSS variables; the glow itself is
// pure CSS (see .pc-spotlight-card__glow).
export const PetalSpotlight = {
  mounted() {
    this.onMove = (e) => {
      const rect = this.el.getBoundingClientRect();
      this.el.style.setProperty("--pc-spotlight-x", `${e.clientX - rect.left}px`);
      this.el.style.setProperty("--pc-spotlight-y", `${e.clientY - rect.top}px`);
    };
    this.el.addEventListener("mousemove", this.onMove);
  },
  destroyed() {
    this.el.removeEventListener("mousemove", this.onMove);
  },
};

// Word rotate: cycles through data-words with a roll-up transition. The exit
// transition runs (200ms), then the word swaps and slides in from below.
export const PetalWordRotate = {
  mounted() {
    this.wordEl = this.el.querySelector(".pc-word-rotate__word");
    let words = [];
    try {
      words = JSON.parse(this.el.dataset.words || "[]");
    } catch (_e) {}
    if (!this.wordEl || words.length < 2) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    this.words = words;
    this.index = 0;
    const interval = parseInt(this.el.dataset.interval || "2500", 10);
    this.timer = setInterval(() => this.rotate(), interval);
  },

  destroyed() {
    clearInterval(this.timer);
    clearTimeout(this.swapTimer);
  },

  rotate() {
    this.index = (this.index + 1) % this.words.length;
    const next = this.words[this.index];
    this.wordEl.classList.add("pc-word-rotate__word--out");
    this.swapTimer = setTimeout(() => {
      this.wordEl.textContent = next;
      // Jump below the line without transitioning, then animate back up.
      this.wordEl.classList.add("pc-word-rotate__word--pre");
      this.wordEl.classList.remove("pc-word-rotate__word--out");
      void this.wordEl.offsetWidth;
      this.wordEl.classList.remove("pc-word-rotate__word--pre");
    }, 200);
  },
};

// Typing effect: replays the server-rendered text character by character.
// Unicode-safe (Array.from keeps emoji/surrogate pairs intact). With
// data-loop, deletes and types again forever.
export const PetalTypingEffect = {
  mounted() {
    this.textEl = this.el.querySelector(".pc-typing-effect__text");
    if (!this.textEl) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    this.chars = Array.from(this.el.dataset.text || "");
    if (this.chars.length === 0) return;
    this.speed = parseInt(this.el.dataset.speed || "60", 10);
    this.loop = this.el.dataset.loop === "true";
    const delay = parseInt(this.el.dataset.startDelay || "0", 10);

    this.textEl.textContent = "";
    this.timer = setTimeout(() => this.type(1), delay);
  },

  destroyed() {
    clearTimeout(this.timer);
  },

  type(i) {
    this.textEl.textContent = this.chars.slice(0, i).join("");
    if (i < this.chars.length) {
      this.timer = setTimeout(() => this.type(i + 1), this.speed);
    } else if (this.loop) {
      this.timer = setTimeout(() => this.erase(this.chars.length - 1), 1800);
    }
  },

  erase(i) {
    this.textEl.textContent = this.chars.slice(0, i).join("");
    if (i > 0) {
      this.timer = setTimeout(() => this.erase(i - 1), Math.max(this.speed / 2, 15));
    } else {
      this.timer = setTimeout(() => this.type(1), 400);
    }
  },
};

// Accordion toggling.
//
// This lives in the bundle (registered once with your app.js) rather than in a
// per-instance inline <script>, because LiveView does NOT execute inline scripts
// injected via live navigation — so an accordion reached by a `navigate` link
// would be dead. One global listener handles every accordion on the page; it
// resolves the target container from the dispatched event's detail and bails if
// the container is gone (which prevented a stale-node `classList` error).
if (typeof window !== "undefined" && !window.__petalComponentsAccordionInit) {
  window.__petalComponentsAccordionInit = true;

  window.addEventListener("click_accordion", (e) => {
    if (!e.detail) return;

    const i = e.detail.index;
    const l = e.detail.length;
    const isMultiple = !!e.detail.multiple;
    const clickedAccordionItem = e.target;
    const container =
      document.getElementById(e.detail.container_id) ||
      (clickedAccordionItem.closest("[data-i]") || {}).parentElement;

    if (!container) return;

    const currentlyOpenAccordionItem = container.querySelector("[data-open='true']");
    const isClosingClickedAccordionItem = clickedAccordionItem.dataset.open === "true";
    const isLastAccordionItem = i == l - 1;
    const isGhostVariant = container.classList.contains("pc-accordion--ghost");

    function setContentDisplay(item, value) {
      const content = item.querySelector(".accordion-content-container");
      if (content) content.style.display = value;
    }

    function closeItem(item) {
      item.dataset.open = "false";
      const toggleBtn = item.querySelector("[aria-expanded]");
      if (toggleBtn) toggleBtn.setAttribute("aria-expanded", "false");
      if (isGhostVariant) {
        const plusIcon = item.querySelector(".pc-accordion-item__plus");
        const minusIcon = item.querySelector(".pc-accordion-item__minus");
        if (plusIcon && minusIcon) {
          plusIcon.classList.remove("hidden");
          minusIcon.classList.add("hidden");
        }
      } else {
        const chevron = item.querySelector("span.hero-chevron-down-solid");
        if (chevron) chevron.classList.remove("rotate-180");
        const btn = item.querySelector(".accordion-button");
        if (btn) btn.classList.remove("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
        if (isLastAccordionItem && item === clickedAccordionItem) {
          const btn2 = item.querySelector(".accordion-button");
          if (btn2) btn2.classList.add("pc-accordion-item--last--closed");
        }
      }
      setContentDisplay(item, "none");
    }

    function openItem(item) {
      item.dataset.open = "true";
      const toggleBtn = item.querySelector("[aria-expanded]");
      if (toggleBtn) toggleBtn.setAttribute("aria-expanded", "true");
      if (isGhostVariant) {
        const plusIcon = item.querySelector(".pc-accordion-item__plus");
        const minusIcon = item.querySelector(".pc-accordion-item__minus");
        if (plusIcon && minusIcon) {
          plusIcon.classList.add("hidden");
          minusIcon.classList.remove("hidden");
        }
      } else {
        const chevron = item.querySelector("span.hero-chevron-down-solid");
        if (chevron) chevron.classList.add("rotate-180");
        const btn = item.querySelector(".accordion-button");
        if (btn) btn.classList.add("pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes");
        if (isLastAccordionItem) {
          const btn2 = item.querySelector(".accordion-button");
          if (btn2) btn2.classList.remove("pc-accordion-item--last--closed");
        }
      }
      setContentDisplay(item, "block");
    }

    // In single mode, close the currently open item (if different from clicked)
    if (!isMultiple && currentlyOpenAccordionItem && currentlyOpenAccordionItem !== clickedAccordionItem) {
      closeItem(currentlyOpenAccordionItem);
    }

    if (isClosingClickedAccordionItem) {
      closeItem(clickedAccordionItem);
    } else {
      if (!isMultiple && currentlyOpenAccordionItem === clickedAccordionItem) {
        closeItem(clickedAccordionItem);
      }
      openItem(clickedAccordionItem);
    }
  });
}


export const PetalInputOTP = {
  mounted() {
    this.input = this.el.querySelector("[data-pc-otp-input]");
    this.slots = Array.from(this.el.querySelectorAll("[data-pc-otp-slot]"));
    this.render = this.render.bind(this);
    this.sanitize = this.sanitize.bind(this);

    this.input.addEventListener("input", () => {
      this.sanitize();
      this.render();
      if (this.input.value.length === this.slots.length) {
        this.el.dispatchEvent(
          new CustomEvent("petal:otp-complete", {
            detail: { value: this.input.value },
            bubbles: true,
          })
        );
      }
    });

    // keep the caret at the end so typing always fills the next slot
    const snapCaret = () => {
      const len = this.input.value.length;
      this.input.setSelectionRange(len, len);
      this.render();
    };
    this.input.addEventListener("focus", snapCaret);
    this.input.addEventListener("click", snapCaret);
    this.input.addEventListener("keyup", this.render);
    this.input.addEventListener("blur", this.render);

    this.render();
  },

  updated() {
    this.slots = Array.from(this.el.querySelectorAll("[data-pc-otp-slot]"));
    this.render();
  },

  sanitize() {
    const pattern =
      this.el.dataset.pattern === "alphanumeric" ? /[^a-zA-Z0-9]/g : /[^0-9]/g;
    const clean = this.input.value.replace(pattern, "").slice(0, this.slots.length);
    if (clean !== this.input.value) this.input.value = clean;
  },

  render() {
    const value = this.input.value;
    const focused = document.activeElement === this.input;
    const activeIndex = Math.min(value.length, this.slots.length - 1);

    this.slots.forEach((slot, i) => {
      slot.textContent = value[i] || "";
      slot.classList.toggle("pc-otp__slot--filled", Boolean(value[i]));
      slot.classList.toggle(
        "pc-otp__slot--active",
        focused && i === activeIndex && value.length < this.slots.length + (value[i] ? 0 : 1) && (i === value.length || (i === this.slots.length - 1 && value.length === this.slots.length))
      );
    });
  },
};

// Positions a top-layer popover (<div popover>) next to its trigger.
// The browser handles open/close and light-dismiss via the popover attribute;
// this hook only computes fixed coordinates, flipping to the opposite side
// and clamping to the viewport when space runs out.
export const PetalPopover = {
  mounted() {
    this.reposition = () => this.position();
    this.onToggle = (e) => {
      if (e.newState === "open") {
        this.position();
        window.addEventListener("scroll", this.reposition, true);
        window.addEventListener("resize", this.reposition);
      } else {
        window.removeEventListener("scroll", this.reposition, true);
        window.removeEventListener("resize", this.reposition);
      }
    };
    this.el.addEventListener("toggle", this.onToggle);
  },
  destroyed() {
    this.el.removeEventListener("toggle", this.onToggle);
    window.removeEventListener("scroll", this.reposition, true);
    window.removeEventListener("resize", this.reposition);
  },
  position() {
    const trigger = document.querySelector(`[popovertarget="${CSS.escape(this.el.id)}"]`);
    if (!trigger) return;

    const gap = 8;
    const pad = 8;
    const t = trigger.getBoundingClientRect();
    const p = this.el.getBoundingClientRect();
    const [side, align] = (this.el.dataset.placement || "bottom").split("-");

    const space = {
      top: t.top,
      bottom: window.innerHeight - t.bottom,
      left: t.left,
      right: window.innerWidth - t.right,
    };

    let s = side;
    if (side === "bottom" && space.bottom < p.height + gap && space.top > space.bottom) s = "top";
    if (side === "top" && space.top < p.height + gap && space.bottom > space.top) s = "bottom";
    if (side === "right" && space.right < p.width + gap && space.left > space.right) s = "left";
    if (side === "left" && space.left < p.width + gap && space.right > space.left) s = "right";

    let top, left;
    if (s === "top" || s === "bottom") {
      top = s === "top" ? t.top - p.height - gap : t.bottom + gap;
      if (align === "start") left = t.left;
      else if (align === "end") left = t.right - p.width;
      else left = t.left + t.width / 2 - p.width / 2;
    } else {
      left = s === "left" ? t.left - p.width - gap : t.right + gap;
      if (align === "start") top = t.top;
      else if (align === "end") top = t.bottom - p.height;
      else top = t.top + t.height / 2 - p.height / 2;
    }

    left = Math.max(pad, Math.min(left, window.innerWidth - p.width - pad));
    top = Math.max(pad, Math.min(top, window.innerHeight - p.height - pad));

    this.el.style.top = `${top}px`;
    this.el.style.left = `${left}px`;
  },
};


// Command palette: client-side filtering + WAI-ARIA combobox keyboard model.
// Items are hidden, never reordered - the server owns DOM order, so the
// palette stays safe under LiveView patches. Scoring: value prefix beats
// word-boundary prefix beats substring beats fuzzy subsequence.
export const PetalCommand = {
  mounted() {
    this.input = this.el.querySelector(".pc-command__input");
    this.list = this.el.querySelector(".pc-command__list");
    if (!this.input || !this.list) return;

    if (!this.list.id) this.list.id = `${this.el.id}-list`;
    this.input.setAttribute("aria-controls", this.list.id);

    this.onInput = () => this.filter();
    this.onKeydown = (e) => this.keydown(e);
    this.onPointerOver = (e) => {
      const item = e.target.closest("[data-pc-command-item]");
      if (item && !item.hasAttribute("data-disabled") && !item.hidden) this.setActive(item, false);
    };
    this.input.addEventListener("input", this.onInput);
    this.input.addEventListener("keydown", this.onKeydown);
    this.list.addEventListener("pointerover", this.onPointerOver);

    this.filter();
  },

  updated() {
    // LiveView patched the palette - re-apply the current query.
    this.filter();
  },

  destroyed() {
    if (!this.input) return;
    this.input.removeEventListener("input", this.onInput);
    this.input.removeEventListener("keydown", this.onKeydown);
    this.list.removeEventListener("pointerover", this.onPointerOver);
  },

  items() {
    return Array.from(this.el.querySelectorAll("[data-pc-command-item]"));
  },

  visibleItems() {
    return this.items().filter((i) => !i.hidden && !i.hasAttribute("data-disabled"));
  },

  searchText(item) {
    const value = item.dataset.value || item.textContent || "";
    const keywords = item.dataset.keywords || "";
    return `${value} ${keywords}`.trim().toLowerCase();
  },

  score(text, query) {
    if (!query) return 1;
    if (text.startsWith(query)) return 4;
    const at = text.indexOf(query);
    if (at > 0 && /[\s\-_/]/.test(text[at - 1])) return 3;
    if (at >= 0) return 2;
    // fuzzy subsequence: every query char appears in order
    let qi = 0;
    for (const ch of text) if (ch === query[qi] && ++qi === query.length) return 1;
    return 0;
  },

  filter() {
    const query = this.input.value.trim().toLowerCase();
    const queryChanged = query !== this._lastQuery;
    this._lastQuery = query;
    let count = 0;
    let idBase = 0;

    for (const item of this.items()) {
      if (!item.id) item.id = `${this.el.id}-item-${idBase}`;
      idBase++;
      const show = this.score(this.searchText(item), query) > 0;
      item.hidden = !show;
      if (show) count++;
    }

    for (const group of this.el.querySelectorAll("[data-pc-command-group]")) {
      const any = Array.from(group.querySelectorAll("[data-pc-command-item]")).some((i) => !i.hidden);
      group.hidden = !any;
    }

    for (const sep of this.el.querySelectorAll("[data-pc-command-separator]")) {
      sep.hidden = query.length > 0;
    }

    const empty = this.el.querySelector("[data-pc-command-empty]");
    if (empty) empty.hidden = count > 0;

    // a new query re-homes the highlight to the best (first) match;
    // otherwise keep it, unless it was filtered away
    const active = this.activeItem();
    if (queryChanged || !active || active.hidden || active.hasAttribute("data-disabled")) {
      this.setActive(this.visibleItems()[0] || null, false);
    }
  },

  activeItem() {
    const id = this.input.getAttribute("aria-activedescendant");
    return id ? document.getElementById(id) : null;
  },

  setActive(item, scroll = true) {
    for (const i of this.items()) {
      const on = i === item;
      i.toggleAttribute("data-selected", on);
      i.setAttribute("aria-selected", on ? "true" : "false");
    }
    if (item) {
      this.input.setAttribute("aria-activedescendant", item.id);
      if (scroll) item.scrollIntoView({ block: "nearest" });
    } else {
      this.input.removeAttribute("aria-activedescendant");
    }
  },

  move(delta) {
    const items = this.visibleItems();
    if (!items.length) return;
    const loop = this.el.dataset.loop === "true";
    const at = items.indexOf(this.activeItem());
    let next = at + delta;
    if (at === -1) next = delta > 0 ? 0 : items.length - 1;
    else if (loop) next = (next + items.length) % items.length;
    else next = Math.max(0, Math.min(next, items.length - 1));
    this.setActive(items[next]);
  },

  keydown(e) {
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        this.move(1);
        break;
      case "ArrowUp":
        e.preventDefault();
        this.move(-1);
        break;
      case "Home":
        e.preventDefault();
        this.setActive(this.visibleItems()[0] || null);
        break;
      case "End":
        e.preventDefault();
        this.setActive(this.visibleItems().slice(-1)[0] || null);
        break;
      case "Enter": {
        e.preventDefault();
        const item = this.activeItem();
        if (item && !item.hidden && !item.hasAttribute("data-disabled")) item.click();
        break;
      }
    }
  },
};

// The palette in a native <dialog>: global shortcut, open/close events,
// autofocus, and query reset. The native element supplies the top layer,
// focus trap, ::backdrop and Escape.
export const PetalCommandDialog = {
  mounted() {
    this.palette = this.el.querySelector(".pc-command");

    this.onShortcut = (e) => {
      const key = this.el.dataset.shortcut;
      if (!key) return;
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === key.toLowerCase()) {
        e.preventDefault();
        this.el.open ? this.close() : this.open();
      }
    };
    this.onOpen = () => this.open();
    this.onCloseEvent = () => this.close();
    this.onClick = (e) => {
      // click on the backdrop = click whose target is the dialog itself
      if (e.target === this.el) this.close();
    };
    this.onClose = () => this.reset();
    this.onItemClick = (e) => {
      const item = e.target.closest("[data-pc-command-item]");
      if (item && !item.hasAttribute("data-keep-open") && !item.hasAttribute("data-disabled")) {
        this.close();
      }
    };

    document.addEventListener("keydown", this.onShortcut);
    this.el.addEventListener("pc:command-open", this.onOpen);
    this.el.addEventListener("pc:command-close", this.onCloseEvent);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("close", this.onClose);
    this.el.addEventListener("click", this.onItemClick);
  },

  destroyed() {
    document.removeEventListener("keydown", this.onShortcut);
  },

  open() {
    if (this.el.open) return;
    this.el.showModal();
    const input = this.el.querySelector(".pc-command__input");
    if (input) input.focus();
  },

  close() {
    if (this.el.open) this.el.close();
  },

  reset() {
    if (this.el.dataset.resetOnClose !== "true") return;
    const input = this.el.querySelector(".pc-command__input");
    if (input && input.value !== "") {
      input.value = "";
      input.dispatchEvent(new Event("input", { bubbles: true }));
    }
  },
};

export default {
  PetalChatStream,
  PetalChatComposer,
  PetalCopy,
  PetalCodeCopy,
  PetalChatScroll,
  PetalPasswordToggle,
  PetalCopyInput,
  PetalClearableInput,
  PetalDualRangeSlider,
  PetalNumberTicker,
  PetalConfetti,
  PetalSpotlight,
  PetalWordRotate,
  PetalTypingEffect,
  PetalInputOTP,
  PetalPopover,
  PetalCommand,
  PetalCommandDialog,
};
