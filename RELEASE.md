RELEASE_TYPE: minor

- Added smooth transitions and easing to interactive components (buttons, tabs, accordion, dropdown, table rows, pagination, menu items, checkboxes, file inputs, alert dismiss)
- Added focus-visible ring to buttons for keyboard accessibility
- Added active press scale feedback on buttons
- Fixed dropdown not working with Alpine.js 3.13.6+ (#379) — removed conflicting `@click.outside` on button, added initial `display: none` style for proper `x-show` initialization
- Fixed accordion state being wiped on LiveView DOM patches (#381, #323) — added `phx-update="ignore"` to LV.JS accordion container, rewrote Alpine accordion to use direct `active` state instead of nested getter/setter pattern that broke with Alpine 3.13+
- Added `multiple` attribute to accordion for expanding multiple sections simultaneously (#38) — works with both Alpine.js and LiveView.JS
- Fixed pagination prev/next arrows not wrapped in `<li>` elements (#391) — invalid HTML per spec
- Fixed multiple select field errors not showing when no option is selected (#439) — added hidden input to ensure `used_input?` returns true
- Added `copy_icon` and `copied_icon` attributes to copyable field (#474) — allows custom icon names instead of hardcoded clipboard icons
