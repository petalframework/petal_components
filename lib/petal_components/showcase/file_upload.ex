defmodule PetalComponents.Showcase.FileUpload do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.FileUpload,
    title: "File upload"

  alias Phoenix.LiveView.UploadConfig
  alias Phoenix.LiveView.UploadEntry

  # The examples render statically, so they hand the component hand-built
  # configs rather than an @uploads assign. In your app these come from
  # allow_upload/3 and nothing else changes.

  @doc false
  def config(ref, opts) do
    %UploadConfig{
      name: Keyword.get(opts, :name, :docs),
      ref: ref,
      accept: Keyword.get(opts, :accept, ~w(.pdf .docx)),
      max_entries: Keyword.get(opts, :max_entries, 4),
      max_file_size: Keyword.get(opts, :max_file_size, 8_000_000),
      entries: Keyword.get(opts, :entries, []),
      errors: Keyword.get(opts, :errors, [])
    }
  end

  @doc false
  def entry(upload_ref, ref, name, size, type, progress) do
    %UploadEntry{
      upload_ref: upload_ref,
      ref: ref,
      client_name: name,
      client_size: size,
      client_type: type,
      progress: progress,
      valid?: true,
      done?: progress == 100
    }
  end

  @doc false
  def uploading_config do
    config("sxfu1",
      entries: [
        entry("sxfu1", "0", "q3-forecast.pdf", 2_400_000, "application/pdf", 100),
        entry("sxfu1", "1", "board-notes.docx", 486_000, "application/msword", 42)
      ]
    )
  end

  @doc false
  def error_config do
    config("sxfu2",
      max_entries: 2,
      entries: [
        entry("sxfu2", "0", "raw-scan.pdf", 61_200_000, "application/pdf", 0),
        entry("sxfu2", "1", "cover-letter.pdf", 94_000, "application/pdf", 100)
      ],
      errors: [{"sxfu2", :too_many_files}, {"0", :too_large}]
    )
  end

  @doc false
  def gallery_config do
    config("sxfu4",
      name: :photos,
      accept: ~w(.png .jpg),
      max_entries: 6,
      entries: [
        entry("sxfu4", "0", "kitchen.jpg", 1_800_000, "image/jpeg", 100),
        entry("sxfu4", "1", "balcony.jpg", 2_100_000, "image/jpeg", 63)
      ]
    )
  end

  example :dropzone, "The dropzone",
    description:
      "Hand it an @uploads.<name> from allow_upload/3 and it renders the whole surface. The hint line is derived from the config, so the accepted types, the size cap and the file count stay true without you repeating them." do
    ~H"""
    <.file_upload
      upload={PetalComponents.Showcase.FileUpload.config("sxfu0", [])}
      label="Drop your documents here"
    />
    """
  end

  example :uploading, "Files in flight",
    description:
      "Each entry gets a type icon, its humanised size, a progress bar carrying role=progressbar, and a cancel button named after the file. Progress comes straight from entry.progress, so the bar moves as LiveView reports chunks." do
    ~H"""
    <.file_upload
      upload={PetalComponents.Showcase.FileUpload.uploading_config()}
      label="Drop your documents here"
    />
    """
  end

  example :errors, "Errors, config level and per entry",
    description:
      "upload_errors/1 and upload_errors/2 are rendered as plain English. The config-level message sits above the list, the per-entry one inside its row, tied to it with aria-describedby so a screen reader reads the file and the problem together." do
    ~H"""
    <.file_upload
      upload={PetalComponents.Showcase.FileUpload.error_config()}
      label="Attach up to two files"
    />
    """
  end

  example :compact, "Compact",
    description:
      "A browse button and the list, no zone. For forms where a full dashed rectangle would shout too loudly. Drag and drop still works, the button is the drop target." do
    ~H"""
    <.file_upload
      upload={PetalComponents.Showcase.FileUpload.config("sxfu3", max_entries: 1)}
      variant="compact"
      label="Attach a file"
    />
    """
  end

  example :gallery, "Gallery",
    description:
      "A grid of preview tiles with the cancel button and progress on the tile itself, plus an add tile that disappears once the config hits max_entries. Thumbnails come from live_img_preview, which needs a running LiveView, so they fill in on the playground rather than here." do
    ~H"""
    <.file_upload
      upload={PetalComponents.Showcase.FileUpload.gallery_config()}
      variant="gallery"
      label="Listing photos"
    />
    """
  end

  example :avatar, "Avatar",
    description:
      "One circular target with a replace overlay on hover and on keyboard focus. Empty here; pick a file and the preview takes over the circle." do
    ~H"""
    <.file_upload
      upload={
        PetalComponents.Showcase.FileUpload.config("sxfu5",
          name: :avatar,
          accept: ~w(.png .jpg),
          max_entries: 1,
          max_file_size: 2_000_000
        )
      }
      variant="avatar"
      label="Profile photo"
    />
    """
  end

  example :custom_entry, "Your own entry row",
    description:
      "The :entry slot hands you the %Phoenix.LiveView.UploadEntry{} and replaces the default row outright, so translated copy or a different layout costs one slot. You own the progress and cancel affordances once you take it over." do
    ~H"""
    <.file_upload
      upload={PetalComponents.Showcase.FileUpload.uploading_config()}
      label="Drop your documents here"
    >
      <:entry :let={entry}>
        <div class="flex items-center justify-between w-full gap-3 text-sm">
          <span class="font-medium truncate">{entry.client_name}</span>
          <span class="text-gray-500 tabular-nums dark:text-gray-400">{entry.progress}%</span>
        </div>
      </:entry>
    </.file_upload>
    """
  end
end
