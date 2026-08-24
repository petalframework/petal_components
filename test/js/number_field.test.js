// PetalNumberField hook: stepping, clamping, the keyboard map, wheel and
// hold-to-repeat. The markup here mirrors what PetalComponents.NumberField
// renders - test/petal/number_field_test.exs pins that structure on the
// Elixir side; update both together if the anatomy changes.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import hooks, { numberFieldMath } from "../../assets/js/petal_components.js";

const mounted = [];

function mount({
  value = "",
  min,
  max,
  step,
  bigStep,
  precision,
  variant = "stacked",
  disabled = false,
  readOnly = false,
} = {}) {
  const el = document.createElement("div");
  el.id = "nf-field";
  el.className = `pc-input-group pc-number-field pc-number-field--${variant}`;
  if (min !== undefined) el.dataset.min = String(min);
  if (max !== undefined) el.dataset.max = String(max);
  if (step !== undefined) el.dataset.step = String(step);
  if (bigStep !== undefined) el.dataset.bigStep = String(bigStep);
  if (precision !== undefined) el.dataset.precision = String(precision);

  const buttons =
    variant === "plain"
      ? ""
      : `
        <button type="button" tabindex="-1" data-pc-number-step="dec" aria-label="Decrease value"></button>
        <button type="button" tabindex="-1" data-pc-number-step="inc" aria-label="Increase value"></button>
      `;

  el.innerHTML = `
    <div class="pc-input-group__row">
      <input type="text" inputmode="decimal" role="spinbutton" data-pc-number-input value="${value}" />
      ${buttons}
    </div>
  `;
  document.body.appendChild(el);

  const input = el.querySelector("[data-pc-number-input]");
  input.disabled = disabled;
  input.readOnly = readOnly;

  const hook = Object.create(hooks.PetalNumberField);
  hook.el = el;
  hook.mounted();
  mounted.push(hook);

  const inputEvents = [];
  input.addEventListener("input", () => inputEvents.push(input.value));

  return {
    hook,
    el,
    input,
    inputEvents,
    dec: el.querySelector("[data-pc-number-step=dec]"),
    inc: el.querySelector("[data-pc-number-step=inc]"),
  };
}

// jsdom has no PointerEvent constructor; a MouseEvent under the pointer name
// walks and quacks the same for addEventListener purposes.
function pointer(type, props = {}) {
  return new MouseEvent(type, { bubbles: true, cancelable: true, ...props });
}

function key(input, k, props = {}) {
  const ev = new KeyboardEvent("keydown", {
    key: k,
    bubbles: true,
    cancelable: true,
    ...props,
  });
  input.dispatchEvent(ev);
  return ev;
}

function wheel(input, deltaY) {
  const ev = new Event("wheel", { bubbles: true, cancelable: true });
  Object.defineProperty(ev, "deltaY", { value: deltaY });
  input.dispatchEvent(ev);
  return ev;
}

afterEach(() => {
  mounted.splice(0).forEach((hook) => hook.destroyed());
  document.body.innerHTML = "";
});

describe("numberFieldMath", () => {
  it("reads a number, and nothing else", () => {
    expect(numberFieldMath.parse("12")).toBe(12);
    expect(numberFieldMath.parse(" 12.5 ")).toBe(12.5);
    expect(numberFieldMath.parse("-3")).toBe(-3);
    expect(numberFieldMath.parse("")).toBe(null);
    expect(numberFieldMath.parse("   ")).toBe(null);
    expect(numberFieldMath.parse("abc")).toBe(null);
    expect(numberFieldMath.parse("12.")).toBe(12);
    expect(numberFieldMath.parse(null)).toBe(null);
    expect(numberFieldMath.parse(undefined)).toBe(null);
    expect(numberFieldMath.parse("Infinity")).toBe(null);
  });

  it("clamps against either bound, or neither", () => {
    expect(numberFieldMath.clamp(5, 1, 10)).toBe(5);
    expect(numberFieldMath.clamp(0, 1, 10)).toBe(1);
    expect(numberFieldMath.clamp(99, 1, 10)).toBe(10);
    expect(numberFieldMath.clamp(-99, null, null)).toBe(-99);
    expect(numberFieldMath.clamp(null, 1, 10)).toBe(null);
  });

  it("steps without float drift", () => {
    expect(numberFieldMath.add(0.1, 0.2)).toBe(0.3);
    expect(numberFieldMath.add(1.1, -0.1)).toBe(1);
    expect(numberFieldMath.add(24.5, 0.5)).toBe(25);
    expect(numberFieldMath.add(3, 1)).toBe(4);
  });

  it("formats to precision, or leaves the number alone", () => {
    expect(numberFieldMath.format(24.5, 2)).toBe("24.50");
    expect(numberFieldMath.format(24.567, 2)).toBe("24.57");
    expect(numberFieldMath.format(24.5, 0)).toBe("25");
    expect(numberFieldMath.format(24.5, null)).toBe("24.5");
    expect(numberFieldMath.format(null, 2)).toBe("");
  });
});

