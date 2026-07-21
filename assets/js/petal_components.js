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
    if (!this.chart) return;
    this.chart.setOption(this.option(), { notMerge: true });
    this.syncLoading();
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
    this.syncLoading();
    const group = this.el.dataset.group;
    if (group) {
      this.chart.group = group;
      window.echarts.connect(group);
    }
  },

  syncLoading() {
    if (this.el.dataset.loading === "true") {
      const dark = this.isDark();
      this.chart.showLoading("default", {
        text: "",
        color: this.palette()[0],
        maskColor: dark
          ? this.alpha("var(--color-gray-900)", 60)
          : "rgba(255, 255, 255, 0.6)",
        spinnerRadius: 12,
        lineWidth: 3,
      });
    } else {
      this.chart.hideLoading();
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
  // replace it with a vertical gradient of that series' own color. Also
  // turns on ECharts' aria description generation unless the option says
  // otherwise (screen readers get a summary of the chart).
  prepareOption(opt) {
    if (!("aria" in opt)) opt.aria = { enabled: true };
    this.substituteFormatters(opt);
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

  // ECharts formats numbers via JS callbacks, which can't travel the wire.
  // Named "petal:*" formatter strings become Intl.NumberFormat functions
  // wherever ECharts accepts a formatter.
  formatterFor(spec) {
    const m = /^petal:(number|percent|currency|currency-compact)(?::([A-Za-z]{3}))?$/.exec(spec);
    if (!m) return null;
    const wrap = (nf, suffix) => (value) =>
      typeof value === "number" ? nf.format(value) + (suffix || "") : value;
    switch (m[1]) {
      case "number":
        return wrap(new Intl.NumberFormat(undefined, { notation: "compact", maximumFractionDigits: 1 }));
      case "percent":
        return wrap(new Intl.NumberFormat(undefined, { maximumFractionDigits: 1 }), "%");
      case "currency":
        return wrap(new Intl.NumberFormat(undefined, { style: "currency", currency: m[2] || "USD", maximumFractionDigits: 0 }));
      case "currency-compact":
        return wrap(
          new Intl.NumberFormat(undefined, {
            style: "currency",
            currency: m[2] || "USD",
            notation: "compact",
            maximumFractionDigits: 1,
          })
        );
    }
  },

  substituteFormatters(node) {
    if (Array.isArray(node)) {
      node.forEach((child) => this.substituteFormatters(child));
      return;
    }
    if (!node || typeof node !== "object") return;
    for (const key of Object.keys(node)) {
      const value = node[key];
      if ((key === "formatter" || key === "valueFormatter") && typeof value === "string") {
        const fn = this.formatterFor(value);
        if (fn) node[key] = fn;
      } else {
        this.substituteFormatters(value);
      }
    }
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
      const clashes =
        h !== null &&
        picked.some((p) => {
          const ph = this.hueOf(p);
          if (ph === null) return false;
          const d = Math.abs(ph - h);
          return Math.min(d, 360 - d) < 25;
        });
      (clashes ? demoted : picked).push(color);
    }
    return picked.concat(demoted);
  },

  // null for achromatic colors - they have no hue and never clash.
  hueOf(rgba) {
    const m = rgba.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (!m) return null;
    const [r, g, b] = [+m[1] / 255, +m[2] / 255, +m[3] / 255];
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    if (max - min < 0.04) return null;
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
    // Label-only axes (no axis lines, no tick marks) and horizontal-only
    // gridlines - the clean dashboard look shadcn also defaults to. Any of
    // it comes back with one line in the option, which always wins.
    const axisStyles = {
      axisLine: { show: false, lineStyle: { color: axisLine } },
      axisTick: { show: false, lineStyle: { color: axisLine } },
      axisLabel: { color: text, margin: 10, fontSize: 12 },
      splitLine: { lineStyle: { color: splitLine } },
      splitArea: { show: false },
    };

    return {
      color: this.palette(),
      backgroundColor: "transparent",
      textStyle: { color: text },
      title: { textStyle: { color: strongText }, subtextStyle: { color: text } },
      legend: {
        textStyle: { color: text },
        inactiveColor: dark ? this.alpha("var(--color-gray-400)", 35) : gray(300),
      },
      bar: { itemStyle: { borderRadius: [4, 4, 0, 0] } },
      line: { showSymbol: false, symbolSize: 6 },
      categoryAxis: { ...axisStyles, splitLine: { show: false, lineStyle: { color: splitLine } } },
      valueAxis: axisStyles,
      timeAxis: axisStyles,
      logAxis: axisStyles,
      tooltip: {
        backgroundColor: dark ? gray(900) : "#ffffff",
        borderColor: dark ? this.alpha(gray(400), 25) : gray(200),
        textStyle: { color: dark ? gray(100) : gray(700), fontSize: 12 },
        axisPointer: {
          lineStyle: { color: dark ? this.alpha(gray(400), 30) : gray(300) },
          crossStyle: { color: dark ? this.alpha(gray(400), 30) : gray(300) },
          shadowStyle: { color: this.alpha(gray(400), dark ? 8 : 12) },
        },
        padding: [8, 12],
        extraCssText:
          "border-radius: clamp(0.25rem, calc(var(--pc-radius, 0.625rem) - 0.125rem), 0.875rem); " +
          "box-shadow: 0 4px 14px rgba(0, 0, 0, 0.18);",
      },
    };
  },
};

// Colour-scheme switch (toggle / dropdown / segmented). Requires the
// window.PetalColorScheme contract from <.color_scheme_script /> in <head>.
// All instances stay in sync via the petal:scheme-changed window event.
export const PetalColorScheme = {
  mounted() {
    if (!window.PetalColorScheme) {
      console.warn(
        "[petal] PetalColorScheme: render <.color_scheme_script /> in your layout's <head>."
      );
      return;
    }
    this.variant = this.el.dataset.variant;
    this.sync = () => this.reflect();
    window.addEventListener("petal:scheme-changed", this.sync);

    if (this.variant === "toggle") {
      this.onClick = () => {
        const next = window.PetalColorScheme.resolved() === "dark" ? "light" : "dark";
        window.PetalColorScheme.set(next);
      };
      this.el.addEventListener("click", this.onClick);
    } else if (this.variant === "segmented") {
      this.onChange = (e) => {
        if (e.target instanceof HTMLInputElement) window.PetalColorScheme.set(e.target.value);
      };
      this.el.addEventListener("change", this.onChange);
    } else {
      this.onClick = (e) => {
        const item = e.target.closest("[data-scheme]");
        if (!item) return;
        window.PetalColorScheme.set(item.dataset.scheme);
        // menus dismiss on select - retoggle via the trigger
        const trigger = this.el.querySelector(".pc-dropdown button");
        if (trigger) trigger.click();
      };
      this.el.addEventListener("click", this.onClick);
    }

    this.reflect();
  },

  updated() {
    this.reflect();
  },

  destroyed() {
    window.removeEventListener("petal:scheme-changed", this.sync);
  },

  reflect() {
    if (!window.PetalColorScheme) return;
    const pref = window.PetalColorScheme.preference();
    this.el.querySelectorAll('input[type="radio"]').forEach((r) => {
      r.checked = r.value === pref;
    });
    this.el.querySelectorAll("[data-scheme]").forEach((n) => {
      n.setAttribute("aria-checked", n.dataset.scheme === pref ? "true" : "false");
    });
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


// Localised timestamps: formats the <time datetime> UTC instant with the
// browser's Intl. Relative forms tick on a decaying cadence and re-render
// when a hidden tab becomes visible (browsers throttle background timers).
export const PetalLocalTime = {
  mounted() {
    this.render = this.render.bind(this);
    this.onVisible = () => {
      if (!document.hidden) this.render();
    };
    document.addEventListener("visibilitychange", this.onVisible);
    this.render();
  },

  updated() {
    // LiveView patches restore the SSR ISO fallback - format it again
    this.render();
  },

  destroyed() {
    clearTimeout(this.timer);
    document.removeEventListener("visibilitychange", this.onVisible);
  },

  config() {
    const d = this.el.dataset;
    let options = null;
    if (d.options) {
      try {
        options = JSON.parse(d.options);
      } catch (_e) {
        console.warn("[petal] PetalLocalTime: invalid data-options JSON on #" + this.el.id);
      }
    }
    return {
      format: d.format || "datetime",
      options,
      locale: d.locale || undefined,
      timezone: d.timezone || undefined,
      threshold: parseInt(d.threshold || "604800", 10),
      title: d.title !== "false",
    };
  },

  absolute(date, cfg) {
    const presets = {
      datetime: { dateStyle: "medium", timeStyle: "short" },
      date: { dateStyle: "medium" },
      time: { timeStyle: "short" },
    };
    const opts = cfg.options || presets[cfg.format] || presets.datetime;
    return new Intl.DateTimeFormat(cfg.locale, { timeZone: cfg.timezone, ...opts }).format(date);
  },

  relative(cfg, ageSeconds) {
    const rtf = new Intl.RelativeTimeFormat(cfg.locale, { numeric: "auto" });
    const abs = Math.abs(ageSeconds);
    const units = [
      ["year", 31536000],
      ["month", 2592000],
      ["week", 604800],
      ["day", 86400],
      ["hour", 3600],
      ["minute", 60],
      ["second", 1],
    ];
    for (const [unit, secs] of units) {
      if (abs >= secs || unit === "second") {
        return rtf.format(Math.round(-ageSeconds / secs), unit);
      }
    }
  },

  render() {
    clearTimeout(this.timer);
    const cfg = this.config();
    const date = new Date(this.el.getAttribute("datetime"));
    if (isNaN(date)) return;

    if (cfg.format === "relative") {
      const age = (Date.now() - date.getTime()) / 1000;

      if (Math.abs(age) > cfg.threshold) {
        this.el.textContent = this.absolute(date, { ...cfg, format: "datetime", options: null });
        return;
      }

      this.el.textContent = this.relative(cfg, age);

      if (cfg.title) {
        this.el.title = new Intl.DateTimeFormat(cfg.locale, {
          timeZone: cfg.timezone,
          dateStyle: "full",
          timeStyle: "short",
        }).format(date);
      }

      // decaying cadence: fresh timestamps tick fast, old ones barely at all
      const abs = Math.abs(age);
      const next = abs < 60 ? 5 : abs < 3600 ? 30 : abs < 86400 ? 900 : 3600;
      this.timer = setTimeout(this.render, next * 1000);
    } else {
      this.el.textContent = this.absolute(date, cfg);
    }
  },
};

// Carousel: ported verbatim from petal_marketing's CarouselHook
// (921 lines, battle-tested) - interaction logic deliberately untouched.
export const PetalCarousel = {
  mounted() {
    this.id = this.el.id;
    this.carouselContainer = this.el;
    // Look for wrapper to support "below" button style
    this.wrapper = this.el.closest(".pc-carousel-wrapper") || this.el;
    this.slideWrapper = this.el.querySelector(".pc-carousel__slides");
    this.slides = Array.from(this.el.querySelectorAll(".pc-carousel__slide"));
    this.navdots = Array.from(
      this.el.querySelectorAll(".pc-carousel__indicator")
    );
    this.thumbs = Array.from(
      this.wrapper.querySelectorAll("[data-thumb-index]")
    );

    this.activeIndex = parseInt(this.el.dataset.activeIndex) || 0;
    this.transitionType = this.el.dataset.transitionType || "fade";
    this.autoplay = this.el.dataset.autoplay === "true";
    this.autoplayInterval = parseInt(this.el.dataset.autoplayInterval) || 5000;
    this.slidesPerViewDesktop = parseInt(this.el.dataset.slidesPerView) || 1;
    this.slidesPerView = this.getResponsiveSlidesPerView();
    this.gap = this.el.dataset.gap || "1rem";
    this.swipe = this.el.dataset.swipe !== "false"; // Default to true
    this.loop = this.el.dataset.loop !== "false"; // Default to true

    // Detect vertical orientation
    this.isVertical = this.el.classList.contains("pc-carousel--vertical");

    // Parameters for CSS Scroll Snap approach
    this.n_slides = this.slides.length;
    // For multi-slide view with infinite loop, clone all slides on each side for seamless wrapping
    // This allows scrolling in both directions through the loop
    this.n_slidesCloned = this.transitionType === "slide" ? this.n_slides : 0;
    this.slideWidth = this.slides[0] ? this.slides[0].offsetWidth : 0;
    // For CSS Scroll Snap, we don't need gaps between slides
    this.spaceBtwSlides = 0;

    // For infinite carousels, we cycle through all slides
    // For non-infinite, the last position shows the last N slides
    this.maxScrollIndex = this.n_slides - 1;

    if (this.transitionType === "slide") {
      this.initScrollSnapCarousel();
    } else {
      this.initFadeCarousel();
    }

    this.setupNavigation();
    this.setupIndicators();
    this.setupThumbnails();
    this.setupKeyboardNavigation();

    if (this.autoplay) {
      this.startAutoplay();

      // Pause on hover
      this.el.addEventListener("mouseenter", () => {
        this.stopAutoplay();
      });

      this.el.addEventListener("mouseleave", () => {
        this.startAutoplay();
      });
    }
  },

  destroyed() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer);
    }
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
    if (this.keyboardHandler) {
      this.el.removeEventListener("keydown", this.keyboardHandler);
    }
  },

  // Helper function to apply slide dimensions based on orientation
  applySlideDimensions(slide) {
    slide.style.flex = `0 0 ${this.slideWidth}px`;

    // CRITICAL: Always use 'start' alignment for consistent scroll positioning calculations
    // Using 'center' for multi-slide views would require adding centering offsets to all
    // scroll position calculations (goto, prevSlide, nextSlide, index_slideCurrent)
    slide.style.scrollSnapAlign = "start";

    if (this.isVertical) {
      slide.style.height = `${this.slideWidth}px`;
      slide.style.minHeight = `${this.slideWidth}px`;
      slide.style.maxHeight = `${this.slideWidth}px`;
      slide.style.width = "100%";
    } else {
      slide.style.width = `${this.slideWidth}px`;
      slide.style.minWidth = `${this.slideWidth}px`;
      slide.style.maxWidth = `${this.slideWidth}px`;
    }
  },

  // Helper function to clone a slide for infinite scrolling
  cloneSlide(slideToClone) {
    const clone = slideToClone.cloneNode(true);
    clone.setAttribute("aria-hidden", "true");
    this.applySlideDimensions(clone);
    return clone;
  },

  // Helper function to reset autoplay after manual interaction
  resetAutoplay() {
    if (this.autoplay) {
      this.stopAutoplay();
      this.startAutoplay();
    }
  },

  getResponsiveSlidesPerView() {
    // If only 1 slide per view on desktop, no need for responsive logic
    if (this.slidesPerViewDesktop <= 1) {
      return 1;
    }

    const width = window.innerWidth;

    // Mobile portrait: 1 slide
    if (width < 768) {
      return 1;
    }
    // Tablet and mobile landscape: 2 slides
    else if (width < 1024) {
      return Math.min(2, this.slidesPerViewDesktop);
    }
    // Desktop: use the configured value
    else {
      return this.slidesPerViewDesktop;
    }
  },

  initScrollSnapCarousel() {
    // Set up CSS Scroll Snap carousel (like the Medium article)
    this.slideWrapper.style.display = "flex";
    this.slideWrapper.style.overflow = "auto";

    // Set scroll snap direction based on orientation
    if (this.isVertical) {
      this.slideWrapper.style.scrollSnapType = "y mandatory";
      this.slideWrapper.style.height = "100%";
    } else {
      this.slideWrapper.style.scrollSnapType = "x mandatory";
      this.slideWrapper.style.width = "100%";
      this.slideWrapper.style.maxWidth = "100%";
    }

    this.slideWrapper.style.scrollbarWidth = "none"; // Firefox

    // Hide webkit scrollbar
    const style = document.createElement("style");
    style.textContent = `
      #${this.id} .pc-carousel__slides::-webkit-scrollbar {
        display: none;
      }
    `;
    document.head.appendChild(style);

    // Update slide dimensions before setting up slides
    this.updateSlideWidth();

    // Set up each slide for scroll snap with explicit dimensions
    this.slides.forEach((slide) => {
      this.applySlideDimensions(slide);
    });

    // Set up infinite scrolling
    this.setupInfiniteScrolling();

    // Set up scroll event listener
    this.setupScrollListener();

    // Set up resize observer
    this.setupResizeObserver();

    // Set up mouse drag support (only if swipe is enabled)
    if (this.swipe) {
      this.setupMouseDrag();
    }

    // Initialize to first real slide (after cloned last slide)
    setTimeout(() => {
      this.goto(0, false); // Use goto with smooth=false for initialization
      this.updateIndicators();
      this.updateButtonStates();
    }, 50);
  },

  initFadeCarousel() {
    // Keep existing fade logic
    this.transitionDuration =
      parseInt(this.el.dataset.transitionDuration) || 500;

    this.slides.forEach((slide, index) => {
      slide.style.position = "absolute";
      slide.style.top = "0";
      slide.style.left = "0";
      slide.style.width = "100%";
      slide.style.height = "100%";
      slide.style.transition = `opacity ${this.transitionDuration}ms ease-in-out`;

      if (index === this.activeIndex) {
        slide.classList.add("pc-carousel__slide--active");
        slide.style.opacity = "1";
        slide.style.zIndex = "10";
      } else {
        slide.classList.add("pc-carousel__slide--inactive");
        slide.style.opacity = "0";
        slide.style.zIndex = "1";
      }
    });
  },

  // CSS Scroll Snap helper functions (from Medium article)
  index_slideCurrent() {
    const scrollPos = this.isVertical
      ? this.slideWrapper.scrollTop
      : this.slideWrapper.scrollLeft;
    const rawPosition = scrollPos / (this.slideWidth + this.spaceBtwSlides);
    const index = Math.round(rawPosition - this.n_slidesCloned);

    return index;
  },

  goto(index, smooth = true) {
    // Account for cloned slides - add offset for the cloned last slide at the beginning
    const scrollPosition =
      (this.slideWidth + this.spaceBtwSlides) * (index + this.n_slidesCloned);

    if (smooth) {
      this.slideWrapper.scrollTo({
        left: this.isVertical ? 0 : scrollPosition,
        top: this.isVertical ? scrollPosition : 0,
        behavior: "smooth",
      });
    } else {
      if (this.isVertical) {
        this.slideWrapper.scrollTo(0, scrollPosition);
      } else {
        this.slideWrapper.scrollTo(scrollPosition, 0);
      }
    }
  },

  setupInfiniteScrolling() {
    if (this.n_slides === 0) return;

    // Skip cloning if loop is disabled
    if (!this.loop) {
      this.n_slidesCloned = 0;
      return;
    }

    // Clone ALL slides and append to end for forward scrolling
    for (let i = 0; i < this.n_slides; i++) {
      this.slideWrapper.append(this.cloneSlide(this.slides[i]));
    }

    // Clone ALL slides and prepend to beginning for backward scrolling
    // Prepend in reverse order so they appear in correct sequence
    for (let i = this.n_slides - 1; i >= 0; i--) {
      this.slideWrapper.prepend(this.cloneSlide(this.slides[i]));
    }
  },

  setupScrollListener() {
    let scrollTimer;
    let indexUpdateTimer;
    this.isScrolling = false;

    this.slideWrapper.addEventListener("scroll", () => {
      // Debounce activeIndex update to prevent jumping during smooth scroll
      if (indexUpdateTimer) clearTimeout(indexUpdateTimer);

      indexUpdateTimer = setTimeout(() => {
        // Update active index based on current scroll position after scrolling settles
        const currentIndex = this.index_slideCurrent();
        if (currentIndex >= 0 && currentIndex < this.n_slides) {
          this.activeIndex = currentIndex;
          this.updateIndicators();
          this.updateButtonStates();
        }
      }, 50); // Short delay to wait for scroll to settle

      // Handle infinite scrolling with debouncing (skip if loop is disabled)
      if (this.loop) {
        if (scrollTimer) clearTimeout(scrollTimer);

        scrollTimer = setTimeout(() => {
          const scrollPos = this.isVertical
            ? this.slideWrapper.scrollTop
            : this.slideWrapper.scrollLeft;

          // For multi-slide view, use position-based detection instead of threshold
          // Calculate the current position index
          const currentPosition = Math.round(
            scrollPos / (this.slideWidth + this.spaceBtwSlides)
          );

          // Check if we're at or before the first real slide position
          // Real slides start at position n_slidesCloned
          if (currentPosition < this.n_slidesCloned) {
            this.forward();
          }
          // Check if we're at or after the last cloned slide position
          // Cloned slides at end start at position (n_slidesCloned + n_slides)
          else if (currentPosition >= this.n_slidesCloned + this.n_slides) {
            this.rewind();
          }
        }, 100);
      }
    });
  },

  rewind() {
    // Update index immediately for indicators
    this.activeIndex = 0;
    this.updateIndicators();
    this.updateButtonStates();

    setTimeout(() => {
      this.goto(0, false); // Instant jump to first slide
    }, 50); // Reduced delay for smoother transition
  },

  forward() {
    // Update index immediately for indicators
    this.activeIndex = this.n_slides - 1;
    this.updateIndicators();
    this.updateButtonStates();

    setTimeout(() => {
      this.goto(this.n_slides - 1, false); // Instant jump to last slide
    }, 50); // Reduced delay for smoother transition
  },

  updateSlideWidth() {
    if (this.slideWrapper) {
      // Use offsetWidth/offsetHeight which includes padding for accurate measurements
      const containerSize = this.isVertical
        ? this.carouselContainer.offsetHeight
        : this.carouselContainer.offsetWidth;

      // Convert gap to pixels if needed
      const gapInPx = this.parseGapToPixels(this.gap);

      // Set CSS custom property for gap (applies to all views)
      this.slideWrapper.style.setProperty("--carousel-gap", this.gap);

      if (this.slidesPerView > 1 && !this.isVertical) {
        // Multi-slide view: calculate width per slide accounting for gaps
        // Total gap space = (number of slides - 1) * gap
        const totalGapSpace = (this.slidesPerView - 1) * gapInPx;
        this.slideWidth = (containerSize - totalGapSpace) / this.slidesPerView;
        this.spaceBtwSlides = gapInPx;
      } else {
        // Single slide view or vertical: full container size
        this.slideWidth = containerSize;
        // Gap still affects scroll positioning even with one slide visible
        this.spaceBtwSlides = gapInPx;
      }

      // Measure actual dimensions after browser renders
      // Verify that CSS gap and slide dimensions match our calculations
      if (this.slides.length > 1) {
        // Use setTimeout to measure after browser fully renders (200ms for larger screens)
        setTimeout(() => {
          if (!this.slides[0]) return;

          const actualWidth = this.isVertical
            ? this.slides[0].offsetHeight
            : this.slides[0].offsetWidth;
          const actualSpacing = this.isVertical
            ? this.slides[1].offsetTop - this.slides[0].offsetTop
            : this.slides[1].offsetLeft - this.slides[0].offsetLeft;
          const measuredGap = actualSpacing - actualWidth;

          let needsUpdate = false;

          // For single-slide views, trust measured width over calculated
          if (
            this.slidesPerView === 1 &&
            Math.abs(actualWidth - this.slideWidth) > 2
          ) {
            this.slideWidth = actualWidth;
            needsUpdate = true;
          }

          // For all views, verify gap matches (critical for loop positioning)
          if (
            measuredGap > 1 &&
            Math.abs(measuredGap - this.spaceBtwSlides) > 2
          ) {
            this.spaceBtwSlides = measuredGap;
            needsUpdate = true;
          }

          // Reapply if measurements differ
          if (needsUpdate) {
            const allSlides = this.slideWrapper.querySelectorAll(
              ".pc-carousel__slide"
            );
            allSlides.forEach((slide) => {
              this.applySlideDimensions(slide);
            });
            this.goto(this.activeIndex, false);
          }
        }, 200);
      }
    }
  },

  parseGapToPixels(gap) {
    // Convert rem, em, or px values to pixels
    if (gap.endsWith("rem")) {
      const remValue = parseFloat(gap);
      const rootFontSize = parseFloat(
        getComputedStyle(document.documentElement).fontSize
      );
      return remValue * rootFontSize;
    } else if (gap.endsWith("em")) {
      const emValue = parseFloat(gap);
      const fontSize = parseFloat(getComputedStyle(this.el).fontSize);
      return emValue * fontSize;
    } else if (gap.endsWith("px")) {
      return parseFloat(gap);
    } else {
      // Assume pixels if no unit
      return parseFloat(gap) || 0;
    }
  },

  setupResizeObserver() {
    if (typeof ResizeObserver !== "undefined") {
      this.resizeObserver = new ResizeObserver(() => {
        const currentIndex = this.activeIndex;

        // Recalculate responsive slides per view
        const newSlidesPerView = this.getResponsiveSlidesPerView();
        const slidesPerViewChanged = newSlidesPerView !== this.slidesPerView;

        if (slidesPerViewChanged) {
          this.slidesPerView = newSlidesPerView;

          // Need to rebuild clones for new slides per view
          if (this.transitionType === "slide") {
            // Remove all cloned slides
            const allSlides = this.slideWrapper.querySelectorAll(
              ".pc-carousel__slide"
            );
            allSlides.forEach((slide) => {
              if (slide.getAttribute("aria-hidden") === "true") {
                slide.remove();
              }
            });

            // Recalculate and setup
            this.updateSlideWidth();
            this.setupInfiniteScrolling();
          }
        } else {
          this.updateSlideWidth();
        }

        // Reapply dimensions to all slides after resize
        if (this.transitionType === "slide") {
          const allSlides = this.slideWrapper.querySelectorAll(
            ".pc-carousel__slide"
          );
          allSlides.forEach((slide) => {
            this.applySlideDimensions(slide);
          });

          this.goto(currentIndex, false); // Instant reposition after resize
        }
      });
      this.resizeObserver.observe(this.slideWrapper);
    }
  },

  setupMouseDrag() {
    let isDragging = false;
    let startPos = 0;
    let scrollPos = 0;
    let currentPos = 0;
    let animationFrame = null;

    // Add cursor style
    this.slideWrapper.style.cursor = "grab";

    // Smooth scrolling with requestAnimationFrame
    const smoothScroll = () => {
      if (!isDragging) return;

      const walk = (currentPos - startPos) * 1.5; // Adjusted multiplier for smooth feel

      if (this.isVertical) {
        this.slideWrapper.scrollTop = scrollPos - walk;
      } else {
        this.slideWrapper.scrollLeft = scrollPos - walk;
      }

      animationFrame = requestAnimationFrame(smoothScroll);
    };

    const handleMouseDown = (e) => {
      // Don't start drag on buttons or links
      if (e.target.closest("button") || e.target.closest("a")) {
        return;
      }

      isDragging = true;
      this.slideWrapper.style.cursor = "grabbing";
      this.slideWrapper.style.userSelect = "none"; // Prevent text selection during drag
      this.slideWrapper.style.scrollSnapType = "none"; // Disable snap during drag

      if (this.isVertical) {
        startPos = e.pageY - this.slideWrapper.offsetTop;
        scrollPos = this.slideWrapper.scrollTop;
      } else {
        startPos = e.pageX - this.slideWrapper.offsetLeft;
        scrollPos = this.slideWrapper.scrollLeft;
      }

      currentPos = startPos;

      // Start smooth scrolling loop
      animationFrame = requestAnimationFrame(smoothScroll);

      // Pause autoplay during drag
      if (this.autoplay) {
        this.stopAutoplay();
      }
    };

    const handleMouseMove = (e) => {
      if (!isDragging) return;

      e.preventDefault();

      if (this.isVertical) {
        currentPos = e.pageY - this.slideWrapper.offsetTop;
      } else {
        currentPos = e.pageX - this.slideWrapper.offsetLeft;
      }
    };

    const handleMouseUp = () => {
      if (!isDragging) return;

      isDragging = false;
      this.slideWrapper.style.cursor = "grab";
      this.slideWrapper.style.userSelect = "";
      // Re-enable snap with proper direction
      this.slideWrapper.style.scrollSnapType = this.isVertical
        ? "y mandatory"
        : "x mandatory";

      // Cancel animation frame
      if (animationFrame) {
        cancelAnimationFrame(animationFrame);
        animationFrame = null;
      }

      // Resume autoplay after drag
      if (this.autoplay) {
        this.startAutoplay();
      }
    };

    const handleMouseLeave = () => {
      if (!isDragging) return;

      isDragging = false;
      this.slideWrapper.style.cursor = "grab";
      this.slideWrapper.style.userSelect = "";
      // Re-enable snap with proper direction
      this.slideWrapper.style.scrollSnapType = this.isVertical
        ? "y mandatory"
        : "x mandatory";

      // Cancel animation frame
      if (animationFrame) {
        cancelAnimationFrame(animationFrame);
        animationFrame = null;
      }

      // Resume autoplay if we were dragging
      if (this.autoplay) {
        this.startAutoplay();
      }
    };

    // Add event listeners
    this.slideWrapper.addEventListener("mousedown", handleMouseDown);
    this.slideWrapper.addEventListener("mousemove", handleMouseMove);
    this.slideWrapper.addEventListener("mouseup", handleMouseUp);
    this.slideWrapper.addEventListener("mouseleave", handleMouseLeave);

    // Prevent drag on links and images
    this.slideWrapper.addEventListener("dragstart", (e) => {
      e.preventDefault();
    });

    // Prevent click events if there was significant dragging
    let clickStartX = 0;
    this.slideWrapper.addEventListener("mousedown", (e) => {
      clickStartX = e.pageX;
    });
    this.slideWrapper.addEventListener(
      "click",
      (e) => {
        const clickEndX = e.pageX;
        if (Math.abs(clickEndX - clickStartX) > 5) {
          e.preventDefault();
          e.stopPropagation();
        }
      },
      true
    );
  },

  setupNavigation() {
    // Look in wrapper to support "below" button style
    const prevButton = this.wrapper.querySelector(`#${this.id}-carousel-prev`);
    const nextButton = this.wrapper.querySelector(`#${this.id}-carousel-next`);

    if (prevButton) {
      prevButton.addEventListener("click", () => {
        this.prevSlide();
        this.resetAutoplay();
      });
    }

    if (nextButton) {
      nextButton.addEventListener("click", () => {
        this.nextSlide();
        this.resetAutoplay();
      });
    }
  },

  setupIndicators() {
    this.navdots.forEach((indicator, index) => {
      indicator.addEventListener("click", () => {
        if (this.transitionType === "slide") {
          this.activeIndex = index;
          this.goto(index);
          this.updateIndicators();
        } else {
          this.goToSlide(index);
        }
        this.resetAutoplay();
      });
    });

    // Set initial indicator state
    this.updateIndicators();
  },

  // Synced thumbnails: same contract as indicators - click to jump,
  // active state follows the carousel.
  setupThumbnails() {
    this.thumbs.forEach((thumb, index) => {
      thumb.addEventListener("click", () => {
        if (this.transitionType === "slide") {
          this.activeIndex = index;
          this.goto(index);
          this.updateIndicators();
        } else {
          this.goToSlide(index);
        }
        this.resetAutoplay();
      });
    });
  },

  setupKeyboardNavigation() {
    // Add keyboard navigation for accessibility
    this.keyboardHandler = (e) => {
      // Only respond to arrow keys
      const isArrowKey = [
        "ArrowLeft",
        "ArrowRight",
        "ArrowUp",
        "ArrowDown",
      ].includes(e.key);
      if (!isArrowKey) return;

      // Prevent default scrolling behavior
      e.preventDefault();

      // Determine direction based on orientation and key
      const isNext = this.isVertical
        ? e.key === "ArrowDown"
        : e.key === "ArrowRight";
      const isPrev = this.isVertical
        ? e.key === "ArrowUp"
        : e.key === "ArrowLeft";

      if (isNext) {
        this.nextSlide();
      } else if (isPrev) {
        this.prevSlide();
      }

      this.resetAutoplay();
    };

    // Make carousel focusable
    if (!this.el.hasAttribute("tabindex")) {
      this.el.setAttribute("tabindex", "0");
    }

    // Add event listener
    this.el.addEventListener("keydown", this.keyboardHandler);
  },

  startAutoplay() {
    // Clear any existing timer first to prevent duplicates
    this.stopAutoplay();

    this.autoplayTimer = setInterval(() => {
      this.nextSlide();
    }, this.autoplayInterval);
  },

  stopAutoplay() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer);
      this.autoplayTimer = null;
    }
  },

  prevSlide() {
    // Prevent rapid consecutive calls
    if (this.isTransitioning) {
      return;
    }

    if (this.transitionType === "slide") {
      this.isTransitioning = true;

      if (this.activeIndex === 0) {
        // If loop is disabled, prevent going past the first slide
        if (!this.loop) {
          this.isTransitioning = false;
          return;
        }

        // At first slide with loop enabled, scroll to the cloned slides at the beginning
        const scrollPosition =
          (this.slideWidth + this.spaceBtwSlides) * (this.n_slidesCloned - 1);
        this.slideWrapper.scrollTo({
          left: this.isVertical ? 0 : scrollPosition,
          top: this.isVertical ? scrollPosition : 0,
          behavior: "smooth",
        });
      } else {
        // Normal previous slide
        this.activeIndex = this.activeIndex - 1;
        this.goto(this.activeIndex);
      }

      // Release lock after transition completes
      setTimeout(() => {
        this.isTransitioning = false;
      }, 600); // Slightly longer than CSS transition
    } else {
      // Fade transition
      if (!this.loop && this.activeIndex === 0) {
        // At first slide with loop disabled, prevent going previous
        return;
      }
      const newIndex = (this.activeIndex - 1 + this.n_slides) % this.n_slides;
      this.goToSlide(newIndex);
    }
  },

  nextSlide() {
    // Prevent rapid consecutive calls
    if (this.isTransitioning) {
      return;
    }

    if (this.transitionType === "slide") {
      this.isTransitioning = true;

      if (this.activeIndex >= this.n_slides - 1) {
        // If loop is disabled, prevent going past the last slide
        if (!this.loop) {
          this.isTransitioning = false;
          return;
        }

        // At last slide with loop enabled, smoothly scroll to the first slide position
        this.activeIndex = 0;
        // Scroll past all slides to trigger rewind
        const scrollPosition =
          (this.slideWidth + this.spaceBtwSlides) *
          (this.n_slides + this.n_slidesCloned);
        this.slideWrapper.scrollTo({
          left: this.isVertical ? 0 : scrollPosition,
          top: this.isVertical ? scrollPosition : 0,
          behavior: "smooth",
        });
      } else {
        // Normal next slide
        this.activeIndex = this.activeIndex + 1;
        this.goto(this.activeIndex);
      }

      // Release lock after transition completes
      setTimeout(() => {
        this.isTransitioning = false;
      }, 600); // Slightly longer than CSS transition
    } else {
      // Fade transition
      if (!this.loop && this.activeIndex >= this.n_slides - 1) {
        // At last slide with loop disabled, prevent going next
        return;
      }
      const newIndex = (this.activeIndex + 1) % this.n_slides;
      this.goToSlide(newIndex);
    }
  },

  goToSlide(newIndex) {
    if (this.isTransitioning) return;

    this.isTransitioning = true;
    const oldIndex = this.activeIndex;
    this.activeIndex = newIndex;

    if (this.transitionType === "slide") {
      // For direct navigation, we'll use a simple approach
      // This could be enhanced to animate to the target slide
      this.isTransitioning = false;
      this.updateIndicators();
    } else {
      // Fade transition - works for both forward and backward
      const currentSlide = this.slides[oldIndex];
      const nextSlide = this.slides[newIndex];

      // Update classes
      currentSlide.classList.remove("pc-carousel__slide--active");
      currentSlide.classList.add("pc-carousel__slide--inactive");
      nextSlide.classList.remove("pc-carousel__slide--inactive");
      nextSlide.classList.add("pc-carousel__slide--active");

      // Set up the incoming slide
      nextSlide.style.zIndex = "10";
      nextSlide.style.opacity = "0";

      // Force reflow to ensure opacity 0 is applied before transition
      void nextSlide.offsetWidth;

      // Start fade in AND fade out simultaneously
      nextSlide.style.opacity = "1";
      currentSlide.style.opacity = "0";

      // Clean up after transition completes
      setTimeout(() => {
        currentSlide.style.zIndex = "1";
        this.isTransitioning = false;
      }, this.transitionDuration);
    }

    // Update indicators and button states
    this.updateIndicators();
    this.updateButtonStates();
  },

  updateIndicators() {
    const indicators = this.el.querySelectorAll(".pc-carousel__indicator");

    indicators.forEach((indicator, index) => {
      if (index === this.activeIndex) {
        indicator.classList.add("opacity-100");
      } else {
        indicator.classList.remove("opacity-100");
      }
    });

    // Update aria-current on slides
    this.slides.forEach((slide, index) => {
      if (index === this.activeIndex) {
        slide.setAttribute("aria-current", "true");
      } else {
        slide.setAttribute("aria-current", "false");
      }
    });

    // Sync thumbnails with the active slide
    this.thumbs.forEach((thumb, index) => {
      thumb.classList.toggle(
        "pc-carousel__thumb--active",
        index === this.activeIndex
      );
      thumb.setAttribute(
        "aria-current",
        index === this.activeIndex ? "true" : "false"
      );
    });

    // Notify listeners once per actual change (updateIndicators also runs
    // on resize and re-init passes where the index hasn't moved)
    if (this._lastEventIndex !== this.activeIndex) {
      this._lastEventIndex = this.activeIndex;
      this.el.dispatchEvent(
        new CustomEvent("petal:carousel-change", {
          detail: {
            id: this.el.id,
            index: this.activeIndex,
            count: this.n_slides,
          },
          bubbles: true,
        })
      );
    }

    // Announce slide change to screen readers
    this.announceSlideChange();
  },

  announceSlideChange() {
    const liveRegion = this.el.querySelector(`#${this.id}-live-region`);
    if (liveRegion) {
      liveRegion.textContent = `Slide ${this.activeIndex + 1} of ${
        this.n_slides
      }`;
    }
  },

  updateButtonStates() {
    // Only update button states when loop is disabled
    if (this.loop) {
      // When loop is enabled, ensure buttons are always enabled
      const prevButton = this.wrapper.querySelector(
        `#${this.id}-carousel-prev`
      );
      const nextButton = this.wrapper.querySelector(
        `#${this.id}-carousel-next`
      );

      if (prevButton) prevButton.disabled = false;
      if (nextButton) nextButton.disabled = false;
      return;
    }

    // When loop is disabled, disable buttons at boundaries
    const prevButton = this.wrapper.querySelector(`#${this.id}-carousel-prev`);
    const nextButton = this.wrapper.querySelector(`#${this.id}-carousel-next`);

    if (prevButton) {
      prevButton.disabled = this.activeIndex === 0;
    }

    if (nextButton) {
      nextButton.disabled = this.activeIndex >= this.n_slides - 1;
    }
  },
};

export default {
  PetalChart,
  PetalColorScheme,
  PetalLocalTime,
  PetalCarousel,
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
