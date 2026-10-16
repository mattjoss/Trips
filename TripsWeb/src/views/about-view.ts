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
          <p>Hi! We’re Matt and Linda — married over 30 years, parents to three grown kids, and always dreaming about our next adventure.</p>
          <p>We love to travel, explore new places, try new things, and collect the kind of memories that make the best stories when we get home.</p>
          <p>We created this website for two reasons: to stop clogging our friends’ and families’ phones with thousands of vacation photos (you’re welcome!) and to share our adventures in a more fun way.</p>
          <p>Think of it as your own little window into our travels — the places we discover, the people we meet, the things that surprise us, and, of course, the occasional travel mishap.</p>
          <p>We’re glad you’re here. Come travel along with us!</p>
          <a class="about-link" href="/">Explore our trips <span aria-hidden="true">→</span></a>
        </div>
      </section>
    `;
  }
}
