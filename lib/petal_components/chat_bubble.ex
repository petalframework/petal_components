defmodule PetalComponents.ChatBubble do
  use Phoenix.Component

  # Base chat bubble component
  attr(:author, :string, default: "Sarah Hill", doc: "author name for the chat message")
  attr(:message, :string, default: "That's awesome. I think our users will really appreciate the improvements.", doc: "main message content")
  attr(:time, :string, default: "10:13", doc: "timestamp for the message")
  attr(:avatar_src, :string, default: "https://res.cloudinary.com/wickedsites/image/upload/v1604268092/unnamed_sagz0l.jpg", doc: "hosted avatar URL")
  attr(:avatar_alt, :string, default: nil, doc: "alt text for avatar image")
  attr(:kind, :atom, default: :default_chat_bubble, 
    values: [
      :default_chat_bubble, :voicenote, :file_attachment,
      :image_attachment, :image_gallery, :url_preview_sharing,
      :outline_chat_bubble, :outline_voicenote, :outline_file_attachment,
      :outline_image_attachment, :outline_image_gallery, :outline_url_preview_sharing,
      :clean_chat_bubble, :clean_voicenote, :clean_file_attachment,
      :clean_image_attachment, :clean_image_gallery, :clean_url_preview_sharing
    ],
    doc: "determines the type of chat bubble to render"
  )
  attr(:class, :any, default: nil, doc: "additional css classes")
  attr(:rest, :global)

  # File attributes
  attr(:file_name, :string, default: "Petal Components Terms & Conditions", doc: "name of the attached file")
  attr(:file_size, :string, default: "18 MB", doc: "size of the attached file")
  attr(:file_pages, :string, default: "12 Pages", doc: "number of pages in document")
  attr(:file_type, :string, default: "PDF", doc: "type of file")
  
  # Voice note attributes
  attr(:duration, :string, default: "3:42", doc: "duration of voice note")
  
  # Image attributes
  attr(:image_src, :string, default: "https://images.unsplash.com/photo-1562664377-709f2c337eb2", doc: "URL of the attached image")
  attr(:image_alt, :string, default: "Image attachment", doc: "alt text for attached image")
  
  # Gallery attributes
  attr(:images, :list, 
    default: [
      "https://images.unsplash.com/photo-1552664730-d307ca884978",
      "https://images.unsplash.com/photo-1551434678-e076c223a692",
      "https://images.unsplash.com/photo-1562664377-709f2c337eb2",
      "https://petal.build/images/logo_dark.svg"
    ],
    doc: "list of gallery image URLs"
  )
  attr(:extra_images_count, :integer, default: 7, doc: "number of additional images not shown")
  
  # URL Preview attributes
  attr(:url, :string, default: "https://petal.build/components", doc: "URL to preview")
  attr(:url_title, :string, default: "Welcome to Petal Components", doc: "title of the URL preview")
  attr(:url_description, :string, default: "A versatile set of beautifully styled components", doc: "description for the URL preview")
  attr(:url_image, :string, default: "https://petal.build/images/favicon.png", doc: "image for the URL preview")
  attr(:url_domain, :string, default: "github.com", doc: "domain name for the URL")
   
  def chat_bubble(assigns) do
    case assigns.kind do
      :default_chat_bubble -> render_default_chat_bubble(assigns)
      :voicenote -> render_voicenote(assigns)
      :file_attachment -> render_file_attachment(assigns)
      :image_attachment -> render_image_attachment(assigns)
      :image_gallery -> render_image_gallery(assigns)
      :url_preview_sharing -> render_url_preview_sharing(assigns)
      
      # Outline variants
      :outline_chat_bubble -> render_outline_chat_bubble(assigns)
      :outline_voicenote -> render_outline_voicenote(assigns)
      :outline_file_attachment -> render_outline_file_attachment(assigns)
      :outline_image_attachment -> render_outline_image_attachment(assigns)
      :outline_image_gallery -> render_outline_image_gallery(assigns)
      :outline_url_preview_sharing -> render_outline_url_preview_sharing(assigns)
      
      # Clean variants
      :clean_chat_bubble -> render_clean_chat_bubble(assigns)
      :clean_voicenote -> render_clean_voicenote(assigns)
      :clean_file_attachment -> render_clean_file_attachment(assigns)
      :clean_image_attachment -> render_clean_image_attachment(assigns)
      :clean_image_gallery -> render_clean_image_gallery(assigns)
      :clean_url_preview_sharing -> render_clean_url_preview_sharing(assigns)
      
      # Default fallback
      _ -> render_default_chat_bubble(assigns)
    end
  end

  defp render_header(assigns) do
  ~H"""
  <div class="flex items-center space-x-2 rtl:space-x-reverse">
    <span class="text-sm font-semibold text-gray-900 dark:text-white"><%= @author %></span>
    <span class="text-sm font-normal text-gray-500 dark:text-gray-400"><%= @time %></span>
  </div>
  """
end
  
