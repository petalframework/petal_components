// PetalInputOTP hook: paste and the active slot. The markup here mirrors
// what PetalComponents.InputOtp renders - test/petal/input_otp_test.exs pins
// that structure on the Elixir side; update both together if it changes.
//
// jsdom never inserts pasted text and never applies maxlength, so these specs
// hold what the hook does with a paste event. A real browser cuts pasted text
// at maxlength before the input event fires, which is why the hook has to
// take the paste itself.
import { afterEach, describe, expect, it } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

function mount({
  length = 6,
  groupSize = null,
  value = "",
  pattern = "numeric",
} = {}) {
  const el = document.createElement("div");
  el.id = "pc-otp-code";
  el.className = "pc-otp";
  el.dataset.pattern = pattern;

  const size = groupSize || length;
  const groups = [];
  for (let start = 0; start < length; start += size) {
    const count = Math.min(size, length - start);
    const slots = Array.from(
      { length: count },
      () => `<div class="pc-otp__slot" data-pc-otp-slot></div>`,
    ).join("");
    if (start > 0) groups.push(`<div class="pc-otp__separator">-</div>`);
    groups.push(`<div class="pc-otp__group">${slots}</div>`);
  }

  el.innerHTML = `
    <input type="text" class="pc-otp__input" name="code" id="pc-otp-code-input"
      value="${value}" maxlength="${length}" data-pc-otp-input />
    <div class="pc-otp__slots" aria-hidden="true">${groups.join("")}</div>
  `;
  document.body.appendChild(el);

  const hook = Object.create(hooks.PetalInputOTP);
  hook.el = el;
  hook.mounted();
  mounted.push(el);

  const input = el.querySelector("input");
  const slotEls = () => Array.from(el.querySelectorAll("[data-pc-otp-slot]"));
  return { el, hook, input, slotEls };
}

function type(input, value) {
  input.value = value;
  input.dispatchEvent(new Event("input", { bubbles: true }));
}

// A paste event carrying clipboard text, the way a browser fires it.
function paste(input, text) {
  const ev = new Event("paste", { bubbles: true, cancelable: true });
  Object.defineProperty(ev, "clipboardData", {
    value: { getData: (type) => (type === "text" ? text : "") },
  });
  input.dispatchEvent(ev);
  return ev;
}

// Counts the input and petal:otp-complete events the field sends.
function listen(el, input) {
  const seen = { inputs: [], completes: [] };
  el.addEventListener("input", () => seen.inputs.push(input.value));
  el.addEventListener("petal:otp-complete", (e) =>
    seen.completes.push(e.detail.value),
  );
  return seen;
}

const active = (slotEls) =>
  slotEls()
    .map((s, i) => (s.classList.contains("pc-otp__slot--active") ? i : null))
    .filter((i) => i !== null);

afterEach(() => {
  mounted.splice(0).forEach((el) => el.remove());
});

describe("the active slot", () => {
  it("an empty focused field marks the first slot", () => {
    const { input, slotEls } = mount();
    input.focus();
    expect(active(slotEls)).toEqual([0]);
  });

  it("a half-filled focused field marks the next empty slot", () => {
    const { input, slotEls } = mount({ value: "123" });
    input.focus();
    expect(active(slotEls)).toEqual([3]);
  });

  it("a field filled by typing keeps the last slot marked, so focus still shows", () => {
    const { input, slotEls } = mount();
    input.focus();
    type(input, "123456");
    expect(active(slotEls)).toEqual([5]);
    expect(slotEls()[5].classList.contains("pc-otp__slot--filled")).toBe(true);
  });

  it("focus gained on a field already full from the server value marks the last slot", () => {
    const { input, slotEls } = mount({ value: "123456" });
    expect(active(slotEls)).toEqual([]);
    input.focus();
    expect(active(slotEls)).toEqual([5]);
  });

  it("with group_size 3 a full field marks the last slot of the last group", () => {
    const { el, input, slotEls } = mount({ groupSize: 3, value: "123456" });
    input.focus();
    expect(active(slotEls)).toEqual([5]);
    const lastGroup = el.querySelectorAll(".pc-otp__group")[1];
    expect(lastGroup.lastElementChild.classList).toContain(
      "pc-otp__slot--active",
    );
  });

  it("a length other than 6 marks its own last slot when full", () => {
    const { input, slotEls } = mount({ length: 4, value: "1234" });
    input.focus();
    expect(active(slotEls)).toEqual([3]);
  });

  it("a server value longer than the length clamps the mark to the last slot", () => {
    const { input, slotEls } = mount({ value: "1234567" });
    input.focus();
    expect(active(slotEls)).toEqual([5]);
  });

  it("deleting from a full field moves the mark to the emptied slot", () => {
    const { input, slotEls } = mount({ value: "123456" });
    input.focus();
    type(input, "12345");
    expect(active(slotEls)).toEqual([5]);
    expect(slotEls()[5].classList.contains("pc-otp__slot--filled")).toBe(false);
  });

  it("no slot is marked without focus, full or not", () => {
    const { input, slotEls } = mount({ value: "123456" });
    input.focus();
    input.blur();
    expect(active(slotEls)).toEqual([]);
  });
});

