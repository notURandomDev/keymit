import type { ReactNode } from 'react';
import type { Dict } from '../i18n';

const REPO_URL = 'https://github.com/notURandomDev/keymit';

export default function SiteFrame({
  t,
  children,
}: {
  t: Dict;
  children: ReactNode;
}) {
  const year = new Date().getFullYear();

  return (
    <>
      <header className="nav">
        <div className="nav-inner">
          <a className="nav-brand" href={t.lang === 'zh' ? '/' : '/en/'}>
            <img src="/keymit-icon.png" alt="Keymit" width={28} height={28} />
            <span>Keymit</span>
          </a>
          <nav className="nav-links">
            <a href={REPO_URL} target="_blank" rel="noopener">
              {t.nav.github}
            </a>
            <a className="lang-switch" href={t.nav.switchHref}>
              {t.nav.switch}
            </a>
          </nav>
        </div>
      </header>

      <main>{children}</main>

      <footer className="footer">
        <div className="footer-inner">
          <span>{t.footer.copyright.replace('{year}', String(year))}</span>
          <a href={REPO_URL} target="_blank" rel="noopener">
            {t.footer.github}
          </a>
        </div>
      </footer>
    </>
  );
}
