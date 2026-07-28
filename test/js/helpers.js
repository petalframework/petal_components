// Shared harness for hook specs: a minimal stand-in for the LiveView hook
// lifecycle - enough of `this` for mounted()/destroyed() to run, capturing
// the handleEvent callbacks so a spec can fan an event out to every group
// the way LiveView does.
import { PetalToast } from "../../assets/js/petal_components.js";

// Ownership is module-level state, so a spec that leaves a group mounted
// would own the page for every spec after it. Track and tear down the way
// LiveView does.
const mounted = [];

export function mountGroup(id) {
  const el = document.createElement("div");
  el.id = id;
  el.className = "pc-toast-group";
  const stack = document.createElement("div");
  stack.id = `${id}-stack`;
  stack.className = "pc-toast-group__stack";
  el.appendChild(stack);
  document.body.appendChild(el);

  const hook = Object.create(PetalToast);
  hook.el = el;
  hook.handlers = {};
  hook.pushed = [];
  hook.handleEvent = (name, cb) => {
    hook.handlers[name] = cb;
  };
  hook.pushEvent = (name, payload) => hook.pushed.push([name, payload]);
  hook.mounted();

  hook.stackEl = stack;
  hook.toastEls = () => stack.querySelectorAll(".pc-toast");
  mounted.push(hook);
  return hook;
}

export function teardownGroups() {
  mounted.splice(0).forEach((hook) => hook.destroyed());
}

// LiveView delivers a push_event to every mounted hook, not just one.
export const fanOutServerToast = (groups, payload) =>
  groups.forEach((g) => g.handlers["petal:toast"](payload));

// jsdom has no PointerEvent constructor; a MouseEvent with pointerType and
// pointerId defined on it walks and quacks the same for addEventListener
// purposes. (MouseEvent's init dict silently drops unknown keys, so
// pointerId must be attached by hand.)
export function pointerEvent(type, pointerType, props = {}) {
  const { pointerId = 1, ...mouseProps } = props;
  const ev = new MouseEvent(type, { bubbles: true, ...mouseProps });
  Object.defineProperty(ev, "pointerType", { value: pointerType });
  Object.defineProperty(ev, "pointerId", { value: pointerId });
  return ev;
}
