import './style.css'
import { marked } from 'marked'

// Interfaces
interface Trip {
  title: string
  year: string
  image: string
  trip_details: string
}

type Section = MarkdownSection | MediaSection;

interface MarkdownSection {
  type: 'markdown'
  title?: string
  markdown: string
}

interface MediaSection {
  type: 'media'
  media: MediaItem[]
}

interface MediaItem {
  type: 'image' | 'video'
  url: string
  caption?: string
}

interface TripSegment {
  name: string
  date?: string
  sections: Section[]
}

interface TripDetails {
  id: string
  title: string
  date: string
  segments: TripSegment[]
  timestamp: number
}

const appElement = document.querySelector<HTMLElement>('main.container')!

// Router
async function router() {
  const urlParams = new URLSearchParams(window.location.search);
  const tripId = urlParams.get('id');
  const hero = document.getElementById('hero');

  if (tripId) {
    if (hero) hero.style.display = 'none';
    await renderDetails(tripId);
  } else {
    if (hero) hero.style.display = 'flex';
    await renderHome();
  }
  // Scroll to top on navigation
  window.scrollTo(0, 0);
}

// Navigation Helper
function navigateTo(url: string) {
  history.pushState(null, '', url);
  router();
}

// Views
async function renderHome() {
  appElement.innerHTML = `
    <section class="trips-section">
      <h2 class="section-title">Trips</h2>
      <div id="trips-grid" class="trips-grid">
         <div class="loading">Loading trips...</div>
      </div>
    </section>
  `;

  try {
    const response = await fetch('/trips.json');
    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
    const trips: Trip[] = await response.json();

    const grid = document.getElementById('trips-grid');
    if (grid) {
      grid.innerHTML = trips.map(trip => `
        <article class="trip-card" data-id="${trip.trip_details}">
          <img src="${trip.image}" alt="${trip.title}" class="trip-image" />
          <div class="trip-details">
            <h3 class="trip-title">${trip.title}</h3>
            <span class="trip-year">${trip.year}</span>
          </div>
        </article>
      `).join('');

      // Add click listeners
      document.querySelectorAll('.trip-card').forEach((card) => {
        card.addEventListener('click', (e) => {
          e.preventDefault();
          const id = (card as HTMLElement).dataset.id;
          if (id) navigateTo(`/?id=${id}`);
        });
      });
    }
  } catch (error) {
    console.error("Could not fetch trips:", error);
    const grid = document.getElementById('trips-grid');
    if (grid) grid.innerHTML = `<p class="error-msg">Error loading trips. Please try again later.</p>`;
  }
}

async function renderDetails(id: string) {
  appElement.innerHTML = `<div class="loading">Loading details...</div>`;

  try {
    const response = await fetch(`/${id}.json`);
    if (!response.ok) throw new Error("Trip not found");
    const data: TripDetails = await response.json();

    appElement.innerHTML = `
      <div class="trip-details-view fade-in">
        
        <header class="details-header">
            <!-- Title & Date -->
            <h1>${data.title}</h1>
            <p class="meta-date">${data.date}</p>
        </header>

        <div class="segments-container">
            ${data.segments.map(renderSegment).join('')}
        </div>
      </div>
    `;

    // Attach event listeners for things like gallery
    setupGalleries();

  } catch (error) {
    console.error(error);
    appElement.innerHTML = `
        <div class="error-container">
            <h2>Trip not found</h2>
            <button onclick="history.back()" class="back-btn">Go Back</button>
        </div>
    `;
  }
}

function renderSegment(segment: TripSegment): string {
  return `
        <section class="trip-segment">
            <header class="segment-header">
                <h2>${segment.name}</h2>
                ${segment.date ? `<span class="segment-date">${segment.date}</span>` : ''}
            </header>
            <div class="segment-content">
                ${segment.sections.map(renderSection).join('')}
            </div>
        </section>
    `;
}

function renderSection(section: Section): string {
  if (section.type === 'markdown') {
    return `
            <div class="markdown-section">
                ${section.title ? `<h3>${section.title}</h3>` : ''}
                <div class="markdown-body">
                    ${marked.parse(section.markdown)}
                </div>
            </div>
        `;
  } else if (section.type === 'media') {
    return `
            <div class="media-section">
                <div class="gallery-container">
                    <button class="gallery-nav prev" aria-label="Previous image">❮</button>
                    <div class="gallery-scroll">
                        ${section.media.map((item, index) => renderMediaItem(item, index)).join('')}
                    </div>
                    <button class="gallery-nav next" aria-label="Next image">❯</button>
                </div>
            </div>
        `;
  }
  return '';
}