describe("paste", () => {
  const cases = [
    ["a space", "123 456", "123456"],
    ["a dash", "123-456", "123456"],
    ["newlines around it", "\n123456\n", "123456"],
    ["spaces and a tab around it", "  123456\t", "123456"],
    ["more digits than the length", "12345678", "123456"],
    ["letters mixed in", "a1b2c3d4e5f6g7", "123456"],
    ["full-width digits around it", "\uff11 123456 \uff12", "123456"],
  ];

  for (const [label, text, expected] of cases) {
    it(`keeps every digit of a code pasted with ${label}`, () => {
      const { input } = mount();
      input.focus();
      const ev = paste(input, text);
      expect(ev.defaultPrevented).toBe(true);
      expect(input.value).toBe(expected);
    });
  }

  it("fires one input event and one petal:otp-complete for a whole code", () => {
    const { el, input } = mount();
    const seen = listen(el, input);
    input.focus();
    paste(input, "123 456");
    expect(seen.inputs).toEqual(["123456"]);
    expect(seen.completes).toEqual(["123456"]);
  });

  it("a whole code pasted into a half-filled field replaces what was typed", () => {
    const { input } = mount({ value: "98" });
    input.focus();
    input.setSelectionRange(2, 2);
    paste(input, "123 456");
    expect(input.value).toBe("123456");
  });

  it("a different whole code pasted into a full field replaces it, once", () => {
    const { el, input } = mount({ value: "123456" });
    const seen = listen(el, input);
    input.focus();
    paste(input, "654 321");
    expect(input.value).toBe("654321");
    expect(seen.inputs).toEqual(["654321"]);
    expect(seen.completes).toEqual(["654321"]);
  });

  it("the same code pasted into a full field fires nothing", () => {
    const { el, input } = mount({ value: "123456" });
    const seen = listen(el, input);
    input.focus();
    const ev = paste(input, "123 456");
    expect(ev.defaultPrevented).toBe(true);
    expect(input.value).toBe("123456");
    expect(seen.inputs).toEqual([]);
    expect(seen.completes).toEqual([]);
  });

  it("a part code pasted into a half-filled field goes in at the caret", () => {
    const { el, input } = mount({ value: "12" });
    const seen = listen(el, input);
    input.focus();
    input.setSelectionRange(2, 2);
    paste(input, "34 5");
    expect(input.value).toBe("12345");
    expect(input.selectionStart).toBe(5);
    expect(seen.inputs).toEqual(["12345"]);
    expect(seen.completes).toEqual([]);
  });

  it("a part code replaces the selected digits", () => {
    const { input } = mount({ value: "129956" });
    input.focus();
    input.setSelectionRange(2, 4);
    paste(input, "3 4");
    expect(input.value).toBe("123456");
  });

  it("a paste of letters into a numeric field changes nothing and fires no input", () => {
    const { el, input } = mount({ value: "12" });
    const seen = listen(el, input);
    input.focus();
    input.setSelectionRange(2, 2);
    const ev = paste(input, "abcdef");
    expect(ev.defaultPrevented).toBe(true);
    expect(input.value).toBe("12");
    expect(seen.inputs).toEqual([]);
  });

  it("the slot count sets the cut for a length other than 6", () => {
    const { el, input } = mount({ length: 4 });
    const seen = listen(el, input);
    input.focus();
    paste(input, "12 34 56");
    expect(input.value).toBe("1234");
    expect(seen.completes).toEqual(["1234"]);
  });

  it("a grouped field (group_size 3) takes a whole code across both groups", () => {
    const { input, slotEls } = mount({ groupSize: 3 });
    input.focus();
    paste(input, "123-456");
    expect(input.value).toBe("123456");
    expect(slotEls().map((s) => s.textContent)).toEqual([
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
    ]);
  });

  it("alphanumeric keeps letters of either case and drops the separators", () => {
    const { input } = mount({ length: 6, pattern: "alphanumeric" });
    input.focus();
    paste(input, " aB-12 cD ");
    expect(input.value).toBe("aB12cD");
  });

  it("an empty clipboard leaves the browser alone", () => {
    const { input } = mount();
    input.focus();
    const ev = paste(input, "");
    expect(ev.defaultPrevented).toBe(false);
  });

  it("after a LiveView update a paste is still handled exactly once", () => {
    const { el, hook, input } = mount();
    hook.updated();
    hook.updated();
    const seen = listen(el, input);
    input.focus();
    input.setSelectionRange(0, 0);
    paste(input, "12");
    expect(input.value).toBe("12");
    expect(seen.inputs).toEqual(["12"]);
  });

  // The hook does not stop the event, so a paste listener of your own on an
  // ancestor still runs. One that writes the paste itself would insert a
  // part paste twice, which is why the changelog says to remove it.
  it("a paste listener on an ancestor still sees the event", () => {
    const { input } = mount();
    const seenByAncestor = [];
    const onPaste = (e) => seenByAncestor.push(e);
    document.body.addEventListener("paste", onPaste);
    try {
      input.focus();
      paste(input, "123 456");
      expect(seenByAncestor.length).toBe(1);
      expect(seenByAncestor[0].defaultPrevented).toBe(true);
    } finally {
      document.body.removeEventListener("paste", onPaste);
    }
  });
});
