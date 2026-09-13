import { LitElement, html } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import { unsafeHTML } from 'lit/directives/unsafe-html.js';
import { marked } from 'marked';

@customElement('trip-markdown')
export class TripMarkdown extends LitElement {
  createRenderRoot() {
    return this;
  }

  @property({ type: String }) sectionTitle: string = '';
  @property({ type: String }) markdown: string = '';

  render() {
    const parsedHtml = marked.parse(this.markdown || '') as string;

    return html`
      <div class="markdown-section">
        ${this.sectionTitle ? html`<h3>${this.sectionTitle}</h3>` : ''}
        <div class="markdown-body">
          ${unsafeHTML(parsedHtml)}
        </div>
      </div>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    'trip-markdown': TripMarkdown;
  }
}
