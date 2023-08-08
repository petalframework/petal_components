# Changelog
### 1.4.4 - 2023-08-08 02:02:15

- Fix: Icon button setting info to primary + test

### 1.4.3 - 2023-08-04 02:12:44

- input can now be passed a class attribute

### 1.4.2 - 2023-08-04 01:45:24

- Add option to send events in pagination component

### 1.4.1 - 2023-07-28 10:32:02

- Added support for styling last accordion item
- Added checked_value and unchecked_value to switch global rest

### 1.4.0 - 2023-07-26 03:14:50

- Updated accordion class name from "pc-accordion-item--last" to "pc-accordion-item--all-except-last"

### 1.3.0 - 2023-07-21 08:00:47

- New: <.vertical_menu> component
- New: <.user_dropdown_menu> component

### 1.2.14 - 2023-07-16 02:42:07

- Fix: Modal phx-remove call to hide_modal
- New: form fields now show a red asterisk for required fields

### 1.2.13 - 2023-06-30 03:32:59

- Updated: button can accept a "form" attribute

### 1.2.12 - 2023-06-26 23:24:23

- Improvement: file input looks better in dark mode

### 1.2.11 - 2023-06-07 00:18:05

- Fix: allow checkbox/radio labels to support links. eg. `<.field type="checkbox" field={@form[:checkbox]} label={raw(~s|Please accept these <a href="#" class="text-blue-500">Terms and Conditions</a> before continuing|)} />`

### 1.2.10 - 2023-06-05 02:06:55

- Bumped phoenix_live_view dep to 0.19

### 1.2.9 - 2023-06-01 02:35:12

- Updated: add empty_message attr to `<.field>` (`<.field type="checkbox-group|radio_group" empty_message="No options">`)
- Fixed: `<.field type="switch">` not providing a `false` value when unchecked

### 1.2.8 - 2023-05-27 05:03:40

- Add light button variant for dark mode friendliness

### 1.2.7 - 2023-05-27 03:34:33

- Fixed radio-group value not being checked for integers

### 1.2.6 - 2023-05-26 01:45:26

- Fix radio-group checked options for <.field>
- Fix select selected options

### 1.2.5 - 2023-05-20 00:34:56

- Fix: <.field type="textarea" rows="1"> - rows for textarea are now overridable

### 1.2.4 - 2023-05-17 04:38:50

- Fixed button with icon (reverted tooltip)

### 1.2.3 - 2023-05-17 03:52:29

- Updated: Move custom css classes to last so they can potentially override default ones (button, loading)
- Added: `tooltip` option to `<.button>`

### 1.2.2 - 2023-05-17 02:26:44

- Updated: checkbox_group now supports `disabled_options` attr

### 1.2.1 - 2023-05-16 02:56:56

- Fixed transitions on modal
- Updated `<.field>` to take a `label_class` attr

### 1.2.0 - 2023-05-11 10:15:53

- Breaking change: `<.field type="checkbox_group">` is now `<.field type="checkbox-group">` (to match `datetime-local`)
- Breaking change: `<.field type="radio_group">` is now `<.field type="radio-group">` (to match `datetime-local`)
- Fixed: radio group state
- Fixed: textarea height
- Fixed: CSS now conforms to tailwind config colors (eg. changing `danger` in tailwind config will now change the color of the `danger` button/alert/etc.)
- Fixed error CSS on textarea/select/switch

### 1.1.6 - 2023-05-09 10:20:42

- Fix <.field> checkbox_group not keeping state
- Changed <.field> textarea to be the same size as v1 form_field version

### 1.1.5 - 2023-05-08 23:07:33

- Fixed `class` attr not working in `<.field>` for types "select", "checkbox_group", "radio_group" and "textarea"
- Fixed <.card_footer> `class` attr not working

### 1.1.4 - 2023-05-06 04:46:08

- For consistency, the group_layout attr on <.field> should be a string like the type

### 1.1.3 - 2023-05-05 23:31:07

- Ensure help_text div isn't in DOM when no help text is provided

### 1.1.2 - 2023-05-05 23:18:10

- Added help_text to <.field>

### 1.1.1 - 2023-05-05 21:34:23

- Renamed .error to .field_error
- Renamed .label to .field_label

### 1.1.0 - 2023-05-05 04:45:56

- New: <.field> component to replace <.form_field>. <.field> takes the new `%Phoenix.HTML.FormField{}` struct, which better optimizes forms for live views
- New: <.input> component - these represent inputs but styled with Petal Components. It differs from <.field> in that you don't get a label or error messages.
- New: <.label> component - just a label styled with Petal Components. These are used inside a <.field>.
- New: <.error> component - an error message for form fields. These are used inside a <.field>.
- Updated: <.tab> can now take a class attr

