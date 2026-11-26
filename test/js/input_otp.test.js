// PetalInputOTP hook: the active slot. The markup here mirrors what
// PetalComponents.InputOtp renders - test/petal/input_otp_test.exs pins that
// structure on the Elixir side; update both together if it changes.
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
