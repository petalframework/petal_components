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
    this.scroller = this.el.closest("[data-pc-scroll]");

    this.handleEvent(event, (payload) => {
      if (payload.id && payload.id !== this.el.id) return;
      // Reader at the live edge rides it: pin after each token. Scrolling up
      // disengages (edge check fails) and nothing ever yanks them back down —
      // the scroll-to-bottom button is the way back. Same model as ChatGPT's
      // follow and shadcn's autoScroll. Edge state is read BEFORE the token
      // lands, so growth below the fold can't disengage a following reader.
      const atEdge =
        this.scroller &&
        this.scroller.scrollHeight - this.scroller.scrollTop - this.scroller.clientHeight < 80;
      this.el.dataset.started = "";
      // markdown mode: replace innerHTML with pre-rendered HTML.
      // text mode: append the raw token delta.
      if (payload.html !== undefined && this.htmlEl) {
        this.htmlEl.innerHTML = payload.html;
      } else if (payload.text !== undefined && this.textEl) {
        this.textEl.textContent += payload.text;
      }
      if (this.scroller) {
        if (atEdge) this.scroller.scrollTop = this.scroller.scrollHeight;
        // content changed without any scroll/patch event — let the scroller
        // hook re-evaluate its jump-to-latest button
        this.scroller.dispatchEvent(new Event("scroll"));
      }
    });
  },
};

