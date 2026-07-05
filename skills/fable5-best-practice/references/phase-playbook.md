# Phase playbook: discovering unknowns before, during, and after implementation

This reference expands the "map is not the territory" section of SKILL.md. Use it when a
task has meaningful unknowns: unfamiliar subsystems, design work where you cannot yet
tell what "good" looks like, or long multi-step runs. You do not need every technique on
every task — pick the ones that fill your empty buckets (the four-bucket taxonomy is in
SKILL.md).

The throughline: every brainstorm, interview, prototype, reference, and explainer is a
cheap way to learn what you did not know before it gets expensive to fix in code. Give
the model your starting point — what you already know, your experience with this problem
and codebase, and where you are in your thinking — so it targets real gaps instead of
guessing. Prefer HTML artifacts for brainstorms, prototypes, plans, pitches, and quizzes;
they are usually the best medium for reacting to and sharing this work.

## Before implementation

### Blind spot pass — for unknown unknowns

When working in an unfamiliar area you may not know what questions to ask, what "good"
looks like, what historical work exists, or what potholes to avoid. Ask the model to find
your unknown unknowns and teach them to you. Use the literal words "blind spot pass" and
"unknown unknowns," state who you are and what you do not know, and ask it to help you
prompt better. Best for new subsystems, unfamiliar domains, or design work.

- "I'm adding a new auth provider but know nothing about the auth modules in this
  codebase. Do a blind spot pass on my unknown unknowns and help me prompt you better."
- "I don't know what color grading is but I need to grade this video. Teach me my unknown
  unknowns about color grading so I can prompt better."

### Brainstorm and prototype — for unknown knowns

When the criteria are "know it when I see it," verbalize them early. Finding them during
implementation is expensive: small spec changes can force very different code, and
reverting is hard. Ask for several wildly different directions as a throwaway HTML
artifact with fake data before wiring anything real. Open most sessions with a short
exploration pass so scope is set with intent rather than guessed too narrow or too wide.

- "I want a dashboard for this data but have no visual taste and don't know what's
  possible. Make an HTML page with 4 wildly different design directions so I can react."
- "Before wiring anything up, make a single HTML file mocking the new editor toolbar with
  fake data. I want to react to the layout before you touch the real app."
- "Rough problem: users churn after onboarding. Search the codebase and brainstorm 10
  places we could intervene, cheapest to most ambitious. I'll tell you which resonate."

### Interview — for remaining known unknowns

After brainstorming you likely still have gaps. Have the model interview you one question
at a time about anything ambiguous, prioritizing questions whose answers would change the
architecture. Give context to guide its questions. See "Start by interviewing the user"
in SKILL.md for the user-facing version of this.

- "Interview me one question at a time about anything ambiguous; prioritize questions
  where my answer would change the architecture."

### References — when you cannot articulate what you want

Sometimes you lack the language, or a full description would take too long. The best
reference is source code: a library, crate, or component that already behaves the way you
want is richer than a screenshot or prose, because the model reads the structure, not
just the surface. This works across languages — point it at the folder and say what to
look for.

- "This Rust crate in vendor/rate-limiter implements the exact backoff behavior I want.
  Read it and reimplement the same semantics in our TypeScript API client."

### Implementation plan — surface the mutable decisions

When ready to build, ask for a plan that leads with the decisions you are most likely to
change — data model changes, new type interfaces, and user-facing flows — and buries
mechanical refactoring at the bottom. This puts the reviewable, mutable choices where you
will actually catch them.

- "Write an implementation plan in HTML, but lead with the decisions I'm most likely to
  tweak: data model changes, new type interfaces, and anything user-facing. Bury the
  mechanical refactoring at the bottom — I trust you on that part."

## During implementation

Start implementation in a fresh session with the artifacts attached (spec, prototype,
plan). No amount of planning removes every unknown unknown, so ask the agent to keep a
temporary `implementation-notes.md`: when an edge case forces a deviation from the plan,
take the conservative option, log it under "Deviations," and keep going. The notes make
the next attempt cheaper and expose unknowns the plan missed. This is a during-run scratch
file for one task, distinct from the durable memory file in "Use memory carefully."

- "Keep an implementation-notes.md file. If you hit an edge case that forces you to
  deviate from the plan, pick the conservative option, log it under 'Deviations,' and
  keep going."

## After implementation

### Pitch and explainer — for buy-in and approvals

Package the spec, prototype, and implementation notes into a single artifact for buy-in.
Lead with the demo and write for reviewers who start with the same unknowns you did.
Showing that you accounted for the failure points an expert would anticipate speeds
approval.

- "Package the prototype, the spec, and the implementation notes into a single doc I can
  drop in Slack to get buy-in. Lead with the demo GIF."

### Quiz — confirm you understand what shipped

After a long run, reading the diff gives only shallow understanding because behavior
depends on existing code paths. Ask the model for a report on the change with context and
intuition, plus a quiz at the bottom you must pass before merging.

- "Give me an HTML report on the changes with context, intuition, and what was done, plus
  a quiz at the bottom that I must pass. I only merge after passing perfectly."
