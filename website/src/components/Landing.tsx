import type { Dict } from '../i18n';

const RELEASES_URL = 'https://github.com/notURandomDev/keymit/releases';
const REPO_URL = 'https://github.com/notURandomDev/keymit';
const SHA256 =
  'afe6af17e24b6560c4f3ea42fe6f643340cf88e5ac434d7314e65e4dd0dc29dd';

// 演示用热力图数据：确定性伪随机，52 周 x 7 天，5 个等级。
const WEEKS = 52;
const DAYS = 7;
let seed = 20260101;
const rand = () => {
  seed = (seed * 9301 + 49297) % 233280;
  return seed / 233280;
};
const cells = Array.from({ length: WEEKS * DAYS }, () => {
  const r = rand();
  if (r < 0.32) return 0;
  if (r < 0.58) return 1;
  if (r < 0.78) return 2;
  if (r < 0.92) return 3;
  return 4;
});

export default function Landing({ t }: { t: Dict }) {
  return (
    <>
      <section className="hero">
        <img
          className="hero-icon"
          src="/keymit-icon.png"
          alt="Keymit app icon"
          width={128}
          height={128}
        />
        <h1>{t.hero.tagline}</h1>
        <p className="hero-sub">{t.hero.subtitle}</p>
        <div className="hero-actions">
          <a
            className="btn btn-primary"
            href={RELEASES_URL}
            target="_blank"
            rel="noopener"
          >
            {t.hero.download}
          </a>
          <a
            className="btn btn-secondary"
            href={REPO_URL}
            target="_blank"
            rel="noopener"
          >
            {t.hero.source}
          </a>
        </div>
        <p className="hero-req">{t.hero.requirement}</p>
      </section>

      <section className="section section-alt" id="features">
        <div className="section-inner">
          <h2>{t.features.heading}</h2>
          <p className="section-sub">{t.features.sub}</p>
          <div className="feature-grid">
            {t.features.items.map((f) => (
              <div className="feature-card" key={f.title}>
                <div className="feature-icon" aria-hidden="true">
                  {f.icon}
                </div>
                <h3>{f.title}</h3>
                <p>{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section" id="privacy">
        <div className="section-inner">
          <h2>{t.privacy.heading}</h2>
          <p className="section-sub">{t.privacy.sub}</p>
          <div className="privacy-grid">
            {t.privacy.points.map((p) => (
              <div className="privacy-item" key={p.title}>
                <h3>{p.title}</h3>
                <p>{p.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section section-alt" id="heatmap">
        <div className="section-inner">
          <h2>{t.heatmap.heading}</h2>
          <p className="section-sub">{t.heatmap.sub}</p>
          <div className="heatmap-wrap">
            <div className="heatmap" role="img" aria-label="activity heatmap demo">
              {cells.map((level, i) => (
                <span className={`hm hm-${level}`} key={i} />
              ))}
            </div>
            <div className="heatmap-legend">
              <span>{t.heatmap.less}</span>
              <span className="hm hm-0"></span>
              <span className="hm hm-1"></span>
              <span className="hm hm-2"></span>
              <span className="hm hm-3"></span>
              <span className="hm hm-4"></span>
              <span>{t.heatmap.more}</span>
            </div>
          </div>
        </div>
      </section>

      <section className="section" id="install">
        <div className="section-inner section-narrow">
          <h2>{t.install.heading}</h2>
          <p className="section-sub">{t.install.sub}</p>
          <ol className="steps">
            {t.install.steps.map((s) => (
              <li key={s}>{s}</li>
            ))}
          </ol>
          <div className="warning">
            <strong>⚠️</strong>
            <p>{t.install.warning}</p>
          </div>
        </div>
      </section>

      <section className="section section-alt" id="download">
        <div className="section-inner section-narrow">
          <h2>{t.download.heading}</h2>
          <dl className="meta">
            <div>
              <dt>{t.download.versionLabel}</dt>
              <dd>v1.0.0</dd>
            </div>
            <div>
              <dt>{t.download.platformLabel}</dt>
              <dd>{t.download.platform}</dd>
            </div>
            <div>
              <dt>{t.download.shaLabel}</dt>
              <dd>
                <code className="sha">{SHA256}</code>
              </dd>
            </div>
          </dl>
          <p className="verify-label">{t.download.verifyLabel}</p>
          <pre className="verify-cmd">
            <code>{t.download.verifyCmd}</code>
          </pre>
          <div className="download-action">
            <a
              className="btn btn-primary"
              href={RELEASES_URL}
              target="_blank"
              rel="noopener"
            >
              {t.download.button}
            </a>
          </div>
        </div>
      </section>
    </>
  );
}