// Composer: Enter submits, Shift+Enter inserts a newline. Auto-grows the
// textarea up to a max height.
export const PetalChatComposer = {
  mounted() {
    this.textarea = this.el.querySelector("textarea");

    // Sending is an intentional act: drop to the live edge (even if scrolled
    // up) so the reply streams in view - incoming content alone never does
    // this. Pinning before the patch lands also flips the scroller's
    // wasAtEdge, so the append sticks.
    this.el.addEventListener("submit", () => {
      const scroller = this.el.closest(".pc-chat")?.querySelector("[data-pc-scroll]");
      if (scroller) {
        scroller.scrollTop = scroller.scrollHeight;
        scroller.dispatchEvent(new Event("scroll"));
      }
    });

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

    // Set the field programmatically (edit a past message, quote, clear).
    // The textarea is phx-update="ignore" so the server can't render into it;
    // this is the channel for it. Focuses and drops the caret at the end.
    this.handleEvent("pc-chat-set-input", (payload) => {
      if (payload.id && payload.id !== this.el.id) return;
      this.textarea.value = payload.value || "";
      this.autogrow();
      this.textarea.focus();
      const end = this.textarea.value.length;
      this.textarea.setSelectionRange(end, end);
    });
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
    const def = this.el.querySelector("[data-pc-copy-default]");
    const done = this.el.querySelector("[data-pc-copy-done]");
    this.el.addEventListener("click", () => {
      navigator.clipboard?.writeText(this.el.dataset.copyText || "");
      if (def && done) {
        // icon mode: clipboard -> check for a moment
        def.classList.add("hidden");
        done.classList.remove("hidden");
        setTimeout(() => {
          def.classList.remove("hidden");
          done.classList.add("hidden");
        }, 1500);
        return;
      }
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
    // A conversation opens at its latest message, not the top.
    this.el.scrollTop = this.el.scrollHeight;
    // Prepend preservation: remember the top-most visible row and how far down
    // the thread it sits. When a patch inserts history ABOVE it, its offsetTop
    // grows - shift scrollTop by the same amount so the reader doesn't move.
    // (Anchor tracking, not added-node inspection: morphdom may recreate
    // trailing nodes, which makes structural prepend detection unreliable.)
    this.recordAnchor();
    this.recordEdge();
    this.onScrollAnchor = () => {
      this.recordAnchor();
      this.recordEdge();
    };
    this.el.addEventListener("scroll", this.onScrollAnchor, { passive: true });
    this.observer = new MutationObserver(() => {
      // If the anchor row moved, content changed ABOVE it (history prepend) —
      // hold the reader on that row. This wins over edge-following: prepending
      // above must never jump you to the bottom, even if you were at the edge.
      const shifted =
        this.anchor && this.anchor.isConnected
          ? this.anchor.offsetTop - this.anchorOffset
          : 0;
      if (shifted !== 0) {
        this.el.scrollTop += shifted;
      } else if (this.wasAtEdge) {
        // nothing moved above and the reader was at the live edge — new content
        // was appended below, so stay pinned to it
        this.el.scrollTop = this.el.scrollHeight;
      }
      this.recordAnchor();
      this.recordEdge();
      this.toggle();
    });
    this.observer.observe(this.el, { childList: true });
    this.toggle();
  },
  updated() {
    this.toggle();
  },
  destroyed() {
    this.el.removeEventListener("scroll", this.onScroll);
    this.el.removeEventListener("scroll", this.onScrollAnchor);
    if (this.observer) this.observer.disconnect();
  },
  recordEdge() {
    this.wasAtEdge =
      this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 80;
  },
  recordAnchor() {
    const top = this.el.scrollTop;
    const visible = [...this.el.children].filter(
      (c) => c.offsetTop + c.offsetHeight > top
    );
    // prefer an id'd row - ids survive LiveView patches, anonymous wrappers
    // (like a "load earlier" button) often don't
    this.anchor = visible.find((c) => c.id) || visible[0] || null;
    this.anchorOffset = this.anchor ? this.anchor.offsetTop : 0;
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
// Apache ECharts wrapper. The engine is bring-your-own (window.echarts), the
// option spec arrives as data-option JSON, and every color the user didn't set
// explicitly derives from the CSS tokens at the element (chart palette from
// --pc-chart-N with a semantic-ramp fallback; axes/labels/gridlines from the
// gray ramp, ghost alphas in dark). Assign-driven updates land via updated();
// push_event("chart:update:<id>") is the merge escape hatch for streams.
export const PetalChart = {
  mounted() {
    if (!window.echarts) {
      console.warn(
        "[petal] PetalChart: window.echarts not found. Add ECharts to your app " +
          "(e.g. <script src=\"https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js\"></script>)."
      );
      return;
    }
    this.canvasEl = this.el.querySelector(".pc-chart__canvas");
    this.initChart();

    this.handleEvent(`chart:update:${this.el.id}`, ({ option }) => {
      if (this.chart) this.chart.setOption(option);
    });

    // Re-derive the theme when dark mode flips or the token dial changes.
    // Theme state in real apps lives in classes ("dark") or data attributes
    // on <html>/<body>/wrappers, so watch those (debounced; a no-op when the
    // token signature is unchanged). window "petal:retheme" is the manual
    // escape hatch for apps that retheme some other way.
    this.retheme = () => {
      clearTimeout(this.rethemeTimer);
      this.rethemeTimer = setTimeout(() => this.rethemeIfChanged(), 120);
    };
    const themeAttrs = [
      "class",
      "data-theme",
      "data-primary",
      "data-secondary",
      "data-gray",
      "data-radius",
    ];
    this.schemeObserver = new MutationObserver(this.retheme);
    this.schemeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: themeAttrs,
    });
    this.schemeObserver.observe(document.body, {
      subtree: true,
      attributes: true,
      attributeFilter: themeAttrs,
    });
    window.addEventListener("petal:retheme", this.retheme);

    if ("ResizeObserver" in window) {
      this.resizeObserver = new ResizeObserver(() => {
        if (this.chart) this.chart.resize();
      });
      this.resizeObserver.observe(this.canvasEl);
    }
  },

  updated() {
    if (this.chart) this.chart.setOption(this.option(), { notMerge: true });
  },

  destroyed() {
    clearTimeout(this.rethemeTimer);
    if (this.schemeObserver) this.schemeObserver.disconnect();
    if (this.resizeObserver) this.resizeObserver.disconnect();
    if (this.retheme) window.removeEventListener("petal:retheme", this.retheme);
    if (this.chart) this.chart.dispose();
  },

  initChart() {
    this.themeSignature = this.currentSignature();
    this.chart = window.echarts.init(this.canvasEl, this.buildTheme(), {
      renderer: this.el.dataset.renderer || "canvas",
    });
    this.chart.setOption(this.option());
    const group = this.el.dataset.group;
    if (group) {
      this.chart.group = group;
      window.echarts.connect(group);
    }
  },

  option() {
    try {
      return this.prepareOption(JSON.parse(this.el.dataset.option || "{}"));
    } catch (_e) {
      console.warn("[petal] PetalChart: invalid data-option JSON on #" + this.el.id);
      return {};
    }
  },

  // Server-side specs can't know the resolved palette, so a series may ask
  // for the shadcn-style soft fade with areaStyle: %{color: "petal:fade"} -
  // replace it with a vertical gradient of that series' own color.
  prepareOption(opt) {
    const series = Array.isArray(opt.series) ? opt.series : opt.series ? [opt.series] : [];
    const palette = series.some((s) => s.areaStyle && s.areaStyle.color === "petal:fade")
      ? this.palette()
      : null;
    series.forEach((s, i) => {
      if (!(s.areaStyle && s.areaStyle.color === "petal:fade")) return;
      const base =
        this.normalizeColor(s.color || (s.itemStyle && s.itemStyle.color) || "") ||
        palette[i % palette.length];
      const stop = (alphaPct) =>
        base.replace(/rgba\(([^)]+),\s*[\d.]+\)/, `rgba($1, ${alphaPct / 100})`);
      s.areaStyle = {
        ...s.areaStyle,
        color: {
          type: "linear",
          x: 0,
          y: 0,
          x2: 0,
          y2: 1,
          colorStops: [
            { offset: 0, color: stop(35) },
            { offset: 1, color: stop(0) },
          ],
        },
      };
    });
    return opt;
  },

  rethemeIfChanged() {
    if (!this.chart) return;
    const sig = this.currentSignature();
    if (sig === this.themeSignature) return;
    this.chart.dispose();
    this.initChart();
  },

  isDark() {
    return !!this.el.closest(".dark");
  },

  // Resolve any CSS color expression to a concrete rgba() at the element
  // (so wrapper-scoped token overrides, var() chains, light-dark() and
  // color-mix() all resolve). The final canvas round-trip matters: computed
  // values can come back as oklch()/color() strings, which the browser
  // paints fine but ECharts' own color math (hover emphasis, gradients,
  // animation lerp) cannot parse - series would vanish on hover. Returns ""
  // when the expression doesn't resolve to a color.
  resolveColor(expression) {
    if (!this.probeEl) {
      this.probeEl = document.createElement("span");
      this.probeEl.style.display = "none";
    }
    if (!this.probeEl.isConnected) this.el.appendChild(this.probeEl);
    this.probeEl.style.color = "";
    this.probeEl.style.color = expression;
    if (!this.probeEl.style.color) return "";
    return this.normalizeColor(getComputedStyle(this.probeEl).color);
  },

  normalizeColor(color) {
    if (!color) return "";
    if (/^rgba\(/.test(color)) return color;
    const rgb = color.match(/^rgb\(([^)]+)\)$/);
    if (rgb) return `rgba(${rgb[1]}, 1)`;
    if (!this.normCtx) {
      this.normCtx = document.createElement("canvas").getContext("2d", {
        willReadFrequently: true,
      });
      this.normCtx.canvas.width = 1;
      this.normCtx.canvas.height = 1;
    }
    const ctx = this.normCtx;
    ctx.clearRect(0, 0, 1, 1);
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, 1, 1);
    const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data;
    return `rgba(${r}, ${g}, ${b}, ${(a / 255).toFixed(3)})`;
  },

  token(name) {
    return getComputedStyle(this.el).getPropertyValue(name).trim();
  },

  palette() {
    const custom = [];
    for (let i = 1; i <= 8; i++) {
      if (!this.token(`--pc-chart-${i}`)) continue;
      const v = this.resolveColor(`var(--pc-chart-${i})`);
      if (v) custom.push(v);
    }
    if (custom.length) return custom;

    // Fallback: semantic ramps, in fixed order, except that any ramp whose
    // hue collides with an earlier pick (e.g. success green when primary is
    // emerald) is pushed to the back so adjacent series stay tellable-apart.
    const candidates = ["primary", "info", "warning", "danger", "success", "secondary"]
      .map((role) => this.resolveColor(`var(--color-${role}-500)`))
      .filter(Boolean);
    const picked = [];
    const demoted = [];
    for (const color of candidates) {
      const h = this.hueOf(color);
      const clashes = picked.some((p) => {
        const d = Math.abs(this.hueOf(p) - h);
        return Math.min(d, 360 - d) < 25;
      });
      (clashes ? demoted : picked).push(color);
    }
    return picked.concat(demoted);
  },

  hueOf(rgba) {
    const m = rgba.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (!m) return 0;
    const [r, g, b] = [+m[1] / 255, +m[2] / 255, +m[3] / 255];
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    if (max === min) return 0;
    const d = max - min;
    let h;
    if (max === r) h = ((g - b) / d) % 6;
    else if (max === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    return (h * 60 + 360) % 360;
  },

  currentSignature() {
    return this.palette().join("|") + "|" + this.resolveColor("var(--color-gray-500)") + "|" + this.isDark();
  },

  alpha(expression, pct) {
    return this.resolveColor(`color-mix(in oklab, ${expression} ${pct}%, transparent)`);
  },

  buildTheme() {
    const dark = this.isDark();
    const gray = (stop) => this.resolveColor(`var(--color-gray-${stop})`);
    const text = dark ? gray(400) : gray(500);
    const strongText = dark ? gray(100) : gray(900);
    const axisLine = dark ? this.alpha("var(--color-gray-400)", 25) : gray(300);
    const splitLine = dark ? this.alpha("var(--color-gray-400)", 17) : gray(200);
    const axisStyles = {
      axisLine: { lineStyle: { color: axisLine } },
      axisTick: { lineStyle: { color: axisLine } },
      axisLabel: { color: text },
      splitLine: { lineStyle: { color: splitLine } },
      splitArea: { show: false },
    };

    return {
      color: this.palette(),
      backgroundColor: "transparent",
      textStyle: { color: text },
      title: { textStyle: { color: strongText }, subtextStyle: { color: text } },
      legend: { textStyle: { color: text } },
      bar: { itemStyle: { borderRadius: [3, 3, 0, 0] } },
      categoryAxis: { ...axisStyles, splitLine: { show: false, lineStyle: { color: splitLine } } },
      valueAxis: axisStyles,
      timeAxis: axisStyles,
      logAxis: axisStyles,
      tooltip: {
        backgroundColor: dark ? gray(900) : "#ffffff",
        borderColor: dark ? this.alpha(gray(400), 25) : gray(200),
        textStyle: { color: dark ? gray(100) : gray(700) },
      },
    };
  },
};

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
    // Remove every listener mounted() registered - the document shortcut AND
    // the dialog-element handlers - so a reused dialog node can't keep stale
    // handlers that fire close/reset against a torn-down hook.
    document.removeEventListener("keydown", this.onShortcut);
    this.el.removeEventListener("pc:command-open", this.onOpen);
    this.el.removeEventListener("pc:command-close", this.onCloseEvent);
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("close", this.onClose);
    this.el.removeEventListener("click", this.onItemClick);
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

// Pauses the aurora drift while the section is off-screen.
export const PetalAurora = {
  mounted() {
    this.lights = this.el.querySelector("[data-pc-aurora]");
    if (!this.lights || !("IntersectionObserver" in window)) return;
    this.observer = new IntersectionObserver(([entry]) => {
      this.lights.classList.toggle("pc-aurora--paused", !entry.isIntersecting);
    });
    this.observer.observe(this.el);
  },
  destroyed() {
    if (this.observer) this.observer.disconnect();
  },
};

// Hover-driven navigation menu. Opens a panel on pointer hover / keyboard
// focus, with a close GRACE PERIOD so moving across the trigger-to-panel gap
// (or between siblings) doesn't drop it — the thing pure CSS :hover can't do.
// On open it also nudges the panel horizontally to stay inside the viewport
// (collision handling), the way shadcn/Radix position their flyouts.
export const PetalNavMenu = {
  mounted() {
    this.closeDelay = 140;
    this.items = [...this.el.querySelectorAll(".pc-nav-menu__item")].filter((i) =>
      i.querySelector("[data-pc-nav-panel]")
    );

    this.items.forEach((item) => {
      const panel = item.querySelector("[data-pc-nav-panel]");
      const trigger = item.querySelector(".pc-nav-menu__trigger");

      // Hover is for mouse/pen only. On touch there's no hover, so a tap would
      // fire enter (open) then click (toggle -> close) and flash - skip the
      // pointer path there and let click/tap drive the toggle instead.
      item.addEventListener("pointerenter", (e) => {
        if (e.pointerType === "touch") return;
        clearTimeout(this.closeTimer);
        this.open(item, panel, trigger);
      });
      item.addEventListener("pointerleave", (e) => {
        if (e.pointerType === "touch") return;
        clearTimeout(this.closeTimer);
        this.closeTimer = setTimeout(() => this.close(item, trigger), this.closeDelay);
      });
      // Click toggles - open it, or close an already-open one (matches shadcn).
      // While the pointer stays on the trigger, enter doesn't refire, so a
      // click-to-close stays closed until you move away and hover back. This
      // also covers keyboard activation (Enter/Space fire a native click) and
      // touch taps, so opening is never tied to focus alone - a click that
      // focuses the button can still close the panel.
      trigger.addEventListener("click", () => {
        clearTimeout(this.closeTimer);
        if (item.classList.contains("pc-nav-menu__item--open")) {
          this.close(item, trigger);
        } else {
          this.open(item, panel, trigger);
        }
      });
      // tabbing focus out of an open item closes it
      item.addEventListener("focusout", (e) => {
        if (!item.contains(e.relatedTarget)) this.close(item, trigger);
      });
    });

    this.onKeydown = (e) => {
      if (e.key === "Escape") this.closeAll();
    };
    // tap/click outside the nav closes any open panel (also the touch dismiss)
    this.onDocPointerDown = (e) => {
      if (!this.el.contains(e.target)) this.closeAll();
    };
    this.onResize = () => {
      const open = this.items.find((i) => i.classList.contains("pc-nav-menu__item--open"));
      if (open) this.position(open.querySelector("[data-pc-nav-panel]"));
    };
    document.addEventListener("keydown", this.onKeydown);
    document.addEventListener("pointerdown", this.onDocPointerDown);
    window.addEventListener("resize", this.onResize);
  },

  destroyed() {
    clearTimeout(this.closeTimer);
    document.removeEventListener("keydown", this.onKeydown);
    document.removeEventListener("pointerdown", this.onDocPointerDown);
    window.removeEventListener("resize", this.onResize);
  },

  open(item, panel, trigger) {
    this.items.forEach((other) => {
      if (other !== item) {
        other.classList.remove("pc-nav-menu__item--open");
        other.querySelector(".pc-nav-menu__trigger")?.setAttribute("aria-expanded", "false");
      }
    });
    item.classList.add("pc-nav-menu__item--open");
    trigger?.setAttribute("aria-expanded", "true");
    this.position(panel);
  },

  close(item, trigger) {
    item.classList.remove("pc-nav-menu__item--open");
    trigger?.setAttribute("aria-expanded", "false");
  },

  closeAll() {
    clearTimeout(this.closeTimer);
    this.items.forEach((item) =>
      this.close(item, item.querySelector(".pc-nav-menu__trigger"))
    );
  },

  // Nudge the panel back inside the viewport if it would spill past an edge.
  position(panel) {
    if (!panel || panel.classList.contains("pc-nav-menu__panel--full")) return;
    panel.style.transform = "";
    const margin = 8;
    const rect = panel.getBoundingClientRect();
    if (rect.right > window.innerWidth - margin) {
      panel.style.transform = `translateX(${-(rect.right - (window.innerWidth - margin))}px)`;
    } else if (rect.left < margin) {
      panel.style.transform = `translateX(${margin - rect.left}px)`;
    }
  },
};

export default {
  PetalChart,
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
  PetalAurora,
  PetalNavMenu,
  PetalCommandDialog,
};