describe("PetalNumberField keyboard", () => {
  it("arrows step by step and preventDefault so the caret stays put", () => {
    const { input } = mount({ value: "5", step: 1 });

    const up = key(input, "ArrowUp");
    expect(input.value).toBe("6");
    expect(up.defaultPrevented).toBe(true);

    key(input, "ArrowDown");
    key(input, "ArrowDown");
    expect(input.value).toBe("4");
  });

  it("shift+arrow steps by big_step, defaulting to ten steps", () => {
    const { input } = mount({ value: "5", step: 0.5 });

    key(input, "ArrowUp", { shiftKey: true });
    expect(input.value).toBe("10");

    key(input, "ArrowDown", { shiftKey: true });
    expect(input.value).toBe("5");
  });

  it("an explicit big_step wins", () => {
    const { input } = mount({ value: "25", step: 5, bigStep: 25 });

    key(input, "ArrowUp", { shiftKey: true });
    expect(input.value).toBe("50");
  });

  it("page up and page down step by big_step without shift", () => {
    const { input } = mount({ value: "0", step: 1, bigStep: 100 });

    key(input, "PageUp");
    expect(input.value).toBe("100");
    key(input, "PageDown");
    expect(input.value).toBe("0");
  });

  it("home and end jump to the bounds", () => {
    const { input } = mount({ value: "5", min: 1, max: 99 });

    key(input, "End");
    expect(input.value).toBe("99");
    key(input, "Home");
    expect(input.value).toBe("1");
  });

  it("home and end do nothing when that bound is unset", () => {
    const { input } = mount({ value: "5" });

    const home = key(input, "Home");
    expect(input.value).toBe("5");
    expect(home.defaultPrevented).toBe(false);
  });

  it("a readonly input ignores every keyboard write, including home and end", () => {
    // readonly inputs still receive keydown (unlike disabled), and Home/End
    // write() directly - the guard has to live in handleKeydown itself
    const { input } = mount({ value: "5", min: 1, max: 99, readOnly: true });

    key(input, "Home");
    key(input, "End");
    key(input, "ArrowUp");
    expect(input.value).toBe("5");
  });

  it("a hold on a readonly control never starts the repeat timer", () => {
    const { input, inc, hook } = mount({ value: "5", min: 1, max: 99, readOnly: true });

    inc.dispatchEvent(pointer("pointerdown"));
    expect(input.value).toBe("5");
    expect(hook.repeatTimer).toBeFalsy();
  });

  it("a plain character keystroke is left to the browser", () => {
    const { input } = mount({ value: "5" });

    const ev = key(input, "7");
    expect(ev.defaultPrevented).toBe(false);
    expect(input.value).toBe("5");
  });

  it("stepping steps to no further than the bounds", () => {
    const { input } = mount({ value: "9", min: 0, max: 10, step: 5 });

    key(input, "ArrowUp");
    expect(input.value).toBe("10");
    key(input, "ArrowUp");
    expect(input.value).toBe("10");
  });

  it("an empty field starts from the lower bound", () => {
    const { input } = mount({ value: "", min: 1, max: 99 });

    key(input, "ArrowUp");
    expect(input.value).toBe("1");
  });

  it("an empty and unbounded field starts from zero", () => {
    const { input } = mount({ value: "", step: 1 });

    key(input, "ArrowDown");
    expect(input.value).toBe("0");
  });

  it("steps decimals cleanly", () => {
    const { input } = mount({ value: "0.1", step: 0.2 });

    key(input, "ArrowUp");
    expect(input.value).toBe("0.3");
  });

  it("stepping formats to precision", () => {
    const { input } = mount({ value: "24.5", step: 0.5, precision: 2 });

    key(input, "ArrowUp");
    expect(input.value).toBe("25.00");
  });

  it("does nothing when disabled or readonly", () => {
    const disabled = mount({ value: "5", disabled: true });
    key(disabled.input, "ArrowUp");
    expect(disabled.input.value).toBe("5");

    const readonly = mount({ value: "5", readOnly: true });
    key(readonly.input, "ArrowUp");
    expect(readonly.input.value).toBe("5");
  });

  it("dispatches an input event so phx-change fires", () => {
    const { input, inputEvents } = mount({ value: "5" });

    key(input, "ArrowUp");
    expect(inputEvents).toEqual(["6"]);
  });

  it("does not re-dispatch when the value could not move", () => {
    const { input, inputEvents } = mount({ value: "10", max: 10 });

    key(input, "ArrowUp");
    expect(input.value).toBe("10");
    expect(inputEvents).toEqual([]);
  });
});

