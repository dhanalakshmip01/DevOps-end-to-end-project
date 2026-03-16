export type ExpiryOption = '1h' | '1d' | '1w' | 'never';

export type SupportedLanguage =
  | 'plaintext'
  | 'python'
  | 'javascript'
  | 'typescript'
  | 'bash'
  | 'sql'
  | 'json'
  | 'yaml'
  | 'go'
  | 'rust'
  | 'java'
  | 'cpp'
  | 'html'
  | 'css'
  | 'markdown';

export interface Paste {
  id: string;
  short_code: string;
  title: string | null;
  content: string;
  language: SupportedLanguage;
  expires_at: string | null;
  view_count: number;
  created_at: string;
}

export interface CreatePasteRequest {
  title?: string;
  content: string;
  language: SupportedLanguage;
  expiry: ExpiryOption;
}

export const LANGUAGE_LABELS: Record<SupportedLanguage, string> = {
  plaintext: 'Plain Text',
  python: 'Python',
  javascript: 'JavaScript',
  typescript: 'TypeScript',
  bash: 'Bash',
  sql: 'SQL',
  json: 'JSON',
  yaml: 'YAML',
  go: 'Go',
  rust: 'Rust',
  java: 'Java',
  cpp: 'C++',
  html: 'HTML',
  css: 'CSS',
  markdown: 'Markdown',
};

export const EXPIRY_LABELS: Record<ExpiryOption, string> = {
  '1h': '1 Hour',
  '1d': '1 Day',
  '1w': '1 Week',
  never: 'Never',
};
