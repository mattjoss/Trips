import { LitElement, html } from 'lit';
import { customElement, state } from 'lit/decorators.js';
import { Trip } from '../types';
import '../components/trip-card';

@customElement('home-view')
export class HomeView extends LitElement {
  createRenderRoot() {
    return this;
  }

  @state() private trips: Trip[] = [];
  @state() private loading: boolean = true;
  @state() private error: string | null = null;

  connectedCallback() {
    super.connectedCallback();
    this.fetchTrips();
  }

  async fetchTrips() {
    this.loading = true;
    this.error = null;
    try {
      // const data_root = 'https://storage.googleapis.com/joss_travel/';

      // const data_url = 'https://firebasestorage.googleapis.com/v0/b/joss-travel-ios.firebasestorage.app/o/data%2Ftrips.json?alt=media&token=9120f59b-8604-4432-bebf-5d0d2dc39695'
      // const data_url = 'https://storage.cloud.google.com/joss-travel-ios.firebasestorage.app/data/trips.json'
      const data_url = 'https://storage.googleapis.com/joss-travel-ios.firebasestorage.app/data/trips.json'

      // const response = await fetch(`${data_root}trips.json`);
      const response = await fetch('/trips.json');
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      this.trips = await response.json();
    } catch (err) {
      console.error('Could not fetch trips:', err);
      this.error = 'Error loading trips. Please try again later.';
    } finally {
      this.loading = false;
    }
  }

  render() {
    return html`
      <section class="trips-section">
        <h2 class="section-title">Trips</h2>
        <div id="trips-grid" class="trips-grid">
          ${this.loading
        ? html`<div class="loading">Loading trips...</div>`
        : this.error
          ? html`<p class="error-msg">${this.error}</p>`
          : this.trips.map(
            (trip) => html`<trip-card .trip=${trip}></trip-card>`
          )}
        </div>
      </section>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'home-view': HomeView;
  }
}
