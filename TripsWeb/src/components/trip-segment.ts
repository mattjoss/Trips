import { LitElement, html } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import { TripSegment as ITripSegment, Section } from '../types';
import './trip-markdown';
import './gallery';

@customElement('trip-segment')
export class TripSegment extends LitElement {
  createRenderRoot() {
    return this;
  }

  @property({ type: Object }) segment?: ITripSegment;

  private renderSection(section: Section) {
    if (section.type === 'markdown') {
      return html`
        <trip-markdown
          .sectionTitle=${section.title || ''}
          .markdown=${section.markdown}
        ></trip-markdown>
      `;
    } else if (section.type === 'media') {
      return html`
        <trip-gallery
          .media=${section.media}
        ></trip-gallery>
      `;
    }
    return html``;
  }

  render() {
    if (!this.segment) return html``;

    return html`
      <section class="trip-segment">
        <header class="segment-header">
          <h2>${this.segment.name}</h2>
          ${this.segment.date ? html`<span class="segment-date">${this.segment.date}</span>` : ''}
        </header>
        <div class="segment-content">
          ${this.segment.sections.map((section) => this.renderSection(section))}
        </div>
      </section>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'trip-segment': TripSegment;
  }
}
