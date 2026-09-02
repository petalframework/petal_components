# Component inventory - petal_components v4.16.1

GENERATED from data/schemas.json - do not hand-edit. Regenerated each release
by `mix petal.gen.skill_snapshot`, alongside the MCP schema sync.

One line per public function component, grouped by module - use this to PICK a
component. To USE one, resolve its full schema via the MCP ladder in SKILL.md
(MCP -> data/schemas.json -> deps source); never write attrs from memory.
Function names have NO pc_ prefix; pc- is the CSS class prefix only.

## Accordion
- `<.accordion>` - 9 attrs, 1 slots · required slots: item

## Alert
- `<.alert>` - 10 attrs, 2 slots

## AlertDialog
- `<.alert_dialog>` - 10 attrs, 3 slots · required: id, title

## Aurora
- `<.aurora>` - 10 attrs, 1 slots

## Avatar
- `<.avatar>` - 12 attrs, 0 slots
- `<.avatar_group>` - 6 attrs, 0 slots

## Badge
- `<.badge>` - 10 attrs, 1 slots

## BorderBeam
- `<.border_beam>` - 14 attrs, 1 slots · required slots: inner_block

## BorderPlasma
- `<.border_plasma>` - 11 attrs, 1 slots · required slots: inner_block

## BrandIcon
- `<.brand_icon>` - 4 attrs, 0 slots · required: name

## Breadcrumbs
- `<.breadcrumbs>` - 7 attrs, 0 slots

## Button
- `<.button>` - 14 attrs, 1 slots
- `<.icon_button>` - 11 attrs, 1 slots

## ButtonGroup
- `<.button_group>` - 9 attrs, 2 slots · required: aria_label
- `<.button_group_separator>` - 1 attrs, 0 slots
- `<.button_group_text>` - 2 attrs, 1 slots · required slots: inner_block

## Calendar
- `<.calendar>` - 24 attrs, 1 slots

## Card
- `<.card>` - 3 attrs, 1 slots
- `<.card_content>` - 5 attrs, 1 slots
- `<.card_footer>` - 2 attrs, 1 slots
- `<.card_header>` - 4 attrs, 2 slots
- `<.card_media>` - 5 attrs, 1 slots
- `<.review_card>` - 6 attrs, 0 slots · required: body, name, username

## Carousel
- `<.carousel>` - 26 attrs, 1 slots · required slots: slide

## Chart
- `<.chart>` - 8 attrs, 0 slots · required: id, option

## Chat

NOT imported by `use PetalComponents` - `alias PetalComponents.Chat`, then call
namespaced exactly as listed below. Bare dot-calls without the namespace will not compile.
- `<Chat.action_button>` - 4 attrs, 0 slots · required: icon, label
- `<Chat.chat_error>` - 3 attrs, 1 slots · required slots: inner_block
- `<Chat.chat_message>` - 3 attrs, 3 slots · required slots: inner_block
- `<Chat.chat_sources>` - 6 attrs, 0 slots · required: sources
- `<Chat.citation>` - 3 attrs, 0 slots · required: index, source
- `<Chat.conversation>` - 4 attrs, 2 slots · required slots: inner_block
- `<Chat.copy_button>` - 5 attrs, 0 slots · required: id, text
- `<Chat.markdown>` - 4 attrs, 0 slots · required: content
- `<Chat.marker>` - 5 attrs, 1 slots · required slots: inner_block
- `<Chat.message_actions>` - 2 attrs, 1 slots · required slots: inner_block
- `<Chat.message_attachments>` - 3 attrs, 0 slots · required: attachments
- `<Chat.prompt_input>` - 16 attrs, 1 slots
- `<Chat.questionnaire>` - 9 attrs, 0 slots · required: spec
- `<Chat.reasoning>` - 3 attrs, 1 slots · required slots: inner_block
- `<Chat.rich_text>` - 3 attrs, 0 slots · required: content
- `<Chat.streaming_text>` - 4 attrs, 0 slots · required: id
- `<Chat.suggestions>` - 3 attrs, 0 slots · required: items
- `<Chat.tool_call>` - 12 attrs, 5 slots · required: name

## Collapsible
- `<.collapsible>` - 6 attrs, 2 slots · required slots: inner_block, trigger

## ColorSchemeSwitch
- `<.color_scheme_switch>` - 8 attrs, 3 slots · required: id

## ComboBox
- `<.combo_box>` - 31 attrs, 5 slots

## Command
- `<.command>` - 4 attrs, 1 slots · required: id · required slots: inner_block
- `<.command_dialog>` - 6 attrs, 1 slots · required: id · required slots: inner_block
- `<.command_empty>` - 2 attrs, 1 slots · required slots: inner_block
- `<.command_group>` - 3 attrs, 1 slots · required slots: inner_block
- `<.command_input>` - 4 attrs, 0 slots
- `<.command_item>` - 8 attrs, 1 slots · required slots: inner_block
- `<.command_list>` - 3 attrs, 1 slots · required slots: inner_block
- `<.command_separator>` - 2 attrs, 0 slots
- `<.command_shortcut>` - 2 attrs, 1 slots · required slots: inner_block
- `<.command_trigger>` - 6 attrs, 0 slots · required: dialog_id

