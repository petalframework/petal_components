RELEASE_TYPE: patch

- Fix submenu keyboard focus: when a menu toggle is activated with Space or Enter, focus now moves to the first link inside the expanded submenu instead of staying on the toggle button. Matches the WAI-ARIA disclosure menu pattern. Affects both the Alpine.js and Phoenix.LiveView.JS variants.
