import './style.css';
import './views/home-view';
import './views/details-view';

const appElement = document.querySelector<HTMLElement>('main.container')!;
const heroElement = document.getElementById('hero');

function router() {
  const urlParams = new URLSearchParams(window.location.search);
  const tripId = urlParams.get('id');

  if (tripId) {
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
  // Handle logo click to return home
  document.querySelector('.logo a')?.addEventListener('click', (e) => {
    e.preventDefault();
    navigateTo('/');
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
