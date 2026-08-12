// PetalSlider hook: the live half of <.slider>.
//
// The server already renders correct geometry, so every spec here is about
// what only the client can know - where the thumb has been dragged to. That
// splits three ways: the percentage custom properties the CSS reads, the
// ordering invariant two overlaid native inputs cannot enforce themselves,
// and the petal:slider-change event an app listens to without a form.
import { afterEach, describe, expect, it } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

function mount({
  mode = "single",
  min = 0,
  max = 100,
  value = 50,
  values = [20, 80],
  prefix = "",
  suffix = "",
  display = false,
  marks = [],
} = {}) {
  const wrap = document.createElement("div");

  const inputs =
    mode === "dual"
      ? `<input type="range" data-pc-slider-input-min min="${min}" max="${max}" value="${values[0]}" />
         <input type="range" data-pc-slider-input-max min="${min}" max="${max}" value="${values[1]}" />`
      : `<input type="range" data-pc-slider-input min="${min}" max="${max}" value="${value}" />`;

  const markEls = marks
    .map(
      (p) =>
        `<span class="pc-slider__mark" data-pc-slider-mark="${p}"></span>`,
    )
    .join("");

  wrap.innerHTML = `
    <div id="s" class="pc-slider"
         data-pc-slider-mode="${mode}"
         data-pc-slider-min="${min}"
         data-pc-slider-max="${max}"
         data-value-prefix="${prefix}"
         data-value-suffix="${suffix}">
      ${inputs}
      ${markEls}
      ${display ? '<span data-pc-slider-display></span>' : ""}
    </div>
  `;
  document.body.appendChild(wrap);

  const el = wrap.querySelector("#s");
  const hook = Object.create(hooks.PetalSlider);
  hook.el = el;

  const events = [];
  el.addEventListener("petal:slider-change", (e) => events.push(e));

  hook.mounted();
  mounted.push({ hook, wrap });
  return { hook, el, events, wrap };
}

function fire(input) {
  input.dispatchEvent(new Event("input", { bubbles: true }));
}

afterEach(() => {
  mounted.splice(0).forEach(({ hook, wrap }) => {
    hook.destroyed();
    wrap.remove();
  });
});

describe("PetalSlider single", () => {
  it("sets --pc-slider-pct from the value on mount", () => {
    const { el } = mount({ value: 25 });
    expect(el.style.getPropertyValue("--pc-slider-pct")).toBe("25%");
  });

  it("computes the percentage against the declared bounds", () => {
    const { el } = mount({ min: 1990, max: 2030, value: 2010 });
    expect(el.style.getPropertyValue("--pc-slider-pct")).toBe("50%");
  });

  it("re-syncs the percentage as the thumb moves", () => {
    const { el } = mount({ value: 10 });
    const input = el.querySelector("[data-pc-slider-input]");
    input.value = "90";
    fire(input);
    expect(el.style.getPropertyValue("--pc-slider-pct")).toBe("90%");
  });

  it("clamps the painted percentage when a value escapes the bounds", () => {
    const { el } = mount({ value: 50 });
    const input = el.querySelector("[data-pc-slider-input]");
    // jsdom does not clamp input.value the way a browser does.
    input.value = "500";
    fire(input);
    expect(el.style.getPropertyValue("--pc-slider-pct")).toBe("100%");
  });

  it("paints 0% rather than dividing by zero on a collapsed range", () => {
    const { el } = mount({ min: 5, max: 5, value: 5 });
    expect(el.style.getPropertyValue("--pc-slider-pct")).toBe("0%");
  });

  it("writes the formatted readout with prefix and suffix", () => {
    const { el } = mount({ value: 40, prefix: "$", suffix: "k", display: true });
    expect(el.querySelector("[data-pc-slider-display]").textContent).toBe("$40k");
  });

  it("strips trailing zeros from the readout", () => {
    const { el } = mount({ value: 50, display: true });
    const input = el.querySelector("[data-pc-slider-input]");
    input.value = "50.0";
    fire(input);
    expect(el.querySelector("[data-pc-slider-display]").textContent).toBe("50");
  });

  it("emits petal:slider-change with the value, bubbling", () => {
    const { el, events } = mount({ value: 10 });
    const input = el.querySelector("[data-pc-slider-input]");
    input.value = "70";
    fire(input);

    const last = events[events.length - 1];
    expect(last.detail).toEqual({ value: 70 });
    expect(last.bubbles).toBe(true);
  });

  it("toggles the filled treatment on marks the fill has swallowed", () => {
    const { el } = mount({ value: 50, marks: [25, 75] });
    const [low, high] = el.querySelectorAll(".pc-slider__mark");
    expect(low.classList.contains("pc-slider__mark--filled")).toBe(true);
    expect(high.classList.contains("pc-slider__mark--filled")).toBe(false);

    const input = el.querySelector("[data-pc-slider-input]");
    input.value = "80";
    fire(input);
    expect(high.classList.contains("pc-slider__mark--filled")).toBe(true);
  });

  it("stops listening once destroyed", () => {
    const { hook, el, events } = mount({ value: 10 });
    const input = el.querySelector("[data-pc-slider-input]");
    hook.destroyed();
    const before = events.length;
    input.value = "70";
    fire(input);
    expect(events.length).toBe(before);
    mounted.length = 0;
  });
});

