import hljs from 'highlight.js';
import 'highlight.js/styles/github-dark.css';
import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { pasteService } from '../services/api';
import type { Paste } from '../types/paste';
import { LANGUAGE_LABELS } from '../types/paste';

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function formatExpiry(iso: string | null): string {
  if (!iso) return 'Never';
  const date = new Date(iso);
  const now = new Date();
  const diffMs = date.getTime() - now.getTime();
  if (diffMs <= 0) return 'Expired';
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  if (diffHours < 24) return `${diffHours}h remaining`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays}d remaining`;
}

export default function ViewPaste() {
  const { shortCode } = useParams<{ shortCode: string }>();
  const navigate = useNavigate();

  const [paste, setPaste] = useState<Paste | null>(null);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [copied, setCopied] = useState(false);
  const codeRef = useRef<HTMLElement>(null);

  useEffect(() => {
    if (!shortCode) return;

    pasteService
      .getByCode(shortCode)
      .then((data) => setPaste(data))
      .catch(() => setNotFound(true))
      .finally(() => setLoading(false));
  }, [shortCode]);

  useEffect(() => {
    if (paste && codeRef.current) {
      codeRef.current.textContent = paste.content;
      hljs.highlightElement(codeRef.current);
    }
  }, [paste]);

  const handleCopy = async () => {
    if (!paste) return;
    await navigator.clipboard.writeText(paste.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleCopyLink = async () => {
    await navigator.clipboard.writeText(window.location.href);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (loading) {
    return (
      <div className="container">
        <p className="muted">Loading...</p>
      </div>
    );
  }

  if (notFound) {
    return (
      <div className="container">
        <header className="header">
          <h1>Snap<span className="accent">Paste</span></h1>
        </header>
        <div className="not-found">
          <h2>Paste not found</h2>
          <p className="muted">This paste may have expired or never existed.</p>
          <button className="btn" onClick={() => navigate('/')}>
            Create New Paste
          </button>
        </div>
      </div>
    );
  }

  if (!paste) return null;

  const langLabel =
    LANGUAGE_LABELS[paste.language as keyof typeof LANGUAGE_LABELS] ?? paste.language;

  return (
    <div className="container">
      <header className="header">
        <h1>Snap<span className="accent">Paste</span></h1>
      </header>

      <div className="paste-view">
        <div className="paste-header">
          <div>
            {paste.title && <h2 className="paste-title">{paste.title}</h2>}
            <div className="meta">
              <span className="badge">{langLabel}</span>
              <span className="badge badge-muted">{paste.view_count} views</span>
              <span className="badge badge-muted">Created {formatDate(paste.created_at)}</span>
              <span className="badge badge-muted">Expires: {formatExpiry(paste.expires_at)}</span>
            </div>
          </div>
          <div className="actions">
            <button className="btn-secondary" onClick={handleCopy}>
              {copied ? 'Copied!' : 'Copy Code'}
            </button>
            <button className="btn-secondary" onClick={handleCopyLink}>
              Copy Link
            </button>
            <button className="btn" onClick={() => navigate('/')}>
              New Paste
            </button>
          </div>
        </div>

        <div className="code-block">
          <pre>
            <code ref={codeRef} className={`language-${paste.language}`} />
          </pre>
        </div>
      </div>
    </div>
  );
}