describe("PetalNumberField wheel", () => {
  it("steps while focused and stops the page scrolling underneath", () => {
    const { input } = mount({ value: "5", step: 1 });
    input.focus();

    const up = wheel(input, -100);
    expect(input.value).toBe("6");
    expect(up.defaultPrevented).toBe(true);

    wheel(input, 100);
    expect(input.value).toBe("5");
  });

  it("ignores the wheel when the input is not focused", () => {
    const { input } = mount({ value: "5" });
    input.blur();

    const ev = wheel(input, -100);
    expect(input.value).toBe("5");
    expect(ev.defaultPrevented).toBe(false);
  });
});

describe("PetalNumberField blur", () => {
  it("clamps typed text on blur, never mid-keystroke", () => {
    const { input } = mount({ value: "", min: 1, max: 99 });
    input.focus();

    input.value = "1";
    input.dispatchEvent(new Event("input", { bubbles: true }));
    expect(input.value).toBe("1");

    input.value = "150";
    input.dispatchEvent(new Event("input", { bubbles: true }));
    expect(input.value).toBe("150");

    input.dispatchEvent(new Event("blur"));
    expect(input.value).toBe("99");
  });

  it("formats to precision on blur", () => {
    const { input } = mount({ value: "", precision: 2 });

    input.value = "3.5";
    input.dispatchEvent(new Event("blur"));
    expect(input.value).toBe("3.50");
  });

  it("leaves an empty field empty", () => {
    const { input } = mount({ value: "", min: 1, precision: 2 });

    input.dispatchEvent(new Event("blur"));
    expect(input.value).toBe("");
  });

  it("leaves text that is not a number for the server to reject", () => {
    const { input } = mount({ value: "" });

    input.value = "abc";
    input.dispatchEvent(new Event("blur"));
    expect(input.value).toBe("abc");
  });

  it("fires the synthetic change only when the clamp rewrote the value", () => {
    // in-range typed input gets the browser's own native change on blur;
    // a synthetic one on top doubled every change handler
    const { input } = mount({ value: "", min: 1, max: 99 });
    const changes = [];
    input.addEventListener("change", () => changes.push(input.value));

    input.value = "50";
    input.dispatchEvent(new Event("blur"));
    expect(changes).toEqual([]);

    input.value = "150";
    input.dispatchEvent(new Event("blur"));
    expect(changes).toEqual(["99"]);
  });
});

describe("PetalNumberField buttons", () => {
  it("a press steps once in each direction", () => {
    const { input, inc, dec } = mount({ value: "5", step: 1 });

    inc.dispatchEvent(pointer("pointerdown"));
    inc.dispatchEvent(pointer("pointerup"));
    expect(input.value).toBe("6");

    dec.dispatchEvent(pointer("pointerdown"));
    dec.dispatchEvent(pointer("pointerup"));
    expect(input.value).toBe("5");
  });

  it("a touch press steps without dragging focus into the input", () => {
    // On iOS, focusing the input summons the software keyboard - a stepper
    // tap must not (React Aria's split). Mouse keeps the focus so arrows
    // and the wheel work right after a click; touch with the input ALREADY
    // focused keeps it (preventDefault holds the keyboard up).
    const { input, inc } = mount({ value: "5", step: 1 });

    const touch = pointer("pointerdown");
    Object.defineProperty(touch, "pointerType", { value: "touch" });
    inc.dispatchEvent(touch);
    inc.dispatchEvent(pointer("pointerup"));
    expect(input.value).toBe("6");
    expect(document.activeElement).not.toBe(input);

    inc.dispatchEvent(pointer("pointerdown"));
    inc.dispatchEvent(pointer("pointerup"));
    expect(input.value).toBe("7");
    expect(document.activeElement).toBe(input);

    const touch2 = pointer("pointerdown");
    Object.defineProperty(touch2, "pointerType", { value: "touch" });
    inc.dispatchEvent(touch2);
    inc.dispatchEvent(pointer("pointerup"));
    expect(input.value).toBe("8");
    expect(document.activeElement).toBe(input);
  });

  it("a right-click is not a step", () => {
    const { input, inc } = mount({ value: "5" });

    inc.dispatchEvent(pointer("pointerdown", { button: 2 }));
    expect(input.value).toBe("5");
  });

  it("a button at its bound does nothing", () => {
    const { input, inc } = mount({ value: "10", max: 10 });

    expect(inc.getAttribute("aria-disabled")).toBe("true");
    inc.dispatchEvent(pointer("pointerdown"));
    expect(input.value).toBe("10");
  });

  it("a disabled button does nothing", () => {
    const { input, inc } = mount({ value: "5", disabled: true });
    inc.disabled = true;

    inc.dispatchEvent(pointer("pointerdown"));
    expect(input.value).toBe("5");
  });

  it("plain renders no buttons and the hook survives it", () => {
    const { el, input } = mount({ value: "5", variant: "plain" });

    expect(el.querySelectorAll("[data-pc-number-step]").length).toBe(0);
    key(input, "ArrowUp");
    expect(input.value).toBe("6");
  });
});