## Confetti
- `<.confetti>` - 5 attrs, 0 slots · required: id

## Container
- `<.container>` - 4 attrs, 1 slots

## ContextMenu
- `<.context_menu>` - 5 attrs, 2 slots · required slots: inner_block, trigger
- `<.context_menu_item>` - 8 attrs, 1 slots
- `<.context_menu_label>` - 2 attrs, 1 slots · required slots: inner_block
- `<.context_menu_separator>` - 2 attrs, 0 slots

## DataTable
- `<.data_table>` - 45 attrs, 5 slots · required: id, state · required slots: col

## DataTable.FilterEditor
- `<.filter_editor>` - 8 attrs, 0 slots · required: label, op_labels, type

## DatePicker
- `<.date_picker>` - 35 attrs, 0 slots

## Dropdown
- `<.dropdown>` - 11 attrs, 2 slots
- `<.dropdown_menu_item>` - 6 attrs, 1 slots
- `<.dropdown_menu_label>` - 2 attrs, 1 slots · required slots: inner_block
- `<.dropdown_menu_row>` - 2 attrs, 1 slots · required slots: inner_block
- `<.dropdown_menu_separator>` - 2 attrs, 0 slots

## Empty
- `<.empty>` - 6 attrs, 3 slots

## Field
- `<.field>` - 43 attrs, 0 slots
- `<.field_error>` - 0 attrs, 1 slots · required slots: inner_block
- `<.field_help_text>` - 3 attrs, 1 slots
- `<.field_label>` - 4 attrs, 1 slots · required slots: inner_block
- `<.field_wrapper>` - 5 attrs, 1 slots · required slots: inner_block

## FileUpload
- `<.file_upload>` - 11 attrs, 2 slots · required: upload

## Filters
- `<.filters>` - 15 attrs, 1 slots · required: id, state · required slots: field

## Form
- `<.checkbox>` - 5 attrs, 0 slots
- `<.checkbox_group>` - 8 attrs, 0 slots
- `<.color_input>` - 5 attrs, 0 slots
- `<.date_input>` - 5 attrs, 0 slots
- `<.date_select>` - 5 attrs, 0 slots
- `<.datetime_local_input>` - 5 attrs, 0 slots
- `<.datetime_select>` - 5 attrs, 0 slots
- `<.email_input>` - 5 attrs, 0 slots
- `<.file_input>` - 5 attrs, 0 slots
- `<.form_field>` - 10 attrs, 0 slots · required: field, form
- `<.form_field_error>` - 3 attrs, 0 slots
- `<.form_help_text>` - 3 attrs, 1 slots
- `<.form_label>` - 6 attrs, 1 slots
- `<.hidden_input>` - 3 attrs, 0 slots
- `<.number_input>` - 5 attrs, 0 slots
- `<.password_input>` - 5 attrs, 0 slots
- `<.radio>` - 6 attrs, 0 slots
- `<.radio_group>` - 7 attrs, 0 slots
- `<.range_input>` - 5 attrs, 0 slots
- `<.search_input>` - 5 attrs, 0 slots
- `<.select>` - 6 attrs, 0 slots
- `<.switch>` - 7 attrs, 0 slots
- `<.telephone_input>` - 5 attrs, 0 slots
- `<.text_input>` - 5 attrs, 0 slots
- `<.textarea>` - 5 attrs, 0 slots
- `<.time_input>` - 5 attrs, 0 slots
- `<.time_select>` - 5 attrs, 0 slots
- `<.url_input>` - 5 attrs, 0 slots

## HoverCard
- `<.hover_card>` - 8 attrs, 2 slots · required slots: inner_block, trigger

## Icon
- `<.icon>` - 3 attrs, 0 slots · required: name

## Input
- `<.input>` - 25 attrs, 0 slots

## InputGroup
- `<.input_group>` - 2 attrs, 5 slots · required slots: inner_block

## InputOtp
- `<.input_otp>` - 9 attrs, 0 slots · required: name

## Kbd
- `<.kbd>` - 5 attrs, 1 slots

## LanguageSelect
- `<.language_select>` - 9 attrs, 0 slots · required: current_locale, language_options

## Link
- `<.a>` - 6 attrs, 1 slots

## Loading
- `<.spinner>` - 5 attrs, 0 slots

## LocalTime
- `<.local_time>` - 9 attrs, 0 slots · required: at, id

## Marquee
- `<.marquee>` - 11 attrs, 1 slots · required slots: inner_block

## Menu
- `<.menu_group>` - 4 attrs, 0 slots
- `<.vertical_menu>` - 4 attrs, 0 slots · required: current_page, menu_items
- `<.vertical_menu_item>` - 10 attrs, 0 slots

## Meteors
- `<.meteors>` - 7 attrs, 0 slots

## Modal
- `<.modal>` - 13 attrs, 2 slots

