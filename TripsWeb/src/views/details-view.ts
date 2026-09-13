import { LitElement, html } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import { TripDetails } from '../types';
import '../components/trip-segment';

@customElement('details-view')
export class DetailsView extends LitElement {
  createRenderRoot() {
    return this;
  }

  @property({ type: String }) tripId: string = '';

  @state() private data: TripDetails | null = null;
  @state() private loading: boolean = true;
  @state() private error: boolean = false;

  willUpdate(changedProperties: Map<string, any>) {
    if (changedProperties.has('tripId') && this.tripId) {
      this.fetchDetails(this.tripId);
    }
  }

  connectedCallback() {
    super.connectedCallback();
    if (this.tripId) {
      this.fetchDetails(this.tripId);
    }
  }

  async fetchDetails(id: string) {
    this.loading = true;
    this.error = false;
    try {
      const response = await fetch(`/${id}.json`);
      if (!response.ok) throw new Error('Trip not found');
      this.data = await response.json();
    } catch (err) {
      console.error(err);
      this.error = true;
    } finally {
      this.loading = false;
    }
  }

  render() {
    if (this.loading) {
      return html`<div class="loading">Loading details...</div>`;
    }

    if (this.error || !this.data) {
      return html`
        <div class="error-container">
          <h2>Trip not found</h2>
          <button @click=${() => history.back()} class="back-btn">Go Back</button>
        </div>
      `;
    }

    return html`
      <div class="trip-details-view fade-in">
        <header class="details-header">
          <h1>${this.data.title}</h1>
          <p class="meta-date">${this.data.date}</p>
        </header>

        <div class="segments-container">
          ${this.data.segments.map(
            (segment) => html`<trip-segment .segment=${segment}></trip-segment>`
          )}
        </div>
      </div>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'details-view': DetailsView;
  }
}