describe("PetalNumberField hold to repeat", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("holds, pauses, then repeats and accelerates", () => {
    const { input, inc } = mount({ value: "0", step: 1 });

    inc.dispatchEvent(pointer("pointerdown"));
    expect(input.value).toBe("1");

    // nothing until the initial delay is served
    vi.advanceTimersByTime(399);
    expect(input.value).toBe("1");

    vi.advanceTimersByTime(1);
    expect(input.value).toBe("2");

    vi.advanceTimersByTime(1000);
    expect(Number(input.value)).toBeGreaterThan(8);
  });

  it("stops on pointerup", () => {
    const { input, inc } = mount({ value: "0", step: 1 });

    inc.dispatchEvent(pointer("pointerdown"));
    inc.dispatchEvent(pointer("pointerup"));
    vi.advanceTimersByTime(2000);
    expect(input.value).toBe("1");
  });

  it("stops when the pointer slides off the button", () => {
    const { input, inc } = mount({ value: "0", step: 1 });

    inc.dispatchEvent(pointer("pointerdown"));
    inc.dispatchEvent(pointer("pointerleave"));
    vi.advanceTimersByTime(2000);
    expect(input.value).toBe("1");
  });

  it("stops on pointercancel", () => {
    const { input, dec } = mount({ value: "9", step: 1 });

    dec.dispatchEvent(pointer("pointerdown"));
    dec.dispatchEvent(pointer("pointercancel"));
    vi.advanceTimersByTime(2000);
    expect(input.value).toBe("8");
  });

  it("stops itself at a bound instead of spinning forever", () => {
    const { input, inc } = mount({ value: "0", max: 3, step: 1 });

    inc.dispatchEvent(pointer("pointerdown"));
    vi.advanceTimersByTime(5000);
    expect(input.value).toBe("3");
  });
});

describe("PetalNumberField aria", () => {
  it("keeps aria-valuenow in step with the value", () => {
    const { input } = mount({ value: "5" });

    expect(input.getAttribute("aria-valuenow")).toBe("5");
    key(input, "ArrowUp");
    expect(input.getAttribute("aria-valuenow")).toBe("6");

    input.value = "";
    input.dispatchEvent(new Event("input", { bubbles: true }));
    expect(input.hasAttribute("aria-valuenow")).toBe(false);
  });

  it("marks the button at its bound aria-disabled, and unmarks it on the way back", () => {
    const { input, inc, dec } = mount({ value: "9", min: 0, max: 10, step: 1 });

    expect(inc.hasAttribute("aria-disabled")).toBe(false);

    key(input, "ArrowUp");
    expect(inc.getAttribute("aria-disabled")).toBe("true");
    expect(dec.hasAttribute("aria-disabled")).toBe(false);

    key(input, "ArrowDown");
    expect(inc.hasAttribute("aria-disabled")).toBe(false);
  });

  it("re-syncs after a LiveView patch", () => {
    const { hook, input, inc } = mount({ value: "5", max: 10 });

    input.value = "10";
    hook.updated();

    expect(input.getAttribute("aria-valuenow")).toBe("10");
    expect(inc.getAttribute("aria-disabled")).toBe("true");
  });
});
