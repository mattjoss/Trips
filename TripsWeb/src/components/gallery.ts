import { LitElement, html } from 'lit';
import { customElement, property, state, query } from 'lit/decorators.js';
import { MediaItem } from '../types';
import './lightbox';

@customElement('trip-gallery')
export class TripGallery extends LitElement {
  createRenderRoot() {
    return this;
  }

  @property({ type: Array }) media: MediaItem[] = [];

  @state() private lightboxOpen: boolean = false;
  @state() private lightboxIndex: number = 0;

  @query('.gallery-scroll') private scrollContainer?: HTMLElement;

  private scrollPrev() {
    if (!this.scrollContainer) return;
    const itemWidth = this.scrollContainer.querySelector('.gallery-item-wrapper')?.clientWidth || 300;
    this.scrollContainer.scrollBy({ left: -itemWidth, behavior: 'smooth' });
  }

  private scrollNext() {
    if (!this.scrollContainer) return;
    const itemWidth = this.scrollContainer.querySelector('.gallery-item-wrapper')?.clientWidth || 300;
    this.scrollContainer.scrollBy({ left: itemWidth, behavior: 'smooth' });
  }

  private handleMediaClick(index: number, item: MediaItem) {
    if (item.type === 'video') return; // let native controls handle video play
    this.lightboxIndex = index;
    this.lightboxOpen = true;
  }

  render() {
    if (!this.media || !this.media.length) return html``;

    return html`
      <div class="media-section">
        <div class="gallery-container">
          <button class="gallery-nav prev" aria-label="Previous image" @click=${this.scrollPrev}>❮</button>
          <div class="gallery-scroll">
            ${this.media.map(
              (item, index) => html`
                <div class="gallery-item-wrapper">
                  <div class="gallery-media-container">
                    ${item.type === 'image'
                      ? html`<img
                          src="${item.url}"
                          alt="${item.caption || ''}"
                          class="gallery-media"
                          loading="lazy"
                          @click=${() => this.handleMediaClick(index, item)}
                        />`
                      : html`<video
                          src="${item.url}"
                          class="gallery-media"
                          controls
                        ></video>`}
                  </div>
                  ${item.caption ? html`<p class="gallery-caption-text">${item.caption}</p>` : ''}
                </div>
              `
            )}
          </div>
          <button class="gallery-nav next" aria-label="Next image" @click=${this.scrollNext}>❯</button>
        </div>
      </div>

      <trip-lightbox
        .items=${this.media}
        .currentIndex=${this.lightboxIndex}
        .open=${this.lightboxOpen}
        @lightbox-close=${() => (this.lightboxOpen = false)}
      ></trip-lightbox>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'trip-gallery': TripGallery;
  }
}
