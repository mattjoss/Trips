import './style.css';
import './views/home-view';
import './views/details-view';
import './views/about-view';

const appElement = document.querySelector<HTMLElement>('main.container')!;
const heroElement = document.getElementById('hero');

function router() {
  const urlParams = new URLSearchParams(window.location.search);
  const tripId = urlParams.get('id');
  const isAbout = !tripId && urlParams.get('page') === 'about';
  document.querySelector('.about-nav')?.toggleAttribute('aria-current', isAbout);
  if (isAbout) document.querySelector('.about-nav')?.setAttribute('aria-current', 'page');
  document.title = isAbout ? 'About us | Travelog' : 'Travelog';

  if (isAbout) {
    if (heroElement) heroElement.style.display = 'none';
    appElement.innerHTML = '<about-view></about-view>';
  } else if (tripId) {
    if (heroElement) heroElement.style.display = 'none';
    appElement.innerHTML = `<details-view tripId="${tripId}"></details-view>`;
  } else {
    if (heroElement) heroElement.style.display = 'flex';
    appElement.innerHTML = `<home-view></home-view>`;
  }

  window.scrollTo(0, 0);
}

function navigateTo(url: string) {
  history.pushState(null, '', url);
  router();
}

// Global Event Listeners
window.addEventListener('popstate', router);

document.addEventListener('DOMContentLoaded', () => {
  // Handle navigation between the home and About pages.
  document.addEventListener('click', (e) => {
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    const link = (e.target as Element).closest<HTMLAnchorElement>('.logo a, .about-nav, .about-link');
    if (!link) return;
    e.preventDefault();
    navigateTo(link.getAttribute('href')!);
  });

  // Listen for custom trip selection events from <trip-card>
  document.addEventListener('trip-select', (e: Event) => {
    const customEvent = e as CustomEvent<{ id: string }>;
    if (customEvent.detail && customEvent.detail.id) {
      navigateTo(`/?id=${customEvent.detail.id}`);
    }
  });

  router();
});
