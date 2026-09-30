import { LitElement, html } from 'lit';
import { customElement } from 'lit/decorators.js';

const aboutPhoto = new URL('../assets/about-photo.jpeg', import.meta.url).href;

@customElement('about-view')
export class AboutView extends LitElement {
  createRenderRoot() {
    return this;
  }

  render() {
    return html`
      <section class="about-page" aria-labelledby="about-title">
        <img class="about-photo" src=${aboutPhoto}
          alt="The two of us beside a rocky cove with clear blue water" />
        <div class="about-copy">
          <p class="about-eyebrow">Our travel journal</p>
          <h1 id="about-title">About us</h1>
          <p>Welcome to Travelog, a place to collect the stories, photos, and
            little moments from our travels.</p>
          <p>From coastal walks to new places to explore, this journal brings
            our trips together so we can revisit the memories and share them
            with you.</p>
          <a class="about-link" href="/">Explore our trips <span aria-hidden="true">→</span></a>
        </div>
      </section>
    `;
  }
}