describe("PetalSlider dual", () => {
  it("sets both percentage properties on mount", () => {
    const { el } = mount({ mode: "dual", values: [20, 80] });
    expect(el.style.getPropertyValue("--pc-slider-pct-min")).toBe("20%");
    expect(el.style.getPropertyValue("--pc-slider-pct-max")).toBe("80%");
  });

  it("clamps the lower thumb to the upper one when dragged past it", () => {
    const { el } = mount({ mode: "dual", values: [20, 60] });
    const minInput = el.querySelector("[data-pc-slider-input-min]");
    minInput.value = "90";
    fire(minInput);

    expect(minInput.value).toBe("60");
    expect(el.style.getPropertyValue("--pc-slider-pct-min")).toBe("60%");
  });

  it("clamps the upper thumb to the lower one when dragged past it", () => {
    const { el } = mount({ mode: "dual", values: [40, 80] });
    const maxInput = el.querySelector("[data-pc-slider-input-max]");
    maxInput.value = "10";
    fire(maxInput);

    expect(maxInput.value).toBe("40");
    expect(el.style.getPropertyValue("--pc-slider-pct-max")).toBe("40%");
  });

  it("lifts the dragged thumb when the two meet, so it can be dragged back out", () => {
    const { el } = mount({ mode: "dual", values: [20, 60] });
    const minInput = el.querySelector("[data-pc-slider-input-min]");
    const maxInput = el.querySelector("[data-pc-slider-input-max]");

    minInput.value = "60";
    fire(minInput);
    expect(minInput.style.zIndex).toBe("20");
    expect(maxInput.style.zIndex).toBe("");

    // Now drag the other one: the lift follows whichever thumb is moving.
    maxInput.value = "60";
    fire(maxInput);
    expect(maxInput.style.zIndex).toBe("20");
    expect(minInput.style.zIndex).toBe("");
  });

  it("drops the lift once the thumbs separate again", () => {
    const { el } = mount({ mode: "dual", values: [60, 60] });
    const minInput = el.querySelector("[data-pc-slider-input-min]");
    minInput.value = "20";
    fire(minInput);
    expect(minInput.style.zIndex).toBe("");
  });

  it("writes a min to max readout", () => {
    const { el } = mount({
      mode: "dual",
      values: [100, 600],
      max: 1000,
      prefix: "$",
      display: true,
    });
    expect(el.querySelector("[data-pc-slider-display]").textContent).toBe("$100 – $600");
  });

  it("emits petal:slider-change with both values", () => {
    const { el, events } = mount({ mode: "dual", values: [20, 80] });
    const maxInput = el.querySelector("[data-pc-slider-input-max]");
    maxInput.value = "70";
    fire(maxInput);

    expect(events[events.length - 1].detail).toEqual({ values: [20, 70] });
  });

  it("marks between the thumbs are filled, marks outside are not", () => {
    const { el } = mount({ mode: "dual", values: [30, 70], marks: [10, 50, 90] });
    const [a, b, c] = el.querySelectorAll(".pc-slider__mark");
    expect(a.classList.contains("pc-slider__mark--filled")).toBe(false);
    expect(b.classList.contains("pc-slider__mark--filled")).toBe(true);
    expect(c.classList.contains("pc-slider__mark--filled")).toBe(false);
  });
});
