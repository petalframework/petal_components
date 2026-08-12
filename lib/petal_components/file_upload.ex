defmodule PetalComponents.FileUpload do
  @moduledoc ~S"""
  A dropzone family that renders a `Phoenix.LiveView` upload end to end: the
  drop surface, the file list with previews and progress, cancel buttons, and
  human-readable errors.

  **This component requires a LiveView.** It renders the state held in a
  `Phoenix.LiveView.UploadConfig` - it does not upload anything itself. All the
  machinery (validation, chunking, progress, previews) comes from
  `Phoenix.LiveView.allow_upload/3`. If you only need a plain styled file input
  in a static form, use `PetalComponents.Field` with `<.field type="file">`
  instead; this component does not replace it.

  ## Wiring it up

  Three pieces: `allow_upload/3` in `mount`, the component inside a form, and
  `consume_uploaded_entries/3` when the form is submitted.

      defmodule MyAppWeb.ProfileLive do
        use MyAppWeb, :live_view

        @impl true
        def mount(_params, _session, socket) do
          {:ok,
           socket
           |> assign(:uploaded_files, [])
           |> allow_upload(:avatar,
             accept: ~w(.png .jpg .jpeg),
             max_entries: 4,
             max_file_size: 8_000_000
           )}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <form id="upload-form" phx-change="validate" phx-submit="save">
            <.file_upload upload={@uploads.avatar} label="Drop your photos here" />
            <.button type="submit">Save</.button>
          </form>
          \"\"\"
        end

        # phx-change is required for the entries to reach the server at all.
        @impl true
        def handle_event("validate", _params, socket), do: {:noreply, socket}

        # The cancel button in each entry row pushes this event with the ref.
        @impl true
        def handle_event("cancel-upload", %{"ref" => ref}, socket) do
          {:noreply, cancel_upload(socket, :avatar, ref)}
        end

        @impl true
        def handle_event("save", _params, socket) do
          uploaded =
            consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
              dest = Path.join("priv/static/uploads", entry.client_name)
              File.cp!(path, dest)
              {:ok, ~p"/uploads/#{entry.client_name}"}
            end)

          {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded))}
        end
      end

  The `phx-change` form binding is not optional. Without it LiveView never
  receives the selected entries, so the list stays empty and nothing uploads.

  ## Variants

      <.file_upload upload={@uploads.docs} />
      <.file_upload upload={@uploads.docs} variant="compact" />
      <.file_upload upload={@uploads.avatar} variant="avatar" label="Profile photo" />
      <.file_upload upload={@uploads.photos} variant="gallery" label="Listing photos" />

    * `dropzone` - a full dashed zone with a label, a hint line and the entry
      list underneath. The default.
    * `compact` - a browse button plus the entry list, no zone.
    * `avatar` - a single circular preview with a replace overlay; a dashed
      circle when empty.
    * `gallery` - a responsive grid of preview tiles with an "add more" tile
      while the config is under `max_entries`.

  ## Drag and drop

  Drag and drop is LiveView's, not ours: the drop surface carries
  `phx-drop-target={@upload.ref}` and LiveView adds a
  `phx-drop-target-active` class while files hover it. The highlight is plain
  CSS keyed off that class, so there is no hook and no JS in this component.

  ## The description line

  With no `description`, one is derived from the config - accepted types from
  `:accept`, the size cap from `:max_file_size`, the count from `:max_entries`:

      allow_upload(:photos, accept: ~w(.png .jpg), max_entries: 4, max_file_size: 8_000_000)
      #=> "PNG or JPG, up to 8 MB, max 4 files"

  Sizes are rendered in SI units (1 KB = 1000 bytes), matching how
  `:max_file_size` is conventionally written. Pass `description` to override,
  or `description=""` to drop the line entirely.

  ## Errors

  Config-level errors (`:too_many_files`) render above the entry list;
  entry-level errors (`:too_large`, `:not_accepted`) render inside the entry
  row and are associated with it via `aria-describedby`. Messages are plain
  English and live in this module - there is no i18n hook. To translate them,
  render your own rows through the `:entry` slot.

  ## Custom entry rows

      <.file_upload upload={@uploads.docs}>
        <:entry :let={entry}>
          <span>{entry.client_name} - {entry.progress}%</span>
        </:entry>
      </.file_upload>

  The slot replaces the whole default row, including the progress bar and the
  cancel button, so re-add whatever you still need. `upload_errors/2` is yours
  to render too.
  """
  use Phoenix.Component

  import PetalComponents.Icon

  @doc """
  Renders an upload surface for a `Phoenix.LiveView.UploadConfig`.

  See the module documentation for the full `allow_upload/3` wiring.
  """
  attr :upload, Phoenix.LiveView.UploadConfig,
    required: true,
    doc: "the upload config from `allow_upload/3`, e.g. `@uploads.avatar`"

  attr :id, :string,
    default: nil,
    doc:
      "id for the wrapper; the ARIA relationships are derived from it. Defaults to the upload ref."

  attr :label, :string, default: nil, doc: "heading text inside the drop zone"

  attr :description, :string,
    default: nil,
    doc:
      "hint line under the label. When nil it is derived from the config - accepted " <>
        "extensions from `:accept`, the cap from `:max_file_size`, the count from " <>
        ~s|`:max_entries` (e.g. "PNG or JPG, up to 8 MB, max 4 files"). Pass "" for no line.|

  attr :variant, :string,
    default: "dropzone",
    values: ["dropzone", "compact", "avatar", "gallery"],
    doc:
      "dropzone = full dashed zone; compact = browse button + list, no zone; " <>
        "avatar = single circular image with a replace overlay; gallery = grid of preview tiles"

  attr :cancel_event, :string,
    default: "cancel-upload",
    doc:
      "phx-click event name emitted by each entry's cancel button. The parent LiveView " <>
        "handles it and calls `cancel_upload/3` with the entry ref, sent as `phx-value-ref`."

  attr :cancel_label, :string,
    default: "Cancel upload of",
    doc: "prefix for each cancel button's accessible name, joined with the file name"

  attr :cancel_target, :any,
    default: nil,
    doc: "phx-target for the cancel event when used inside a LiveComponent"

  attr :class, :any, default: nil, doc: "CSS class for the outer wrapper"
  attr :rest, :global

  slot :entry,
    doc:
      "optional custom rendering for each entry; receives the " <>
        "`%Phoenix.LiveView.UploadEntry{}` and replaces the default entry row"

  def file_upload(assigns) do
    assigns = normalize(assigns)

    ~H"""
    <div
      id={@id}
      class={["pc-file-upload", "pc-file-upload--#{@variant}", @class]}
      role="group"
      aria-labelledby={@label && "#{@id}-label"}
      aria-label={is_nil(@label) && "File upload"}
      {@rest}
    >
      <.surface {assigns} />
      <.config_errors upload={@upload} id={@id} />
      <.entry_list {assigns} />
    </div>
    """
  end

  # The drop surface. Every variant hands the same `label` element to
  # LiveView: it wraps the (focusable) file input, carries the drop target and
  # acts as the click surface. Only the contents change.
  defp surface(%{variant: "gallery"} = assigns) do
    # The gallery's add-tile lives inside the grid, next to the entry tiles.
    ~H"""
    <div :if={@label || @description != ""} class="pc-file-upload__heading">
      <span :if={@label} id={"#{@id}-label"} class="pc-file-upload__label">{@label}</span>
      <span :if={@description != ""} class="pc-file-upload__description">{@description}</span>
    </div>
    """
  end

  defp surface(%{variant: "avatar"} = assigns) do
    ~H"""
    <div :if={@label || @description != ""} class="pc-file-upload__heading">
      <span :if={@label} id={"#{@id}-label"} class="pc-file-upload__label">{@label}</span>
      <span :if={@description != ""} class="pc-file-upload__description">{@description}</span>
    </div>

    <label for={@upload.ref} phx-drop-target={@upload.ref} class="pc-file-upload__zone">
      <.live_file_input upload={@upload} class="pc-file-upload__input" />
      <.live_img_preview
        :if={@avatar_entry}
        entry={@avatar_entry}
        id={"#{@id}-avatar-preview"}
        class="pc-file-upload__avatar-img"
        alt={@avatar_entry.client_name}
      />
      <.icon
        :if={is_nil(@avatar_entry)}
        name="hero-user-circle"
        class="pc-file-upload__glyph"
        aria-hidden="true"
      />
      <span class="pc-file-upload__overlay" aria-hidden="true">
        <.icon name="hero-arrow-up-tray" class="pc-file-upload__overlay-icon" />
      </span>
      <span class="pc-file-upload__live" aria-live="polite">{@drop_hint}</span>
    </label>
    """
  end

  defp surface(%{variant: "compact"} = assigns) do
    ~H"""
    <div class="pc-file-upload__bar">
      <label for={@upload.ref} phx-drop-target={@upload.ref} class="pc-file-upload__zone">
        <.live_file_input upload={@upload} class="pc-file-upload__input" />
        <.icon name="hero-arrow-up-tray" class="pc-file-upload__glyph" aria-hidden="true" />
        <span :if={@label} id={"#{@id}-label"} class="pc-file-upload__label">{@label}</span>
        <span :if={is_nil(@label)} class="pc-file-upload__label">Choose files</span>
        <span class="pc-file-upload__live" aria-live="polite">{@drop_hint}</span>
      </label>
      <span :if={@description != ""} class="pc-file-upload__description">{@description}</span>
    </div>
    """
  end

  defp surface(assigns) do
    ~H"""
    <label for={@upload.ref} phx-drop-target={@upload.ref} class="pc-file-upload__zone">
      <.live_file_input upload={@upload} class="pc-file-upload__input" />
      <.icon name="hero-cloud-arrow-up" class="pc-file-upload__glyph" aria-hidden="true" />
      <span :if={@label} id={"#{@id}-label"} class="pc-file-upload__label">{@label}</span>
      <span :if={is_nil(@label)} class="pc-file-upload__label">
        Drop files here, or click to browse
      </span>
      <span :if={@description != ""} class="pc-file-upload__description">{@description}</span>
      <span class="pc-file-upload__live" aria-live="polite">{@drop_hint}</span>
    </label>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :id, :string, required: true

  defp config_errors(assigns) do
    ~H"""
    <p
      :for={{error, i} <- Enum.with_index(upload_errors(@upload))}
      id={"#{@id}-error-#{i}"}
      class="pc-file-upload__error pc-file-upload__error--config"
    >
      <.icon name="hero-exclamation-circle" class="pc-file-upload__error-icon" aria-hidden="true" />
      {error_to_string(error)}
    </p>
    """
  end

  # The entry list. Gallery renders tiles in a grid alongside the add-tile;
  # every other variant renders rows.
  defp entry_list(%{variant: "gallery"} = assigns) do
    ~H"""
    <div class="pc-file-upload__grid">
      <div :for={entry <- @upload.entries} class="pc-file-upload__tile">
        <.entry_cell
          e={entry}
          id={@id}
          upload={@upload}
          custom={@entry}
          cancel_event={@cancel_event}
          cancel_target={@cancel_target}
          cancel_label={@cancel_label}
        />
      </div>
      <label
        :if={length(@upload.entries) < @upload.max_entries}
        for={@upload.ref}
        phx-drop-target={@upload.ref}
        class="pc-file-upload__zone pc-file-upload__tile pc-file-upload__tile--add"
      >
        <.live_file_input upload={@upload} class="pc-file-upload__input" />
        <.icon name="hero-plus" class="pc-file-upload__glyph" aria-hidden="true" />
        <span class="pc-file-upload__tile-label">Add files</span>
        <span class="pc-file-upload__live" aria-live="polite">{@drop_hint}</span>
      </label>
    </div>
    """
  end

  defp entry_list(%{variant: "avatar"} = assigns) do
    # The avatar surface IS the preview, so only progress and errors are left
    # to report for the single entry it holds.
    ~H"""
    <div :if={@avatar_entry} class="pc-file-upload__entries">
      <div class="pc-file-upload__entry">
        <.entry_cell
          e={@avatar_entry}
          id={@id}
          upload={@upload}
          custom={@entry}
          cancel_event={@cancel_event}
          cancel_target={@cancel_target}
          cancel_label={@cancel_label}
        />
      </div>
    </div>
    """
  end

  defp entry_list(assigns) do
    ~H"""
    <ul :if={@upload.entries != []} class="pc-file-upload__entries">
      <li :for={entry <- @upload.entries} class="pc-file-upload__entry">
        <.entry_cell
          e={entry}
          id={@id}
          upload={@upload}
          custom={@entry}
          cancel_event={@cancel_event}
          cancel_target={@cancel_target}
          cancel_label={@cancel_label}
        />
      </li>
    </ul>
    """
  end

  attr :e, Phoenix.LiveView.UploadEntry, required: true
  attr :id, :string, required: true
  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :custom, :any, required: true
  attr :cancel_event, :string, required: true
  attr :cancel_target, :any, required: true
  attr :cancel_label, :string, required: true

  # A non-empty :entry slot replaces the whole default row.
  defp entry_cell(%{custom: [_ | _]} = assigns) do
    ~H"""
    {render_slot(@custom, @e)}
    """
  end

  defp entry_cell(assigns) do
    assigns = assign(assigns, :entry_errors, upload_errors(assigns.upload, assigns.e))

    ~H"""
    <div
      class={[
        "pc-file-upload__entry-inner",
        @entry_errors != [] && "pc-file-upload__entry-inner--invalid"
      ]}
      aria-describedby={@entry_errors != [] && "#{@id}-#{@e.ref}-error"}
    >
      <span class="pc-file-upload__media">
        <.live_img_preview
          :if={image?(@e)}
          entry={@e}
          id={"#{@id}-preview-#{@e.ref}"}
          class="pc-file-upload__thumb"
          alt={@e.client_name}
        />
        <.icon
          :if={not image?(@e)}
          name={type_icon(@e.client_type)}
          class="pc-file-upload__type-icon"
          aria-hidden="true"
        />
      </span>

      <span class="pc-file-upload__entry-body">
        <span class="pc-file-upload__entry-name" title={@e.client_name}>{@e.client_name}</span>
        <span class="pc-file-upload__entry-meta">{format_bytes(@e.client_size)}</span>

        <span
          class="pc-file-upload__progress"
          role="progressbar"
          aria-valuemin="0"
          aria-valuemax="100"
          aria-valuenow={@e.progress}
          aria-valuetext={"#{@e.progress}%"}
          aria-label={"Upload progress for #{@e.client_name}"}
        >
          <span class="pc-file-upload__progress-bar" style={"width: #{@e.progress}%"}></span>
        </span>

        <span
          :if={@entry_errors != []}
          id={"#{@id}-#{@e.ref}-error"}
          class="pc-file-upload__error pc-file-upload__error--entry"
        >
          <.icon
            name="hero-exclamation-circle"
            class="pc-file-upload__error-icon"
            aria-hidden="true"
          />
          {@entry_errors |> Enum.map(&error_to_string/1) |> Enum.join(". ")}
        </span>
      </span>

      <button
        type="button"
        class="pc-file-upload__cancel"
        phx-click={@cancel_event}
        phx-value-ref={@e.ref}
        phx-target={@cancel_target}
        aria-label={"#{@cancel_label} #{@e.client_name}"}
      >
        <.icon name="hero-x-mark" class="pc-file-upload__cancel-icon" aria-hidden="true" />
      </button>
    </div>
    """
  end

  # -- assigns ---------------------------------------------------------------

  defp normalize(assigns) do
    upload = assigns.upload

    assigns
    |> assign_new(:id, fn -> nil end)
    |> then(&assign(&1, :id, &1.id || "pc-file-upload-#{upload.ref}"))
    |> assign(:description, assigns.description || derive_description(upload))
    |> assign(:avatar_entry, List.first(upload.entries))
    |> assign(:drop_hint, "Drop files to upload")
  end

  # -- copy ------------------------------------------------------------------

  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:too_large), do: "This file is too large"
  defp error_to_string(:not_accepted), do: "This file type is not accepted"
  # Anything else - :external_client_failure, {:writer_failure, reason}, or a
  # custom validator's reason - degrades to a generic line rather than
  # crashing the render on an atom we have no copy for.
  defp error_to_string(_other), do: "Upload failed, please try again"

  @doc false
  # Derives the hint line from the config: accepted types, size cap, count.
  def derive_description(%Phoenix.LiveView.UploadConfig{} = upload) do
    [
      accept_phrase(upload.accept),
      size_phrase(upload.max_file_size),
      entries_phrase(upload.max_entries)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  defp accept_phrase(:any), do: nil
  defp accept_phrase([]), do: nil
  defp accept_phrase(""), do: nil

  # allow_upload/3 stores :accept comma-joined, ready for the input's accept
  # attribute, so that is what a real config hands us. The list form is the
  # struct's own default and what hand-built configs tend to carry.
  defp accept_phrase(accept) when is_binary(accept) do
    accept |> String.split(",") |> Enum.map(&String.trim/1) |> accept_phrase()
  end

  defp accept_phrase(accept) when is_list(accept) do
    accept
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&accept_label/1)
    |> Enum.uniq()
    |> case do
      [] -> nil
      labels -> to_sentence(labels)
    end
  end

  defp accept_phrase(_other), do: nil

  defp accept_label("." <> ext), do: String.upcase(ext)

  defp accept_label(type) do
    case String.split(type, "/") do
      [group, "*"] -> group <> "s"
      [_group, sub] -> sub |> String.split("+") |> hd() |> String.upcase()
      _ -> type
    end
  end

  defp to_sentence([one]), do: one
  defp to_sentence([a, b]), do: "#{a} or #{b}"

  defp to_sentence(list) do
    {rest, [last]} = Enum.split(list, -1)
    "#{Enum.join(rest, ", ")} or #{last}"
  end

  defp size_phrase(nil), do: nil
  defp size_phrase(bytes) when is_integer(bytes), do: "up to #{format_bytes(bytes)}"
  defp size_phrase(_other), do: nil

  defp entries_phrase(n) when is_integer(n) and n > 1, do: "max #{n} files"
  defp entries_phrase(_other), do: nil

  # -- formatting ------------------------------------------------------------

  @doc false
  # SI units, matching how :max_file_size is conventionally written
  # (the LiveView default of 8_000_000 reads as "8 MB", not "7.6 MB").
  def format_bytes(nil), do: ""
  def format_bytes(bytes) when is_integer(bytes) and bytes < 1_000, do: "#{bytes} B"

  def format_bytes(bytes) when is_integer(bytes) and bytes < 1_000_000,
    do: "#{trim_float(bytes / 1_000)} KB"

  def format_bytes(bytes) when is_integer(bytes) and bytes < 1_000_000_000,
    do: "#{trim_float(bytes / 1_000_000)} MB"

  def format_bytes(bytes) when is_integer(bytes), do: "#{trim_float(bytes / 1_000_000_000)} GB"
  def format_bytes(_other), do: ""

  defp trim_float(number) do
    rounded = Float.round(number, 1)

    if rounded == Float.round(rounded, 0) do
      rounded |> trunc() |> Integer.to_string()
    else
      Float.to_string(rounded)
    end
  end

  defp image?(%{client_type: "image/" <> _}), do: true
  defp image?(_entry), do: false

  defp type_icon("image/" <> _), do: "hero-photo"
  defp type_icon("video/" <> _), do: "hero-film"
  defp type_icon("audio/" <> _), do: "hero-musical-note"
  defp type_icon("application/pdf"), do: "hero-document-text"
  defp type_icon("text/" <> _), do: "hero-document-text"
  defp type_icon("application/zip"), do: "hero-archive-box"
  defp type_icon(_other), do: "hero-document"
end
