import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { dict } from '../../i18n';
import SiteFrame from '../../components/SiteFrame';
import '../globals.css';

const t = dict.zh;

export const metadata: Metadata = {
  title: t.title,
  description: t.description,
  icons: {
    icon: [{ url: '/keymit-icon.png', type: 'image/png' }],
  },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang={t.htmlLang}>
      <body>
        <SiteFrame t={t}>{children}</SiteFrame>
      </body>
    </html>
  );
}
