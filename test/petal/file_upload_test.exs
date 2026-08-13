defmodule PetalComponents.FileUploadTest do
  use ComponentCase

  import PetalComponents.FileUpload

  alias Phoenix.LiveView.UploadConfig
  alias Phoenix.LiveView.UploadEntry

  # The render layer only reads the structs LiveView hands it, so the whole
  # suite runs against hand-built configs - no live upload required.
  defp config(opts \\ []) do
    %UploadConfig{
      name: Keyword.get(opts, :name, :docs),
      ref: Keyword.get(opts, :ref, "phx-ref-1"),
      accept: Keyword.get(opts, :accept, ~w(.pdf)),
      max_entries: Keyword.get(opts, :max_entries, 3),
      max_file_size: Keyword.get(opts, :max_file_size, 8_000_000),
      entries: Keyword.get(opts, :entries, []),
      errors: Keyword.get(opts, :errors, []),
      auto_upload?: Keyword.get(opts, :auto_upload?, false)
    }
  end

  defp entry(opts \\ []) do
    %UploadEntry{
      upload_ref: Keyword.get(opts, :upload_ref, "phx-ref-1"),
      ref: Keyword.get(opts, :ref, "0"),
      client_name: Keyword.get(opts, :client_name, "report.pdf"),
      client_size: Keyword.get(opts, :client_size, 2_400_000),
      client_type: Keyword.get(opts, :client_type, "application/pdf"),
      progress: Keyword.get(opts, :progress, 40),
      valid?: true,
      done?: Keyword.get(opts, :progress, 40) == 100
    }
  end

  defp query(html, selector) do
    html |> LazyHTML.from_fragment() |> LazyHTML.query(selector)
  end

  defp attr_of(html, selector, attribute) do
    html |> query(selector) |> LazyHTML.attribute(attribute) |> List.first()
  end

  defp text_of(html, selector) do
    html |> query(selector) |> LazyHTML.text()
  end

  # format_bytes/1 and derive_description/1 are private - `use PetalComponents`
  # blanket-imports this module, so neither name may be public. Both are
  # exercised through the markup they produce.
  defp rendered_description(upload) do
    assigns = %{upload: upload}

    ~H"<.file_upload upload={@upload} />"
    |> rendered_to_string()
    |> text_of(".pc-file-upload__description")
  end

  defp rendered_size(bytes) do
    assigns = %{upload: config(entries: [entry(client_size: bytes)])}

    ~H"<.file_upload upload={@upload} />"
    |> rendered_to_string()
    |> text_of(".pc-file-upload__entry-meta")
  end

  describe "variants" do
    test "dropzone is the default and renders the zone" do
      assigns = %{upload: config()}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert_has_class(html, "pc-file-upload")
      assert_has_class(html, "pc-file-upload--dropzone")
      assert Enum.count(query(html, ".pc-file-upload__zone")) == 1
      assert html =~ "Drop files here, or click to browse"
    end

    test "compact renders a browse bar and no dashed zone body" do
      assigns = %{upload: config()}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant=\"compact\" />")

      assert_has_class(html, "pc-file-upload--compact")
      assert Enum.count(query(html, ".pc-file-upload__bar")) == 1
      assert html =~ "Choose files"
    end

    test "avatar renders the circular target with a replace overlay" do
      assigns = %{upload: config(max_entries: 1)}

      html =
        rendered_to_string(
          ~H"<.file_upload upload={@upload} variant=\"avatar\" label=\"Photo\" />"
        )

      assert_has_class(html, "pc-file-upload--avatar")
      assert Enum.count(query(html, ".pc-file-upload__overlay")) == 1
      # empty state falls back to the placeholder glyph
      assert has_icon?(html, "hero-user-circle")
    end

    test "avatar swaps the placeholder for a preview once an entry exists" do
      assigns = %{upload: config(entries: [entry(client_type: "image/png")])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant=\"avatar\" />")

      assert Enum.count(query(html, ".pc-file-upload__avatar-img")) == 1
      refute has_icon?(html, "hero-user-circle")
    end

    # live_img_preview on a PDF renders a broken image. A document pick is
    # reachable from any avatar config whose accept list is not images-only.
    test "avatar falls back to the placeholder glyph for a non-image entry" do
      assigns = %{
        upload: config(max_entries: 1, entries: [entry(client_type: "application/pdf")]),
        variant: "avatar"
      }

      html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

      assert Enum.empty?(query(html, ".pc-file-upload__avatar-img"))
      assert has_icon?(html, "hero-user-circle")
      # the row underneath still names the file and its type
      assert html =~ "report.pdf"
      assert has_icon?(html, "hero-document-text")
    end

    test "avatar shows only the first entry when the config holds several" do
      entries = [
        entry(ref: "0", client_name: "first.png", client_type: "image/png"),
        entry(ref: "1", client_name: "second.png", client_type: "image/png")
      ]

      assigns = %{upload: config(max_entries: 3, entries: entries), variant: "avatar"}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

      assert Enum.count(query(html, ".pc-file-upload__avatar-img")) == 1
      assert Enum.count(query(html, ".pc-file-upload__entry")) == 1
      assert attr_of(html, ".pc-file-upload__avatar-img", "alt") == "first.png"
      refute html =~ "second.png"
    end

    test "gallery renders a tile per entry plus an add tile under max_entries" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]
      assigns = %{upload: config(max_entries: 6, entries: entries)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant=\"gallery\" />")

      assert_has_class(html, "pc-file-upload--gallery")
      assert Enum.count(query(html, ".pc-file-upload__grid")) == 1
      # two entry tiles + the add tile
      assert Enum.count(query(html, ".pc-file-upload__tile")) == 3
      assert Enum.count(query(html, ".pc-file-upload__tile--add")) == 1
    end

    test "gallery drops the add tile once max_entries is reached" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]
      assigns = %{upload: config(max_entries: 2, entries: entries)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant=\"gallery\" />")

      assert Enum.empty?(query(html, ".pc-file-upload__tile--add"))
    end
  end

  describe "LiveView upload wiring" do
    test "the drop target is the config ref" do
      assigns = %{upload: config(ref: "phx-F123")}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert attr_of(html, ".pc-file-upload__zone", "phx-drop-target") == "phx-F123"
    end

    test "every variant sets phx-drop-target" do
      for variant <- ~w(dropzone compact avatar gallery) do
        assigns = %{upload: config(ref: "phx-F9"), variant: variant}
        html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

        assert attr_of(html, "[phx-drop-target]", "phx-drop-target") == "phx-F9",
               "#{variant} did not set phx-drop-target"
      end
    end

    test "the live_file_input is rendered, keyed to the ref, and stays focusable" do
      assigns = %{upload: config(ref: "phx-F123")}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      input = query(html, "input[type=file]")
      assert Enum.count(input) == 1
      assert attr_of(html, "input[type=file]", "id") == "phx-F123"
      assert attr_of(html, "input[type=file]", "data-phx-upload-ref") == "phx-F123"

      # Clipped by CSS, never removed from the tab order.
      assert_has_class(html, "pc-file-upload__input")
      assert LazyHTML.attribute(input, "hidden") == []
      assert LazyHTML.attribute(input, "tabindex") == []
      assert LazyHTML.attribute(input, "disabled") == []
    end

    test "the zone labels the input via for=" do
      assigns = %{upload: config(ref: "phx-F123")}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert attr_of(html, "label.pc-file-upload__zone", "for") == "phx-F123"
    end

    # LiveView keeps the picked File objects and the preview blob-URL lookups
    # on the input element itself (live_uploader.js serializeUploads /
    # getEntryDataURL). Drop it from the DOM at capacity and a manual-mode
    # submit uploads nothing while re-rendered previews go blank.
    test "every variant keeps exactly one file input at max_entries" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]

      for variant <- ~w(dropzone compact avatar gallery) do
        assigns = %{upload: config(max_entries: 2, entries: entries), variant: variant}
        html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

        inputs = query(html, "input[type=file]")

        assert Enum.count(inputs) == 1,
               "#{variant} rendered #{Enum.count(inputs)} file inputs at capacity, expected 1"

        assert LazyHTML.attribute(inputs, "data-phx-upload-ref") == ["phx-ref-1"]
      end
    end

    # Gallery is the one variant whose visible surface disappears at capacity,
    # so its clipped input would otherwise be a focus ring with nothing to draw.
    test "gallery takes the input out of the tab order once it is full, and only then" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]
      assigns = %{upload: config(max_entries: 2, entries: entries), variant: "gallery"}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

      assert attr_of(html, "input[type=file]", "tabindex") == "-1"

      assigns = %{upload: config(max_entries: 4, entries: entries), variant: "gallery"}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

      assert LazyHTML.attribute(query(html, "input[type=file]"), "tabindex") == []
    end

    test "gallery keeps the input reachable from the add tile label" do
      assigns = %{
        upload: config(ref: "phx-F5", max_entries: 4, entries: [entry()]),
        variant: "gallery"
      }

      html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

      assert attr_of(html, ".pc-file-upload__tile--add", "for") == "phx-F5"
      assert attr_of(html, "input[type=file]", "id") == "phx-F5"
    end

    test "multiple is set by live_file_input when max_entries > 1" do
      assigns = %{upload: config(max_entries: 4)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")
      assert LazyHTML.attribute(query(html, "input[type=file]"), "multiple") == [""]

      assigns = %{upload: config(max_entries: 1)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")
      assert LazyHTML.attribute(query(html, "input[type=file]"), "multiple") == []
    end
  end

  describe "entry rows" do
    test "renders the file name and a humanised size" do
      assigns = %{upload: config(entries: [entry(client_name: "q3.pdf", client_size: 2_400_000)])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "q3.pdf"
      assert html =~ "2.4 MB"
    end

    test "renders one row per entry" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]
      assigns = %{upload: config(entries: entries)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert Enum.count(query(html, ".pc-file-upload__entry")) == 2
    end

    test "no entry list is rendered when there are no entries" do
      assigns = %{upload: config()}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert Enum.empty?(query(html, ".pc-file-upload__entries"))
    end

    test "the cancel button carries the event, the ref and no target by default" do
      assigns = %{upload: config(entries: [entry(ref: "7")])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert attr_of(html, ".pc-file-upload__cancel", "phx-click") == "cancel-upload"
      assert attr_of(html, ".pc-file-upload__cancel", "phx-value-ref") == "7"
      assert attr_of(html, ".pc-file-upload__cancel", "type") == "button"
      assert LazyHTML.attribute(query(html, ".pc-file-upload__cancel"), "phx-target") == []
    end

    test "cancel_event and cancel_target override the defaults" do
      assigns = %{upload: config(entries: [entry(ref: "7")])}

      html =
        rendered_to_string(
          ~H"<.file_upload upload={@upload} cancel_event=\"drop-it\" cancel_target=\"#me\" />"
        )

      assert attr_of(html, ".pc-file-upload__cancel", "phx-click") == "drop-it"
      assert attr_of(html, ".pc-file-upload__cancel", "phx-target") == "#me"
    end

    test "auto_upload false still reads sensibly at 0%" do
      assigns = %{upload: config(auto_upload?: false, entries: [entry(progress: 0)])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "report.pdf"
      assert attr_of(html, "[role=progressbar]", "aria-valuenow") == "0"
      assert attr_of(html, "[role=progressbar]", "aria-valuetext") == "0%"
    end
  end

  describe "previews and type icons" do
    test "image entries render a live preview element, not the type icon" do
      assigns = %{upload: config(entries: [entry(client_type: "image/png", ref: "3")])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      preview = query(html, "img.pc-file-upload__thumb")
      assert Enum.count(preview) == 1
      assert LazyHTML.attribute(preview, "data-phx-hook") == ["Phoenix.LiveImgPreview"]
      assert LazyHTML.attribute(preview, "data-phx-entry-ref") == ["3"]
      assert Enum.empty?(query(html, ".pc-file-upload__type-icon"))
    end

    test "non-image entries render a type icon and no preview" do
      assigns = %{upload: config(entries: [entry(client_type: "application/pdf")])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert Enum.empty?(query(html, "img.pc-file-upload__thumb"))
      assert has_icon?(html, "hero-document-text")
    end

    test "the type icon follows the MIME family" do
      for {type, icon} <- [
            {"video/mp4", "hero-film"},
            {"audio/mpeg", "hero-musical-note"},
            {"application/pdf", "hero-document-text"},
            {"text/csv", "hero-document-text"},
            {"application/zip", "hero-archive-box"},
            {"application/octet-stream", "hero-document"}
          ] do
        assigns = %{upload: config(entries: [entry(client_type: type)])}
        html = rendered_to_string(~H"<.file_upload upload={@upload} />")

        assert has_icon?(html, icon), "#{type} did not render #{icon}"
      end
    end

    test "a nil client_type falls back to the generic document icon" do
      assigns = %{upload: config(entries: [entry(client_type: nil)])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert has_icon?(html, "hero-document")
    end
  end

  describe "progress" do
    test "aria-valuenow tracks entry.progress and the bar width follows" do
      assigns = %{upload: config(entries: [entry(progress: 63)])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      bar = query(html, "[role=progressbar]")
      assert Enum.count(bar) == 1
      assert LazyHTML.attribute(bar, "aria-valuenow") == ["63"]
      assert LazyHTML.attribute(bar, "aria-valuemin") == ["0"]
      assert LazyHTML.attribute(bar, "aria-valuemax") == ["100"]
      assert attr_of(html, ".pc-file-upload__progress-bar", "style") == "width: 63%"
    end

    test "the progress bar is named after its file" do
      assigns = %{upload: config(entries: [entry(client_name: "q3.pdf")])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert attr_of(html, "[role=progressbar]", "aria-label") == "Upload progress for q3.pdf"
    end

    test "one progress bar per entry" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]
      assigns = %{upload: config(entries: entries)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert Enum.count(query(html, "[role=progressbar]")) == 2
    end
  end

  describe "errors" do
    test "config-level :too_many_files renders above the list" do
      assigns = %{upload: config(ref: "phx-F1", errors: [{"phx-F1", :too_many_files}])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "You have selected too many files"
      assert Enum.count(query(html, ".pc-file-upload__error--config")) == 1
    end

    test "entry-level :too_large renders inside the row" do
      assigns = %{upload: config(entries: [entry(ref: "0")], errors: [{"0", :too_large}])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "This file is too large"
      assert Enum.count(query(html, ".pc-file-upload__error--entry")) == 1
      assert_has_class(html, "pc-file-upload__entry-inner--invalid")
    end

    test "entry-level :not_accepted renders inside the row" do
      assigns = %{upload: config(entries: [entry(ref: "0")], errors: [{"0", :not_accepted}])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "This file type is not accepted"
    end

    test ":external_client_failure and unknown reasons degrade to a generic line" do
      for reason <- [:external_client_failure, {:writer_failure, :enospc}, :some_custom_reason] do
        assigns = %{upload: config(entries: [entry(ref: "0")], errors: [{"0", reason}])}
        html = rendered_to_string(~H"<.file_upload upload={@upload} />")

        assert html =~ "Upload failed, please try again",
               "#{inspect(reason)} did not degrade gracefully"
      end
    end

    test "an error on one entry does not leak onto another" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]
      assigns = %{upload: config(entries: entries, errors: [{"0", :too_large}])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert Enum.count(query(html, ".pc-file-upload__error--entry")) == 1
      assert Enum.count(query(html, ".pc-file-upload__entry-inner--invalid")) == 1
    end

    test "no error markup when the config is clean" do
      assigns = %{upload: config(entries: [entry()])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert Enum.empty?(query(html, ".pc-file-upload__error"))
    end
  end

  describe "description" do
    test "is derived from accept, max_file_size and max_entries" do
      assigns = %{
        upload: config(accept: ~w(.png .jpg), max_file_size: 8_000_000, max_entries: 4)
      }

      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "PNG or JPG, up to 8 MB, max 4 files"
    end

    test "drops the file count for a single-entry config" do
      assigns = %{upload: config(accept: ~w(.pdf), max_file_size: 1_000_000, max_entries: 1)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "PDF, up to 1 MB"
      refute html =~ "max 1 files"
    end

    # allow_upload/3 joins :accept into a comma-separated string for the
    # input's accept attribute, so that - not the list - is what a real
    # config carries. Missing this silently dropped the whole phrase.
    test "reads the comma-joined accept a real allow_upload/3 config carries" do
      assigns = %{
        upload: config(accept: ".png,.jpg,.pdf", max_file_size: 8_000_000, max_entries: 4)
      }

      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert html =~ "PNG, JPG or PDF, up to 8 MB, max 4 files"
    end

    test "an empty accept string contributes nothing" do
      assert rendered_description(config(accept: "", max_entries: 1, max_file_size: 500)) ==
               "up to 500 B"
    end

    test "handles MIME wildcards and three-or-more accept lists" do
      assert rendered_description(config(accept: ~w(image/*), max_entries: 1, max_file_size: nil)) ==
               "images"

      assert rendered_description(
               config(accept: ~w(.png .jpg .gif), max_entries: 1, max_file_size: nil)
             ) == "PNG, JPG or GIF"

      assert rendered_description(
               config(accept: ~w(application/pdf), max_entries: 1, max_file_size: nil)
             ) == "PDF"
    end

    test "an :any accept contributes nothing" do
      assert rendered_description(config(accept: :any, max_entries: 1, max_file_size: 500)) ==
               "up to 500 B"
    end

    test "the compact variant carries the derived line beside the browse button" do
      assigns = %{
        upload: config(accept: ~w(.pdf), max_file_size: 2_000_000, max_entries: 5),
        variant: "compact"
      }

      html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

      assert text_of(html, ".pc-file-upload__bar .pc-file-upload__description") ==
               "PDF, up to 2 MB, max 5 files"
    end

    test "an explicit description overrides the derivation" do
      assigns = %{upload: config(accept: ~w(.png))}

      html =
        rendered_to_string(~H"<.file_upload upload={@upload} description=\"Anything goes\" />")

      assert html =~ "Anything goes"
      refute html =~ "up to 8 MB"
    end

    test "an empty description drops the line entirely" do
      assigns = %{upload: config()}
      html = rendered_to_string(~H"<.file_upload upload={@upload} description=\"\" />")

      assert Enum.empty?(query(html, ".pc-file-upload__description"))
    end
  end

  describe "entry sizes" do
    test "cross the B / KB / MB / GB boundaries" do
      for {bytes, rendered} <- [
            {0, "0 B"},
            {999, "999 B"},
            {1_000, "1 KB"},
            {1_500, "1.5 KB"},
            {999_999, "1000 KB"},
            {1_000_000, "1 MB"},
            {2_400_000, "2.4 MB"},
            {8_000_000, "8 MB"},
            {999_999_999, "1000 MB"},
            {1_000_000_000, "1 GB"},
            {2_500_000_000, "2.5 GB"}
          ] do
        assert rendered_size(bytes) == rendered, "#{bytes} did not render as #{rendered}"
      end
    end

    test "a missing size renders nothing rather than crashing" do
      assert rendered_size(nil) == ""
    end
  end

  describe "the :entry slot" do
    test "replaces the default row entirely" do
      assigns = %{upload: config(entries: [entry(client_name: "q3.pdf")])}

      html =
        rendered_to_string(~H"""
        <.file_upload upload={@upload}>
          <:entry :let={entry}>
            <span class="mine">{entry.client_name}</span>
          </:entry>
        </.file_upload>
        """)

      assert html =~ ~s(<span class="mine">q3.pdf</span>)
      # the default row's furniture is gone
      assert Enum.empty?(query(html, "[role=progressbar]"))
      assert Enum.empty?(query(html, ".pc-file-upload__cancel"))
    end

    test "is invoked once per entry" do
      entries = [entry(ref: "0"), entry(ref: "1", client_name: "b.pdf")]
      assigns = %{upload: config(entries: entries)}

      html =
        rendered_to_string(~H"""
        <.file_upload upload={@upload}>
          <:entry :let={entry}><span class="mine">{entry.client_name}</span></:entry>
        </.file_upload>
        """)

      assert Enum.count(query(html, "span.mine")) == 2
    end

    test "applies to gallery tiles too" do
      assigns = %{upload: config(entries: [entry()], max_entries: 4)}

      html =
        rendered_to_string(~H"""
        <.file_upload upload={@upload} variant="gallery">
          <:entry :let={entry}><span class="mine">{entry.client_name}</span></:entry>
        </.file_upload>
        """)

      assert Enum.count(query(html, "span.mine")) == 1
    end
  end

  describe "accessibility" do
    test "the wrapper is a group labelled by the label element" do
      assigns = %{upload: config(ref: "phx-F1")}
      html = rendered_to_string(~H"<.file_upload upload={@upload} label=\"Receipts\" />")

      assert attr_of(html, ".pc-file-upload", "role") == "group"
      labelledby = attr_of(html, ".pc-file-upload", "aria-labelledby")
      assert labelledby == "pc-file-upload-phx-F1-label"
      assert attr_of(html, ".pc-file-upload__label", "id") == labelledby
      assert LazyHTML.attribute(query(html, ".pc-file-upload"), "aria-label") == []
    end

    test "falls back to aria-label when no label is given" do
      assigns = %{upload: config()}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert attr_of(html, ".pc-file-upload", "aria-label") == "File upload"
      assert LazyHTML.attribute(query(html, ".pc-file-upload"), "aria-labelledby") == []
    end

    # The hint's text never changes - only its opacity does - so a live region
    # here would be one that can never announce. It is decorative instead.
    test "the drag hint is decorative, not a live region" do
      for variant <- ~w(dropzone compact avatar gallery) do
        assigns = %{upload: config(), variant: variant}
        html = rendered_to_string(~H"<.file_upload upload={@upload} variant={@variant} />")

        hint = query(html, ".pc-file-upload__live")
        assert Enum.count(hint) == 1, "#{variant} did not render the hint"

        assert LazyHTML.attribute(hint, "aria-live") == [],
               "#{variant} still promises an announce"

        assert LazyHTML.attribute(hint, "aria-hidden") == ["true"]
        assert html =~ "Drop files to upload"
      end
    end

    test "cancel buttons are named after their file" do
      assigns = %{upload: config(entries: [entry(client_name: "q3.pdf")])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert attr_of(html, ".pc-file-upload__cancel", "aria-label") == "Cancel upload of q3.pdf"
    end

    test "cancel_label customises the accessible name prefix" do
      assigns = %{upload: config(entries: [entry(client_name: "q3.pdf")])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} cancel_label=\"Remove\" />")

      assert attr_of(html, ".pc-file-upload__cancel", "aria-label") == "Remove q3.pdf"
    end

    # aria-describedby has to hang off something focusable to be read: a plain
    # div with no role is not a widget, and the cancel button is the only
    # focusable thing in the row.
    test "entry errors are described from the row's cancel button" do
      assigns = %{
        upload: config(ref: "phx-F1", entries: [entry(ref: "9")], errors: [{"9", :too_large}])
      }

      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      described = attr_of(html, ".pc-file-upload__cancel", "aria-describedby")
      assert described == "pc-file-upload-phx-F1-9-error"
      assert attr_of(html, ".pc-file-upload__error--entry", "id") == described

      assert LazyHTML.attribute(query(html, ".pc-file-upload__entry-inner"), "aria-describedby") ==
               []
    end

    test "a clean row carries no dangling aria-describedby" do
      assigns = %{upload: config(entries: [entry()])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert LazyHTML.attribute(query(html, ".pc-file-upload__cancel"), "aria-describedby") == []

      assert LazyHTML.attribute(query(html, ".pc-file-upload__entry-inner"), "aria-describedby") ==
               []
    end

    test "config errors are described from the wrapper, and their ids are not dead" do
      assigns = %{
        upload:
          config(ref: "phx-F1", errors: [{"phx-F1", :too_many_files}, {"phx-F1", :too_large}])
      }

      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      described = attr_of(html, ".pc-file-upload", "aria-describedby")
      assert described == "pc-file-upload-phx-F1-error-0 pc-file-upload-phx-F1-error-1"

      assert query(html, ".pc-file-upload__error--config") |> LazyHTML.attribute("id") ==
               String.split(described, " ")
    end

    test "a clean config leaves no dangling aria-describedby on the wrapper" do
      assigns = %{upload: config(entries: [entry()])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      assert LazyHTML.attribute(query(html, ".pc-file-upload"), "aria-describedby") == []
    end

    test "decorative icons are hidden from assistive tech" do
      assigns = %{upload: config(entries: [entry()], errors: [{"0", :too_large}])}
      html = rendered_to_string(~H"<.file_upload upload={@upload} />")

      for selector <- [
            ".pc-file-upload__glyph",
            ".pc-file-upload__type-icon",
            ".pc-file-upload__cancel-icon",
            ".pc-file-upload__error-icon"
          ] do
        nodes = query(html, selector)
        refute Enum.empty?(nodes), "#{selector} was not rendered"

        assert LazyHTML.attribute(nodes, "aria-hidden") |> Enum.uniq() == ["true"],
               "#{selector} is not aria-hidden"
      end
    end

    test "the avatar replace overlay is decorative" do
      assigns = %{upload: config(max_entries: 1)}
      html = rendered_to_string(~H"<.file_upload upload={@upload} variant=\"avatar\" />")

      assert attr_of(html, ".pc-file-upload__overlay", "aria-hidden") == "true"
    end
  end

  describe "pass-through" do
    test "class lands on the wrapper alongside the component classes" do
      assigns = %{upload: config()}
      html = rendered_to_string(~H"<.file_upload upload={@upload} class=\"mt-8 max-w-lg\" />")

      classes = attr_of(html, ".pc-file-upload", "class")
      assert classes =~ "pc-file-upload"
      assert classes =~ "pc-file-upload--dropzone"
      assert classes =~ "mt-8 max-w-lg"
    end

    test "rest attributes land on the wrapper" do
      assigns = %{upload: config()}

      html =
        rendered_to_string(~H"<.file_upload upload={@upload} data-role=\"uploader\" hidden />")

      assert attr_of(html, ".pc-file-upload", "data-role") == "uploader"
      assert_attribute(html, "hidden")
    end

    test "id overrides the ref-derived default and drives the ARIA ids" do
      assigns = %{upload: config(entries: [entry(ref: "9")], errors: [{"9", :too_large}])}

      html =
        rendered_to_string(
          ~H"<.file_upload upload={@upload} id=\"my-uploader\" label=\"Docs\" />"
        )

      assert attr_of(html, ".pc-file-upload", "id") == "my-uploader"
      assert attr_of(html, ".pc-file-upload", "aria-labelledby") == "my-uploader-label"
      assert attr_of(html, ".pc-file-upload__error--entry", "id") == "my-uploader-9-error"
    end
  end
end