## NavigationMenu
- `<.navigation_menu>` - 4 attrs, 1 slots · required: id · required slots: item
- `<.navigation_menu_footer>` - 2 attrs, 1 slots · required slots: inner_block
- `<.navigation_menu_footer_link>` - 5 attrs, 0 slots · required: label, to
- `<.navigation_menu_link>` - 7 attrs, 0 slots · required: title, to

## NumberField
- `<.number_field>` - 16 attrs, 2 slots

## NumberTicker
- `<.number_ticker>` - 10 attrs, 0 slots · required: id, value

## Pagination
- `<.pagination>` - 16 attrs, 0 slots

## Popover
- `<.popover>` - 8 attrs, 2 slots · required slots: inner_block, trigger

## Progress
- `<.progress>` - 9 attrs, 0 slots
- `<.progress_ring>` - 8 attrs, 1 slots

## QrCode
- `<.qr_code>` - 9 attrs, 1 slots · required: value

## Rating
- `<.rating>` - 16 attrs, 1 slots
- `<.rating_star>` - 2 attrs, 0 slots

## Resizable
- `<.resizable_group>` - 5 attrs, 1 slots · required slots: inner_block
- `<.resizable_handle>` - 9 attrs, 0 slots
- `<.resizable_panel>` - 8 attrs, 1 slots · required slots: inner_block

## ScrollArea
- `<.scroll_area>` - 6 attrs, 1 slots · required slots: inner_block

## Scrollspy
- `<.scrollspy>` - 9 attrs, 0 slots · required: id, items

## Separator
- `<.separator>` - 6 attrs, 1 slots

## ShineBorder
- `<.shine_border>` - 6 attrs, 1 slots · required slots: inner_block

## Sidebar
- `<.sidebar_group>` - 7 attrs, 1 slots · required slots: inner_block
- `<.sidebar_item>` - 11 attrs, 1 slots · required: label
- `<.sidebar_nav>` - 8 attrs, 3 slots · required: id · required slots: inner_block
- `<.sidebar_shell>` - 3 attrs, 2 slots · required: for · required slots: inner_block, sidebar
- `<.sidebar_trigger>` - 7 attrs, 1 slots · required: for

## Skeleton
- `<.skeleton>` - 5 attrs, 0 slots
- `<.skeleton_group>` - 4 attrs, 1 slots · required slots: inner_block
- `<.skeleton_text>` - 4 attrs, 0 slots

## SlideOver
- `<.slide_over>` - 18 attrs, 2 slots

## Slider
- `<.slider>` - 22 attrs, 0 slots

## SocialButton
- `<.social_button>` - 10 attrs, 0 slots · required: provider

## Sortable
- `<.sortable>` - 8 attrs, 1 slots · required: id, on_reorder · required slots: item

## Sparkline
- `<.sparkline>` - 6 attrs, 0 slots · required: data

## SpotlightCard
- `<.spotlight_card>` - 5 attrs, 1 slots · required: id · required slots: inner_block

## Stepper
- `<.stepper>` - 6 attrs, 0 slots · required: steps

## Table
- `<.table>` - 14 attrs, 3 slots
- `<.td>` - 2 attrs, 1 slots
- `<.th>` - 2 attrs, 1 slots
- `<.tr>` - 2 attrs, 1 slots
- `<.user_inner_td>` - 5 attrs, 0 slots

## Tabs
- `<.tab>` - 11 attrs, 1 slots
- `<.tabs>` - 4 attrs, 1 slots

## TextAnimation
- `<.gradient_text>` - 5 attrs, 1 slots · required slots: inner_block
- `<.shimmer_text>` - 3 attrs, 1 slots · required slots: inner_block
- `<.typing_effect>` - 8 attrs, 0 slots · required: id, text
- `<.word_rotate>` - 5 attrs, 0 slots · required: id, words

## Timeline
- `<.timeline>` - 7 attrs, 1 slots · required slots: item

## Toast
- `<.toast_group>` - 6 attrs, 0 slots

## ToggleGroup
- `<.toggle_group>` - 10 attrs, 1 slots · required: aria_label · required slots: item

## Tooltip
- `<.tooltip>` - 8 attrs, 2 slots · required slots: inner_block

## Tree
- `<.tree>` - 14 attrs, 3 slots · required: id

## Typography
- `<.blockquote>` - 2 attrs, 1 slots
- `<.h1>` - 6 attrs, 1 slots
- `<.h2>` - 6 attrs, 1 slots
- `<.h3>` - 6 attrs, 1 slots
- `<.h4>` - 6 attrs, 1 slots
- `<.h5>` - 6 attrs, 1 slots
- `<.hr>` - 2 attrs, 0 slots
- `<.inline_code>` - 2 attrs, 1 slots
- `<.lead>` - 2 attrs, 1 slots
- `<.ol>` - 2 attrs, 1 slots
- `<.p>` - 3 attrs, 1 slots
- `<.prose>` - 2 attrs, 1 slots
- `<.text_large>` - 2 attrs, 1 slots
- `<.text_muted>` - 2 attrs, 1 slots
- `<.text_small>` - 2 attrs, 1 slots
- `<.ul>` - 2 attrs, 1 slots

## UserDropdownMenu
- `<.user_dropdown_menu>` - 11 attrs, 1 slots
