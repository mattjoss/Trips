import { LitElement, html } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import { MediaItem } from '../types';

@customElement('trip-lightbox')
export class TripLightbox extends LitElement {
  createRenderRoot() {
    return this;
  }

  @property({ type: Array }) items: MediaItem[] = [];
  @property({ type: Number }) currentIndex: number = 0;
  @property({ type: Boolean }) open: boolean = false;

  @state() private activeIndex: number = 0;

  willUpdate(changedProperties: Map<string, any>) {
    if (changedProperties.has('currentIndex')) {
      this.activeIndex = this.currentIndex;
    }
  }

  updated(changedProperties: Map<string, any>) {
    if (changedProperties.has('open')) {
      if (this.open) {
        document.body.style.overflow = 'hidden';
        window.addEventListener('keydown', this.handleKeyDown);
      } else {
        document.body.style.overflow = '';
        window.removeEventListener('keydown', this.handleKeyDown);
      }
    }
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    document.body.style.overflow = '';
    window.removeEventListener('keydown', this.handleKeyDown);
  }

  private handleKeyDown = (e: KeyboardEvent) => {
    if (!this.open) return;
    if (e.key === 'Escape') this.close();
    if (e.key === 'ArrowLeft') this.prev();
    if (e.key === 'ArrowRight') this.next();
  };

  close() {
    this.open = false;
    this.dispatchEvent(new CustomEvent('lightbox-close', { bubbles: true, composed: true }));
  }

  prev() {
    if (this.items.length === 0) return;
    this.activeIndex = (this.activeIndex - 1 + this.items.length) % this.items.length;
  }

  next() {
    if (this.items.length === 0) return;
    this.activeIndex = (this.activeIndex + 1) % this.items.length;
  }

  private handleBackdropClick(e: MouseEvent) {
    if ((e.target as HTMLElement).classList.contains('lightbox-modal')) {
      this.close();
    }
  }

  render() {
    if (!this.open || !this.items.length) return html``;

    const currentItem = this.items[this.activeIndex];
    const caption = currentItem.caption || (currentItem.type === 'video' ? 'Video' : '');

    return html`
      <div class="lightbox-modal fade-in" @click=${this.handleBackdropClick}>
        <button class="lightbox-close" aria-label="Close" @click=${this.close}>×</button>
        <button class="lightbox-nav prev" aria-label="Previous" @click=${this.prev}>❮</button>
        <div class="lightbox-content">
          ${currentItem.type === 'image'
            ? html`<img src="${currentItem.url}" alt="${caption}" class="lightbox-media fade-in" />`
            : html`<video src="${currentItem.url}" controls class="lightbox-media fade-in"></video>`}
        </div>
        <button class="lightbox-nav next" aria-label="Next" @click=${this.next}>❯</button>
        <div class="lightbox-caption">${caption}</div>
      </div>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'trip-lightbox': TripLightbox;
  }
}
