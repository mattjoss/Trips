import { LitElement, html } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import { Trip } from '../types';

@customElement('trip-card')
export class TripCard extends LitElement {
  createRenderRoot() {
    return this;
  }

  @property({ type: Object }) trip?: Trip;

  private handleClick(e: Event) {
    e.preventDefault();
    if (this.trip) {
      this.dispatchEvent(
        new CustomEvent('trip-select', {
          detail: { id: this.trip.trip_details },
          bubbles: true,
          composed: true,
        })
      );
    }
  }

  render() {
    if (!this.trip) return html``;

    return html`
      <article class="trip-card" data-id="${this.trip.trip_details}" @click=${this.handleClick}>
        <img src="${this.trip.image}" alt="${this.trip.title}" class="trip-image" />
        <div class="trip-details">
          <h3 class="trip-title">${this.trip.title}</h3>
          <span class="trip-year">${this.trip.year}</span>
        </div>
      </article>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'trip-card': TripCard;
  }
}
