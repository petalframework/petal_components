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
        this.scroller.scrollHeight -
          this.scroller.scrollTop -
          this.scroller.clientHeight <
          80;
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
      const scroller = this.el
        .closest(".pc-chat")
        ?.querySelector("[data-pc-scroll]");
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
      (c) => c.offsetTop + c.offsetHeight > top,
    );
    // prefer an id'd row - ids survive LiveView patches, anonymous wrappers
    // (like a "load earlier" button) often don't
    this.anchor = visible.find((c) => c.id) || visible[0] || null;
    this.anchorOffset = this.anchor ? this.anchor.offsetTop : 0;
  },
  toggle() {
    if (!this.btn) return;
    const slack =
      this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight;
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
      btn.setAttribute("aria-pressed", String(revealed));
      btn.setAttribute(
        "aria-label",
        revealed ? "Hide password" : "Show password",
      );
    });
  },
};

// Copyable field: copy the (readonly) input value, flip to a success check for
// 2s, and announce the copy to screen readers via the polite live region.
export const PetalCopyInput = {
  mounted() {
    const input = this.el.querySelector("[data-pc-copy-input]");
    const btn = this.el.querySelector("[data-pc-copy-btn]");
    const def = this.el.querySelector("[data-pc-copy-default]");
    const done = this.el.querySelector("[data-pc-copy-done]");
    const announce = this.el.querySelector("[data-pc-copy-announce]");
    if (!input || !btn) return;

    btn.addEventListener("click", () => {
      navigator.clipboard?.writeText(input.value);
      if (def) def.classList.add("hidden");
      if (done) done.classList.remove("hidden");
      if (announce) announce.textContent = "Copied to clipboard";
      clearTimeout(this.revertTimer);
      this.revertTimer = setTimeout(() => {
        if (def) def.classList.remove("hidden");
        if (done) done.classList.add("hidden");
        if (announce) announce.textContent = "";
      }, 2000);
    });
  },
  destroyed() {
    clearTimeout(this.revertTimer);
  },
};

