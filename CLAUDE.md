# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Dev server** (configured in `.claude/launch.json`):
```bash
npx serve -l 3456 .
```
Open `http://localhost:3456` for the questionnaire and `http://localhost:3456/admin.html` for the CRM.

No build step, no package.json, no dependencies to install — the project is static HTML.

## Architecture

This is a two-page static site with no framework, no bundler, and all CSS/JS inlined inside each HTML file.

**`index.html`** — The questionnaire (26 questions in 7 sections, entirely in French). Flow: intro screen → questionnaire cards (one at a time) → synthèse (summary). Key mechanisms:
- State (`responses`, `currentStep`) lives in module-scope JS variables, mirrored to `localStorage` key `questionnaire_cecile` on every change.
- Supabase is synced via a 2-second debounce (`debouncedSync`) on every input, and immediately on completion (`markCompleted`). Uses `upsert` on `session_id` (a `crypto.randomUUID()` stored in localStorage).
- Voice input uses the Web Speech API (`SpeechRecognition`, `fr-FR`). Only works in Chrome/Edge.
- `SECTIONS` array is the single source of truth for question definitions — it drives card rendering, synthesis display, and email body generation.

**`admin.html`** — Password-protected CRM dashboard. Password is hardcoded as `fabien2026`, checked client-side only, with `sessionStorage` used to persist auth across page refreshes. Reads all rows from the `submissions` Supabase table and lets Fabien set status (`nouveau` / `en_cours` / `traité`) and add notes per submission.

**`setup.sql`** — Supabase schema. The `submissions` table stores one row per `session_id` with a `responses` JSONB column, a `status` text field, and free-text `notes`. RLS policies allow anonymous insert, update, and select (the anon key is public in the source).

## Key Conventions

- **All user-facing text is in French.** Keep it that way.
- Both HTML files share the same Supabase URL/key and an identical `SECTIONS` constant (question IDs `l1`–`l26`). If questions change, update both files.
- The Supabase publishable key (`sb_publishable_*`) is intentionally public and safe to commit — it is an anon key restricted by RLS.
- Deployment target is Vercel (`.vercel` is gitignored). No CI configuration exists.
- There is no linter, formatter, or test suite.