### 1.0.8 - 2023-05-03 04:47:14

- Fix checkbox group issue introduced in 1.0.7

### 1.0.7 - 2023-04-27 08:16:41

- Fixed checkbox group giving an empty string instead of a list when submitted
- Added transitions to the icon button tooltip

### 1.0.6 - 2023-04-22 00:52:23

- New: Add `separator_class` option to `<.breadcrumb>`
- New: Add `tooltip` option to `<.icon_button>`

### 1.0.5 - 2023-04-03 09:33:31

- New: <.rating> component
- Fixed: error was showing prematurely on forms

### 1.0.4 - 2023-02-28 03:57:29

- Updated: Slideover now accepts a close target for when it is in a live_component
- Fixed: Disabled buttons and links should not do anything when clicked

### 1.0.3 - 2023-02-26 03:47:33

- Fixed: `hidden_input` not working correctly in `form_field`. Thanks @BobbieBarker!
- Fixed: `disabled` attribute wasn't working on non-button buttons (eg. a live_redirect)
- Fixed: Added alpine JS x-cloak hidden in CSS to avoid flash of unstyled content

### 1.0.2 - 2023-02-23 10:33:11

- Fixed: fixed an issue where phx-feedback-for was not being properly included inside of the form_field component (thanks @BobbieBarker)
- Update: Make paragraph text easier to read

### 1.0.1 - 2023-02-20 05:37:11

