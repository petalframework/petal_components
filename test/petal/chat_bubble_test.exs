defmodule PetalComponents.ChatBubbleTest do
  use ComponentCase
  import PetalComponents.ChatBubble

  test "default chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble author="Test User" message="Hello world" time="12:45" />
      """)

    assert html =~ "Test User"
    assert html =~ "Hello world"
    assert html =~ "12:45"
    assert html =~ "Delivered"
    assert html =~ "pc-chat-bubble--default"
  end

  test "voice note chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:voicenote} author="Voice User" time="15:20" duration="2:15" />
      """)

    assert html =~ "Voice User"
    assert html =~ "15:20"
    assert html =~ "2:15"
    assert html =~ "pc-chat-bubble--voice-note"
    assert html =~ ~s(<svg class="w-[145px] md:w-[185px] md:h-[40px]")
    assert html =~ ~s(<button class="inline-flex self-center items-center p-2)
  end

  test "file attachment chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:file_attachment} author="File User" time="16:45" />
      """)

    assert html =~ "File User"
    assert html =~ "16:45"
    assert html =~ "Petal Components Terms &amp; Conditions"
    assert html =~ "18 MB"
    assert html =~ "12 Pages"
    assert html =~ "PDF"
    assert html =~ "pc-chat-bubble--file-attachment"
    assert html =~ "Download file"
  end

  test "image attachment chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:image_attachment}
        author="Image User"
        time="17:00"
        image_src="https://example.com/image.jpg"
        image_alt="Example image"
      />
      """)

    assert html =~ "Image User"
    assert html =~ "17:00"
    assert html =~ ~s(src="https://example.com/image.jpg")
    assert html =~ ~s(alt="Example image")
    assert html =~ "pc-chat-bubble--image-attachment"
  end

  test "image gallery chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:image_gallery}
        author="Gallery User"
        time="18:00"
        images={[
          "https://example.com/image1.jpg",
          "https://example.com/image2.jpg",
          "https://example.com/image3.jpg",
          "https://example.com/image4.jpg"
        ]}
        extra_images_count={2}
      />
      """)

    assert html =~ "Gallery User"
    assert html =~ "18:00"
    assert html =~ ~s(src="https://example.com/image1.jpg")
    assert html =~ ~s(src="https://example.com/image2.jpg")
    assert html =~ ~s(src="https://example.com/image3.jpg")
    assert html =~ ~s(src="https://example.com/image4.jpg")
    assert html =~ "pc-chat-bubble--image-gallery"
  end

  test "URL preview sharing chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:url_preview_sharing}
        author="URL User"
        time="19:00"
        url="https://example.com"
        url_title="Example Title"
        url_description="Example Description"
        url_image="https://example.com/image.jpg"
        url_domain="example.com"
      />
      """)

    assert html =~ "URL User"
    assert html =~ "19:00"
    assert html =~ ~s(href="https://example.com")
    assert html =~ "Example Title"
    assert html =~ "Example Description"
    assert html =~ ~s(src="https://example.com/image.jpg")
    assert html =~ "example.com"
    assert html =~ "pc-chat-bubble--url-preview"
  end

  test "outline chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:outline_chat_bubble}
        author="Outline User"
        time="20:00"
        message="Outline message"
      />
      """)

    assert html =~ "Outline User"
    assert html =~ "20:00"
    assert html =~ "Outline message"
    assert html =~ "Delivered"
    assert html =~ "pc-chat-bubble--outline-chat-bubble"
  end

  test "outline voicenote chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:outline_voicenote} author="Outline Voice User" time="23:00" duration="3:00" />
      """)

    assert html =~ "Outline Voice User"
    assert html =~ "23:00"
    assert html =~ "3:00"
    assert html =~ "pc-chat-bubble--outline-voicenote"
    assert html =~ ~s(<svg class="w-[145px] md:w-[185px] md:h-[40px]")
    assert html =~ ~s(<button class="inline-flex self-center items-center p-2)
  end

  test "outline file attachment chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:outline_file_attachment}
        author="Outline File User"
        time="00:00"
        file_name="Outline File.pdf"
        file_size="10 MB"
        file_pages="5 Pages"
        file_type="PDF"
      />
      """)

    assert html =~ "Outline File User"
    assert html =~ "00:00"
    assert html =~ "Outline File.pdf"
    assert html =~ "10 MB"
    assert html =~ "5 Pages"
    assert html =~ "PDF"
    assert html =~ "pc-chat-bubble--outline-file-attachment"
    assert html =~ "Download file"
  end

  test "outline image attachment chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:outline_image_attachment}
        author="Outline Image User"
        time="01:00"
        image_src="https://example.com/outline_image.jpg"
        image_alt="Outline Example Image"
      />
      """)

    assert html =~ "Outline Image User"
    assert html =~ "01:00"
    assert html =~ ~s(src="https://example.com/outline_image.jpg")
    assert html =~ ~s(alt="Outline Example Image")
    assert html =~ "pc-chat-bubble--outline-image-attachment"
  end

  test "outline image gallery chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:outline_image_gallery}
        author="Outline Gallery User"
        time="01:00"
        images={[
          "https://example.com/image1.jpg",
          "https://example.com/image2.jpg",
          "https://example.com/image3.jpg"
        ]}
        extra_images_count={5}
      />
      """)

    assert html =~ "Outline Gallery User"
    assert html =~ "01:00"
    assert html =~ "pc-chat-bubble--outline-image-gallery"
    assert html =~ ~s(src="https://example.com/image1.jpg")
    assert html =~ ~s(src="https://example.com/image2.jpg")
    assert html =~ ~s(src="https://example.com/image3.jpg")
    assert html =~ "+5"
  end

  test "outline URL preview sharing chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:outline_url_preview_sharing}
        author="Outline URL User"
        time="22:00"
        url="https://example.com"
        url_title="Outline Example Title"
        url_description="Outline Example Description"
        url_image="https://example.com/image.jpg"
        url_domain="example.com"
      />
      """)

    assert html =~ "Outline URL User"
    assert html =~ "22:00"
    assert html =~ ~s(href="https://example.com")
    assert html =~ "Outline Example Title"
    assert html =~ "Outline Example Description"
    assert html =~ ~s(src="https://example.com/image.jpg")
    assert html =~ "example.com"
    assert html =~ "pc-chat-bubble--outline-url-preview"
  end

  test "clean chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_chat_bubble} author="Clean User" time="21:00" message="Clean message" />
      """)

    assert html =~ "Clean User"
    assert html =~ "21:00"
    assert html =~ "Clean message"
    assert html =~ "Delivered"
    assert html =~ "pc-chat-bubble--clean-chat-bubble"
  end

  test "clean voicenote chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble kind={:clean_voicenote} author="Clean Voice User" time="23:00" duration="3:00" />
      """)

    assert html =~ "Clean Voice User"
    assert html =~ "23:00"
    assert html =~ "3:00"
    assert html =~ "pc-chat-bubble--clean-voicenote"
    assert html =~ ~s(<svg class="w-[145px] md:w-[185px] md:h-[40px]")
    assert html =~ ~s(<button class="inline-flex self-center items-center p-2)
  end

  test "clean file attachment chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:clean_file_attachment}
        author="Clean File User"
        time="00:00"
        file_name="Clean File.pdf"
        file_size="10 MB"
        file_pages="5 Pages"
        file_type="PDF"
      />
      """)

    assert html =~ "Clean File User"
    assert html =~ "00:00"
    assert html =~ "Clean File.pdf"
    assert html =~ "10 MB"
    assert html =~ "5 Pages"
    assert html =~ "PDF"
    assert html =~ "pc-chat-bubble--clean-file-attachment"
    assert html =~ "Download file"
  end

  test "clean image attachment chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:clean_image_attachment}
        author="Clean Image User"
        time="02:00"
        image_src="https://example.com/clean_image.jpg"
        image_alt="Clean Example Image"
      />
      """)

    assert html =~ "Clean Image User"
    assert html =~ "02:00"
    assert html =~ ~s(src="https://example.com/clean_image.jpg")
    assert html =~ ~s(alt="Clean Example Image")
    assert html =~ "pc-chat-bubble--clean-image-attachment"
  end

  test "clean image gallery chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:clean_image_gallery}
        author="Clean Gallery User"
        time="03:00"
        images={[
          "https://example.com/image1.jpg",
          "https://example.com/image2.jpg",
          "https://example.com/image3.jpg"
        ]}
        extra_images_count={4}
      />
      """)

    assert html =~ "Clean Gallery User"
    assert html =~ "03:00"
    assert html =~ "pc-chat-bubble--clean-image-gallery"
    assert html =~ ~s(src="https://example.com/image1.jpg")
    assert html =~ ~s(src="https://example.com/image2.jpg")
    assert html =~ ~s(src="https://example.com/image3.jpg")
    assert html =~ "+4"
  end

  test "clean URL preview sharing chat bubble" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.chat_bubble
        kind={:clean_url_preview_sharing}
        author="Clean URL User"
        time="02:00"
        url="https://example.com"
        url_title="Clean Example Title"
        url_description="Clean Example Description"
        url_image="https://example.com/image.jpg"
        url_domain="example.com"
      />
      """)

    assert html =~ "Clean URL User"
    assert html =~ "02:00"
    assert html =~ ~s(href="https://example.com")
    assert html =~ "Clean Example Title"
    assert html =~ "Clean Example Description"
    assert html =~ ~s(src="https://example.com/image.jpg")
    assert html =~ "example.com"
    assert html =~ "pc-chat-bubble--clean-url-preview"
  end
end
