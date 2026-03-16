import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { pasteService } from '../services/api';
import type { ExpiryOption, SupportedLanguage } from '../types/paste';
import { EXPIRY_LABELS, LANGUAGE_LABELS } from '../types/paste';

export default function CreatePaste() {
  const navigate = useNavigate();

  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [language, setLanguage] = useState<SupportedLanguage>('plaintext');
  const [expiry, setExpiry] = useState<ExpiryOption>('never');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!content.trim()) {
      setError('Content cannot be empty.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const paste = await pasteService.create({
        title: title.trim() || undefined,
        content,
        language,
        expiry,
      });
      navigate(`/paste/${paste.short_code}`);
    } catch {
      setError('Failed to create paste. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <header className="header">
        <h1>Snap<span className="accent">Paste</span></h1>
        <p className="subtitle">Paste code or text — get a shareable link instantly.</p>
      </header>

      <form className="form" onSubmit={handleSubmit}>
        <input
          className="input"
          type="text"
          placeholder="Title (optional)"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          maxLength={255}
        />

        <textarea
          className="textarea"
          placeholder="Paste your code or text here..."
          value={content}
          onChange={(e) => setContent(e.target.value)}
          required
          spellCheck={false}
          autoComplete="off"
        />

        <div className="form-row">
          <div className="field">
            <label className="label" htmlFor="language">Language</label>
            <select
              id="language"
              className="select"
              value={language}
              onChange={(e) => setLanguage(e.target.value as SupportedLanguage)}
            >
              {(Object.keys(LANGUAGE_LABELS) as SupportedLanguage[]).map((lang) => (
                <option key={lang} value={lang}>
                  {LANGUAGE_LABELS[lang]}
                </option>
              ))}
            </select>
          </div>

          <div className="field">
            <label className="label" htmlFor="expiry">Expires</label>
            <select
              id="expiry"
              className="select"
              value={expiry}
              onChange={(e) => setExpiry(e.target.value as ExpiryOption)}
            >
              {(Object.keys(EXPIRY_LABELS) as ExpiryOption[]).map((opt) => (
                <option key={opt} value={opt}>
                  {EXPIRY_LABELS[opt]}
                </option>
              ))}
            </select>
          </div>
        </div>

        {error && <p className="error">{error}</p>}

        <button className="btn" type="submit" disabled={loading}>
          {loading ? 'Creating...' : 'Create Paste'}
        </button>
      </form>
    </div>
  );
}