- Fixed issue "The `invalid-feedback` class does not exist" [#141]

### 1.0.0 - 2023-02-16 20:22:49

- Extracted classnames for each component into a CSS file using BEM naming convention. This allows for more flexibility in styling and theming.

### 0.19.10 - 2023-01-14 09:24:34

- Fixed: support button attrs: 'value', 'name'
- Fixed: support form element attr: 'accept'
- Fixed: support link attr: 'download'

### 0.19.9 - 2023-01-12 22:41:06

- Fix: <.th> can now accept colspan and rowspan

### 0.19.8 - 2023-01-12 00:37:24

- New: Button now can take an icon name as an attribute. eg `<.button icon={:home} label="Home" />`

### 0.19.7 - 2023-01-11 21:20:15

- Fixed disabled buttons

### 0.19.6 - 2023-01-01 22:18:07

- New: `<.hidden_input>` form element
- Added "list" attr warning for inputs
- Added "for" attr warning for label

### 0.19.5 - 2022-12-30 06:00:52

- Changed: form_help_text colours

### 0.19.4 - 2022-12-29 00:10:21

- New <.icon> functional component that renders a dynamic Heroicon (v2)
- Added label_class attr to all form inputs so you can change the look of labels
- Fixed "checked" attr for checkbox_group use with form_field

### 0.19.3 - 2022-12-22 02:42:17

- Added: help text for form fields
- Enhancement: <.td> can now accept colspan and rowspan attributes
- Enhancement: Added some optional textarea attributes: cols, rows and wrap
- Fixed: checkbox_group "checked" attr wasn't getting passed through
- Fixed: checkbox label wasn't working when no label attr was passed

### 0.19.2 - 2022-12-18 20:22:40

- Enhancement: Dropdowns are more customisable with classes
- Chore: Cleaned up form field attrs
- Fix: Changed the heading attr :no_margin to be a :boolean

### 0.19.1 - 2022-12-14 00:56:52

- Fixed form_field class attribute - it wasn't getting appended to the input classes properly

### 0.19.0 - 2022-12-13 05:11:47

- Added declarative assigns for all components
- Fix default green button having the wrong background

### 0.18.5 - 2022-10-06 02:04:15

- Fix compilation error on form.ex

### 0.18.4 - 2022-10-06 01:43:08

- Fixed compilation errors in accordion

### 0.18.3 - 2022-09-28 03:54:34

- Fix accordion icon not animating when opening

### 0.18.2 - 2022-09-28 00:38:14

- Add disabled classes for checkbox

### 0.18.1 - 2022-09-27 03:29:44

- HeroiconsV1 do not have default classes anymore
- Fix issue where `.icon_button` svg icons were not the correct size

### 0.18.0 - 2022-09-25 01:11:49

- Sorry, the last release was meant to be minor, not patch

### 0.17.8 - 2022-09-25 01:10:23

- Updated to work with Live View 0.18 - see UPGRADE_GUIDE.md
- Disabled fields fixed in dark mode - thanks @moogle19
- Pagination component can receive a function as a parameter that will define the path of the page - thanks @Wigny

Breaking changes

- `<.link>` was renamed to `<.a>`.
- Renamed `Heroicons` to `HeroiconsV1`

### 0.17.7 - 2022-08-10 00:34:26

- Fix 'modal' IDs used at SlideOver component
- Make accordion items dynamic
- Add coveralls + dependabot
- Remove credo from ci
- Add codecov token
- Add mix audit alias
- Add codecov badge
- Use string.replace to allow "-"
- Make borders for radio and checkbox consistent with other inputs
- Fixed pagination control if users set sibling_count to less than 1 or boundary_count less than 1
- Moved Pagination.get_items to PaginationInternal.get_pagination_items so we can get at it in the unit tests

### 0.17.6 - 2022-07-20 03:59:09

- Fixed issue where closing modal/slideover caused two events to be fired

### 0.17.5 - 2022-07-15 05:01:55

- Move card bg colors to the parent div

### 0.17.4 - 2022-07-15 04:09:17

- modified accordion aesthetic
- differentiated white inverted button type

### 0.17.2 - 2022-07-07 06:19:05

- Added an inverted button type that fills the outlined button on hover
- Added ring/border to card and table to add more distinction on white backgrounds
- Added a bg color and shadow to accordion

### 0.17.1 - 2022-07-06 01:05:09

- Modals - only send close_modal event to target if provided

### 0.17.0 - 2022-07-02 03:29:33

- New components: <.prose>, <.ul>, <.ol>
- Modals fade in (extra CSS required)
- Improve readability of card content in dark mode
- Extra assigns on <.p> are forwarded to the p tag
- Fix extra_assigns in headings
- Fix dropdown button not closing when clicked

### 0.16.0 - 2022-05-03 00:56:17

- Generate prettier classes with build_class
- Accordion
- Now use inline-block for icon buttons

### 0.15.0 - 2022-04-19 00:06:22

- Switch - new form component

### 0.14.0 - 2022-04-08 00:49:03

- Slide Over

### 0.13.7 - 2022-03-28 00:02:41

- Added info, warning and gray variants to buttons
- Added gray variant to progress
- Fixed progress test
- Form does not leak the class assign as it's already set from classes
- Made tabs text in dark mode lighter and changed assigns_to_attributes to be consistent with other components

### 0.13.6 - 2022-03-27 23:59:54

- Added info, warning and gray variants to buttons
- Added gray variant to progress
- Fixed progress test
- Form does not leak the class assign as it's already set from classes
- Made tabs text in dark mode lighter and changed assigns_to_attributes to be consistent with other components

### 0.13.5 - 2022-03-09 04:53:41

- Excluded label and sub_label in the user_inner_td
- Fixed pagination to work when less than 5 pages
- Fixed corners of red bg on file input error
- Removed prop references to size_class, rename size_class / css_class to :string
- Updated the heroicons generator to use "extra_assigns" instead of "extra_attributes"

### 0.13.4 - 2022-03-07 03:11:28

- Fixed table to accept extra attributes and updated table tests

### 0.13.3 - 2022-03-06 23:47:24

- added user_inner_td and fixed formatting where thead and tbody are required

### 0.13.2 - 2022-02-28 02:23:54

- added row layout to radio group

### 0.13.1 - 2022-02-25 20:17:55

- Fixed button type not working

### 0.13.0 - 2022-02-25 03:50:18

- Table

### 0.12.0 - 2022-02-22 21:25:39

- Icon buttons
- Made a link type button and refactored dropdown
- Removed negative margin on spinner
- Removed unnecessary underline statement in tabs

### 0.11.4 - 2022-02-21 00:52:06

- Removed excess class "border-transparent" from white button

### 0.11.3 - 2022-02-17 23:24:49

- Fixed bug with placeholder avatars

### 0.11.2 - 2022-02-16 05:40:24

- Fix issue where untouched inputs were highlighted red

### 0.11.1 - 2022-02-16 04:15:40

- Added object-cover to card_media

### 0.11.0 - 2022-02-15 22:00:59

- Heroicons.Solid icons size defaults to "w-5 h-5" as recommended in their docs
- Form inputs no longer show errors before they have been touched by the user. To get this to work, I had to remove the error classes off the inputs themselves, so they no longer turn red on error by default. However, you can turn this back on by adding these rules to your app.css file (we will update the install docs with this):

```
label.has-error:not(.phx-no-feedback) {
  @apply !text-red-900 dark:!text-red-200;
}

textarea.has-error:not(.phx-no-feedback), input.has-error:not(.phx-no-feedback), select.has-error:not(.phx-no-feedback) {
  @apply !border-red-500 focus:!border-red-500 !text-red-900 !placeholder-red-700 !bg-red-50 dark:!text-red-100 dark:!placeholder-red-300 dark:!bg-red-900;
}

input[type=file_input].has-error:not(.phx-no-feedback) {
  @apply !border-red-500 !rounded-md focus:!border-red-500 !text-red-900 !placeholder-red-700 !bg-red-50 file:!border-none dark:!border-none dark:!bg-[#160B0B] dark:text-red-400;
}

input[type=checkbox].has-error:not(.phx-no-feedback) {
  @apply !border-red-500 !text-red-900 dark:!text-red-200;
}

input[type=radio].has-error:not(.phx-no-feedback) {
  @apply !border-red-500;
}
```

### 0.10.8 - 2022-02-15 01:11:32

- Fixed <.a> emitting white spaces

### 0.10.7 - 2022-02-14 03:44:45

- Fixed white button background

### 0.10.6 - 2022-02-14 03:31:50

- Removed pure_white button shadow variant and fixed white bg for shadow

### 0.10.5 - 2022-02-11 22:30:21

- Fixed Heroicons sometimes failing

### 0.10.4 - 2022-02-10 19:49:47

- Fixed card_media not working properly on Safari

### 0.10.3 - 2022-02-03 01:18:38

- Added <.card_footer> for content you would like fixed to the bottom of a card
- Added `category_color_class` to <.card_content> so that you can customize category colors

### 0.10.2 - 2022-01-29 01:51:55

- <.h1>, <.h2> etc now turn into those underlying html elements (h1, h2 etc)
- <.card_media> utilises Tailwinds aspect-ratio classes
- Fix <.card> `class` assigns appearing twice

### 0.10.1 - 2022-01-26 04:02:41

- Buttons can now take custom classes

### 0.10.0 - 2022-01-26 01:18:58

- [BREAKING CHANGE] Rename alert property "state" to "color"
- Add checkbox_group form field type
- Fix z-index issue with dropdown
- Update Alert colors
- Add icons to badges

### 0.9.3 - 2022-01-19 19:28:35

- Fixed z-index issue with dropdowns

### 0.9.2 - 2022-01-19 05:33:26

- Fixed `<.dropdown_menu_item>` where extra_attributes weren't being passed to underlying button
- Fixed z-index issue on dropdowns

### 0.9.1 - 2022-01-19 02:55:17

- New form component `<.date_select ...>`
- New form component `<.date_input ...>`
- Add dark mode to components
- Fix dropdown failing when no label provided
- Fix dropdown button not having type=button
- Allow dropdown to have custom trigger buttons

### 0.9.0 - 2022-01-07 04:43:03

- New component: Card
- Button colored shadow option
- Improve styling on disabled inputs
- Allow custom attributes to be forwarded to underlying svg element on Heroicons

### 0.8.0 - 2021-12-15 20:17:41

- New component: Tabs
- Fix button that was failing when in a loading state and no size given
- Avatar now uses the `object-cover` class for non-square images
- New badge variations
- Badge can now accept a class prop

### 0.7.0 - 2021-12-07 03:54:41

- Breadcrumbs no longer need a parent flex container

### 0.6.1 - 2021-12-07 00:51:25

- Default the modal max_width to md

### 0.6.0 - 2021-12-07 00:14:21

- New component: `<.modal>`
- Fixed container not defaulting to full width when inside a flex
- Add docs for `<.p>` and heading params

### 0.5.1 - 2021-11-26 00:54:25

- `<.a>`, `<.button>` and `<.dropdown_menu_item>` all now take `method` as a parameter. eg. `<.a method={:delete} to="/logout" label="Logout" />`

### 0.5.0 - 2021-11-22 02:00:02

- Added `<.pagination>`
- Added `<.progress>`
- Improved `<.a>` to work as a live_patch or live_rediect

### 0.4.0 - 2021-11-18 02:18:16

- Added new form components ("email_input", "number_input", "password_input", "search_input", "telephone_input", "url_input", "time_input", "time_select", "datetime_local_input", "datetime_select", "color_input", "file_input", "range_input")
- `<.spinner>` defaults to visible

### 0.3.2 - 2021-11-15 02:50:45

- Add new component Avatar
- `<.form_field>` now shows errors from changesets

### 0.3.1 - 2021-11-09 07:36:13

- Added breadcrumbs components
- Removed unnecessary badge colors

### 0.3.0 - 2021-11-07 20:11:56

- import instead of alias the functions
- removed references to assigns in the HEEX templates to allow proper change tracking
- form functions like text_input now only create an input without the label
- added a `form_field` function that will include the label
- fixed the spinner on different button sizes
- removed alert sizing - stick with on size for now

### 0.2.2 - 2021-11-06 01:34:48

- Fixed Alert.alert not allowing wrapping
- Added heading parameter to Alert.alert

### 0.2.1 - 2021-11-04 22:45:38

- Updated dropdown to include live_patch and live_redirect

### 0.2.0 - 2021-11-04 06:43:01

- Added new component Alert
  - Added new component Loading
  - Added some tests
