defmodule PetalComponents.ChatBubbleTest do
  use ComponentCase
  import PetalComponents.ChatBubble

  test "renders chat_bubble without specifying kind" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as default_chat_bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:default_chat_bubble} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as voice_note_message" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:voice_note_message} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as file_attachment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:file_attachment} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as image_attachment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:image_attachment} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

 
  test "renders chat_bubble specifying kind as image_gallery" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:image_gallery} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as url_preview_sharing" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:url_preview_sharing} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as outline_chat_bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:outline_chat_bubble} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as outline_voicenote" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:outline_voicenote} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as outline_file_attachment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:outline_file_attachment} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as outline_image_attachment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:outline_image_attachment} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as outline_image_gallery" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:outline_image_gallery} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as outline_url_preview_sharing" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:outline_url_preview_sharing} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as clean_chat_bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_chat_bubble} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as clean_voicenote" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_voicenote} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as clean_file_attachment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_file_attachment} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as clean_image_attachment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_image_attachment} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as clean_image_gallery" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_image_gallery} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end

  test "renders chat_bubble specifying kind as clean_url_preview_sharing" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_url_preview_sharing} />
      """)

    assert html =~ "class=\"flex items-start gap-2.5\""
  end
end