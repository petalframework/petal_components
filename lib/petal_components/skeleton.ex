defmodule PetalComponents.Skeleton do
  use Phoenix.Component

  attr(:kind, :atom,
    default: :default,
    doc: "skeleton",
    values: [:default, :image, :video, :text, :card, :widget, :list, :testimonial]
  )

  def skeleton(%{kind: :default} = assigns) do
    ~H"""
    <div role="status" data-skeleton="default" class="pc-skeleton--default">
      <div class="pc-skeleton--default__line pc-skeleton--default__line--h-2.5 pc-skeleton--default__line--w-48 pc-skeleton--default__line--mb-4">
      </div>
      <div class="pc-skeleton--default__line pc-skeleton--default__line--h-2 pc-skeleton--default__line--max-w-360px pc-skeleton--default__line--mb-2.5">
      </div>
      <div class="pc-skeleton--default__line pc-skeleton--default__line--h-2 pc-skeleton--default__line--mb-2.5">
      </div>
      <div class="pc-skeleton--default__line pc-skeleton--default__line--h-2 pc-skeleton--default__line--max-w-330px pc-skeleton--default__line--mb-2.5">
      </div>
      <div class="pc-skeleton--default__line pc-skeleton--default__line--h-2 pc-skeleton--default__line--max-w-300px pc-skeleton--default__line--mb-2.5">
      </div>
      <div class="pc-skeleton--default__line pc-skeleton--default__line--h-2 pc-skeleton--default__line--max-w-360px">
      </div>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  def skeleton(%{kind: :image} = assigns) do
    ~H"""
    <div role="status" data-skeleton="image" class="pc-skeleton--image">
      <div class="pc-skeleton--image__image-placeholder">
        <svg
          class="pc-skeleton--image__icon"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          fill="currentColor"
          viewBox="0 0 20 18"
        >
          <path d="M18 0H2a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2Zm-5.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3Zm4.376 10.481A1 1 0 0 1 16 15H4a1 1 0 0 1-.895-1.447l3.5-7A1 1 0 0 1 7.468 6a.965.965 0 0 1 .9.5l2.775 4.757 1.546-1.887a1 1 0 0 1 1.618.1l2.541 4a1 1 0 0 1 .028 1.011Z" />
        </svg>
      </div>
      <div class="pc-skeleton--image__content">
        <div class="pc-skeleton--image__line pc-skeleton--image__line--h-2.5 pc-skeleton--image__line--w-48 pc-skeleton--image__line--mb-4">
        </div>
        <div class="pc-skeleton--image__line pc-skeleton--image__line--h-2 pc-skeleton--image__line--max-w-480px pc-skeleton--image__line--mb-2.5">
        </div>
        <div class="pc-skeleton--image__line pc-skeleton--image__line--h-2 pc-skeleton--image__line--mb-2.5">
        </div>
        <div class="pc-skeleton--image__line pc-skeleton--image__line--h-2 pc-skeleton--image__line--max-w-440px pc-skeleton--image__line--mb-2.5">
        </div>
        <div class="pc-skeleton--image__line pc-skeleton--image__line--h-2 pc-skeleton--image__line--max-w-460px pc-skeleton--image__line--mb-2.5">
        </div>
        <div class="pc-skeleton--image__line pc-skeleton--image__line--h-2 pc-skeleton--image__line--max-w-360px">
        </div>
      </div>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  def skeleton(%{kind: :video} = assigns) do
    ~H"""
    <div role="status" data-skeleton="video" class="pc-skeleton--video">
      <svg
        class="pc-skeleton--video__icon"
        aria-hidden="true"
        xmlns="http://www.w3.org/2000/svg"
        fill="currentColor"
        viewBox="0 0 16 20"
      >
        <path d="M5 5V.13a2.96 2.96 0 0 0-1.293.749L.879 3.707A2.98 2.98 0 0 0 .13 5H5Z" />
        <path d="M14.066 0H7v5a2 2 0 0 1-2 2H0v11a1.97 1.97 0 0 0 1.934 2h12.132A1.97 1.97 0 0 0 16 18V2a1.97 1.97 0 0 0-1.934-2ZM9 13a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2Zm4 .382a1 1 0 0 1-1.447.894L10 13v-2l1.553-1.276a1 1 0 0 1 1.447.894v2.764Z" />
      </svg>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  def skeleton(%{kind: :text} = assigns) do
    ~H"""
    <div role="status" data-skeleton="text" class="pc-skeleton--text">
      <div class="pc-skeleton--text__line-group">
        <div class="pc-skeleton--text__block pc-skeleton--text__block--w-32"></div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-24">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-full">
        </div>
      </div>
      <div class="pc-skeleton--text__line-group pc-skeleton--text__line-group--max-w-480px">
        <div class="pc-skeleton--text__block pc-skeleton--text__block--bg-gray-200 pc-skeleton--text__block--w-full">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-full">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-24">
        </div>
      </div>
      <div class="pc-skeleton--text__line-group pc-skeleton--text__line-group--max-w-400px">
        <div class="pc-skeleton--text__block pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-full">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-200 pc-skeleton--text__block--w-80">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-full">
        </div>
      </div>
      <div class="pc-skeleton--text__line-group pc-skeleton--text__line-group--max-w-480px">
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-200 pc-skeleton--text__block--w-full">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-full">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-24">
        </div>
      </div>
      <div class="pc-skeleton--text__line-group pc-skeleton--text__line-group--max-w-440px">
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-32">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-24">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-200 pc-skeleton--text__block--w-full">
        </div>
      </div>
      <div class="pc-skeleton--text__line-group pc-skeleton--text__line-group--max-w-360px">
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-full">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-200 pc-skeleton--text__block--w-80">
        </div>
        <div class="pc-skeleton--text__block pc-skeleton--text__block--ms-2 pc-skeleton--text__block--bg-gray-300 pc-skeleton--text__block--w-full">
        </div>
      </div>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  def skeleton(%{kind: :card} = assigns) do
    ~H"""
    <div role="status" data-skeleton="card" class="pc-skeleton--card">
      <div class="pc-skeleton--card__image-placeholder">
        <svg
          class="pc-skeleton--card__icon"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          fill="currentColor"
          viewBox="0 0 16 20"
        >
          <path d="M14.066 0H7v5a2 2 0 0 1-2 2H0v11a1.97 1.97 0 0 0 1.934 2h12.132A1.97 1.97 0 0 0 16 18V2a1.97 1.97 0 0 0-1.934-2ZM10.5 6a1.5 1.5 0 1 1 0 2.999A1.5 1.5 0 0 1 10.5 6Zm2.221 10.515a1 1 0 0 1-.858.485h-8a1 1 0 0 1-.9-1.43L5.6 10.039a.978.978 0 0 1 .936-.57 1 1 0 0 1 .9.632l1.181 2.981.541-1a.945.945 0 0 1 .883-.522 1 1 0 0 1 .879.529l1.832 3.438a1 1 0 0 1-.031.988Z" />
          <path d="M5 5V.13a2.96 2.96 0 0 0-1.293.749L.879 3.707A2.98 2.98 0 0 0 .13 5H5Z" />
        </svg>
      </div>
      <div class="pc-skeleton--card__line pc-skeleton--card__line--h-2.5 pc-skeleton--card__line--w-48 pc-skeleton--card__line--mb-4">
      </div>
      <div class="pc-skeleton--card__line pc-skeleton--card__line--h-2 pc-skeleton--card__line--mb-2.5">
      </div>
      <div class="pc-skeleton--card__line pc-skeleton--card__line--h-2 pc-skeleton--card__line--mb-2.5">
      </div>
      <div class="pc-skeleton--card__line pc-skeleton--card__line--h-2"></div>
      <div class="pc-skeleton--card__avatar">
        <svg
          class="pc-skeleton--card__avatar-icon"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M10 0a10 10 0 1 0 10 10A10.011 10.011 0 0 0 10 0Zm0 5a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm0 13a8.949 8.949 0 0 1-4.951-1.488A3.987 3.987 0 0 1 9 13h2a3.987 3.987 0 0 1 3.951 3.512A8.949 8.949 0 0 1 10 18Z" />
        </svg>
        <div>
          <div class="pc-skeleton--card__avatar-text pc-skeleton--card__avatar-text--w-32"></div>
          <div class="pc-skeleton--card__avatar-text pc-skeleton--card__avatar-text--w-48"></div>
        </div>
      </div>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  def skeleton(%{kind: :widget} = assigns) do
    ~H"""
    <div role="status" data-skeleton="widget" class="pc-skeleton--widget">
      <div class="pc-skeleton--widget__header-line pc-skeleton--widget__header-line--w-32"></div>
      <div class="pc-skeleton--widget__header-line pc-skeleton--widget__header-line--w-48"></div>
      <div class="pc-skeleton--widget__chart">
        <div class="pc-skeleton--widget__chart-bar pc-skeleton--widget__chart-bar--h-72"></div>
        <div class="pc-skeleton--widget__chart-bar pc-skeleton--widget__chart-bar--h-56 pc-skeleton--widget__chart-bar--ms-6">
        </div>
        <div class="pc-skeleton--widget__chart-bar pc-skeleton--widget__chart-bar--h-72 pc-skeleton--widget__chart-bar--ms-6">
        </div>
        <div class="pc-skeleton--widget__chart-bar pc-skeleton--widget__chart-bar--h-64 pc-skeleton--widget__chart-bar--ms-6">
        </div>
        <div class="pc-skeleton--widget__chart-bar pc-skeleton--widget__chart-bar--h-80 pc-skeleton--widget__chart-bar--ms-6">
        </div>
        <div class="pc-skeleton--widget__chart-bar pc-skeleton--widget__chart-bar--h-72 pc-skeleton--widget__chart-bar--ms-6">
        </div>
        <div class="pc-skeleton--widget__chart-bar pc-skeleton--widget__chart-bar--h-80 pc-skeleton--widget__chart-bar--ms-6">
        </div>
      </div>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  def skeleton(%{kind: :list} = assigns) do
    ~H"""
    <div role="status" data-skeleton="list" class="pc-skeleton--list">
      <!-- First List Item -->
      <div class="pc-skeleton--list__item">
        <div class="pc-skeleton--list__text-group">
          <div class="pc-skeleton--list__text-line pc-skeleton--list__text-line--h-2.5"></div>
          <div class="pc-skeleton--list__sub-text-line"></div>
        </div>
        <div class="pc-skeleton--list__button pc-skeleton--list__button--w-12"></div>
      </div>
      <!-- Second List Item -->
      <div class="pc-skeleton--list__item pc-skeleton--list__item--pt-4">
        <div class="pc-skeleton--list__text-group">
          <div class="pc-skeleton--list__text-line pc-skeleton--list__text-line--h-2.5"></div>
          <div class="pc-skeleton--list__sub-text-line"></div>
        </div>
        <div class="pc-skeleton--list__button pc-skeleton--list__button--w-12"></div>
      </div>
      <!-- Third List Item -->
      <div class="pc-skeleton--list__item pc-skeleton--list__item--pt-4">
        <div class="pc-skeleton--list__text-group">
          <div class="pc-skeleton--list__text-line pc-skeleton--list__text-line--h-2.5"></div>
          <div class="pc-skeleton--list__sub-text-line"></div>
        </div>
        <div class="pc-skeleton--list__button pc-skeleton--list__button--w-12"></div>
      </div>
      <!-- Fourth List Item -->
      <div class="pc-skeleton--list__item pc-skeleton--list__item--pt-4">
        <div class="pc-skeleton--list__text-group">
          <div class="pc-skeleton--list__text-line pc-skeleton--list__text-line--h-2.5"></div>
          <div class="pc-skeleton--list__sub-text-line"></div>
        </div>
        <div class="pc-skeleton--list__button pc-skeleton--list__button--w-12"></div>
      </div>
      <!-- Fifth List Item -->
      <div class="pc-skeleton--list__item pc-skeleton--list__item--pt-4">
        <div class="pc-skeleton--list__text-group">
          <div class="pc-skeleton--list__text-line pc-skeleton--list__text-line--h-2.5"></div>
          <div class="pc-skeleton--list__sub-text-line"></div>
        </div>
        <div class="pc-skeleton--list__button pc-skeleton--list__button--w-12"></div>
      </div>

      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  def skeleton(%{kind: :testimonial} = assigns) do
    ~H"""
    <div role="status" data-skeleton="testimonial" class="pc-skeleton--testimonial">
      <div class="pc-skeleton--testimonial__line pc-skeleton--testimonial__line--h-2.5 pc-skeleton--testimonial__line--max-w-640px">
      </div>
      <div class="pc-skeleton--testimonial__line pc-skeleton--testimonial__line--h-2.5 pc-skeleton--testimonial__line--max-w-540px">
      </div>
      <div class="pc-skeleton--testimonial__footer">
        <svg
          class="pc-skeleton--testimonial__avatar-icon"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M10 0a10 10 0 1 0 10 10A10.011 10.011 0 0 0 10 0Zm0 5a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm0 13a8.949 8.949 0 0 1-4.951-1.488A3.987 3.987 0 0 1 9 13h2a3.987 3.987 0 0 1 3.951 3.512A8.949 8.949 0 0 1 10 18Z" />
        </svg>
        <div class="pc-skeleton--testimonial__avatar-text pc-skeleton--testimonial__avatar-text--w-20">
        </div>
        <div class="pc-skeleton--testimonial__avatar-text pc-skeleton--testimonial__avatar-text--w-24">
        </div>
      </div>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end
end
