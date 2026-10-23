import { LitElement, html } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import { keyed } from 'lit/directives/keyed.js';
import { TripDetails } from '../types';
import { getTripDetailsUrl, getTripSegmentUrl } from '../config';
import '../components/trip-segment';

@customElement('details-view')
export class DetailsView extends LitElement {
  createRenderRoot() {
    return this;
  }

  @property({ type: String }) tripId: string = '';
  @property({ type: String }) segment: string = '';

  @state() private data: TripDetails | null = null;
  @state() private loading: boolean = true;
  @state() private error: boolean = false;
  @state() private selectedSegment = 0;

  willUpdate(changedProperties: Map<string, any>) {
    if (changedProperties.has('tripId') && this.tripId) {
      this.fetchDetails(this.tripId);
    }
    if (changedProperties.has('segment') && this.data) this.syncSelectedSegment();
  }

  connectedCallback() {
    super.connectedCallback();
    if (this.tripId) {
      this.fetchDetails(this.tripId);
    }
  }

  async fetchDetails(id: string) {
    this.selectedSegment = this.segmentIndex;
    this.loading = true;
    this.error = false;
    try {
      const url = getTripDetailsUrl(id);
      const response = await fetch(url);
      if (!response.ok) throw new Error('Trip not found');
      this.data = await response.json();
      this.syncSelectedSegment();
    } catch (err) {
      console.error(err);
      this.error = true;
    } finally {
      this.loading = false;
    }
  }

  private get segmentIndex(): number {
    const parsed = Number.parseInt(this.segment, 10) - 1;
    return Number.isInteger(parsed) && parsed >= 0 ? parsed : 0;
  }

  private syncSelectedSegment() {
    const count = this.data?.segments.length ?? 0;
    this.selectedSegment = count ? Math.min(this.segmentIndex, count - 1) : 0;
  }

  private selectSegment(index: number) {
    this.selectedSegment = index;
    const url = getTripSegmentUrl(this.tripId, index);
    history.pushState(null, '', url);
    this.querySelector<HTMLElement>(`#segment-tab-${index}`)?.scrollIntoView({
      block: 'nearest', inline: 'nearest',
    });
  }

  private handleTabKeydown(event: KeyboardEvent, index: number) {
    const count = this.data?.segments.length ?? 0;
    let nextIndex = index;
    if (event.key === 'ArrowRight') nextIndex = (index + 1) % count;
    else if (event.key === 'ArrowLeft') nextIndex = (index - 1 + count) % count;
    else if (event.key === 'Home') nextIndex = 0;
    else if (event.key === 'End') nextIndex = count - 1;
    else return;
    event.preventDefault();
    this.selectSegment(nextIndex);
    this.querySelector<HTMLElement>(`#segment-tab-${nextIndex}`)?.focus();
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

        ${this.data.segments.length ? html`
          <div class="segment-tabs" role="tablist" aria-label="Trip segments">
            ${this.data.segments.map((segment, index) => html`
              <button class="segment-tab" id="segment-tab-${index}"
                role="tab" aria-selected=${this.selectedSegment === index}
                aria-controls="segment-panel"
                tabindex=${this.selectedSegment === index ? 0 : -1}
                @click=${() => this.selectSegment(index)}
                @keydown=${(event: KeyboardEvent) => this.handleTabKeydown(event, index)}
              >${segment.name}</button>
            `)}
          </div>
          <div class="segments-container" id="segment-panel" role="tabpanel"
            aria-labelledby="segment-tab-${this.selectedSegment}" tabindex="0">
            ${keyed(this.selectedSegment, html`
              <trip-segment .segment=${this.data.segments[this.selectedSegment]}
                .hideTitle=${true}></trip-segment>
            `)}
            ${this.selectedSegment < this.data.segments.length - 1 ? html`
              <p class="next-segment">Next: <a href=${getTripSegmentUrl(this.tripId, this.selectedSegment + 1)}
                @click=${(event: Event) => { event.preventDefault(); this.selectSegment(this.selectedSegment + 1); }}
              >${this.data.segments[this.selectedSegment + 1].name}</a></p>
            ` : ''}
          </div>
        ` : html`<p class="empty-state">No segments have been added to this trip yet.</p>`}
      </div>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'details-view': DetailsView;
  }
}
