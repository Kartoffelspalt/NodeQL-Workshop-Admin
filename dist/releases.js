'use strict';

const releasesUrl = new URL('https://github.com/Kartoffelspalt/NodeQL-Workshop-Admin/releases');
const statusText = document.querySelector('#release-status');
const releaseLink = document.querySelector('#release-link');
const history = document.querySelector('#release-history');
const emptyHistory = document.querySelector('#history-empty');
const checksum = document.querySelector('#checksum');
const dateFormatter = new Intl.DateTimeFormat('de-DE', { dateStyle: 'long', timeZone: 'UTC' });

function safeReleaseLink(value) {
  try {
    const url = new URL(value);
    return url.origin === releasesUrl.origin && url.pathname.startsWith(releasesUrl.pathname + '/')
      ? url.href
      : null;
  } catch {
    return null;
  }
}

function releaseLabel(release) {
  const label = release.prerelease ? 'Vorabversion' : 'Version';
  return label + ' ' + release.tag;
}

function renderReleases(releases) {
  const latest = releases[0];
  if (!latest) {
    statusText.textContent = 'Es gibt noch kein veröffentlichtes Release.';
    return;
  }

  statusText.textContent = releaseLabel(latest) + ' · ' + dateFormatter.format(new Date(latest.published_at));
  releaseLink.href = safeReleaseLink(latest.url) ?? releasesUrl.href;
  releaseLink.firstChild.textContent = 'Versionshinweise ';
  for (const anchor of document.querySelectorAll('[data-asset]')) {
    const url = safeReleaseLink(latest.assets?.[anchor.dataset.asset]);
    if (url) {
      anchor.href = url;
      anchor.hidden = false;
    }
  }
  checksum.hidden = checksum.firstElementChild.hidden;

  for (const release of releases) {
    const url = safeReleaseLink(release.url);
    if (!url) continue;
    const item = document.createElement('li');
    const link = document.createElement('a');
    link.className = 'text-link';
    link.href = url;
    link.textContent = releaseLabel(release);
    const time = document.createElement('time');
    time.dateTime = release.published_at;
    time.textContent = dateFormatter.format(new Date(release.published_at));
    item.append(link, time);
    history.append(item);
  }
  if (history.children.length) {
    history.hidden = false;
    emptyHistory.hidden = true;
  }
}

async function loadReleases() {
  try {
    const response = await fetch('releases.json', { cache: 'no-cache' });
    if (!response.ok) throw new Error('Release-Daten konnten nicht geladen werden');
    renderReleases(await response.json());
  } catch {
    statusText.textContent = 'Die Versionsliste ist gerade nicht verfügbar. Öffne GitHub Releases für den aktuellen Stand.';
  }
}

loadReleases();