function renderMediaItem(item: MediaItem, index: number): string {
  const captionHtml = item.caption ? `<p class="gallery-caption-text">${item.caption}</p>` : '';

  let mediaHtml = '';
  if (item.type === 'image') {
    mediaHtml = `<img src="${item.url}" alt="${item.caption || ''}" class="gallery-media" data-index="${index}" loading="lazy" />`;
  } else if (item.type === 'video') {
    mediaHtml = `<video src="${item.url}" class="gallery-media" data-index="${index}" controls></video>`;
  }

  return `
        <div class="gallery-item-wrapper">
            <div class="gallery-media-container">
                ${mediaHtml}
            </div>
            ${captionHtml}
        </div>
    `;
}

function setupGalleries() {
  // Horizontal scroll buttons
  document.querySelectorAll('.gallery-container').forEach(container => {
    const scroll = container.querySelector('.gallery-scroll') as HTMLElement;
    const prevBtn = container.querySelector('.prev') as HTMLElement;
    const nextBtn = container.querySelector('.next') as HTMLElement;

    if (!scroll || !prevBtn || !nextBtn) return;

    prevBtn.addEventListener('click', () => {
      // Scroll by the width of one item wrapper
      const itemWidth = scroll.querySelector('.gallery-item-wrapper')?.clientWidth || 300;
      scroll.scrollBy({ left: -itemWidth, behavior: 'smooth' });
    });

    nextBtn.addEventListener('click', () => {
      const itemWidth = scroll.querySelector('.gallery-item-wrapper')?.clientWidth || 300;
      scroll.scrollBy({ left: itemWidth, behavior: 'smooth' });
    });

    // Fullscreen Modal Logic
    // Note: We select .gallery-media now, not .gallery-item
    const mediaItems = scroll.querySelectorAll('.gallery-media');
    mediaItems.forEach(item => {
      item.addEventListener('click', (e) => {
        const target = e.target as HTMLElement;
        if (target.tagName === 'VIDEO') return;

        openLightbox(container, item as HTMLElement);
      });
    });
  });
}

function openLightbox(container: Element, clickedItem: HTMLElement) {
  // Clone items for the lightbox
  const scrollContainer = container.querySelector('.gallery-scroll');
  if (!scrollContainer) return;

  const items = Array.from(scrollContainer.querySelectorAll('.gallery-media'));
  let currentIndex = items.indexOf(clickedItem);

  const lightbox = document.createElement('div');
  lightbox.className = 'lightbox-modal fade-in';
  lightbox.innerHTML = `
        <button class="lightbox-close">×</button>
        <button class="lightbox-nav prev">❮</button>
        <div class="lightbox-content">
            <!-- Content Injected Here -->
        </div>
        <button class="lightbox-nav next">❯</button>
        <div class="lightbox-caption"></div>
    `;

  document.body.appendChild(lightbox);
  document.body.style.overflow = 'hidden'; // Prevent scrolling bg

  const contentDiv = lightbox.querySelector('.lightbox-content')!;
  const captionDiv = lightbox.querySelector('.lightbox-caption')!;

  const updateView = () => {
    contentDiv.innerHTML = '';
    const original = items[currentIndex] as HTMLElement;
    let clone: HTMLElement;

    if (original.tagName === 'IMG') {
      clone = document.createElement('img');
      (clone as HTMLImageElement).src = (original as HTMLImageElement).src;
      (clone as HTMLImageElement).alt = (original as HTMLImageElement).alt;
    } else {
      clone = document.createElement('video');
      (clone as HTMLVideoElement).src = (original as HTMLVideoElement).src;
      (clone as HTMLVideoElement).controls = true;
    }

    clone.className = 'lightbox-media fade-in';
    contentDiv.appendChild(clone);

    // Update caption
    const caption = original.getAttribute('alt') || (original.tagName === 'VIDEO' ? 'Video' : '');
    captionDiv.textContent = caption;
  };

  updateView();

  // Event Listeners
  lightbox.querySelector('.lightbox-close')?.addEventListener('click', () => {
    document.body.removeChild(lightbox);
    document.body.style.overflow = '';
  });

  lightbox.querySelector('.prev')?.addEventListener('click', () => {
    currentIndex = (currentIndex - 1 + items.length) % items.length;
    updateView();
  });

  lightbox.querySelector('.next')?.addEventListener('click', () => {
    currentIndex = (currentIndex + 1) % items.length;
    updateView();
  });

  // Close on click outside
  lightbox.addEventListener('click', (e) => {
    if (e.target === lightbox) {
      document.body.removeChild(lightbox);
      document.body.style.overflow = '';
    }
  });
}


// Initial Load & Event Listeners
window.addEventListener('popstate', router);
document.addEventListener('DOMContentLoaded', () => {
  // Intercept logo click
  document.querySelector('.logo a')?.addEventListener('click', (e) => {
    e.preventDefault();
    navigateTo('/');
  });
  router();
});
