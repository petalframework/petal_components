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
    this.el.addEventListener("click", () => {
      navigator.clipboard?.writeText(this.el.dataset.copyText || "");
      const label = this.el.querySelector("[data-pc-copy-label]");
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

export default { PetalChatStream, PetalChatComposer, PetalCopy, PetalCodeCopy, PetalChatScroll };
