// The put_flash bridge, with and without a connected LiveView.
//
// The bug this pins (seen in the Petal Pro 4.5 browser walk): processFlash
// always pushed lv:clear-flash. On a controller-rendered page the hook runs
// in LiveView's dead view, which has no channel, so the push rejected and
// the browser logged "Uncaught (in promise) Error: unable to push hook
// event. LiveView not connected". The toast still rendered; the uncaught
// rejection was the bug. A connected LiveView must still get the push, or
// the next patch toasts the same flash again.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { mountGroup, teardownGroups } from "./helpers.js";

const DURATION = 5000; // hook default
const REMOVE_FALLBACK = 400; // dismiss() safety timeout (no transitions in jsdom)

// ViewHook.pushEvent as LiveView 1.1+ implements it (view_hook.ts): the push
// rejects when the hook's view has no joined channel. Without a reply
// callback the rejection goes back to the caller; with one, LiveView
// swallows it.
const liveViewPushEvent = (hook, viewConnected) => (event, payload, onReply) => {
  hook.pushed.push([event, payload]);
  const push = viewConnected
    ? Promise.resolve({ reply: {}, ref: 1 })
    : Promise.reject(new Error("unable to push hook event. LiveView not connected"));
  if (onReply === undefined) return push.then(({ reply }) => reply);
  push.then(({ reply, ref }) => onReply(reply, ref)).catch(() => {});
};

// A controller-rendered page: LiveView never opens the socket.
const deadPage = (hook) => {
  hook.liveSocket = { isConnected: () => false };
  hook.pushEvent = liveViewPushEvent(hook, false);
};

// A group outside a LiveView's container on a live page (in the root
// layout, say): the socket is up, but the group belongs to the dead view.
const deadViewOnLivePage = (hook) => {
  hook.liveSocket = { isConnected: () => true };
  hook.pushEvent = liveViewPushEvent(hook, false);
};

const liveView = (hook) => {
  hook.liveSocket = { isConnected: () => true };
  hook.pushEvent = liveViewPushEvent(hook, true);
};

// Node reports an unhandled rejection once the microtask queue drains, so
// give it a real macrotask turn before asserting there was none.
const settle = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("PetalToast put_flash bridge", () => {
  let rejections;
  const onRejection = (reason) => rejections.push(reason);

  beforeEach(() => {
    document.body.innerHTML = "";
    rejections = [];
    process.on("unhandledRejection", onRejection);
  });

  afterEach(() => {
    teardownGroups();
    vi.useRealTimers();
    process.off("unhandledRejection", onRejection);
  });

  it("toasts a flash on a dead page without pushing or rejecting", async () => {
    const g = mountGroup("flash_group", { flash: { info: "Signed out" }, setup: deadPage });

    expect(g.toastEls()).toHaveLength(1);
    expect(g.toastEls()[0].textContent).toContain("Signed out");
    expect(g.pushed).toEqual([]);

    await settle();
    expect(rejections).toEqual([]);
  });

  it("auto-dismisses a flash on a dead page", () => {
    vi.useFakeTimers();
    const g = mountGroup("flash_group", { flash: { error: "Link expired" }, setup: deadPage });
    expect(g.toastEls()).toHaveLength(1);

    vi.advanceTimersByTime(DURATION + REMOVE_FALLBACK + 100);

    expect(g.toastEls()).toHaveLength(0);
  });

  it("swallows the rejection when the socket is up but the group is in the dead view", async () => {
    const g = mountGroup("flash_group", {
      flash: { info: "Welcome back" },
      setup: deadViewOnLivePage,
    });

    expect(g.toastEls()).toHaveLength(1);

    await settle();
    expect(rejections).toEqual([]);
  });

  it("still pushes lv:clear-flash for each key on a connected LiveView", async () => {
    const g = mountGroup("flash_group", {
      flash: { info: "Saved", error: "Card declined" },
      setup: liveView,
    });

    expect(g.toastEls()).toHaveLength(2);
    expect(g.pushed).toEqual([
      ["lv:clear-flash", { key: "info" }],
      ["lv:clear-flash", { key: "error" }],
    ]);

    await settle();
    expect(rejections).toEqual([]);
  });
});