// Clearable field: show the clear button only when there's a value; clear resets
// the input and dispatches an input event so LiveView/forms see the change.
export const PetalClearableInput = {
  mounted() {
    this.input = this.el.querySelector("[data-pc-clear-input]");
    this.btn = this.el.querySelector("[data-pc-clear-btn]");
    if (!this.input || !this.btn) return;

    this.sync = () =>
      this.btn.classList.toggle("hidden", this.input.value.length === 0);
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

// Range fill: keeps --pc-range-fill in sync with a single <input type="range">
// so webkit can paint a primary fill from the start to the thumb (Firefox does
// it natively via ::-moz-range-progress). The server sets the initial value; the
// hook updates it as you drag.
export const PetalRangeFill = {
  mounted() {
    this.sync = () => {
      const min = parseFloat(this.el.min);
      const max = parseFloat(this.el.max);
      const lo = Number.isNaN(min) ? 0 : min;
      const hi = Number.isNaN(max) ? 100 : max;
      const val = parseFloat(this.el.value);
      const v = Number.isNaN(val) ? lo : val;
      const pct = hi <= lo ? 0 : ((v - lo) / (hi - lo)) * 100;
      this.el.style.setProperty(
        "--pc-range-fill",
        Math.max(0, Math.min(100, pct)) + "%",
      );
    };
    this.el.addEventListener("input", this.sync);
    this.sync();
  },
  updated() {
    if (this.sync) this.sync();
  },
  destroyed() {
    if (this.sync) this.el.removeEventListener("input", this.sync);
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
    this.display.textContent = `${this.prefix}${fmt(min)}${this.suffix} – ${this.prefix}${fmt(max)}${this.suffix}`;
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
          '(e.g. <script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>).',
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
      console.warn(
        "[petal] PetalChart: invalid data-option JSON on #" + this.el.id,
      );
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
    const series = Array.isArray(opt.series)
      ? opt.series
      : opt.series
        ? [opt.series]
        : [];
    const palette = series.some(
      (s) => s.areaStyle && s.areaStyle.color === "petal:fade",
    )
      ? this.palette()
      : null;
    series.forEach((s, i) => {
      if (!(s.areaStyle && s.areaStyle.color === "petal:fade")) return;
      const base =
        this.normalizeColor(
          s.color || (s.itemStyle && s.itemStyle.color) || "",
        ) || palette[i % palette.length];
      const stop = (alphaPct) =>
        base.replace(
          /rgba\(([^)]+),\s*[\d.]+\)/,
          `rgba($1, ${alphaPct / 100})`,
        );
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
    const m =
      /^petal:(number|percent|currency|currency-compact)(?::([A-Za-z]{3}))?$/.exec(
        spec,
      );
    if (!m) return null;
    const wrap = (nf, suffix) => (value) =>
      typeof value === "number" ? nf.format(value) + (suffix || "") : value;
    switch (m[1]) {
      case "number":
        return wrap(
          new Intl.NumberFormat(undefined, {
            notation: "compact",
            maximumFractionDigits: 1,
          }),
        );
      case "percent":
        return wrap(
          new Intl.NumberFormat(undefined, { maximumFractionDigits: 1 }),
          "%",
        );
      case "currency":
        return wrap(
          new Intl.NumberFormat(undefined, {
            style: "currency",
            currency: m[2] || "USD",
            maximumFractionDigits: 0,
          }),
        );
      case "currency-compact":
        return wrap(
          new Intl.NumberFormat(undefined, {
            style: "currency",
            currency: m[2] || "USD",
            notation: "compact",
            maximumFractionDigits: 1,
          }),
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
      if (
        (key === "formatter" || key === "valueFormatter") &&
        typeof value === "string"
      ) {
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
    const candidates = [
      "primary",
      "info",
      "warning",
      "danger",
      "success",
      "secondary",
    ]
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
    return (
      this.palette().join("|") +
      "|" +
      this.resolveColor("var(--color-gray-500)") +
      "|" +
      this.isDark()
    );
  },

  alpha(expression, pct) {
    return this.resolveColor(
      `color-mix(in oklab, ${expression} ${pct}%, transparent)`,
    );
  },

  buildTheme() {
    const dark = this.isDark();
    const gray = (stop) => this.resolveColor(`var(--color-gray-${stop})`);
    const text = dark ? gray(400) : gray(500);
    const strongText = dark ? gray(100) : gray(900);
    const axisLine = dark ? this.alpha("var(--color-gray-400)", 25) : gray(300);
    const splitLine = dark
      ? this.alpha("var(--color-gray-400)", 17)
      : gray(200);
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
      title: {
        textStyle: { color: strongText },
        subtextStyle: { color: text },
      },
      legend: {
        textStyle: { color: text },
        inactiveColor: dark
          ? this.alpha("var(--color-gray-400)", 35)
          : gray(300),
      },
      bar: { itemStyle: { borderRadius: [4, 4, 0, 0] } },
      line: { showSymbol: false, symbolSize: 6 },
      categoryAxis: {
        ...axisStyles,
        splitLine: { show: false, lineStyle: { color: splitLine } },
      },
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
        "[petal] PetalColorScheme: render <.color_scheme_script /> in your layout's <head>.",
      );
      return;
    }
    this.variant = this.el.dataset.variant;
    this.sync = () => this.reflect();
    window.addEventListener("petal:scheme-changed", this.sync);

    if (this.variant === "toggle") {
      this.onClick = () => {
        const next =
          window.PetalColorScheme.resolved() === "dark" ? "light" : "dark";
        window.PetalColorScheme.set(next);
      };
      this.el.addEventListener("click", this.onClick);
    } else if (this.variant === "segmented") {
      this.onChange = (e) => {
        if (e.target instanceof HTMLInputElement)
          window.PetalColorScheme.set(e.target.value);
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
      n.setAttribute(
        "aria-checked",
        n.dataset.scheme === pref ? "true" : "false",
      );
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
    const start = () =>
      this.animate(parseFloat(this.el.dataset.startValue || "0"));
    if ("IntersectionObserver" in window) {
      this.observer = new IntersectionObserver(
        (entries) => {
          if (entries[0].isIntersecting) {
            this.observer.disconnect();
            this.observer = null;
            start();
          }
        },
        { threshold: 0.3 },
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
      (this.el.dataset.prefix || "") +
      fmt.format(value) +
      (this.el.dataset.suffix || "");
  },
};

// Confetti cannon. Zero dependencies — bursts are drawn on a temporary
// full-screen canvas that is removed once every particle has faded.
//
// Fire from the server:  push_event(socket, "pc-confetti", %{id: ..., ...opts})
// Fire from the client:  JS.dispatch("pc:confetti", to: "#my-confetti")
// Options: particle_count, spread, angle, velocity, colors, origin {x, y} (0..1).
export const PetalConfetti = {
  defaultColors: [
    "#26ccff",
    "#a25afd",
    "#ff5e7e",
    "#88ff5a",
    "#fcff42",
    "#ffa62d",
    "#ff36ff",
  ],

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

    const count =
      opts.particle_count ||
      parseInt(this.el.dataset.particleCount || "100", 10);
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
      this.el.style.setProperty(
        "--pc-spotlight-x",
        `${e.clientX - rect.left}px`,
      );
      this.el.style.setProperty(
        "--pc-spotlight-y",
        `${e.clientY - rect.top}px`,
      );
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
      this.timer = setTimeout(
        () => this.erase(i - 1),
        Math.max(this.speed / 2, 15),
      );
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

    const currentlyOpenAccordionItem =
      container.querySelector("[data-open='true']");
    const isClosingClickedAccordionItem =
      clickedAccordionItem.dataset.open === "true";
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
        if (btn)
          btn.classList.remove(
            "pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes",
          );
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
        if (btn)
          btn.classList.add(
            "pc-accordion-item__content-container--highlight-accordion-button-on-expanded-js-attributes",
          );
        if (isLastAccordionItem) {
          const btn2 = item.querySelector(".accordion-button");
          if (btn2) btn2.classList.remove("pc-accordion-item--last--closed");
        }
      }
      setContentDisplay(item, "block");
    }

    // In single mode, close the currently open item (if different from clicked)
    if (
      !isMultiple &&
      currentlyOpenAccordionItem &&
      currentlyOpenAccordionItem !== clickedAccordionItem
    ) {
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
          }),
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
    const clean = this.input.value
      .replace(pattern, "")
      .slice(0, this.slots.length);
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
        focused &&
          i === activeIndex &&
          value.length < this.slots.length + (value[i] ? 0 : 1) &&
          (i === value.length ||
            (i === this.slots.length - 1 &&
              value.length === this.slots.length)),
      );
    });
  },
};

// Number field maths, kept pure and exported so the specs can pin the rules
// without a DOM: parsing, clamping, decimal-safe stepping and blur formatting.
export const numberFieldMath = {
  // "" and "abc" are both "no number yet" - a half-typed field must not
  // resolve to 0, or every keystroke would fight the user.
  parse(text) {
    if (text === null || text === undefined) return null;
    const trimmed = String(text).trim();
    if (trimmed === "") return null;
    const n = Number(trimmed);
    return Number.isFinite(n) ? n : null;
  },

  clamp(n, min, max) {
    if (n === null) return null;
    let out = n;
    if (min !== null && out < min) out = min;
    if (max !== null && out > max) out = max;
    return out;
  },

  decimals(n) {
    const s = String(n);
    const dot = s.indexOf(".");
    if (dot === -1 || s.includes("e") || s.includes("E")) return 0;
    return s.length - dot - 1;
  },

  // 0.1 + 0.2 is 0.30000000000000004 in every browser. Re-round to the
  // decimals the operands actually carry so a 0.1 step reads as 0.3.
  add(value, delta) {
    const places = Math.min(
      Math.max(this.decimals(value), this.decimals(delta)),
      12,
    );
    return Number((value + delta).toFixed(places));
  },

  format(n, precision) {
    if (n === null) return "";
    if (precision === null || precision === undefined) return String(n);
    return n.toFixed(precision);
  },
};

// Number field: one text input carrying role="spinbutton", plus the buttons.
// The hook owns everything the markup can't - stepping, clamping, the keyboard
// map, wheel, hold-to-repeat, and keeping aria-valuenow honest.
export const PetalNumberField = {
  mounted() {
    this.repeatTimer = null;
    // A variant switch swaps which buttons exist, so binding is idempotent
    // and re-runs on every patch rather than assuming mount-time nodes.
    this.bound = new WeakSet();
    this.stopRepeat = () => this.cancelRepeat();
    window.addEventListener("pointerup", this.stopRepeat);
    window.addEventListener("blur", this.stopRepeat);

    this.bind();
    if (this.input) this.syncAria();
  },

  updated() {
    this.bind();
    if (this.input) this.syncAria();
  },

  bind() {
    this.input = this.el.querySelector("[data-pc-number-input]");
    if (!this.input) return;
    this.buttons = Array.from(this.el.querySelectorAll("[data-pc-number-step]"));

    if (!this.bound.has(this.input)) {
      this.bound.add(this.input);
      this.input.addEventListener("keydown", (e) => this.handleKeydown(e));
      // passive: false or preventDefault is ignored and the page scrolls
      // out from under the field.
      this.input.addEventListener("wheel", (e) => this.handleWheel(e), {
        passive: false,
      });
      this.input.addEventListener("blur", () => this.commitTyped());
      this.input.addEventListener("input", () => this.syncAria());
    }

    this.buttons.forEach((btn) => {
      if (this.bound.has(btn)) return;
      this.bound.add(btn);
      btn.addEventListener("pointerdown", (e) => this.startRepeat(e, btn));
      // pointerup alone leaks a stuck repeat when the finger slides off the
      // button before lifting.
      ["pointerup", "pointerleave", "pointercancel"].forEach((type) =>
        btn.addEventListener(type, this.stopRepeat),
      );
    });
  },

  destroyed() {
    this.cancelRepeat();
    if (this.stopRepeat) {
      window.removeEventListener("pointerup", this.stopRepeat);
      window.removeEventListener("blur", this.stopRepeat);
    }
  },

  config() {
    const d = this.el.dataset;
    const step = numberFieldMath.parse(d.step);
    const bigStep = numberFieldMath.parse(d.bigStep);
    const precision = numberFieldMath.parse(d.precision);
    const resolvedStep = step === null ? 1 : step;

    return {
      min: numberFieldMath.parse(d.min),
      max: numberFieldMath.parse(d.max),
      step: resolvedStep,
      bigStep: bigStep === null ? resolvedStep * 10 : bigStep,
      precision: precision === null ? null : Math.trunc(precision),
    };
  },

  currentValue() {
    return numberFieldMath.parse(this.input.value);
  },

  // An empty field starts from the lower bound when there is one, so the
  // first press on a 1..99 quantity lands on 1, not 0.
  origin(cfg) {
    if (cfg.min !== null) return cfg.min;
    if (cfg.max !== null && cfg.max < 0) return cfg.max;
    return 0;
  },

  step(delta) {
    if (this.input.disabled || this.input.readOnly) return;
    const cfg = this.config();
    const current = this.currentValue();
    const base = current === null ? this.origin(cfg) - delta : current;
    const next = numberFieldMath.clamp(
      numberFieldMath.add(base, delta),
      cfg.min,
      cfg.max,
    );
    this.write(next, cfg.precision);
  },

  // Returns whether it mutated the value, so callers can avoid firing
  // synthetic events for writes that changed nothing.
  write(value, precision) {
    const text = numberFieldMath.format(value, precision);
    if (text === this.input.value) {
      this.syncAria();
      return false;
    }
    this.input.value = text;
    this.syncAria();
    this.input.dispatchEvent(new Event("input", { bubbles: true }));
    return true;
  },

  // Typed text is left alone until blur: clamping mid-keystroke would snap
  // "1" to the maximum on the way to "15". The synthetic change fires ONLY
  // when the clamp actually rewrote the value - for in-range typed input the
  // browser's own native change already fires on blur, and dispatching a
  // second one doubled every change handler.
  commitTyped() {
    const cfg = this.config();
    const current = this.currentValue();
    if (current === null) {
      this.syncAria();
      return;
    }
    const mutated = this.write(
      numberFieldMath.clamp(current, cfg.min, cfg.max),
      cfg.precision,
    );
    if (mutated) {
      this.input.dispatchEvent(new Event("change", { bubbles: true }));
    }
  },

  handleKeydown(e) {
    // Home/End write() directly, bypassing step()'s guard - and readonly
    // inputs still receive keydown, so without this a readonly value could
    // be rewritten from the keyboard.
    if (this.input.disabled || this.input.readOnly) return;
    const cfg = this.config();
    const big = e.shiftKey ? cfg.bigStep : cfg.step;

    switch (e.key) {
      case "ArrowUp":
        e.preventDefault();
        return this.step(big);
      case "ArrowDown":
        e.preventDefault();
        return this.step(-big);
      case "PageUp":
        e.preventDefault();
        return this.step(cfg.bigStep);
      case "PageDown":
        e.preventDefault();
        return this.step(-cfg.bigStep);
      case "Home":
        if (cfg.min === null) return;
        e.preventDefault();
        return this.write(cfg.min, cfg.precision);
      case "End":
        if (cfg.max === null) return;
        e.preventDefault();
        return this.write(cfg.max, cfg.precision);
      default:
        return undefined;
    }
  },

  // Only while focused, so a scroll down the page never rewrites a number
  // the pointer happened to pass over.
  handleWheel(e) {
    if (document.activeElement !== this.input) return;
    if (this.input.disabled || this.input.readOnly) return;
    if (e.deltaY === 0) return;
    e.preventDefault();
    const cfg = this.config();
    this.step(e.deltaY < 0 ? cfg.step : -cfg.step);
  },

  startRepeat(e, btn) {
    if (e.button !== undefined && e.button !== 0) return;
    if (btn.disabled || btn.getAttribute("aria-disabled") === "true") return;
    // Mirror step()'s guard: a hold on a readonly control otherwise focuses
    // the input and schedules a repeat timer that no-ops every tick.
    if (this.input.disabled || this.input.readOnly) return;
    e.preventDefault();
    this.input.focus();

    const cfg = this.config();
    const delta = btn.dataset.pcNumberStep === "inc" ? cfg.step : -cfg.step;
    this.step(delta);

    // A press is one step; a hold accelerates from a deliberate pause down
    // to a fast repeat, the way a native spinner feels.
    let interval = 120;
    const tick = () => {
      if (btn.getAttribute("aria-disabled") === "true") return;
      this.step(delta);
      interval = Math.max(40, interval - 12);
      this.repeatTimer = setTimeout(tick, interval);
    };
    this.repeatTimer = setTimeout(tick, 400);
  },

  cancelRepeat() {
    if (this.repeatTimer) clearTimeout(this.repeatTimer);
    this.repeatTimer = null;
  },

  syncAria() {
    const cfg = this.config();
    const value = this.currentValue();

    if (value === null) this.input.removeAttribute("aria-valuenow");
    else this.input.setAttribute("aria-valuenow", String(value));

    this.buttons.forEach((btn) => {
      const inc = btn.dataset.pcNumberStep === "inc";
      const bound = inc ? cfg.max : cfg.min;
      const atBound =
        value !== null &&
        bound !== null &&
        (inc ? value >= bound : value <= bound);
      if (atBound) btn.setAttribute("aria-disabled", "true");
      else btn.removeAttribute("aria-disabled");
    });
  },
};

// Positions a top-layer popover (<div popover>) next to its trigger.
// The browser handles open/close and light-dismiss via the popover attribute;
// this hook only computes fixed coordinates, flipping to the opposite side
// and clamping to the viewport when space runs out.
// min wins when the panel is taller/wider than the space it has: better
// to overflow the far edge than to push the anchored edge off-screen
const clamp = (value, min, max) => Math.max(min, Math.min(value, max));

export const PetalPopover = {
  mounted() {
    this.open = false;
    this.frame = null;

    // Scroll fires far faster than the screen refreshes, and each pass
    // reads layout then writes it. Coalescing to one pass per frame is
    // what stops the panel juddering behind the scroll.
    this.reposition = () => {
      if (this.frame) return;
      this.frame = requestAnimationFrame(() => {
        this.frame = null;
        this.position();
      });
    };

    // An unpositioned top-layer panel sits at 0,0 (the CSS zeroes the
    // margin that would otherwise centre it), and `toggle` fires as a
    // queued task - late enough for the browser to paint that corner
    // first. `beforetoggle` runs synchronously BEFORE the panel is
    // shown, so hiding it here means the first painted frame is
    // already the positioned one.
    this.onBeforeToggle = (e) => {
      if (e.newState === "open") this.el.style.opacity = "0";
    };

    this.onToggle = (e) => {
      this.open = e.newState === "open";

      if (this.open) {
        this.position();
        this.el.style.opacity = "";
        this.listen("addEventListener");
      } else {
        this.el.style.opacity = "";
        this.listen("removeEventListener");
      }
    };

    this.el.addEventListener("beforetoggle", this.onBeforeToggle);
    this.el.addEventListener("toggle", this.onToggle);

    // A native popovertarget works from first paint, so a fast tap can
    // open a panel before this hook exists - it opens centred (the UA
    // default) and lands here already open. Anchor it now.
    if (this.isOpen()) {
      this.open = true;
      this.position();
      this.listen("addEventListener");
    }
  },

  isOpen() {
    try {
      return this.el.matches(":popover-open");
    } catch {
      return false;
    }
  },

  // A patch merges server attributes onto the panel, which drops the
  // inline top/left this hook owns (the server never renders them) -
  // an open panel would snap to 0,0. Re-assert before the next paint.
  // Open state lives on the hook instance, not the DOM, for the same
  // reason: an attribute stamp would be stripped by that same merge.
  updated() {
    if (this.open) this.position();
  },

  destroyed() {
    if (this.frame) cancelAnimationFrame(this.frame);
    this.el.removeEventListener("beforetoggle", this.onBeforeToggle);
    this.el.removeEventListener("toggle", this.onToggle);
    this.listen("removeEventListener");
  },

  // The visual viewport is its own thing on mobile: opening the
  // keyboard shrinks and offsets it WITHOUT firing window scroll or
  // resize, so a panel anchored on layout-viewport numbers is left
  // behind (off-screen, then adrift once the page does scroll).
  listen(method) {
    window[method]("scroll", this.reposition, true);
    window[method]("resize", this.reposition);
    if (window.visualViewport) {
      window.visualViewport[method]("resize", this.reposition);
      window.visualViewport[method]("scroll", this.reposition);
    }
  },

  // The box the panel must stay inside, in client coordinates: the
  // visible region when a keyboard or pinch-zoom has shrunk it,
  // otherwise the window.
  viewport() {
    const vv = window.visualViewport;

    return vv
      ? {
          top: vv.offsetTop,
          left: vv.offsetLeft,
          width: vv.width,
          height: vv.height,
        }
      : {
          top: 0,
          left: 0,
          width: window.innerWidth,
          height: window.innerHeight,
        };
  },
  position() {
    const trigger = document.querySelector(
      `[popovertarget="${CSS.escape(this.el.id)}"]`,
    );
    if (!trigger) return;

    const gap = 8;
    const pad = 8;

    // margin:0 anchors the panel to our top/left - without it the UA's
    // `inset: 0; margin: auto` centres it, which is the sane look for
    // the split second before this hook mounts
    this.el.style.margin = "0";
    // measure unconstrained: a previous pass may have capped the height
    this.el.style.maxHeight = "";

    const t = trigger.getBoundingClientRect();
    const p = this.el.getBoundingClientRect();
    const vp = this.viewport();
    const [side, align] = (this.el.dataset.placement || "bottom").split("-");

    const space = {
      top: t.top - vp.top,
      bottom: vp.top + vp.height - t.bottom,
      left: t.left - vp.left,
      right: vp.left + vp.width - t.right,
    };

    // Anchored means anchored: a trigger scrolled out of the visible
    // region takes its panel with it rather than stranding it against
    // an edge, on top of whatever chrome lives there.
    const offscreen =
      t.bottom < vp.top ||
      t.top > vp.top + vp.height ||
      t.right < vp.left ||
      t.left > vp.left + vp.width;

    this.el.style.visibility = offscreen ? "hidden" : "";

    let s = side;
    if (
      side === "bottom" &&
      space.bottom < p.height + gap &&
      space.top > space.bottom
    )
      s = "top";
    if (
      side === "top" &&
      space.top < p.height + gap &&
      space.bottom > space.top
    )
      s = "bottom";
    if (
      side === "right" &&
      space.right < p.width + gap &&
      space.left > space.right
    )
      s = "left";
    if (
      side === "left" &&
      space.left < p.width + gap &&
      space.right > space.left
    )
      s = "right";

    let top, left, maxHeight;

    if (s === "top" || s === "bottom") {
      // Cap the panel to the room on its chosen side and let it scroll.
      // Clamping the MAIN axis instead is what tore the panel off its
      // trigger - pinning it to the top of the screen, over the header,
      // over the button that opened it.
      // No minimum, the same call the combobox listbox already makes: a
      // floor taller than the actual room pushes the panel back out of
      // the viewport, which is the thing this cap exists to prevent.
      maxHeight = Math.max(
        (s === "top" ? space.top : space.bottom) - gap - pad,
        0,
      );
      const height = Math.min(p.height, maxHeight);

      top = s === "top" ? t.top - height - gap : t.bottom + gap;

      if (align === "start") left = t.left;
      else if (align === "end") left = t.right - p.width;
      else left = t.left + t.width / 2 - p.width / 2;

      // cross axis only - keeping it on screen sideways never detaches it
      left = clamp(left, vp.left + pad, vp.left + vp.width - p.width - pad);
    } else {
      maxHeight = Math.max(vp.height - 2 * pad, 0);
      const height = Math.min(p.height, maxHeight);

      left = s === "left" ? t.left - p.width - gap : t.right + gap;

      if (align === "start") top = t.top;
      else if (align === "end") top = t.bottom - height;
      else top = t.top + t.height / 2 - height / 2;

      top = clamp(top, vp.top + pad, vp.top + vp.height - height - pad);
    }

    this.el.style.maxHeight = `${Math.round(maxHeight)}px`;
    this.el.style.overflowY = "auto";
    // whole pixels: sub-pixel writes shimmer against a scrolling page
    this.el.style.top = `${Math.round(top)}px`;
    this.el.style.left = `${Math.round(left)}px`;
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
      if (item && !item.hasAttribute("data-disabled") && !item.hidden)
        this.setActive(item, false);
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
    return this.items().filter(
      (i) => !i.hidden && !i.hasAttribute("data-disabled"),
    );
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
    for (const ch of text)
      if (ch === query[qi] && ++qi === query.length) return 1;
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
      const any = Array.from(
        group.querySelectorAll("[data-pc-command-item]"),
      ).some((i) => !i.hidden);
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
    if (
      queryChanged ||
      !active ||
      active.hidden ||
      active.hasAttribute("data-disabled")
    ) {
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
        if (item && !item.hidden && !item.hasAttribute("data-disabled"))
          item.click();
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
      if (
        (e.metaKey || e.ctrlKey) &&
        e.key.toLowerCase() === key.toLowerCase()
      ) {
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
      if (
        item &&
        !item.hasAttribute("data-keep-open") &&
        !item.hasAttribute("data-disabled")
      ) {
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

// Opens the command dialog named in data-dialog. A hook rather than a
// phx-click JS command: hooks mount on dead views (LiveView 1.1+), phx-click
// JS commands only execute inside a LiveView - so the trigger works on
// controller-rendered pages too.
export const PetalCommandTrigger = {
  mounted() {
    this.onClick = () => {
      const dialog = document.getElementById(this.el.dataset.dialog);
      if (dialog) dialog.dispatchEvent(new CustomEvent("pc:command-open"));
    };
    this.el.addEventListener("click", this.onClick);
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
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
    this.items = [...this.el.querySelectorAll(".pc-nav-menu__item")].filter(
      (i) => i.querySelector("[data-pc-nav-panel]"),
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
        this.closeTimer = setTimeout(
          () => this.close(item, trigger),
          this.closeDelay,
        );
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
      const open = this.items.find((i) =>
        i.classList.contains("pc-nav-menu__item--open"),
      );
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
        other
          .querySelector(".pc-nav-menu__trigger")
          ?.setAttribute("aria-expanded", "false");
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
      this.close(item, item.querySelector(".pc-nav-menu__trigger")),
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
        console.warn(
          "[petal] PetalLocalTime: invalid data-options JSON on #" + this.el.id,
        );
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
    return new Intl.DateTimeFormat(cfg.locale, {
      timeZone: cfg.timezone,
      ...opts,
    }).format(date);
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
        this.el.textContent = this.absolute(date, {
          ...cfg,
          format: "datetime",
          options: null,
        });
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
      this.wrapper.querySelectorAll(".pc-carousel__indicator"),
    );
    this.thumbs = Array.from(
      this.wrapper.querySelectorAll("[data-thumb-index]"),
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

    // W3C carousel pattern: autoplay pauses while the pointer is over
    // the carousel and resumes when it leaves
    if (this.autoplay) {
      this.hoverPause = () => this.stopAutoplay();
      this.hoverResume = () => this.startAutoplay();
      this.el.addEventListener("mouseenter", this.hoverPause);
      this.el.addEventListener("mouseleave", this.hoverResume);
    }
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
      this.wrapper.removeEventListener("keydown", this.keyboardHandler);
    }
    if (this.hoverPause) {
      this.el.removeEventListener("mouseenter", this.hoverPause);
      this.el.removeEventListener("mouseleave", this.hoverResume);
    }
    if (this.scrollbarStyle) {
      this.scrollbarStyle.remove();
      this.scrollbarStyle = null;
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
    // clones must not duplicate ids (LiveView warns, and getElementById
    // would resolve to the wrong node)
    clone.removeAttribute("id");
    clone.querySelectorAll("[id]").forEach((n) => n.removeAttribute("id"));
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

    // Hide webkit scrollbar. The id comes from the caller, and an HTML-valid id
    // can still contain characters that are special in a selector (".", ":",
    // digits leading), so escape it - an unescaped one silently produces a rule
    // that never matches and the scrollbar shows. Kept on `this` so destroyed()
    // can remove it instead of leaking a style node per remount.
    this.scrollbarStyle = document.createElement("style");
    this.scrollbarStyle.textContent = `
      #${CSS.escape(this.id)} .pc-carousel__slides::-webkit-scrollbar {
        display: none;
      }
    `;
    document.head.appendChild(this.scrollbarStyle);

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

    this.scrollSlidesTo(scrollPosition, smooth);
  },

  // The single scroll entry point for slide transitions - goto() AND the
  // loop-wrap paths (which scroll into the clone strip and can't go through
  // goto) all funnel here, so the reduced-motion gate can't be bypassed.
  // Instant jumps are already a supported path (loop teleports use them),
  // so reduced motion just routes every scroll through it.
  scrollSlidesTo(scrollPosition, smooth = true) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      smooth = false;
    }

    this.slideWrapper.scrollTo({
      left: this.isVertical ? 0 : scrollPosition,
      top: this.isVertical ? scrollPosition : 0,
      behavior: smooth ? "smooth" : "auto",
    });
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
            scrollPos / (this.slideWidth + this.spaceBtwSlides),
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
              ".pc-carousel__slide",
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
        getComputedStyle(document.documentElement).fontSize,
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
              ".pc-carousel__slide",
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
            ".pc-carousel__slide",
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
      true,
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
    this.wrapper.addEventListener("keydown", this.keyboardHandler);
  },

  startAutoplay() {
    // Respect the OS motion preference: a carousel that moves by itself
    // is exactly what prefers-reduced-motion asks to stop
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return;
    }

    // Clear any existing timer first to prevent duplicates
    this.stopAutoplay();

    // W3C carousel pattern: don't announce auto-advancing slides - a
    // polite region firing every few seconds spams screen readers
    const live = this.el.querySelector("[aria-live]");
    if (live) live.setAttribute("aria-live", "off");

    this.autoplayTimer = setInterval(() => {
      this.nextSlide();
    }, this.autoplayInterval);
  },

  stopAutoplay() {
    if (this.autoplayTimer) {
      clearInterval(this.autoplayTimer);
      this.autoplayTimer = null;
    }

    const live = this.el.querySelector("[aria-live]");
    if (live) live.setAttribute("aria-live", "polite");
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
        this.scrollSlidesTo(scrollPosition);
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
        this.scrollSlidesTo(scrollPosition);
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
    // Navigating to the slide you're already on must be a no-op: in the
    // fade path current and next would be the SAME element, and the
    // sequence ends opacity 1 then 0 - a permanently blank slide. Easily
    // reached by clicking the active thumbnail or indicator dot, or by a
    // single-slide fade carousel wrapping onto itself.
    if (this.isTransitioning || newIndex === this.activeIndex) return;

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
    const indicators = this.wrapper.querySelectorAll(".pc-carousel__indicator");

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

    // Sync thumbnails with the active slide; if focus is on a thumb,
    // it follows the active one so arrow keys read as moving the ring
    this.thumbs.forEach((thumb, index) => {
      thumb.classList.toggle(
        "pc-carousel__thumb--active",
        index === this.activeIndex,
      );
      thumb.setAttribute(
        "aria-current",
        index === this.activeIndex ? "true" : "false",
      );
    });

    if (this.thumbs.includes(document.activeElement)) {
      const activeThumb = this.thumbs[this.activeIndex];
      if (activeThumb) activeThumb.focus({ preventScroll: true });
    }

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
        }),
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
        `#${this.id}-carousel-prev`,
      );
      const nextButton = this.wrapper.querySelector(
        `#${this.id}-carousel-next`,
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

// Toasts: a collapsed stack that expands on hover, per-toast timeout with
// progress, pause on hover, swipe to dismiss, six positions. Server API via
// push_event("petal:toast", ...), window CustomEvent for plain JS, and a
// put_flash bridge. The stack DOM is hook-owned (phx-update="ignore").
// One toast_group owns the page - that is the documented contract, and this
// enforces it. Both delivery paths are GLOBAL: LiveView fans push_event out
// to every mounted hook, and the window CustomEvent reaches all of them. So a
// second group anywhere on the page renders an identical toast directly
// behind the first (a burst of 6 dismisses as 12), which is exactly what a
// page combining a layout group with a self-contained demo group hits.
// First-mounted wins; later groups stay inert for global events. Set
// iteration is insertion-ordered, so destroying the primary promotes the
// next one for free. put_flash is unaffected - each group renders only its
// own data-flash, and only the group given flash={@flash} has any.
const toastGroups = new Set();
const isPrimaryToastGroup = (hook) =>
  toastGroups.values().next().value === hook;

export const PetalToast = {
  mounted() {
    toastGroups.add(this);
    if (!isPrimaryToastGroup(this)) {
      const owner = toastGroups.values().next().value;
      console.warn(
        `[petal_components] More than one <.toast_group> is mounted: ` +
          `#${owner.el.id} and #${this.el.id}. Toasts are global, so a second group ` +
          `would render an identical toast behind every one - #${this.el.id} will ` +
          `ignore server and window toast events. Keep a single group in your layout. ` +
          `(Which group wins is not guaranteed to follow DOM order, so remove the ` +
          `extra rather than relying on this.)`,
      );
    }
    this.stack = document.getElementById(this.el.id + "-stack");
    this.top = (this.el.dataset.position || "bottom-right").startsWith("top");
    this.max = parseInt(this.el.dataset.max) || 3;
    this.defaultDuration = parseInt(this.el.dataset.duration) || 5000;
    this.toasts = []; // newest first
    this.seq = 0;
    this.expanded = false;

    this.handleEvent("petal:toast", (d) => {
      if (!isPrimaryToastGroup(this)) return;
      this.upsert(d || {});
    });
    this.handleEvent("petal:toast-dismiss", (d) => {
      if (!isPrimaryToastGroup(this)) return;
      if (d && d.all) [...this.toasts].forEach((t) => this.dismiss(t));
      else if (d && d.id != null) {
        const t = this.toasts.find((t) => t.id === String(d.id));
        if (t) this.dismiss(t);
      }
    });
    this.onWindowToast = (e) => {
      if (!isPrimaryToastGroup(this)) return;
      this.upsert(e.detail || {});
    };
    window.addEventListener("petal:toast", this.onWindowToast);

    // hover expands the stack and pauses every timer; a short grace on
    // leave stops flicker when the pointer crosses the gaps between toasts.
    // MOUSE ONLY: touch taps synthesize a compatibility mouseenter but never
    // the matching mouseleave (the emulated pointer only moves on the next
    // tap), so listening to mouse events latched the stack into its paused
    // state the first time a finger tapped inside it - after dismissing via
    // the X, every later toast mounted unarmed with its progress frozen at
    // 100%. pointerenter carries pointerType, mouseenter doesn't. Touch
    // pauses via press-and-hold in the swipe handlers below instead.
    this.onEnter = (e) => {
      if (e.pointerType !== "mouse") return;
      clearTimeout(this.collapseTimer);
      if (!this.expanded) {
        this.expanded = true;
        this.pauseAll();
        this.layout();
      }
    };
    this.onLeave = (e) => {
      if (e.pointerType !== "mouse") return;
      clearTimeout(this.collapseTimer);
      this.collapseTimer = setTimeout(() => {
        // Never resume mid-gesture: a drag that strays outside the stack
        // must not re-arm a nearly-expired toast under the pointer. (With
        // pointer capture the leave never fires mid-drag anyway; this
        // covers the no-capture fallback.) Release handles the collapse
        // when it ends outside the stack; a leave arriving after that is
        // a no-op via the expanded check.
        if (this.dragging || !this.expanded) return;
        this.expanded = false;
        this.resumeAll();
        this.layout();
      }, 150);
    };
    this.stack.addEventListener("pointerenter", this.onEnter);
    this.stack.addEventListener("pointerleave", this.onLeave);

    // action + close buttons (event delegation - the DOM is hook-built)
    this.onClick = (e) => {
      const closeBtn = e.target.closest("[data-toast-close]");
      const actionBtn = e.target.closest("[data-toast-action]");
      const toastEl = e.target.closest(".pc-toast");
      if (!toastEl) return;
      const t = this.toasts.find((t) => t.el === toastEl);
      if (!t) return;

      if (closeBtn) this.dismiss(t);

      if (actionBtn) {
        const event = actionBtn.dataset.toastAction;
        let value = {};
        try {
          value = JSON.parse(actionBtn.dataset.toastValue || "{}");
        } catch (_e) {}
        if (event) this.pushEvent(event, value);
        this.dismiss(t);
      }
    };
    this.stack.addEventListener("click", this.onClick);

    this.setupSwipe();
    this.processFlash();
  },

  updated() {
    // position can change via a normal patch (the stack itself is ignored)
    this.top = (this.el.dataset.position || "bottom-right").startsWith("top");
    this.layout();
    this.processFlash();
  },

  destroyed() {
    toastGroups.delete(this);
    window.removeEventListener("petal:toast", this.onWindowToast);
    // gesture-scoped listeners, in case a drag was live at teardown
    window.removeEventListener("pointermove", this.onPointerMove);
    window.removeEventListener("pointerup", this.onPointerUp);
    window.removeEventListener("pointercancel", this.onPointerUp);
    clearTimeout(this.collapseTimer);
    this.toasts.forEach((t) => clearTimeout(t.timer));
  },

  // ------------------------------------------------------------------ flash
  processFlash() {
    let flash = {};
    try {
      flash = JSON.parse(this.el.dataset.flash || "{}");
    } catch (_e) {}
    Object.keys(flash).forEach((key) => {
      const msg = flash[key];
      if (!msg) return;
      const kind = key === "error" ? "danger" : key === "info" ? "info" : key;
      this.upsert({ kind, title: msg });
      this.pushEvent("lv:clear-flash", { key });
    });
  },

  // ---------------------------------------------------------------- content
  esc(s) {
    return String(s == null ? "" : s).replace(
      /[&<>"']/g,
      (c) =>
        ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#39;",
        })[c],
    );
  },

  iconFor(kind) {
    const map = {
      info: ["hero-information-circle-solid", "pc-toast__icon--info"],
      success: ["hero-check-circle-solid", "pc-toast__icon--success"],
      warning: ["hero-exclamation-triangle-solid", "pc-toast__icon--warning"],
      danger: ["hero-exclamation-circle-solid", "pc-toast__icon--danger"],
    };
    if (kind === "loading")
      return '<span class="pc-toast__spinner" aria-hidden="true"></span>';
    if (!map[kind]) return "";
    const [icon, color] = map[kind];
    return (
      '<span class="pc-toast__icon ' +
      icon +
      " " +
      color +
      '" aria-hidden="true"></span>'
    );
  },

  contentFor(t) {
    const action = t.action
      ? '<button type="button" class="pc-toast__action" data-toast-action="' +
        this.esc(t.action.event || "") +
        "\" data-toast-value='" +
        this.esc(JSON.stringify(t.action.value || {})) +
        "'>" +
        this.esc(t.action.label) +
        "</button>"
      : "";
    const close = t.closeable
      ? '<button type="button" class="pc-toast__close" data-toast-close aria-label="Dismiss">' +
        '<span class="hero-x-mark pc-toast__close-icon" aria-hidden="true"></span></button>'
      : "";
    const desc = t.description
      ? '<p class="pc-toast__description">' + this.esc(t.description) + "</p>"
      : "";
    const progress =
      t.duration > 0 && t.progress
        ? '<div class="pc-toast__progress pc-toast__progress--' +
          this.esc(t.kind) +
          '" style="animation-duration: ' +
          t.duration +
          'ms"></div>'
        : "";

    return (
      '<div class="pc-toast__body">' +
      this.iconFor(t.kind) +
      '<div class="pc-toast__text">' +
      '<div class="pc-toast__title">' +
      this.esc(t.title) +
      "</div>" +
      desc +
      "</div>" +
      action +
      close +
      "</div>" +
      progress
    );
  },

  // ----------------------------------------------------------------- upsert
  upsert(d) {
    const id = d.id != null ? String(d.id) : "pc-toast-" + ++this.seq;
    const kind = d.kind || "neutral";
    const duration =
      d.duration != null
        ? d.duration
        : kind === "loading"
          ? 0
          : this.defaultDuration;

    let t = this.toasts.find((t) => t.id === id);

    if (t) {
      clearTimeout(t.timer);
      Object.assign(t, {
        kind,
        title: d.title != null ? d.title : t.title,
        description: d.description,
        action: d.action,
        duration,
        remaining: duration,
        closeable: d.closeable !== false,
        progress: d.progress !== false,
      });
      t.el.className = "pc-toast pc-toast--" + kind;
      t.el.setAttribute("role", kind === "danger" ? "alert" : "status");
      t.el.innerHTML = this.contentFor(t);
    } else {
      t = {
        id,
        kind,
        title: d.title,
        description: d.description,
        action: d.action,
        duration,
        remaining: duration,
        closeable: d.closeable !== false,
        progress: d.progress !== false,
        el: document.createElement("div"),
      };
      t.el.className = "pc-toast pc-toast--" + kind;
      t.el.setAttribute("role", kind === "danger" ? "alert" : "status");
      t.el.dataset.state = "entering";
      t.el.innerHTML = this.contentFor(t);
      this.stack.appendChild(t.el);
      this.toasts.unshift(t);
      requestAnimationFrame(() =>
        requestAnimationFrame(() => {
          t.el.dataset.state = "open";
        }),
      );
    }

    if (this.toasts.length > 40) {
      const drop = this.toasts.pop();
      clearTimeout(drop.timer);
      drop.el.remove();
    }

    this.layout();
    if (!this.expanded) this.arm(t);
    return t;
  },

  dismiss(t, dx) {
    if (t.closing) return;
    t.closing = true;
    clearTimeout(t.timer);
    this.el.dispatchEvent(
      new CustomEvent("petal:toast-dismissed", {
        detail: { id: t.id, kind: t.kind },
        bubbles: true,
      }),
    );
    t.el.dataset.state = "closing";
    if (dx) t.el.style.setProperty("--pc-toast-swipe-end", dx + "px");
    const remove = () => {
      t.el.remove();
      this.toasts = this.toasts.filter((x) => x !== t);
      this.layout();
    };
    t.el.addEventListener("transitionend", remove, { once: true });
    setTimeout(remove, 400); // safety if transitions are off (reduced motion)
  },

  // ----------------------------------------------------------------- layout
  layout() {
    const dir = this.top ? 1 : -1;
    const gap = 12;
    let offset = 0;

    this.toasts.forEach((t, i) => {
      if (t.closing) return;
      const el = t.el;
      el.style.zIndex = String(200 - i);

      const hidden = i >= this.max;
      el.classList.toggle("pc-toast--hidden", hidden);
      el.setAttribute("aria-hidden", hidden ? "true" : "false");

      if (this.expanded) {
        el.style.setProperty("--pc-toast-y", dir * offset + "px");
        el.style.setProperty("--pc-toast-scale", "1");
        if (!hidden) offset += el.offsetHeight + gap;
      } else {
        el.style.setProperty("--pc-toast-y", dir * i * 12 + "px");
        el.style.setProperty(
          "--pc-toast-scale",
          String(Math.max(0, 1 - i * 0.06)),
        );
      }
    });

    this.stack.classList.toggle(
      "pc-toast-group__stack--expanded",
      this.expanded,
    );
  },

  // ----------------------------------------------------------------- timers
  arm(t) {
    clearTimeout(t.timer);
    if (!t.duration || t.remaining <= 0) return;
    t.startedAt = Date.now();
    t.timer = setTimeout(() => this.dismiss(t), t.remaining);
  },

  pauseAll() {
    this.toasts.forEach((t) => {
      if (!t.timer) return;
      clearTimeout(t.timer);
      t.timer = null;
      t.remaining -= Date.now() - t.startedAt;
    });
    this.stack.classList.add("pc-toast-group__stack--paused");
  },

  resumeAll() {
    this.stack.classList.remove("pc-toast-group__stack--paused");
    this.toasts.forEach((t) => {
      if (t.duration && t.remaining > 0 && !t.closing) this.arm(t);
    });
  },

  // ------------------------------------------------------------------ swipe
  setupSwipe() {
    // One gesture at a time, keyed by pointerId: a second finger neither
    // steals the drag state nor ends the first finger's hold - without the
    // id check, finger A lifting would compute its dx against finger B's
    // start and could fake-swipe B's toast away.
    let active = null;
    let activeId = null;
    let startX = 0;
    this.dragging = false;

    this.onPointerDown = (e) => {
      if (active) return;
      const toastEl = e.target.closest(".pc-toast");
      if (!toastEl || e.target.closest("button")) return;
      const t = this.toasts.find((t) => t.el === toastEl);
      if (!t || t.closing) return;
      active = t;
      activeId = e.pointerId;
      startX = e.clientX;
      // Press-and-hold pauses the timers - the touch counterpart of
      // hover-to-pause (and on any pointer it stops a mid-drag expiry
      // yanking the toast out from under the gesture). The hover machinery
      // reads this so a leave-grace firing mid-drag can't resume timers
      // (pointer capture already suppresses that in browsers; this keeps
      // the no-capture fallback honest too).
      this.dragging = true;
      this.pauseAll();
      toastEl.classList.add("pc-toast--swiping");
      // Gesture-scoped WINDOW listeners: a release outside the stack still
      // ends the gesture. Stack-scoped up/move relied on pointer capture
      // retargeting - fine in browsers, but in the no-capture fallback a
      // drag released outside the stack would never see its pointerup and
      // every timer stayed paused indefinitely. Attached BEFORE the capture
      // attempt: setPointerCapture throws on an already-inactive pointerId
      // (and under synthetic events), and a throw here must not leave an
      // armed gesture with no way to end.
      window.addEventListener("pointermove", this.onPointerMove);
      window.addEventListener("pointerup", this.onPointerUp);
      window.addEventListener("pointercancel", this.onPointerUp);
      try {
        toastEl.setPointerCapture && toastEl.setPointerCapture(e.pointerId);
      } catch (_e) {
        // capture is an optimisation (retargets moves during fast drags);
        // the window listeners above are the correctness path
      }
    };

    this.onPointerMove = (e) => {
      if (!active || e.pointerId !== activeId) return;
      const dx = e.clientX - startX;
      active.el.style.setProperty("--pc-toast-swipe", dx + "px");
      active.el.style.opacity = String(Math.max(0.3, 1 - Math.abs(dx) / 260));
    };

    this.onPointerUp = (e) => {
      if (!active || e.pointerId !== activeId) return;
      const dx = e.clientX - startX;
      active.el.classList.remove("pc-toast--swiping");
      if (Math.abs(dx) > 64) {
        this.dismiss(active, dx > 0 ? 320 : -320);
      } else {
        active.el.style.setProperty("--pc-toast-swipe", "0px");
        active.el.style.opacity = "";
      }
      active = null;
      activeId = null;
      this.dragging = false;
      window.removeEventListener("pointermove", this.onPointerMove);
      window.removeEventListener("pointerup", this.onPointerUp);
      window.removeEventListener("pointercancel", this.onPointerUp);
      // Release resumes - unless a mouse hover still holds the stack open.
      if (!this.expanded) {
        this.resumeAll();
        return;
      }
      // Hover held it open, but the pointer may have ended OUTSIDE the
      // stack - the matching pointerleave either fired mid-drag (consumed
      // by the dragging guard, no-capture path) or fires on capture
      // release. Don't depend on it: collapse here when outside. The
      // idempotent grace callback makes a double collapse harmless.
      const r = this.stack.getBoundingClientRect();
      const inside =
        e.clientX >= r.left &&
        e.clientX <= r.right &&
        e.clientY >= r.top &&
        e.clientY <= r.bottom;
      if (!inside) {
        this.expanded = false;
        this.resumeAll();
        this.layout();
      }
    };

    this.stack.addEventListener("pointerdown", this.onPointerDown);
  },
};

// Combo box: the command palette's filter + keyboard core wired to a real
// hidden <select>. The select IS the form control - choosing an option sets
// its value and dispatches bubbling input/change events, so phx-change and
// LiveView form recovery behave exactly like a native select. Options are
// hidden, never reordered - the server owns DOM order. aria-selected tracks
// the CHOSEN option (the check mark); the keyboard highlight is virtual:
// data-highlighted + aria-activedescendant.
// Same selection, any order: server-rendered rich content follows chosen
// order while the hook reads DOM option order - freshness compares
// MULTISETS (duplicate values are counted, never flattened), never
// sequences.
function sameValueMultiset(a, b) {
  if (a.length !== b.length) return false;
  const counts = new Map();
  for (const v of a) counts.set(v, (counts.get(v) || 0) + 1);
  for (const v of b) {
    const n = counts.get(v);
    if (!n) return false;
    counts.set(v, n - 1);
  }
  return true;
}

// Slot content the panel must let the pointer focus - everything else in
// there is chrome whose press has to keep focus in the search input.
// [tabindex] covers hand-rolled widgets; the option rows have none.
const FOCUSABLE_IN_PANEL = "input, select, textarea, button, [tabindex]";

export const PetalComboBox = {
  mounted() {
    this.select = this.el.querySelector(".pc-combo-box__select");
    this.input = this.el.querySelector(".pc-combo-box__input");
    this.control = this.el.querySelector(".pc-combo-box__control");
    this.trigger = this.el.querySelector("[data-pc-combo-trigger]");
    this.triggerLabel = this.el.querySelector("[data-pc-combo-trigger-label]");
    this.panel = this.el.querySelector("[data-pc-combo-panel]");
    this.list = this.el.querySelector(".pc-combo-box__list");
    if (!this.select || !this.input || !this.panel || !this.list) return;

    this.multiple = this.select.multiple;
    this.chips = this.el.querySelector("[data-pc-combo-chips]");
    this.freeText = this.el.hasAttribute("data-free-text");
    this.remoteEvent = this.el.dataset.remoteEvent || null;
    this.remoteTarget = this.el.dataset.remoteTarget || null;
    this.loadingRow = this.el.querySelector("[data-pc-combo-loading]");
    this.remoteSeq = 0;
    this.createRow = this.el.querySelector("[data-pc-combo-create]");
    if (this.createRow) {
      this.createRow.id = `${this.el.id}-create`;
      this.createQueryEl = this.createRow.querySelector(
        "[data-pc-combo-create-query]",
      );
    }
    this.live = this.el.querySelector("[data-pc-combo-live]");
    this.errorEl = this.el.querySelector("[data-pc-combo-error]");
    this.query = "";

    this.onInput = (e) => {
      // The display input is chrome, not data: keep its keystrokes inside the
      // component. Without this every character reaches an enclosing form's
      // phx-change - a round trip per keystroke, validation running against
      // the not-yet-chosen value, and a patch that can wipe the query
      // mid-type. The select's own input/change events (dispatched in
      // choose) still bubble, which is how the server learns the value.
      e.stopPropagation();
      this.query = this.input.value.trim().toLowerCase();
      if (this.panel.hidden) this.openPanel({ keepQuery: true });
      if (this.remoteEvent) {
        // every keystroke invalidates in-flight replies immediately - a
        // reply landing inside the NEXT search's debounce window must
        // never render against the newer query
        this.remoteSeq++;
        clearTimeout(this.remoteTimer);
        this.remoteTimer = setTimeout(() => this.remoteSearch(), 300);
      }
      this.filter();
    };
    this.onKeydown = (e) => this.keydown(e);
    this.onPointerOver = (e) => {
      if (this.createRow && e.target.closest("[data-pc-combo-create]")) {
        if (!this.createRow.hidden) this.highlight(this.createRow, false);
        return;
      }
      const item = e.target.closest("[data-pc-combo-item]");
      if (item && !item.hasAttribute("data-disabled") && !item.hidden)
        this.highlight(item, false);
    };
    this.onListClick = (e) => {
      if (this.createRow && e.target.closest("[data-pc-combo-create]")) {
        if (!this.createRow.hidden) this.commitFreeText();
        return;
      }
      const item = e.target.closest("[data-pc-combo-item]");
      if (item && !item.hasAttribute("data-disabled")) this.choose(item);
    };
    // keep focus on the input while clicking inside the panel, or the
    // focusout close would swallow the click before it lands; the search
    // input (trigger variant) must stay clickable for caret work
    this.onPanelPointerDown = (e) => {
      if (e.target === this.input) return;
      // ...but a focusable control in a :header / :footer slot needs the
      // press to do its normal job: preventDefault here is what made a
      // text field or select in a slot impossible to focus by pointer.
      // The panel survives the focus move because onFocusOut only closes
      // when focus lands OUTSIDE the component.
      if (e.target.closest && e.target.closest(FOCUSABLE_IN_PANEL)) return;
      e.preventDefault();
    };
    // Chrome-vs-caret is decided at POINTERDOWN, not click: pointer events
    // hit-test the real touch point, while iOS tap-target correction
    // rewrites the synthesized click's target AND coordinates (snapping
    // both onto the nearby text field), so the click is unreliable
    // evidence of where the finger landed. preventDefault on chrome
    // presses keeps focus in the input - on desktop the blur would fire
    // focusout, close the panel mid-press, and the click would then
    // REOPEN it (the flash). Same pattern onPanelPointerDown proves.
    // Each pointer carries its OWN chrome-vs-caret verdict, so
    // interleaved fingers in any press/release order can never consume
    // one another's record - the click claims its pointer's verdict.
    this.onControlPointerDown = (e) => {
      if (this.input.disabled) return;
      // any fresh press ends close-suppression: a legitimate rapid
      // follow-up tap has its own pointerdown, a trailing same-gesture
      // click does not - the exact discriminator, no time window needed
      this.suppressOpenAt = -Infinity;
      const chrome = e.target !== this.input;
      this.pressVerdicts.set(e.pointerId, { chrome, at: performance.now() });
      if (chrome) e.preventDefault();
    };
    // Abandoned records must not linger to poison a later synthetic
    // caret click: a cancel or an off-control release deletes at once.
    // An on-control release leaves the record for its click - which iOS
    // Safari may synthesize LATER than any queued task, so there is no
    // timer sweep; leftovers age out at click time instead (see below).
    this.onPressSettle = (e) => {
      if (e.type === "pointercancel" || !this.control?.contains(e.target)) {
        this.pressVerdicts.delete(e.pointerId);
      }
    };
    this.onControlClick = (e) => {
      if (this.input.disabled) return;
      // the click claims its own pointer's verdict (clicks are
      // PointerEvents in modern browsers); a click without a usable
      // pointerId takes the sole surviving verdict, a click with NO
      // verdicts (synthetic - tests, assistive tech) falls back to its
      // own target, and genuine multi-pointer ambiguity degrades to
      // caret-safe (never close on a guess)
      // verdicts older than a second are leftovers from presses whose
      // click never arrived - drop them before deciding (timer-free, so
      // no race with Safari's late click synthesis)
      const now = performance.now();
      for (const [id, v] of this.pressVerdicts) {
        if (now - v.at > 1000) this.pressVerdicts.delete(id);
      }

      let chrome;
      if (this.pressVerdicts.has(e.pointerId)) {
        chrome = this.pressVerdicts.get(e.pointerId).chrome;
        this.pressVerdicts.delete(e.pointerId);
      } else if (this.pressVerdicts.size === 1) {
        chrome = this.pressVerdicts.values().next().value.chrome;
        this.pressVerdicts.clear();
      } else if (this.pressVerdicts.size === 0) {
        chrome = e.target !== this.input;
      } else {
        chrome = false;
        this.pressVerdicts.clear();
      }
      if (e.target.closest("[data-pc-combo-chip-remove]")) {
        const value = e.target.closest("[data-pc-combo-chip-remove]").dataset
          .value;
        this.setSelected(value, false);
        this.input.focus();
        return;
      }
      if (this.panel.hidden) {
        // a deliberate chrome close wins its own gesture: trailing
        // clicks from OTHER fingers of the same burst arrive WITHOUT a
        // fresh pointerdown (which clears the suppression) and must not
        // reopen. The 1s age cap frees clicks with no pointer sequence
        // at all (assistive tech) from a long-stale suppression.
        if (now - this.suppressOpenAt < 1000) return;
        this.openPanel();
        this.input.focus();
      } else if (chrome) {
        // chevron / control chrome toggles; a press on the input itself
        // is caret work - closing would discard the active query
        this.closePanel();
        this.input.focus();
        this.suppressOpenAt = now;
      }
    };
    // the clear button is bound directly so both anatomies share one
    // path: inside the input variant's control, and as the trigger
    // variant's sibling over the right rail. stopPropagation keeps the
    // clear from reading as a control/trigger toggle.
    this.onClearClick = (e) => {
      e.stopPropagation();
      // the select carries the disabled state in both anatomies, so it is
      // the one honest check - a disabled widget must not ship a working
      // control, and a cleared-but-disabled select posts nothing, which
      // would desync the server from what the user sees
      if (this.select.disabled) return;
      this.select.value = "";
      this.dispatchChange();
      this.syncFromSelect();
      if (this.trigger) {
        // the trigger variant's search input lives INSIDE the panel, so
        // clearing with it open parked focus on the trigger - outside the
        // panel, with nothing driving it: arrows dead, and Escape read as
        // "panel already closed" and leaked to the enclosing modal. Close
        // it; focus belongs on the trigger either way.
        this.closePanel();
        this.trigger.focus();
      } else {
        this.input.focus();
      }
    };
    // The hidden select is the form control, but it is inert and off
    // screen: the browser can neither draw its validation bubble nor move
    // focus to it, so a failed submit was silent - blocked, unexplained,
    // focus on <body>. Take the report over. preventDefault only drops the
    // (undrawable) native UI; the submit stays blocked, as required means.
    this.onSelectInvalid = (e) => {
      e.preventDefault();
      this.showError(this.select.validationMessage);
      (this.trigger || this.input).focus();
    };
    this.onFocusOut = (e) => {
      // iOS Safari reports relatedTarget as null even when focus moves
      // WITHIN the component (tapping the trigger button while the panel
      // search has focus) - trusting it closed the panel mid-tap and the
      // button's click then reopened it, an endless flash. Verify where
      // focus actually landed once it settles; closing a tick later is
      // imperceptible on the genuine Tab-away/click-away paths.
      if (this.el.contains(e.relatedTarget)) return;
      clearTimeout(this.focusOutTimer);
      this.focusOutTimer = setTimeout(() => {
        if (!this.el.contains(document.activeElement)) this.closePanel();
      }, 0);
    };
    // trigger variant: the button opens the panel and focus moves to the
    // search input inside it; ArrowDown/Up on the button open too
    this.onTriggerClick = () => {
      if (this.trigger.disabled) return;
      if (this.panel.hidden) {
        this.openPanel();
        this.input.focus();
      } else {
        this.closePanel();
      }
    };
    this.onTriggerKeydown = (e) => {
      if (e.key !== "ArrowDown" && e.key !== "ArrowUp") return;
      e.preventDefault();
      if (this.panel.hidden) {
        this.openPanel();
        this.input.focus();
      }
    };
    // focusout covers Tab-away and desktop clicks (desktop blurs the input
    // when you click static content), but iOS Safari deliberately keeps
    // focus when tapping non-interactive content - no blur, no focusout, a
    // panel that would not close. Outside-press detection is the standard
    // answer; bound only while the panel is open. The dismiss is a
    // completed PRESS, not a touch-start: closing on pointerdown would
    // kill the panel the instant a scroll gesture lands outside it, so
    // the decision waits for pointerup - a scroll ends in pointercancel
    // (or a far-away pointerup on pages that cannot scroll), a tap ends
    // in a pointerup where it started.
    // The press record is scoped to its pointerId: only the arming
    // finger's release can complete the dismiss, and a second finger
    // landing mid-press disarms it - multi-touch is a gesture (pinch,
    // two-finger scroll), never a deliberate dismiss tap.
    this.onOutsidePointerDown = (e) => {
      // A press that never gets its pointerup or pointercancel - a
      // right-click handing the release to the context menu, a pointer
      // lost to a system gesture - would sit in here forever and read as
      // "a second finger is down" on every later press, disarming
      // outside-tap dismissal for the rest of the open session. Age
      // leftovers out at press time, the way the press verdicts do.
      const now = performance.now();
      for (const [id, at] of this.activePointers) {
        if (now - at > 1000) this.activePointers.delete(id);
      }
      this.activePointers.set(e.pointerId, now);
      if (this.activePointers.size > 1) {
        this.outsidePress = null;
        return;
      }
      this.outsidePress = this.el.contains(e.target)
        ? null
        : { id: e.pointerId, x: e.clientX, y: e.clientY };
    };
    this.onOutsidePointerUp = (e) => {
      this.activePointers.delete(e.pointerId);
      const press = this.outsidePress;
      if (!press || e.pointerId !== press.id) return;
      this.outsidePress = null;
      if (Math.hypot(e.clientX - press.x, e.clientY - press.y) > 10) return;
      if (!this.el.contains(e.target)) this.closePanel();
    };
    this.onOutsidePointerCancel = (e) => {
      this.activePointers.delete(e.pointerId);
      if (this.outsidePress && e.pointerId === this.outsidePress.id) {
        this.outsidePress = null;
      }
    };
    // form.reset() resets the select; nothing else would re-sync the chrome
    this.onFormReset = () => {
      clearTimeout(this.resetTimer);
      this.resetTimer = setTimeout(() => {
        this.clearError();
        this.syncFromSelect();
      }, 0);
    };
    this.onReposition = () => this.positionPanel();

    this.input.addEventListener("input", this.onInput);
    this.input.addEventListener("keydown", this.onKeydown);
    this.list.addEventListener("pointerover", this.onPointerOver);
    this.list.addEventListener("click", this.onListClick);
    this.panel.addEventListener("pointerdown", this.onPanelPointerDown);
    this.clearButton = null;
    this.bindClearButton();
    this.select.addEventListener("invalid", this.onSelectInvalid);
    this.pressVerdicts = new Map();
    this.suppressOpenAt = -Infinity;
    if (this.control) {
      this.control.addEventListener("pointerdown", this.onControlPointerDown);
      this.control.addEventListener("click", this.onControlClick);
      // click fires between pointerup and any queued task, so consuming
      // in onControlClick wins the race; these only catch abandonment
      document.addEventListener("pointerup", this.onPressSettle);
      document.addEventListener("pointercancel", this.onPressSettle);
    }
    if (this.trigger) {
      this.trigger.addEventListener("click", this.onTriggerClick);
      this.trigger.addEventListener("keydown", this.onTriggerKeydown);
    }
    this.el.addEventListener("focusout", this.onFocusOut);
    this.form = this.select.form;
    if (this.form) this.form.addEventListener("reset", this.onFormReset);
    this.syncFromSelect();
    // everything from here is a real state CHANGE, so it can be announced
    this.announceReady = true;
  },

  updated() {
    // mode configuration and conditionally-rendered rows are server
    // truth and can change on any patch - re-read them, and a CHANGED
    // remote event/target invalidates the previous configuration's
    // in-flight work so obsolete results can never land
    const prevEvent = this.remoteEvent;
    const prevTarget = this.remoteTarget;
    this.freeText = this.el.hasAttribute("data-free-text");
    this.multiple = this.select.multiple;
    this.chips = this.el.querySelector("[data-pc-combo-chips]");
    this.errorEl = this.el.querySelector("[data-pc-combo-error]");
    // clearable={@editing} / multiple={@mode == :many} are ordinary server
    // state: a clear button that appeared on this patch has no listener
    // until we bind it, and a chips container we never re-read stays null
    // so no chip ever renders
    this.bindClearButton();
    this.remoteEvent = this.el.dataset.remoteEvent || null;
    this.remoteTarget = this.el.dataset.remoteTarget || null;
    if (this.remoteEvent !== prevEvent || this.remoteTarget !== prevTarget) {
      this.remoteSeq++;
      clearTimeout(this.remoteTimer);
      if (this.loadingRow) this.loadingRow.hidden = true;
    }
    this.loadingRow = this.el.querySelector("[data-pc-combo-loading]");
    this.createRow = this.el.querySelector("[data-pc-combo-create]");
    if (this.createRow) {
      this.createRow.id = `${this.el.id}-create`;
      this.createQueryEl = this.createRow.querySelector(
        "[data-pc-combo-create-query]",
      );
    } else {
      this.createQueryEl = null;
    }
    // LiveView patched the component - the select (server state) wins
    // for SELECTION, but open-state belongs to the client: the server
    // always renders the panel hidden, so a phx-change round-trip would
    // otherwise slam the panel shut mid-multi-pick (Nic's find - reui
    // and every peer keep it open). Re-assert and re-measure.
    if (this.isOpen && this.panel.hidden) {
      this.panel.hidden = false;
      this.input.setAttribute("aria-expanded", "true");
      if (this.trigger) this.trigger.setAttribute("aria-expanded", "true");
      this.positionPanel();
    }
    // the highlight is client state too: the patch re-renders options
    // without data-highlighted, and filter() would re-home on the first
    // item (visible on iOS, masked by hover re-highlighting on desktop)
    const keepHighlight = this.highlightedValue;
    this.syncFromSelect();
    if (!this.panel.hidden) {
      this.filter();
      if (keepHighlight) {
        const item = this.visibleItems().find(
          (i) => i.dataset.value === keepHighlight,
        );
        if (item) this.highlight(item, false);
      }
    }
  },

  // the clear button is conditionally rendered, so binding is not a
  // one-shot: rebind whenever the node identity changes (a patch that
  // added, removed or replaced it), never twice on the same node
  bindClearButton() {
    const next = this.el.querySelector("[data-pc-combo-clear]");
    if (next === this.clearButton) return;
    if (this.clearButton) {
      this.clearButton.removeEventListener("click", this.onClearClick);
    }
    this.clearButton = next;
    if (this.clearButton) {
      this.clearButton.addEventListener("click", this.onClearClick);
    }
  },

  destroyed() {
    // mounted() bails on half-mounted markup without binding anything, so
    // teardown bails on exactly the same shape - dereferencing this.list
    // here threw, and the throw left the document listeners attached
    if (!this.select || !this.input || !this.panel || !this.list) return;
    this.input.removeEventListener("input", this.onInput);
    this.input.removeEventListener("keydown", this.onKeydown);
    this.list.removeEventListener("pointerover", this.onPointerOver);
    this.list.removeEventListener("click", this.onListClick);
    this.panel.removeEventListener("pointerdown", this.onPanelPointerDown);
    this.select.removeEventListener("invalid", this.onSelectInvalid);
    if (this.control) {
      this.control.removeEventListener(
        "pointerdown",
        this.onControlPointerDown,
      );
      this.control.removeEventListener("click", this.onControlClick);
      document.removeEventListener("pointerup", this.onPressSettle);
      document.removeEventListener("pointercancel", this.onPressSettle);
    }
    if (this.trigger) {
      this.trigger.removeEventListener("click", this.onTriggerClick);
      this.trigger.removeEventListener("keydown", this.onTriggerKeydown);
    }
    this.el.removeEventListener("focusout", this.onFocusOut);
    clearTimeout(this.labelPatchTimer);
    clearTimeout(this.remoteTimer);
    // the deferred close and the post-reset re-sync both reach into the
    // tree they were queued against - torn down in the same tick as a
    // focusout or a reset, they would run against a detached one
    clearTimeout(this.focusOutTimer);
    clearTimeout(this.resetTimer);
    if (this.clearButton) {
      this.clearButton.removeEventListener("click", this.onClearClick);
    }
    if (this.form) this.form.removeEventListener("reset", this.onFormReset);
    document.removeEventListener(
      "pointerdown",
      this.onOutsidePointerDown,
      true,
    );
    document.removeEventListener("pointerup", this.onOutsidePointerUp, true);
    document.removeEventListener(
      "pointercancel",
      this.onOutsidePointerCancel,
      true,
    );
    window.removeEventListener("scroll", this.onReposition, true);
    window.removeEventListener("resize", this.onReposition);
  },

  items() {
    return Array.from(this.el.querySelectorAll("[data-pc-combo-item]"));
  },

  visibleItems() {
    return this.items().filter(
      (i) => !i.hidden && !i.hasAttribute("data-disabled"),
    );
  },

  // same ladder as the command palette: prefix > word-boundary > substring > fuzzy
  score(text, query) {
    if (!query) return 1;
    if (text.startsWith(query)) return 4;
    const at = text.indexOf(query);
    if (at > 0 && /[\s\-_/]/.test(text[at - 1])) return 3;
    if (at >= 0) return 2;
    let qi = 0;
    for (const ch of text)
      if (ch === query[qi] && ++qi === query.length) return 1;
    return 0;
  },

  openPanel({ keepQuery = false } = {}) {
    if (!this.panel.hidden) return;
    this.isOpen = true;
    this.panel.hidden = false;
    this.input.setAttribute("aria-expanded", "true");
    if (this.trigger) this.trigger.setAttribute("aria-expanded", "true");
    this.outsidePress = null;
    // pointerId -> the time it went down, so a stranded press can age out
    this.activePointers = new Map();
    document.addEventListener("pointerdown", this.onOutsidePointerDown, true);
    document.addEventListener("pointerup", this.onOutsidePointerUp, true);
    document.addEventListener(
      "pointercancel",
      this.onOutsidePointerCancel,
      true,
    );
    window.addEventListener("scroll", this.onReposition, true);
    window.addEventListener("resize", this.onReposition);
    if (!keepQuery) this.query = "";
    this.filter();
    this.positionPanel();
  },

  closePanel() {
    document.removeEventListener(
      "pointerdown",
      this.onOutsidePointerDown,
      true,
    );
    document.removeEventListener("pointerup", this.onOutsidePointerUp, true);
    document.removeEventListener(
      "pointercancel",
      this.onOutsidePointerCancel,
      true,
    );
    window.removeEventListener("scroll", this.onReposition, true);
    window.removeEventListener("resize", this.onReposition);
    this.isOpen = false;
    if (this.remoteEvent) {
      this.remoteSeq++;
      clearTimeout(this.remoteTimer);
      if (this.loadingRow) this.loadingRow.hidden = true;
    }
    if (this.panel.hidden) return;
    this.panel.hidden = true;
    this.panel.removeAttribute("data-flip");
    this.list.style.maxHeight = "";
    this.input.setAttribute("aria-expanded", "false");
    this.highlight(null, false);
    this.query = "";
    this.restoreDisplay();
    if (this.trigger) {
      this.trigger.setAttribute("aria-expanded", "false");
      // the search input just vanished with the panel - focus returns to
      // the trigger unless something outside already took it
      if (
        this.el.contains(document.activeElement) ||
        document.activeElement === document.body
      ) {
        this.trigger.focus();
      }
    }
  },

  // Open downward by default; flip above when the viewport has no room
  // below AND more room above (the bottom-of-form combobox that used to
  // open 200px off-screen). When NEITHER side fits the whole panel, the
  // winning side's space caps the scroll area instead - the list scrolls
  // within what fits, so no option ever sits outside the viewport.
  // Measured with flip and cap cleared so natural height decides.
  positionPanel() {
    if (this.panel.hidden) return;
    this.panel.removeAttribute("data-flip");
    this.list.style.maxHeight = "";
    const anchor = this.control || this.trigger;
    if (!anchor) return;
    const control = anchor.getBoundingClientRect();
    const panelH = this.panel.offsetHeight;
    if (!panelH || (!control.top && !control.bottom)) return; // jsdom / unrendered
    const gap = 8;
    const below = window.innerHeight - control.bottom - gap;
    const above = control.top - gap;
    const flip = panelH > below && above > below;
    if (flip) this.panel.setAttribute("data-flip", "");
    const room = flip ? above : below;
    if (panelH > room) {
      // no floor: in a viewport too cramped for even one row, a sliver of
      // scrollable list still beats options rendered outside the viewport
      const chrome = panelH - this.list.offsetHeight;
      this.list.style.maxHeight = `${Math.max(room - chrome, 0)}px`;
    }
  },

  selectedValues() {
    return Array.from(this.select.selectedOptions)
      .map((o) => o.value)
      .filter((v) => v !== "");
  },

  maxReached() {
    const max = parseInt(this.el.dataset.maxItems || "", 10);
    return this.multiple && !isNaN(max) && this.selectedValues().length >= max;
  },

  // At the cap the unchosen options stop being choosable, and CSS alone
  // only made them LOOK that way: visibleItems()/navItems() read
  // data-disabled, screen readers read aria-disabled, so without both the
  // keyboard walked onto an option that Enter then silently refused.
  // data-max-blocked keeps OUR capping separable from a server-rendered
  // per-option `disabled: true`, which must survive the cap lifting.
  applyCap(capped) {
    for (const item of this.items()) {
      const blocked = capped && item.getAttribute("aria-selected") !== "true";
      if (blocked && !item.hasAttribute("data-disabled")) {
        item.setAttribute("data-max-blocked", "");
        item.setAttribute("data-disabled", "true");
        item.setAttribute("aria-disabled", "true");
      } else if (!blocked && item.hasAttribute("data-max-blocked")) {
        item.removeAttribute("data-max-blocked");
        item.removeAttribute("data-disabled");
        item.removeAttribute("aria-disabled");
      }
    }
  },

  chosenItem() {
    const value = this.select.value;
    if (!value) return null;
    return this.items().find((i) => i.dataset.value === value) || null;
  },

  // the chip row is the visual order of record; the select is only the
  // fallback for a multiple combobox rendered without a chips container
  lastChipValue() {
    if (this.chips) {
      const chips = this.chips.querySelectorAll("[data-pc-combo-chip]");
      return chips.length ? chips[chips.length - 1].dataset.value : null;
    }
    const values = this.selectedValues();
    return values.length ? values[values.length - 1] : null;
  },

  restoreDisplay() {
    if (this.multiple || this.trigger) {
      // chips carry the state in multiple mode; the trigger label carries
      // it in trigger mode - the input is pure query either way
      this.input.value = "";
      return;
    }
    const chosen = this.chosenItem();
    if (chosen) {
      this.input.value = chosen.dataset.label || "";
      return;
    }
    // free-text values have no list item - the select option carries
    // their display text. select.value is the single source of truth
    // (selectedOptions can carry stale flags after form.reset()).
    const v = this.select.value;
    if (v === "") {
      this.input.value = "";
      return;
    }
    const opt = Array.from(this.select.options).find((o) => o.value === v);
    this.input.value = opt ? opt.textContent.trim() : v;
  },

  dispatchChange() {
    this.select.dispatchEvent(new Event("input", { bubbles: true }));
    this.select.dispatchEvent(new Event("change", { bubbles: true }));
  },

  setSelected(value, selected) {
    const option = Array.from(this.select.options).find(
      (o) => o.value === value,
    );
    if (!option || option.selected === selected) return;
    if (this.multiple) {
      option.selected = selected;
    } else {
      this.select.value = selected ? value : "";
    }
    this.dispatchChange();
    this.syncFromSelect();
    if (!this.panel.hidden) this.filter();
  },

  syncChips() {
    if (!this.chips) return;
    // Incremental sync: chips whose value still belongs to the selection
    // are NEVER touched - server-rendered rich :chip content survives
    // both patches and client-side picks with zero flash. Surplus chips
    // are removed, missing ones appended as plain optimistic chips (the
    // LiveView patch swaps rich content in: server wins). Multiset
    // counting keeps duplicate-value options honest.
    const want = Array.from(this.select.selectedOptions)
      .map((o) => o.value)
      .filter((v) => v !== "");
    const need = new Map();
    for (const v of want) need.set(v, (need.get(v) || 0) + 1);
    for (const chip of Array.from(
      this.chips.querySelectorAll("[data-pc-combo-chip]"),
    )) {
      const n = need.get(chip.dataset.value) || 0;
      if (n > 0) need.set(chip.dataset.value, n - 1);
      else chip.remove();
    }
    for (const v of want) {
      const left = need.get(v) || 0;
      if (left === 0) continue;
      need.set(v, left - 1);
      this.chips.appendChild(this.buildChip(v));
    }
    this.applyChipOrder();
  },

  // The server's chosen order arrives via data-order (data attrs still
  // update on phx-update=ignore containers). Enforce it after membership
  // reconciliation; chips the server does not know yet (client picks
  // awaiting their patch) keep their spot at the end.
  applyChipOrder() {
    let order = null;
    try {
      order = JSON.parse(this.chips.dataset.order || "null");
    } catch {
      order = null;
    }
    if (!Array.isArray(order)) return;
    const byValue = new Map();
    const current = [];
    for (const chip of Array.from(
      this.chips.querySelectorAll("[data-pc-combo-chip]"),
    )) {
      current.push(chip);
      const v = chip.dataset.value;
      if (!byValue.has(v)) byValue.set(v, []);
      byValue.get(v).push(chip);
    }
    const seq = [];
    for (const v of order) {
      const arr = byValue.get(v);
      if (arr && arr.length) seq.push(arr.shift());
    }
    for (const arr of byValue.values()) seq.push(...arr);
    if (
      seq.length === current.length &&
      seq.every((c, i) => c === current[i])
    ) {
      return;
    }
    for (const chip of seq) this.chips.appendChild(chip);
  },

  buildChip(value) {
    const option = Array.from(this.select.options).find(
      (o) => o.value === value,
    );
    const text = option ? option.textContent.trim() : value;
    const removeLabel = (this.chips.dataset.removeLabel || "Remove") + " ";
    const chip = document.createElement("span");
    chip.className = "pc-combo-box__chip";
    chip.setAttribute("data-pc-combo-chip", "");
    chip.dataset.value = value;
    const label = document.createElement("span");
    label.className = "pc-combo-box__chip-label";
    // server-rendered :chip templates let client-built chips be RICH
    // immediately - no round-trip pop-in, rich even without wiring
    const tpl = Array.from(
      this.el.querySelectorAll("template[data-pc-combo-chip-template]"),
    ).find((t) => t.dataset.value === value);
    if (tpl) {
      label.appendChild(tpl.content.cloneNode(true));
    } else {
      label.textContent = text;
    }
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "pc-combo-box__chip-remove";
    btn.setAttribute("data-pc-combo-chip-remove", "");
    btn.dataset.value = value;
    btn.setAttribute("aria-label", removeLabel + text);
    btn.tabIndex = -1;
    const icon = document.createElement("span");
    icon.className = "hero-x-mark-mini pc-combo-box__chip-remove-icon";
    btn.appendChild(icon);
    chip.append(label, btn);
    return chip;
  },

  syncFromSelect() {
    const values = this.selectedValues();
    // a satisfied constraint retires the message the hook drew for it -
    // .validity is the reading that does NOT re-fire the invalid event
    if (this.errorEl && !this.errorEl.hidden && this.select.validity.valid) {
      this.clearError();
    }
    for (const i of this.items()) {
      i.setAttribute(
        "aria-selected",
        values.includes(i.dataset.value) ? "true" : "false",
      );
    }
    this.el.toggleAttribute("data-has-value", values.length > 0);
    if (this.multiple) {
      this.syncChips();
      const capped = this.maxReached();
      // the transition is tracked in hook state, not read back off the
      // attribute: a patch can rewrite the root element's attributes, and
      // that must not read as "the cap was just reached" all over again
      const wasCapped = this.capped === true;
      this.capped = capped;
      this.el.toggleAttribute("data-max-reached", capped);
      this.applyCap(capped);
      // "invites more picks while every option is dimmed" was the reason
      // the placeholder used to be blanked to transparent at the cap - but
      // that left the field looking empty while a screen reader still read
      // the placeholder aloud. Say the same thing both ways instead. The
      // server's placeholder rides in data-placeholder-text, so it stays
      // the truth to return to (a patch updates it even while capped).
      const base = this.input.dataset.placeholderText;
      const maxText = this.live && this.live.dataset.maxItemsText;
      if (base != null) this.input.placeholder = (capped && maxText) || base;
      // reaching the cap is a state change worth hearing once - but a
      // combobox that MOUNTS at its cap has not just changed, and a page
      // full of them announcing on load would be noise
      if (capped && !wasCapped && this.announceReady) this.announceMax();
    }
    // :selected slot content is server-rendered; the label carries the
    // values it was rendered for. When they match the selection (the
    // patch that just landed), leave the rich DOM alone - overwrite with
    // optimistic text only for client-side changes, and drop the marker
    // so later syncs stay optimistic until the next patch.
    // Order differences are legitimate: the server renders chosen order
    // (chips follow pick order by design) while the hook reads DOM option
    // order - so freshness is a SET comparison, never a sequence one.
    let labelIsFresh = false;
    if (this.triggerLabel && this.triggerLabel.dataset.customLabel != null) {
      // JSON-encoded stamp: no delimiter to collide with value contents
      let rendered = null;
      try {
        rendered = JSON.parse(this.triggerLabel.dataset.values);
      } catch {
        rendered = null;
      }
      if (Array.isArray(rendered) && sameValueMultiset(rendered, values)) {
        labelIsFresh = true;
        clearTimeout(this.labelPatchTimer);
        this.labelPatchTimer = null;
        this.labelStaleSince = null;
      } else {
        delete this.triggerLabel.dataset.values;
        // a phx-change form means the patch that re-renders the rich
        // content is already on its way - keeping the briefly-stale rich
        // DOM reads better than flashing plain text for one round trip.
        // Unwired comboboxes get the honest optimistic text instead, and
        // the grace window self-heals wired ones whose handler never
        // re-renders the value. The window anchors to the FIRST
        // divergence - continuing picks or unrelated patches never
        // extend it, so a silent handler always degrades within 2s.
        const form = this.select.form;
        if (form && form.hasAttribute("phx-change") && values.length > 0) {
          if (this.labelStaleSince == null) {
            this.labelStaleSince = performance.now();
            clearTimeout(this.labelPatchTimer);
            this.labelPatchTimer = setTimeout(() => {
              this.labelPatchTimer = null;
              this.syncFromSelect();
            }, 2000);
          }
          if (performance.now() - this.labelStaleSince < 2000) {
            labelIsFresh = true;
          }
        }
      }
    }
    if (this.triggerLabel && !labelIsFresh) {
      const placeholder = this.triggerLabel.dataset.placeholderText;
      if (values.length === 0) {
        this.triggerLabel.textContent = placeholder || "";
        this.trigger.setAttribute("data-placeholder", "true");
      } else {
        this.trigger.removeAttribute("data-placeholder");
        if (this.multiple) {
          this.triggerLabel.textContent = `${values.length} ${this.triggerLabel.dataset.countLabel || "selected"}`;
        } else {
          const chosen = this.chosenItem();
          this.triggerLabel.textContent = chosen
            ? chosen.dataset.label || ""
            : "";
        }
      }
    }
    if (this.panel.hidden || document.activeElement !== this.input)
      this.restoreDisplay();
  },

  // remote rows (and free-text commits) have no server-rendered option in
  // the hidden select - create one so the form posts the value. Marked
  // data-pc-combo-custom: the server owns persistence on the next patch.
  ensureOption(value, label) {
    let option = Array.from(this.select.options).find((o) => o.value === value);
    if (!option) {
      option = document.createElement("option");
      option.value = value;
      option.textContent = label;
      option.setAttribute("data-pc-combo-custom", "");
      this.select.appendChild(option);
    }
    return option;
  },

  choose(item) {
    const value = item.dataset.value;
    this.ensureOption(value, item.dataset.label || value);
    if (this.multiple) {
      const selected = this.selectedValues().includes(value);
      if (!selected && this.maxReached()) {
        // capped options are aria-disabled so the keyboard should never
        // land here - a pointer or assistive tech still can, and refusing
        // in silence was the whole complaint
        this.announceMax();
        return;
      }
      this.setSelected(value, !selected);
      // the panel stays open for more picks; the query resets so the next
      // keystrokes start a fresh search. The highlight stays on the item
      // just toggled (Base UI/downshift grammar) - arrowing resumes from
      // where the user is, not from the top; filter() with the cleared
      // query would otherwise re-home it on the first option.
      this.query = "";
      this.input.value = "";
      this.filter();
      this.highlight(item, false);
      this.input.focus();
      return;
    }
    this.setSelected(value, true);
    this.closePanel();
    if (!this.trigger) this.input.focus();
  },

  // Remote search, contract-verbatim from the Tom Select era: push the
  // raw search term, receive {:reply, %{results: [%{text, value}]}}, and
  // render the results as the option list. The listbox is hook-owned in
  // remote mode (phx-update=ignore), so there is exactly one writer. A
  // sequence counter drops stale replies from out-of-order round trips.
  remoteSearch() {
    if (
      typeof this.pushEventTo !== "function" &&
      typeof this.pushEvent !== "function"
    ) {
      return; // remote needs a LiveView socket
    }
    const seq = this.remoteSeq;
    if (this.loadingRow) this.loadingRow.hidden = false;
    const term = this.input.value.trim();
    const handle = (reply) => {
      if (seq !== this.remoteSeq) return; // a newer search superseded this one
      if (this.loadingRow) this.loadingRow.hidden = true;
      this.renderRemoteResults((reply && reply.results) || []);
    };
    if (this.remoteTarget && typeof this.pushEventTo === "function") {
      this.pushEventTo(this.remoteTarget, this.remoteEvent, term, handle);
    } else {
      this.pushEvent(this.remoteEvent, term, handle);
    }
  },

  renderRemoteResults(results) {
    for (const stale of this.el.querySelectorAll(
      "[data-pc-combo-item], [data-pc-combo-group]",
    )) {
      stale.remove();
    }
    // rows go before the create row when there is one, otherwise at the
    // end of the listbox - the empty row is panel chrome and lives
    // outside the list, so it is not an anchor insertBefore can use
    const anchor =
      this.createRow && this.createRow.parentElement === this.list
        ? this.createRow
        : null;
    for (const result of results) {
      const row = document.createElement("div");
      row.className = "pc-combo-box__option";
      row.setAttribute("role", "option");
      row.setAttribute("data-pc-combo-item", "");
      row.setAttribute("aria-selected", "false");
      row.dataset.value = String(result.value);
      row.dataset.label = String(result.text);
      const label = document.createElement("span");
      label.className = "pc-combo-box__option-label";
      label.textContent = String(result.text);
      const check = document.createElement("span");
      check.className = "hero-check-mini pc-combo-box__check";
      row.append(label, check);
      this.list.insertBefore(row, anchor);
    }
    this.syncFromSelect();
    this.filter();
  },

  // free-text commit: the typed query becomes a real value in the hidden
  // select (a dynamic option marked data-pc-combo-custom), so the form
  // posts it like any other choice. The SERVER owns persistence: unless
  // the app re-renders the value into options, the next patch drops it.
  commitFreeText() {
    const raw = this.input.value.trim();
    if (!raw) return;
    // an existing option with the same label wins - never dupe by case
    const existing = this.items().find(
      (i) => (i.dataset.label || "").trim().toLowerCase() === raw.toLowerCase(),
    );
    if (existing && !existing.hasAttribute("data-disabled")) {
      this.choose(existing);
      return;
    }
    if (this.multiple && this.maxReached()) {
      this.announceMax();
      return;
    }
    const option = this.ensureOption(raw, raw);
    if (this.multiple) {
      option.selected = true;
      this.dispatchChange();
      this.syncFromSelect();
      this.query = "";
      this.input.value = "";
      this.filter();
      this.input.focus();
      return;
    }
    this.select.value = raw;
    this.dispatchChange();
    this.syncFromSelect();
    this.closePanel();
    (this.trigger || this.input).focus();
  },

  announce(count) {
    if (!this.live) return;
    const label = this.live.dataset.resultsLabel || "results";
    const empty = this.live.dataset.noResultsText || "No results found";
    const base = count === 0 ? empty : `${count} ${label}`;
    // filter() runs after every pick, so a cap message written on its own
    // would be overwritten a tick later by the result count. While the cap
    // is on, the two belong together anyway: a bare count invites picks
    // that are then refused.
    const max = this.capped && this.live.dataset.maxItemsText;
    this.live.textContent = max ? `${max}. ${base}` : base;
  },

  // A blocked pick used to be pure silence: choose() returned early and
  // nothing spoke. A live region only speaks on a CHANGE, though, and a
  // second blocked press carries the identical string - so alternate an
  // invisible zero-width space to guarantee every press is heard.
  announceMax() {
    const text = this.live && this.live.dataset.maxItemsText;
    if (!text) return;
    this.live.textContent =
      this.live.textContent === text ? `${text}\u200b` : text;
  },

  // The browser writes validationMessage in the user's own locale - the
  // right message to show, and nothing new to translate.
  showError(message) {
    (this.trigger || this.input).setAttribute("aria-invalid", "true");
    if (!this.errorEl) return;
    this.errorEl.textContent = message;
    this.errorEl.hidden = false;
  },

  clearError() {
    (this.trigger || this.input).removeAttribute("aria-invalid");
    if (!this.errorEl) return;
    this.errorEl.textContent = "";
    this.errorEl.hidden = true;
  },

  filter() {
    const query = this.query;
    let count = 0;
    let idBase = 0;
    let best = null;
    let bestScore = 0;

    for (const item of this.items()) {
      if (!item.id) item.id = `${this.el.id}-opt-${idBase}`;
      idBase++;
      const text = `${item.dataset.label || item.textContent || ""}`
        .trim()
        .toLowerCase();
      // remote mode: the server already filtered - every row is a match
      const score = this.remoteEvent ? 1 : this.score(text, query);
      item.hidden = score === 0;
      if (score === 0) continue;
      count++;
      // Options are hidden, never reordered (the server owns DOM order), so
      // the highlight carries the ranking instead: Enter must commit the best
      // match, not whichever match happens to sit highest. Typing "tok" has to
      // land on Tokyo, not on Stockholm's fuzzy subsequence.
      if (score > bestScore && !item.hasAttribute("data-disabled")) {
        best = item;
        bestScore = score;
      }
    }

    for (const group of this.el.querySelectorAll("[data-pc-combo-group]")) {
      const any = Array.from(
        group.querySelectorAll("[data-pc-combo-item]"),
      ).some((i) => !i.hidden);
      group.hidden = !any;
    }

    // the create row shows for a non-empty query with no EXACT label
    // match (a case-insensitive duplicate would be a confusing offer)
    let createVisible = false;
    if (this.createRow) {
      const q = query.trim();
      const exact =
        q &&
        this.items().some(
          (i) =>
            (i.dataset.label || "").trim().toLowerCase() === q.toLowerCase(),
        );
      createVisible = Boolean(q) && !exact;
      this.createRow.hidden = !createVisible;
      // display the raw typed text - the scoring query is lowercased
      if (this.createQueryEl)
        this.createQueryEl.textContent = this.input.value.trim();
    }

    const empty = this.el.querySelector("[data-pc-combo-empty]");
    if (empty) empty.hidden = count > 0 || createVisible;
    this.announce(count);

    // an empty query (just opened) homes the highlight on the chosen value;
    // a typed query homes it on the best (first) visible match
    const chosen = this.multiple ? null : this.chosenItem();
    if (
      !query &&
      chosen &&
      !chosen.hidden &&
      !chosen.hasAttribute("data-disabled")
    ) {
      this.highlight(chosen, true);
    } else {
      this.highlight(best || this.visibleItems()[0] || null, false);
    }

    // filtering changes the panel's height (narrowing shrinks, broadening
    // grows it back) - the flip decision must track it or a grown panel
    // near the viewport bottom re-clips
    this.positionPanel();
  },

  highlightedItem() {
    const id = this.input.getAttribute("aria-activedescendant");
    return id ? document.getElementById(id) : null;
  },

  highlight(item, scroll = true) {
    this.highlightedValue = item ? item.dataset.value : null;
    for (const i of this.items())
      i.toggleAttribute("data-highlighted", i === item);
    if (this.createRow)
      this.createRow.toggleAttribute(
        "data-highlighted",
        this.createRow === item,
      );
    if (item) {
      this.input.setAttribute("aria-activedescendant", item.id);
      if (scroll) item.scrollIntoView({ block: "nearest" });
    } else {
      this.input.removeAttribute("aria-activedescendant");
    }
  },

  // Arrow keys wrap through an empty stop (shadcn/Base UI behavior): Down
  // from the last item clears the highlight, Down again starts from the
  // top. The empty state is the input itself taking a turn in the cycle -
  // in free-text mode Enter there means "use what I typed, not an option" -
  // and it reads as a felt boundary instead of a disorienting teleport.
  // the visible create row participates as the last keyboard stop - the
  // footer-region consumer the panel-slot ruling promised
  navItems() {
    const items = this.visibleItems();
    if (this.createRow && !this.createRow.hidden) items.push(this.createRow);
    return items;
  },

  move(delta) {
    const items = this.navItems();
    if (!items.length) return;
    const at = items.indexOf(this.highlightedItem());
    if (at === -1) {
      this.highlight(delta > 0 ? items[0] : items[items.length - 1]);
      return;
    }
    const next = at + delta;
    this.highlight(next < 0 || next >= items.length ? null : items[next]);
  },

  keydown(e) {
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        this.panel.hidden ? this.openPanel() : this.move(1);
        break;
      case "ArrowUp":
        e.preventDefault();
        this.panel.hidden ? this.openPanel() : this.move(-1);
        break;
      case "Home":
        if (this.panel.hidden) return;
        e.preventDefault();
        this.highlight(this.visibleItems()[0] || null);
        break;
      case "End":
        if (this.panel.hidden) return;
        e.preventDefault();
        this.highlight(this.navItems().slice(-1)[0] || null);
        break;
      case "Backspace": {
        if (!this.multiple || this.input.value !== "") return;
        // Backspace removes the chip the user sees LAST. selectedValues()
        // is the select's DOM order, which diverges from the chip row the
        // moment someone picks out of option order (chips follow pick
        // order by design) - reading it deleted a chip from the middle.
        const value = this.lastChipValue();
        if (value != null) this.setSelected(value, false);
        break;
      }
      case "Enter": {
        if (this.panel.hidden) return; // closed: let the form submit
        e.preventDefault();
        const item = this.highlightedItem();
        if (item === this.createRow && this.createRow) {
          this.commitFreeText();
          break;
        }
        if (item && !item.hidden && !item.hasAttribute("data-disabled")) {
          this.choose(item);
          break;
        }
        // the empty stop: in free-text mode Enter here means "use what I
        // typed, not an option" - the grammar this state was built for
        if (this.freeText && this.input.value.trim()) this.commitFreeText();
        break;
      }
      case "Escape":
        if (this.panel.hidden) return; // closed: let dialogs/modals handle it
        e.preventDefault();
        e.stopPropagation();
        this.closePanel();
        break;
      case "Tab":
        this.closePanel();
        break;
    }
  },
};

// Link-mode wiring for the data table's quick search and rows-per-page
// select. Event mode posts through plain phx-change forms and never
// mounts this hook; link mode has no events by design (handle_params is
// the whole backend), so state changes must become patch URLs. The
// component renders URL templates (:term / :page_size placeholders,
// assembled around the already-encoded rest of the query) and a hidden
// data-phx-link anchor; the hook fills a template in and clicks the
// anchor so navigation stays LiveView's own.
export const PetalDataTable = {
  mounted() {
    this.searchTimer = null;

    this.onInput = (e) => {
      // the select editor's option-filter box: purely visual narrowing
      // of the checkbox list, never submitted, never navigates
      const optionFilter = e.target.closest("[data-pc-dt-option-filter]");
      if (optionFilter) {
        this.filterOptions(optionFilter);
        return;
      }

      if (!e.target.closest("[data-pc-dt-search]")) return;
      clearTimeout(this.searchTimer);
      const wait = parseInt(this.el.dataset.debounce || "300", 10);
      this.searchTimer = setTimeout(() => this.patchTo(this.navUrl()), wait);
    };

    this.onChange = (e) => {
      // unchecking a kept-visible-because-checked option row must rerun
      // the narrowing, or the stale row lingers until the term changes
      const optionRow = e.target.closest(".pc-data-table__filter-option");
      if (optionRow) {
        const box = optionRow
          .closest(".pc-data-table__filter-form")
          ?.querySelector("[data-pc-dt-option-filter]");
        if (box?.value) this.filterOptions(box);
        return;
      }

      if (!e.target.closest("[data-pc-dt-page-size]")) return;
      // the nav URL reads the live search input too, so the pending
      // debounced patch is redundant - and letting it fire later would
      // navigate with a template predating this pick
      clearTimeout(this.searchTimer);
      this.patchTo(this.navUrl());
    };

    // link mode has no events, so a filter editor's Apply becomes a
    // patch built from the form's inputs: replace this field's entry in
    // the committed filter list (an empty editor removes it), close the
    // popover, navigate
    this.onSubmit = (e) => {
      const form = e.target.closest(".pc-data-table__filter-form");
      if (!form) return;

      // event mode: the form pushes its own phx-submit - only the menu
      // close is ours
      if (!form.hasAttribute("data-pc-dt-filter")) {
        this.closeMenu({ restoreFocus: true });
        return;
      }

      e.preventDefault();
      clearTimeout(this.searchTimer);

      const field = form.dataset.field;
      const filters = this.committedFilters().filter((f) => f.field !== field);
      const next = this.readFilter(form, field);
      if (next) filters.push(next);

      this.closeMenu({ restoreFocus: true });
      this.patchTo(this.navUrl(filters));
    };

    // -- menus --------------------------------------------------------
    // The filter and column panels sit NEXT TO their triggers in the
    // page, not in the browser's top layer. That is the whole trick:
    // the page moves them together at compositor speed, so scrolling
    // (including an iOS momentum flick, and the scroll iOS does to
    // reveal a focused field) can't desync them. There is deliberately
    // no scroll listener here - nothing to chase, nothing to judder.
    this.openMenu = null;

    this.onMenuClick = (e) => {
      const trigger = e.target.closest("[data-pc-menu-trigger]");
      if (!trigger || !this.el.contains(trigger)) return;
      e.preventDefault();
      this.toggleMenu(trigger.getAttribute("data-pc-menu-trigger"));
    };

    // Dismiss on a TAP outside, not a press outside. Closing on
    // pointerdown means a drag that starts on the page - the ordinary
    // way anyone scrolls a phone - kills the menu before it moves. The
    // native popover's light dismiss has the same shape: press and
    // release must both land outside, and a gesture that turns into a
    // scroll never releases (it cancels).
    // Per pointer, because fingers come in twos: a pinch or two-finger
    // scroll would otherwise have one finger overwrite the other's press
    // record, or one finger's cancel disarm the other's tap.
    // `active` is EVERY pointer currently down, `presses` only the ones
    // that started outside. Tracking both matters: a finger resting
    // inside the panel is invisible to `presses`, and without it a
    // second finger tapping outside would look like a lone clean tap.
    this.active = new Set();
    this.presses = new Map();
    this.multiTouch = false;

    this.onPressStart = (e) => {
      if (!this.openMenu) return;
      this.active.add(e.pointerId);
      if (this.active.size > 1) this.multiTouch = true;
      if (this.isOutsideMenu(e.target)) {
        this.presses.set(e.pointerId, { x: e.clientX, y: e.clientY });
      }
    };

    this.onPressEnd = (e) => {
      const press = this.presses.get(e.pointerId);
      this.presses.delete(e.pointerId);
      this.active.delete(e.pointerId);

      const gesture = this.multiTouch;
      if (this.active.size === 0) this.multiTouch = false;
      if (!press || gesture || !this.openMenu) return;

      // a release far from the press is a drag, not a tap - iOS uses a
      // comparable slop before it commits to "this was a tap"
      const dragged = Math.hypot(e.clientX - press.x, e.clientY - press.y) > 10;
      if (!dragged && this.isOutsideMenu(e.target)) this.closeMenu();
    };

    this.onPressCancel = (e) => {
      this.presses.delete(e.pointerId);
      this.active.delete(e.pointerId);
      if (this.active.size === 0) this.multiTouch = false;
    };

    this.onMenuKeydown = (e) => {
      if (e.key !== "Escape" || !this.openMenu) return;
      // a data table inside a modal would otherwise close both at once
      e.stopPropagation();
      const trigger = this.menuTrigger();
      this.closeMenu();
      trigger?.focus();
    };

    this.onWindowResize = () => {
      if (this.openMenu) this.alignMenu();
    };

    // Tab out of the panel closes it. relatedTarget lies on iOS, so this
    // is the combobox's proven shape: defer a tick, then ask the document
    // where focus actually landed.
    this.onMenuFocusOut = () => {
      if (!this.openMenu) return;
      setTimeout(() => {
        if (!this.openMenu) return;
        const panel = this.menuPanel();
        const trigger = this.menuTrigger();
        const active = document.activeElement;
        if (!active || active === document.body) return;
        if (panel?.contains(active) || trigger?.contains(active)) return;
        this.closeMenu();
      }, 0);
    };

    this.el.addEventListener("click", this.onMenuClick);
    this.el.addEventListener("keydown", this.onMenuKeydown);
    this.el.addEventListener("focusout", this.onMenuFocusOut);
    document.addEventListener("pointerdown", this.onPressStart, true);
    document.addEventListener("pointerup", this.onPressEnd, true);
    document.addEventListener("pointercancel", this.onPressCancel, true);
    window.addEventListener("resize", this.onWindowResize);

    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("change", this.onChange);
    this.el.addEventListener("submit", this.onSubmit);
    this.syncIndeterminate();
  },

  // id lookups without CSS.escape: ids here come from a developer's
  // table id and field names, and escaping is one more thing to get
  // wrong (it is also absent in jsdom, so specs would diverge)
  isOutsideMenu(target) {
    const panel = this.menuPanel();
    const trigger = this.menuTrigger();

    return !panel?.contains(target) && !trigger?.contains(target);
  },

  menuPanel() {
    return this.openMenu ? document.getElementById(this.openMenu) : null;
  },

  menuTrigger() {
    if (!this.openMenu) return null;

    return (
      Array.from(this.el.querySelectorAll("[data-pc-menu-trigger]")).find(
        (button) =>
          button.getAttribute("data-pc-menu-trigger") === this.openMenu,
      ) || null
    );
  },

  toggleMenu(id) {
    if (this.openMenu === id) return this.closeMenu();
    if (this.openMenu) this.closeMenu();
    this.openMenu = id;
    this.revealMenu();
    this.alignMenu();
  },

  revealMenu() {
    const panel = this.menuPanel();
    if (!panel) return;
    // a pending hide from a previous close would yank it back
    clearTimeout(panel.pcHideTimer);
    panel.hidden = false;
    this.menuTrigger()?.setAttribute("aria-expanded", "true");
    // a frame later so the fade has a start state to move from
    requestAnimationFrame(() => {
      if (this.openMenu) this.menuPanel()?.setAttribute("data-pc-open", "");
    });
  },

  closeMenu({ restoreFocus = false } = {}) {
    const panel = this.menuPanel();
    const trigger = this.menuTrigger();
    trigger?.setAttribute("aria-expanded", "false");
    // closing hides the panel, which blurs whatever was focused inside
    // it - without this the user lands on <body>
    if (restoreFocus) trigger?.focus();
    this.openMenu = null;
    if (!panel) return;
    panel.removeAttribute("data-pc-open");
    // Per-panel timer, and the check names THIS panel rather than asking
    // whether any menu is open: opening a sibling within the fade window
    // would otherwise leave this one unhidden - invisible, but still
    // laid out and still swallowing taps.
    clearTimeout(panel.pcHideTimer);
    panel.pcHideTimer = setTimeout(() => {
      if (this.openMenu !== panel.id) panel.hidden = true;
    }, 120);
  },

  // One-shot geometry, run on open and on resize only. A page-anchored
  // panel keeps its offset relative to the trigger for free, so this
  // never needs to run again while the user scrolls.
  alignMenu() {
    const panel = this.menuPanel();
    const trigger = this.menuTrigger();
    if (!panel || !trigger) return;

    panel.style.transform = "";
    panel.style.maxHeight = "";
    panel.removeAttribute("data-pc-flip");

    const vv = window.visualViewport;
    const view = vv
      ? {
          top: vv.offsetTop,
          left: vv.offsetLeft,
          width: vv.width,
          height: vv.height,
        }
      : {
          top: 0,
          left: 0,
          width: window.innerWidth,
          height: window.innerHeight,
        };
    const pad = 8;

    const t = trigger.getBoundingClientRect();
    const below = view.top + view.height - t.bottom;
    const above = t.top - view.top;
    let r = panel.getBoundingClientRect();

    if (r.height + pad > below && above > below) {
      panel.setAttribute("data-pc-flip", "top");
      r = panel.getBoundingClientRect();
    }

    // slide sideways into view - true for as long as the panel is open,
    // because horizontal position relative to the page doesn't change
    const overRight = r.right - (view.left + view.width - pad);
    const overLeft = view.left + pad - r.left;
    const shift = overRight > 0 ? -overRight : overLeft > 0 ? overLeft : 0;
    if (shift) panel.style.transform = `translateX(${Math.round(shift)}px)`;

    const flipped = panel.getAttribute("data-pc-flip") === "top";
    const room = (flipped ? above : below) - pad * 2;
    panel.style.maxHeight = `${Math.max(Math.round(room), 0)}px`;
    panel.style.overflowY = "auto";
  },

  beforeUpdate() {
    const panel = this.menuPanel();
    const active = document.activeElement;
    this.refocus = panel && active && panel.contains(active) ? active : null;
  },

  updated() {
    this.syncIndeterminate();
    this.syncOptionFilters();

    // a patch re-renders panels from the server: `hidden` comes back and
    // the inline offsets this hook owns are dropped
    if (this.openMenu) {
      const panel = this.menuPanel();
      if (panel) {
        panel.hidden = false;
        panel.setAttribute("data-pc-open", "");
        this.menuTrigger()?.setAttribute("aria-expanded", "true");
        this.alignMenu();
        // hiding an ancestor blurs its focused descendant, and LiveView
        // only re-focuses text inputs and selects - never a checkbox or
        // a button, which is what these panels are full of
        if (this.refocus?.isConnected) {
          let target = this.refocus;
          // the patch can disable the very control that was pressed - a
          // move-to-top button, say. Fall to the nearest enabled control
          // in the same row so keyboard flow continues instead of dying.
          if (target.disabled) {
            // parentElement first: closest() matches the element itself,
            // and the disabled control may carry an id of its own
            const row = target.parentElement?.closest("[id]");
            target =
              Array.from(row?.querySelectorAll("button, input") ?? []).find(
                (el) => !el.disabled,
              ) ?? target;
          }
          target.focus();
        }
      } else {
        this.openMenu = null;
      }
    }
  },

  // Hide checkbox rows whose label does not contain the typed term.
  // Checked rows stay visible regardless - hiding an active selection
  // behind a filter box reads as losing it.
  filterOptions(input) {
    const list = input.nextElementSibling;
    if (!list) return;
    const term = input.value.trim().toLowerCase();

    list.querySelectorAll(".pc-data-table__filter-option").forEach((row) => {
      const matches =
        term === "" || (row.textContent || "").toLowerCase().includes(term);
      const checked = row.querySelector("input:checked");
      row.hidden = !matches && !checked;
    });
  },

  // a patch re-renders the option rows all-visible while the focused
  // input keeps its value - reapply the narrowing
  syncOptionFilters() {
    this.el
      .querySelectorAll("[data-pc-dt-option-filter]")
      .forEach((input) => input.value && this.filterOptions(input));
  },

  // indeterminate is a DOM property, not an attribute - mirror the
  // server-stamped data attr onto it after every mount/patch
  syncIndeterminate() {
    this.el.querySelectorAll("[data-pc-dt-indeterminate]").forEach((box) => {
      box.indeterminate = box.dataset.pcDtIndeterminate === "true";
    });
  },

  destroyed() {
    clearTimeout(this.searchTimer);
    this.el
      .querySelectorAll("[data-pc-menu]")
      .forEach((panel) => clearTimeout(panel.pcHideTimer));
    this.el.removeEventListener("input", this.onInput);
    this.el.removeEventListener("change", this.onChange);
    this.el.removeEventListener("submit", this.onSubmit);
    this.el.removeEventListener("click", this.onMenuClick);
    this.el.removeEventListener("keydown", this.onMenuKeydown);
    this.el.removeEventListener("focusout", this.onMenuFocusOut);
    document.removeEventListener("pointerdown", this.onPressStart, true);
    document.removeEventListener("pointerup", this.onPressEnd, true);
    document.removeEventListener("pointercancel", this.onPressCancel, true);
    window.removeEventListener("resize", this.onWindowResize);
    this.presses?.clear();
    this.active?.clear();
  },

  committedFilters() {
    try {
      return JSON.parse(this.el.dataset.filters || "[]");
    } catch {
      return [];
    }
  },

  readFilter(form, field) {
    if (form.querySelector('input[name="values[]"]')) {
      const values = Array.from(
        form.querySelectorAll('input[name="values[]"]:checked'),
        (i) => i.value,
      );
      return values.length ? { field, op: "in", value: values } : null;
    }

    const op = form.querySelector('select[name="filter_op"]')?.value || "eq";

    // is_empty / is_not_empty carry no value, so an empty input must not
    // read as "remove this filter" the way it does for every other op
    if (op === "is_empty" || op === "is_not_empty")
      return { field, op, value: true };

    const value = (form.querySelector('[name="value"]')?.value || "").trim();

    if (op === "between") {
      const value2 = (
        form.querySelector('[name="value2"]')?.value || ""
      ).trim();
      // a half-empty range can't match anything, so it reads as removal
      return value === "" || value2 === ""
        ? null
        : { field, op, value: [value, value2] };
    }

    return value === "" ? null : { field, op, value };
  },

  // Both placeholders resolve from the live DOM in one pass, so
  // whichever control triggers the patch carries the other's current
  // (possibly uncommitted) value instead of a stale committed one.
  navUrl(filtersOverride) {
    let url = this.el.dataset.navTemplate;

    if (url.includes(":term")) {
      const input = this.el.querySelector("[data-pc-dt-search]");
      const trimmed = (input ? input.value : "").trim();
      url =
        trimmed === ""
          ? // a blank term drops the search param entirely so URLs stay clean
            url.replace(/search=:term&?/, "")
          : url.replace(":term", encodeURIComponent(trimmed));
    }

    if (url.includes(":page_size")) {
      const select = this.el.querySelector("[data-pc-dt-page-size]");
      url = url.replace(":page_size", encodeURIComponent(select.value));
    }

    if (url.includes(":filters")) {
      const encoded = this.encodeFilters(
        filtersOverride || this.committedFilters(),
      );
      url =
        encoded === ""
          ? url.replace(/:filters&?/, "")
          : url.replace(":filters", encoded);
    }

    return url.replace(/[?&]$/, "");
  },

  // mirrors the server's Phoenix-style indexed flattening, list values
  // as repeated "[value][]" keys - from_params reads either side back
  encodeFilters(filters) {
    const enc = encodeURIComponent;
    const pairs = [];

    filters.forEach((f, i) => {
      const base = `filters[${i}]`;
      pairs.push(`${enc(`${base}[field]`)}=${enc(f.field)}`);
      pairs.push(`${enc(`${base}[op]`)}=${enc(f.op)}`);
      if (Array.isArray(f.value)) {
        f.value.forEach((v) =>
          pairs.push(`${enc(`${base}[value][]`)}=${enc(v)}`),
        );
      } else if (f.value && typeof f.value === "object") {
        Object.entries(f.value).forEach(([k, v]) =>
          pairs.push(`${enc(`${base}[value][${k}]`)}=${enc(v)}`),
        );
      } else {
        pairs.push(`${enc(`${base}[value]`)}=${enc(f.value)}`);
      }
    });

    return pairs.join("&");
  },

  patchTo(url) {
    const nav = this.el.querySelector("[data-pc-dt-nav]");
    if (!nav) return;
    nav.setAttribute("href", url);
    nav.click();
  },
};

export default {
  PetalChart,
  PetalColorScheme,
  PetalLocalTime,
  PetalCarousel,
  PetalToast,
  PetalChatStream,
  PetalChatComposer,
  PetalCopy,
  PetalCodeCopy,
  PetalChatScroll,
  PetalPasswordToggle,
  PetalCopyInput,
  PetalClearableInput,
  PetalRangeFill,
  PetalDualRangeSlider,
  PetalNumberTicker,
  PetalConfetti,
  PetalSpotlight,
  PetalWordRotate,
  PetalTypingEffect,
  PetalInputOTP,
  PetalNumberField,
  PetalPopover,
  PetalCommand,
  PetalCommandTrigger,
  PetalAurora,
  PetalNavMenu,
  PetalCommandDialog,
  PetalComboBox,
  PetalDataTable,
};