defp render_default_chat_bubble(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--default", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col w-full max-w-[320px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal py-2.5 text-gray-900 dark:text-white"><%= @message %></p>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_waveform(assigns) do
  ~H"""
  <div class="flex items-center space-x-2 rtl:space-x-reverse">
    <button class="inline-flex self-center items-center p-2 text-sm font-medium text-center text-gray-900 bg-gray-100 rounded-lg hover:bg-gray-200 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50 dark:bg-gray-700 dark:hover:bg-gray-600 dark:focus:ring-gray-600" type="button">
      <svg class="w-4 h-4 text-gray-800 dark:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 12 16">
        <path d="M3 0H2a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2Zm7 0H9a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2Z"/>
      </svg>
    </button>
    <svg class="w-[145px] md:w-[185px] md:h-[40px]" aria-hidden="true" viewBox="0 0 185 40" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect y="17" width="3" height="6" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="7" y="15.5" width="3" height="9" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="21" y="6.5" width="3" height="27" rx="1.5" fill="#6B7280"class="dark:fill-white"/>
      <rect x="14" y="6.5" width="3" height="27" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="28" y="3" width="3" height="34" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="35" y="3" width="3" height="34" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="42" y="5.5" width="3" height="29" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="49" y="10" width="3" height="20" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="56" y="13.5" width="3" height="13" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="63" y="16" width="3" height="8" rx="1.5" fill="#6B7280" class="dark:fill-white"/>
      <rect x="70" y="12.5" width="3" height="15" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="77" y="3" width="3" height="34" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="84" y="3" width="3" height="34" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="91" y="0.5" width="3" height="39" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="98" y="0.5" width="3" height="39" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="105" y="2" width="3" height="36" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="112" y="6.5" width="3" height="27" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="119" y="9" width="3" height="22" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="126" y="11.5" width="3" height="17" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="133" y="2" width="3" height="36" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="140" y="2" width="3" height="36" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="147" y="7" width="3" height="26" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="154" y="9" width="3" height="22" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="161" y="9" width="3" height="22" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="168" y="13.5" width="3" height="13" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="175" y="16" width="3" height="8" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="182" y="17.5" width="3" height="5" rx="1.5" fill="#E5E7EB" class="dark:fill-gray-500"/>
      <rect x="66" y="16" width="8" height="8" rx="4" fill="#1C64F2"/>
    </svg>
    <span class="inline-flex self-center items-center p-2 text-sm font-medium text-gray-900 dark:text-white"><%= assigns[:duration] %></span>
  </div>
  """
end

defp render_voicenote(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:class, assigns[:class])
    |> assign(:duration, assigns[:duration])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--voice-note", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1 w-full max-w-[320px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
        <%= render_header(assigns) %>
        <%= render_waveform(assigns) %>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_file_attachment(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:class, assigns[:class])
    |> assign(:file_name, assigns[:file_name])
    |> assign(:file_size, assigns[:file_size])
    |> assign(:file_pages, assigns[:file_pages])
    |> assign(:file_type, assigns[:file_type])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--file-attachment", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1">
        <div class="flex flex-col w-full max-w-[326px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <div class="flex items-center space-x-2 rtl:space-x-reverse">
            <span class="text-sm font-semibold text-gray-900 dark:text-white"><%= @author %></span>
            <span class="text-sm font-normal text-gray-500 dark:text-gray-400"><%= @time %></span>
          </div>
          <div class="flex items-start my-2.5 bg-gray-50 dark:bg-gray-600 rounded-xl p-2">
            <div class="me-2">
              <span class="flex items-center gap-2 text-sm font-medium text-gray-900 dark:text-white pb-2">
                <svg fill="none" aria-hidden="true" class="w-5 h-5 shrink-0" viewBox="0 0 20 21">
                     <g clip-path="url(#clip0_3173_1381)">
                        <path fill="#E2E5E7" d="M5.024.5c-.688 0-1.25.563-1.25 1.25v17.5c0 .688.562 1.25 1.25 1.25h12.5c.687 0 1.25-.563 1.25-1.25V5.5l-5-5h-8.75z"/>
                        <path fill="#B0B7BD" d="M15.024 5.5h3.75l-5-5v3.75c0 .688.562 1.25 1.25 1.25z"/>
                        <path fill="#CAD1D8" d="M18.774 9.25l-3.75-3.75h3.75v3.75z"/>
                        <path fill="#F15642" d="M16.274 16.75a.627.627 0 01-.625.625H1.899a.627.627 0 01-.625-.625V10.5c0-.344.281-.625.625-.625h13.75c.344 0 .625.281.625.625v6.25z"/>
                        <path fill="#fff" d="M3.998 12.342c0-.165.13-.345.34-.345h1.154c.65 0 1.235.435 1.235 1.269 0 .79-.585 1.23-1.235 1.23h-.834v.66c0 .22-.14.344-.32.344a.337.337 0 01-.34-.344v-2.814zm.66.284v1.245h.834c.335 0 .6-.295.6-.605 0-.35-.265-.64-.6-.64h-.834zM7.706 15.5c-.165 0-.345-.09-.345-.31v-2.838c0-.18.18-.31.345-.31H8.85c2.284 0 2.234 3.458.045 3.458h-1.19zm.315-2.848v2.239h.83c1.349 0 1.409-2.24 0-2.24h-.83zM11.894 13.486h1.274c.18 0 .36.18.36.355 0 .165-.18.3-.36.3h-1.274v1.049c0 .175-.124.31-.3.31-.22 0-.354-.135-.354-.31v-2.839c0-.18.135-.31.355-.31h1.754c.22 0 .35.13.35.31 0 .16-.13.34-.35.34h-1.455v.795z"/>
                        <path fill="#CAD1D8" d="M15.649 17.375H3.774V18h11.875a.627.627 0 00.625-.625v-.625a.627.627 0 01-.625.625z"/>
                     </g>
                     <defs>
                        <clipPath id="clip0_3173_1381">
                           <path fill="#fff" d="M0 0h20v20H0z" transform="translate(0 .5)"/>
                        </clipPath>
                     </defs>
                  </svg>
                <%= @file_name %>
              </span>
              <span class="flex text-xs font-normal text-gray-500 dark:text-gray-400 gap-2">
                <%= @file_pages %> 
                <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="self-center" width="3" height="4" viewBox="0 0 3 4" fill="none">
                  <circle cx="1.5" cy="2" r="1.5" fill="#6B7280"/>
                </svg>
                <%= @file_size %> 
                <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="self-center" width="3" height="4" viewBox="0 0 3 4" fill="none">
                  <circle cx="1.5" cy="2" r="1.5" fill="#6B7280"/>
                </svg>
                <%= @file_type %>
              </span>
            </div>
            <!-- Download button -->
            <div class="relative inline-flex self-center items-center" x-data="{ showTooltip: false }">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false"
                class="inline-flex self-center items-center p-2 text-sm font-medium text-center text-gray-900 bg-gray-50 rounded-lg hover:bg-gray-100 focus:ring-4 focus:outline-none dark:text-white"
                type="button"
              >
                <svg class="w-4 h-4 text-gray-900 dark:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M14.707 7.793a1 1 0 0 0-1.414 0L11 10.086V1.5a1 1 0 0 0-2 0v8.586L6.707 7.793a1 1 0 1 0-1.414 1.414l4 4a1 1 0 0 0 1.416 0l4-4a1 1 0 0 0-.002-1.414Z"/>
                  <path d="M18 12h-2.55l-2.975 2.975a3.5 3.5 0 0 1-4.95 0L4.55 12H2a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-4a2 2 0 0 0-2-2Zm-3 5a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"/>
                </svg>
              </button>
              <!-- Alpine.js Tooltip -->
              <div 
                x-show="showTooltip"
                x-transition
                class="absolute bottom-full mb-2 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700 whitespace-nowrap"
                aria-label="Tooltip text"
              >
                Download file
              </div>
            </div>
          </div>
          <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
        </div>
      </div>
    </div>
  </div>
  """
end

defp render_image_attachment(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:image_src, assigns[:image_src])
    |> assign(:image_alt, assigns[:image_alt])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--image-attachment", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1">
        <div class="flex flex-col w-full max-w-[326px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <div class="flex items-center space-x-2 rtl:space-x-reverse mb-2">
            <span class="text-sm font-semibold text-gray-900 dark:text-white"><%= @author %></span>
            <span class="text-sm font-normal text-gray-500 dark:text-gray-400"><%= @time %></span>
          </div>
          <p class="text-sm font-normal text-gray-900 dark:text-white"><%= @message %></p>

          <div x-data="{ showTooltip: false }" class="group relative my-2.5">
            <div class="absolute w-full h-full bg-gray-900/50 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg flex items-center justify-center">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false" 
                class="inline-flex items-center justify-center rounded-full h-10 w-10 bg-white/30 hover:bg-white/50 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50"
              >
                <svg class="w-5 h-5 text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                  <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
                </svg>
              </button>
              <!-- Tooltip -->
              <div 
                x-show="showTooltip" 
                x-transition 
                class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                aria-label="Tooltip text"
              >
                Download image
              </div>
            </div>
            <img src={@image_src} alt={@image_alt} class="rounded-lg" />
          </div>
          <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
        </div>
      </div>
    </div>
  </div>
  """
end

defp render_image_gallery(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:images, assigns[:images] || [])
    |> assign(:extra_images_count, assigns[:extra_images_count] || 0)
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--image-gallery", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1">
        <div class="flex flex-col w-full max-w-[326px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <div class="flex items-center space-x-2 rtl:space-x-reverse mb-2">
            <span class="text-sm font-semibold text-gray-900 dark:text-white"><%= @author %></span>
            <span class="text-sm font-normal text-gray-500 dark:text-gray-400"><%= @time %></span>
          </div>
          <p class="text-sm font-normal text-gray-900 dark:text-white"><%= @message %></p>
          
          <!-- Image Grid with Tooltips -->
          <div class="grid gap-4 grid-cols-2 my-2.5">
            <!-- First 3 Images -->
            <%= for {img, _index} <- Enum.with_index(Enum.take(@images, 3)) do %>
              <div x-data="{ showTooltip: false }" class="group relative">
                <div class="absolute w-full h-full bg-gray-900/50 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg flex items-center justify-center">
                  <button 
                    @mouseenter="showTooltip = true" 
                    @mouseleave="showTooltip = false" 
                    class="inline-flex items-center justify-center rounded-full h-8 w-8 bg-white/30 hover:bg-white/50 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50"
                  >
                    <svg class="w-4 h-4 text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
                    </svg>
                  </button>
                  <!-- Alpine.js Tooltip -->
                  <div 
                    x-show="showTooltip"
                    x-transition
                    class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                    aria-label="Tooltip text"
                  >
                    Download image
                  </div>
                </div>
                <img src={img} class="rounded-lg" />
              </div>
            <% end %>
            
            <!-- Extra Images Overlay -->
            <div x-data="{ showTooltip: false }" class="group relative">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false"
                class="absolute w-full h-full bg-gray-900/90 hover:bg-gray-900/50 transition-all duration-300 rounded-lg flex items-center justify-center"
              >
                <span class="text-xl font-medium text-white">+<%= @extra_images_count %></span>
              </button>
              <div 
                x-show="showTooltip"
                x-transition
                class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                aria-label="Tooltip text"
              >
                View more
              </div>
              <%= if length(@images) > 3 do %>
                <img src={Enum.at(@images, 3)} class="rounded-lg" />
              <% else %>
                <div class="rounded-lg bg-gray-300 dark:bg-gray-500 aspect-square"></div>
              <% end %>
            </div>
          </div>

          <div class="flex justify-between items-center">
            <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
            <button class="text-sm text-blue-700 dark:text-blue-500 font-medium inline-flex items-center hover:underline">
              <svg class="w-3 h-3 me-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
              </svg>
              Save all
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
  """
end

defp render_url_preview_sharing(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:url, assigns[:url])
    |> assign(:url_title, assigns[:url_title])
    |> assign(:url_description, assigns[:url_description])
    |> assign(:url_image, assigns[:url_image])
    |> assign(:url_domain, assigns[:url_domain])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--url-preview", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col w-full max-w-[320px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal py-2.5 text-gray-900 dark:text-white"><%= @message %></p>
        <p class="text-sm font-normal pb-2.5 text-gray-900 dark:text-white">
          <a href={@url} class="text-blue-700 dark:text-blue-500 underline hover:no-underline font-medium break-all"><%= @url %></a>
        </p>
        <a href={@url} class="bg-gray-50 dark:bg-gray-600 rounded-xl p-4 mb-2 hover:bg-gray-200 dark:hover:bg-gray-500 cursor-pointer">
          <img src={@url_image} class="rounded-lg mb-2" />
          <div class="w-full p-2.5 bg-white dark:bg-gray-800">
            <p class="text-sm font-medium text-gray-900 dark:text-white"><%= @url_title %></p>
            <p class="text-xs font-normal text-gray-500 dark:text-gray-400 my-1"><%= @url_description %></p>
            <span class="flex items-center text-xs font-normal text-gray-500 dark:text-gray-400">
              <svg class="w-3 h-3 me-1" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.083 8.222L8.364 3.94a1.59 1.59 0 0 1 2.25 0l4.279 4.28a1.59 1.59 0 0 1 0 2.251l-4.28 4.28a1.59 1.59 0 0 1-2.25 0l-4.28-4.28a1.591 1.591 0 0 1 0-2.251z"/>
              </svg>
              <%= @url_domain %>
            </span>
          </div>
        </a>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_outline_chat_bubble(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--outline-chat-bubble", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1">
        <%= render_header(assigns) %>
        <div class="flex flex-col w-full max-w-[326px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <p class="text-sm font-normal py-2.5 text-gray-900 dark:text-white"><%= @message %></p>
        </div>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_outline_voicenote(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--outline-voicenote", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1 w-full max-w-[326px]">
        <%= render_header(assigns) %>
        <div class="flex flex-col leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <%= render_waveform(assigns) %>
        </div>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_outline_file_attachment(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:file_name, assigns[:file_name])
    |> assign(:file_size, assigns[:file_size])
    |> assign(:file_pages, assigns[:file_pages])
    |> assign(:file_type, assigns[:file_type])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--outline-file-attachment", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1">
        <%= render_header(assigns) %>
        <div class="flex flex-col w-full max-w-[320px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <div class="flex items-start bg-gray-50 dark:bg-gray-600 rounded-xl p-2">
            <div class="me-2">
              <span class="flex items-center gap-2 text-sm font-medium text-gray-900 dark:text-white pb-2">
                <svg fill="none" aria-hidden="true" class="w-5 h-5 shrink-0" viewBox="0 0 20 21">
                     <g clip-path="url(#clip0_3173_1381)">
                        <path fill="#E2E5E7" d="M5.024.5c-.688 0-1.25.563-1.25 1.25v17.5c0 .688.562 1.25 1.25 1.25h12.5c.687 0 1.25-.563 1.25-1.25V5.5l-5-5h-8.75z"/>
                        <path fill="#B0B7BD" d="M15.024 5.5h3.75l-5-5v3.75c0 .688.562 1.25 1.25 1.25z"/>
                        <path fill="#CAD1D8" d="M18.774 9.25l-3.75-3.75h3.75v3.75z"/>
                        <path fill="#F15642" d="M16.274 16.75a.627.627 0 01-.625.625H1.899a.627.627 0 01-.625-.625V10.5c0-.344.281-.625.625-.625h13.75c.344 0 .625.281.625.625v6.25z"/>
                        <path fill="#fff" d="M3.998 12.342c0-.165.13-.345.34-.345h1.154c.65 0 1.235.435 1.235 1.269 0 .79-.585 1.23-1.235 1.23h-.834v.66c0 .22-.14.344-.32.344a.337.337 0 01-.34-.344v-2.814zm.66.284v1.245h.834c.335 0 .6-.295.6-.605 0-.35-.265-.64-.6-.64h-.834zM7.706 15.5c-.165 0-.345-.09-.345-.31v-2.838c0-.18.18-.31.345-.31H8.85c2.284 0 2.234 3.458.045 3.458h-1.19zm.315-2.848v2.239h.83c1.349 0 1.409-2.24 0-2.24h-.83zM11.894 13.486h1.274c.18 0 .36.18.36.355 0 .165-.18.3-.36.3h-1.274v1.049c0 .175-.124.31-.3.31-.22 0-.354-.135-.354-.31v-2.839c0-.18.135-.31.355-.31h1.754c.22 0 .35.13.35.31 0 .16-.13.34-.35.34h-1.455v.795z"/>
                        <path fill="#CAD1D8" d="M15.649 17.375H3.774V18h11.875a.627.627 0 00.625-.625v-.625a.627.627 0 01-.625.625z"/>
                     </g>
                     <defs>
                        <clipPath id="clip0_3173_1381">
                           <path fill="#fff" d="M0 0h20v20H0z" transform="translate(0 .5)"/>
                        </clipPath>
                     </defs>
                  </svg>
                <%= @file_name %>
              </span>
              <span class="flex text-xs font-normal text-gray-500 dark:text-gray-400 gap-2">
                <%= @file_pages %>
                <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="self-center" width="3" height="4" viewBox="0 0 3 4" fill="none">
                  <circle cx="1.5" cy="2" r="1.5" fill="#6B7280"/>
                </svg>
                <%= @file_size %>
                <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="self-center" width="3" height="4" viewBox="0 0 3 4" fill="none">
                  <circle cx="1.5" cy="2" r="1.5" fill="#6B7280"/>
                </svg>
                <%= @file_type %>
              </span>
            </div>
            <!-- Download button -->
            <div class="relative inline-flex self-center items-center" x-data="{ showTooltip: false }">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false"
                class="inline-flex self-center items-center p-2 text-sm font-medium text-center text-gray-900 bg-gray-50 rounded-lg hover:bg-gray-100 focus:ring-4 focus:outline-none dark:text-white"
                type="button"
              >
                <svg class="w-4 h-4 text-gray-900 dark:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M14.707 7.793a1 1 0 0 0-1.414 0L11 10.086V1.5a1 1 0 0 0-2 0v8.586L6.707 7.793a1 1 0 1 0-1.414 1.414l4 4a1 1 0 0 0 1.416 0l4-4a1 1 0 0 0-.002-1.414Z"/>
                  <path d="M18 12h-2.55l-2.975 2.975a3.5 3.5 0 0 1-4.95 0L4.55 12H2a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-4a2 2 0 0 0-2-2Zm-3 5a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"/>
                </svg>
              </button>
              <div 
                x-show="showTooltip"
                x-transition
                class="absolute bottom-full mb-2 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700 whitespace-nowrap"
                aria-label="Tooltip text"
              >
                Download file
              </div>
            </div>
          </div>
        </div>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_outline_image_attachment(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:image_src, assigns[:image_src])
    |> assign(:image_alt, assigns[:image_alt])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--outline-image-attachment", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1 w-full max-w-[326px]">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal text-gray-900 dark:text-white"><%= @message %></p>
        <div class="flex flex-col w-full leading-1.5 p-2 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <div x-data="{ showTooltip: false }" class="group relative border-gray-200 bg-gray-100 p-2 rounded-lg dark:bg-gray-700">
            <div class="absolute w-full h-full bg-gray-900/50 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg flex items-center justify-center">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false" 
                class="inline-flex items-center justify-center rounded-full h-10 w-10 bg-white/30 hover:bg-white/50 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50"
              >
                <svg class="w-5 h-5 text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                  <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
                </svg>
              </button>
              <div 
                x-show="showTooltip" 
                x-transition 
                class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                    aria-label="Tooltip text"
              >
                Download image
              </div>
            </div>
            <img src={@image_src} alt={@image_alt} class="rounded-lg" />
          </div>
        </div>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_outline_image_gallery(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:images, assigns[:images] || [])
    |> assign(:extra_images_count, assigns[:extra_images_count] || 0)
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--outline-image-gallery", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal text-gray-900 dark:text-white max-w-[326px]"><%= @message %></p>
        <div class="flex flex-col w-full max-w-[326px] leading-1.5 p-2 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <!-- Image Grid -->
          <div class="grid gap-4 grid-cols-2 my-2.5">
            <%= for {img, _index} <- Enum.with_index(Enum.take(@images, 3)) do %>
              <div x-data="{ showTooltip: false }" class="group relative">
                <div class="absolute w-full h-full bg-gray-900/50 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg flex items-center justify-center">
                  <button 
                    @mouseenter="showTooltip = true" 
                    @mouseleave="showTooltip = false"
                    class="inline-flex items-center justify-center rounded-full h-8 w-8 bg-white/30 hover:bg-white/50 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50"
                  >
                    <svg class="w-4 h-4 text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
                    </svg>
                  </button>
                  <div 
                    x-show="showTooltip"
                    x-transition
                    class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                    aria-label="Tooltip text"
                  >
                    Download image
                  </div>
                </div>
                <img src={img} class="rounded-lg" />
              </div>
            <% end %>
            <!-- Extra Images Overlay -->
            <div x-data="{ showTooltip: false }" class="group relative">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false"
                class="absolute w-full h-full bg-gray-900/90 hover:bg-gray-900/50 transition-all duration-300 rounded-lg flex items-center justify-center"
              >
                <span class="text-xl font-medium text-white">+<%= @extra_images_count %></span>
              </button>
              <div 
                x-show="showTooltip"
                x-transition
                class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                    aria-label="Tooltip text"

              >
                View more
              </div>
              <%= if length(@images) > 3 do %>
                <img src={Enum.at(@images, 3)} class="rounded-lg" />
              <% else %>
                <div class="rounded-lg bg-gray-300 dark:bg-gray-500 aspect-square"></div>
              <% end %>
            </div>
          </div>

          
        <div class="flex justify-end items-center">
            <button class="text-sm text-blue-700 dark:text-blue-500 font-medium inline-flex items-center hover:underline">
                <svg class="w-3 h-3 me-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                    <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
                </svg>
            Save all</button>
         </div>
          </div>
          <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_outline_url_preview_sharing(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:url, assigns[:url])
    |> assign(:url_title, assigns[:url_title])
    |> assign(:url_description, assigns[:url_description])
    |> assign(:url_image, assigns[:url_image])
    |> assign(:url_domain, assigns[:url_domain])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--outline-url-preview", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1 w-full max-w-[320px]">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal py-2.5 text-gray-900 dark:text-white"><%= @message %></p>
        <div class="flex flex-col w-full leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
          <p class="text-sm font-normal pb-2.5 text-gray-900 dark:text-white">
            <a href={@url} class="text-blue-700 dark:text-blue-500 underline hover:no-underline font-medium break-all"><%= @url %></a>
          </p>
          <a href={@url} class="flex flex-col items-start hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer">
            <img class="w-full h-auto object-cover" src={@url_image} alt="">
            <div class="w-full p-2.5 bg-white dark:bg-gray-800">
              <p class="text-sm font-medium text-gray-900 dark:text-white"><%= @url_title %></p>
              <p class="text-xs font-normal text-gray-500 dark:text-gray-400 my-1"><%= @url_description %></p>
              <span class="flex items-center text-xs font-normal text-gray-500 dark:text-gray-400">
                <svg class="w-3 h-3 me-1" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M4.083 8.222L8.364 3.94a1.59 1.59 0 0 1 2.25 0l4.279 4.28a1.59 1.59 0 0 1 0 2.251l-4.28 4.28a1.59 1.59 0 0 1-2.25 0l-4.28-4.28a1.591 1.591 0 0 1 0-2.251z"/>
                </svg>
                <%= @url_domain %>
              </span>
            </div>
          </a>
        </div>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_clean_chat_bubble(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--clean-chat-bubble", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col w-full max-w-[320px] leading-1.5">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal py-2.5 text-gray-900 dark:text-white"><%= @message %></p>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_clean_voicenote(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--clean-voicenote", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col w-full max-w-[320px] leading-1.5">
        <%= render_header(assigns) %>
        <%= render_waveform(assigns) %>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_clean_file_attachment(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:file_name, assigns[:file_name])
    |> assign(:file_size, assigns[:file_size])
    |> assign(:file_pages, assigns[:file_pages])
    |> assign(:file_type, assigns[:file_type])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--clean-file-attachment", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col w-full max-w-[326px] leading-1.5">
        <%= render_header(assigns) %>
        <div class="flex items-start my-2.5 bg-gray-50 dark:bg-gray-600 rounded-xl p-2">
          <div class="me-2">
            <span class="flex items-center gap-2 text-sm font-medium text-gray-900 dark:text-white pb-2">
              <svg fill="none" aria-hidden="true" class="w-5 h-5 shrink-0" viewBox="0 0 20 21">
                     <g clip-path="url(#clip0_3173_1381)">
                        <path fill="#E2E5E7" d="M5.024.5c-.688 0-1.25.563-1.25 1.25v17.5c0 .688.562 1.25 1.25 1.25h12.5c.687 0 1.25-.563 1.25-1.25V5.5l-5-5h-8.75z"/>
                        <path fill="#B0B7BD" d="M15.024 5.5h3.75l-5-5v3.75c0 .688.562 1.25 1.25 1.25z"/>
                        <path fill="#CAD1D8" d="M18.774 9.25l-3.75-3.75h3.75v3.75z"/>
                        <path fill="#F15642" d="M16.274 16.75a.627.627 0 01-.625.625H1.899a.627.627 0 01-.625-.625V10.5c0-.344.281-.625.625-.625h13.75c.344 0 .625.281.625.625v6.25z"/>
                        <path fill="#fff" d="M3.998 12.342c0-.165.13-.345.34-.345h1.154c.65 0 1.235.435 1.235 1.269 0 .79-.585 1.23-1.235 1.23h-.834v.66c0 .22-.14.344-.32.344a.337.337 0 01-.34-.344v-2.814zm.66.284v1.245h.834c.335 0 .6-.295.6-.605 0-.35-.265-.64-.6-.64h-.834zM7.706 15.5c-.165 0-.345-.09-.345-.31v-2.838c0-.18.18-.31.345-.31H8.85c2.284 0 2.234 3.458.045 3.458h-1.19zm.315-2.848v2.239h.83c1.349 0 1.409-2.24 0-2.24h-.83zM11.894 13.486h1.274c.18 0 .36.18.36.355 0 .165-.18.3-.36.3h-1.274v1.049c0 .175-.124.31-.3.31-.22 0-.354-.135-.354-.31v-2.839c0-.18.135-.31.355-.31h1.754c.22 0 .35.13.35.31 0 .16-.13.34-.35.34h-1.455v.795z"/>
                        <path fill="#CAD1D8" d="M15.649 17.375H3.774V18h11.875a.627.627 0 00.625-.625v-.625a.627.627 0 01-.625.625z"/>
                     </g>
                     <defs>
                        <clipPath id="clip0_3173_1381">
                           <path fill="#fff" d="M0 0h20v20H0z" transform="translate(0 .5)"/>
                        </clipPath>
                     </defs>
                  </svg>
              <%= @file_name %>
            </span>
            <span class="flex text-xs font-normal text-gray-500 dark:text-gray-400 gap-2">
              <%= @file_pages %>
              <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="self-center" width="3" height="4" viewBox="0 0 3 4" fill="none">
                <circle cx="1.5" cy="2" r="1.5" fill="#6B7280"/>
              </svg>
              <%= @file_size %>
              <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" class="self-center" width="3" height="4" viewBox="0 0 3 4" fill="none">
                <circle cx="1.5" cy="2" r="1.5" fill="#6B7280"/>
              </svg>
              <%= @file_type %>
            </span>
          </div>
          <div class="relative inline-flex self-center items-center" x-data="{ showTooltip: false }">
            <button 
              @mouseenter="showTooltip = true" 
              @mouseleave="showTooltip = false"
              class="inline-flex self-center items-center p-2 text-sm font-medium text-center text-gray-900 bg-gray-50 rounded-lg hover:bg-gray-100 focus:ring-4 focus:outline-none dark:text-white"
              type="button"
            >
              
                <svg class="w-4 h-4 text-gray-900 dark:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M14.707 7.793a1 1 0 0 0-1.414 0L11 10.086V1.5a1 1 0 0 0-2 0v8.586L6.707 7.793a1 1 0 1 0-1.414 1.414l4 4a1 1 0 0 0 1.416 0l4-4a1 1 0 0 0-.002-1.414Z"/>
                  <path d="M18 12h-2.55l-2.975 2.975a3.5 3.5 0 0 1-4.95 0L4.55 12H2a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-4a2 2 0 0 0-2-2Zm-3 5a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"/>
                
              </svg>
            </button>
            <div 
              x-show="showTooltip"
              x-transition
              class="absolute bottom-full mb-2 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700 whitespace-nowrap"
                    aria-label="Tooltip text"
            >
              Download file
            </div>
          </div>
        </div>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_clean_image_attachment(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:image_src, assigns[:image_src])
    |> assign(:image_alt, assigns[:image_alt])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--clean-image-attachment", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col w-full max-w-[326px] leading-1.5">
        <%= render_header(assigns) %>
        <div class="flex flex-col w-full max-w-[326px] leading-1.5 p-4">
          <p class="text-sm font-normal text-gray-900 dark:text-white"><%= @message %></p>
        </div>
        <div class="my-2.5">
          <div x-data="{ showTooltip: false }" class="group relative">
            <div class="absolute w-full h-full bg-gray-900/50 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg flex items-center justify-center">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false" 
                class="inline-flex items-center justify-center rounded-full h-10 w-10 bg-white/30 hover:bg-white/50 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50"
              >
                <svg class="w-5 h-5 text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                  <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
                </svg>
              </button>
              <div 
                x-show="showTooltip"
                x-transition 
                class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                    aria-label="Tooltip text"
              >
                Download image
              </div>
            </div>
            <img src={@image_src} alt={@image_alt} class="rounded-lg" />
          </div>
        </div>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

defp render_clean_image_gallery(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:images, assigns[:images] || [])
    |> assign(:extra_images_count, assigns[:extra_images_count] || 0)
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--clean-image-gallery", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col gap-1">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal text-gray-900 dark:text-white max-w-[326px]"><%= @message %></p>
        <div class="flex flex-col w-full max-w-[326px] leading-1.5 p-2">
          <!-- Image Grid with Tooltips -->
          <div class="grid gap-4 grid-cols-2 my-2.5">
            <!-- First 3 Images -->
            <%= for {img, _index} <- Enum.with_index(Enum.take(@images, 3)) do %>
              <div x-data="{ showTooltip: false }" class="group relative">
                <div class="absolute w-full h-full bg-gray-900/50 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg flex items-center justify-center">
                  <button 
                    @mouseenter="showTooltip = true" 
                    @mouseleave="showTooltip = false" 
                    class="inline-flex items-center justify-center rounded-full h-8 w-8 bg-white/30 hover:bg-white/50 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50"
                  >
                    <svg class="w-4 h-4 text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
                    </svg>
                  </button>
                  <!-- Alpine.js Tooltip -->
                  <div 
                    x-show="showTooltip"
                    x-transition
                    class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                    aria-label="Tooltip text"
                  >
                    Download image
                  </div>
                </div>
                <img src={img} class="rounded-lg" />
              </div>
            <% end %>
            
            <!-- Extra Images Overlay -->
            <div x-data="{ showTooltip: false }" class="group relative">
              <button 
                @mouseenter="showTooltip = true" 
                @mouseleave="showTooltip = false"
                class="absolute w-full h-full bg-gray-900/90 hover:bg-gray-900/50 transition-all duration-300 rounded-lg flex items-center justify-center"
              >
                <span class="text-xl font-medium text-white">+<%= @extra_images_count %></span>
              </button>
              <div 
                x-show="showTooltip"
                x-transition
                class="absolute -top-10 left-1/2 transform -translate-x-1/2 z-10 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-xs dark:bg-gray-700"
                aria-label="Tooltip text"
              >
                View more
              </div>
              <%= if length(@images) > 3 do %>
                <img src={Enum.at(@images, 3)} class="rounded-lg" />
              <% else %>
                <div class="rounded-lg bg-gray-300 dark:bg-gray-500 aspect-square"></div>
              <% end %>
            </div>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
            <button class="text-sm text-blue-700 dark:text-blue-500 font-medium inline-flex items-center hover:underline">
              <svg class="w-3 h-3 me-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 18">
                <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 1v11m0 0 4-4m-4 4L4 8m11 4v3a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-3"/>
              </svg>
              Save all
            </button>
          </div>
        
        </div>
      </div>
    </div>
  </div>
  """
end

defp render_clean_url_preview_sharing(assigns) do
  assigns =
    assigns
    |> assign(:author, assigns[:author])
    |> assign(:message, assigns[:message])
    |> assign(:time, assigns[:time])
    |> assign(:avatar_src, assigns[:avatar_src])
    |> assign(:avatar_alt, assigns[:avatar_alt] || "#{assigns[:author]} image")
    |> assign(:url, assigns[:url])
    |> assign(:url_title, assigns[:url_title])
    |> assign(:url_description, assigns[:url_description])
    |> assign(:url_image, assigns[:url_image])
    |> assign(:url_domain, assigns[:url_domain])
    |> assign(:class, assigns[:class])
    |> assign(:rest, assigns[:rest])

  ~H"""
  <div {@rest} class={["pc-chat-bubble", "pc-chat-bubble--clean-url-preview", @class]}>
    <div class="flex items-start gap-2.5">
      <img class="w-8 h-8 rounded-full" src={@avatar_src} alt={@avatar_alt}>
      <div class="flex flex-col w-full max-w-[320px] leading-1.5">
        <%= render_header(assigns) %>
        <p class="text-sm font-normal py-2.5 text-gray-900 dark:text-white"><%= @message %></p>
        <p class="text-sm font-normal pb-2.5 text-gray-900 dark:text-white">
          <a href={@url} class="text-blue-700 dark:text-blue-500 underline hover:no-underline font-medium break-all"><%= @url %></a>
        </p>
        <a href={@url} class="flex flex-col items-start my-2.5 hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer">
          <img class="w-full h-auto object-cover" src={@url_image} alt="">
          <div class="w-full p-2.5 bg-white dark:bg-gray-800">
            <p class="text-sm font-medium text-gray-900 dark:text-white"><%= @url_title %></p>
            <p class="text-xs font-normal text-gray-500 dark:text-gray-400 my-1"><%= @url_description %></p>
            <span class="flex items-center text-xs font-normal text-gray-500 dark:text-gray-400">
              <svg class="w-3 h-3 me-1" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.083 8.222L8.364 3.94a1.59 1.59 0 0 1 2.25 0l4.279 4.28a1.59 1.59 0 0 1 0 2.251l-4.28 4.28a1.59 1.59 0 0 1-2.25 0l-4.28-4.28a1.591 1.591 0 0 1 0-2.251z"/>
              </svg>
              <%= @url_domain %>
            </span>
          </div>
        </a>
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">Delivered</span>
      </div>
    </div>
  </div>
  """
end

end
