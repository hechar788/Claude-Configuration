---
description: Generate feature documentation with user stories
argument-hint: <feature-name> | <feature>/<sub-feature> | all
allowed-tools: Read, Glob, Grep, Write, Task, Bash(mkdir *)
---

# Document Command

Generate or update feature documentation in `.claude/data/documentation/`.

## Input

`$ARGUMENTS`:

- Empty or `all`: Crawl codebase and document all undocumented features
- `<feature-name>`: Document all sub-features within a feature domain
- `<feature>/<sub-feature>`: Document only the specified sub-feature

## Agent Instructions

Documentation agents have detailed instructions in `.claude/agents/documentation/`:

| File                       | Purpose                                           | Use When                 |
| -------------------------- | ------------------------------------------------- | ------------------------ |
| `feature-identifier.md`    | Guidelines for identifying sub-features           | Discovery phase          |
| `domain-overview.md`       | Template for domain overview.md                   | Creating domain docs     |
| `product-owner.md`         | Template for product-brief.md and user-stories.md | Sub-feature product docs |
| `implementation-expert.md` | Template for technical <sub-feature>.md           | Sub-feature tech docs    |

**Important**: When launching `documentation-generator` agents, READ the relevant instruction file first and include its guidelines in the prompt. This ensures consistent documentation quality.

## Output Structure

Documentation uses a **hierarchical structure** with feature domains containing sub-features:

```
.claude/data/documentation/
├── _index.md                    # Master index of all features
└── <feature-domain>/
    ├── overview.md              # Domain overview, architecture, shared patterns
    └── <sub-feature>/
        ├── product-brief.md     # WHY - Business value, user problems, goals
        ├── user-stories.md      # WHAT - User perspective and flows
        └── <sub-feature>.md     # HOW - Technical implementation details
```

### Example Structure

```
.claude/data/documentation/
├── _index.md
├── <domain-a>/
│   ├── overview.md              # Domain overview: architecture, shared patterns
│   ├── <sub-feature-1>/
│   │   ├── product-brief.md
│   │   ├── user-stories.md
│   │   └── <sub-feature-1>.md
│   ├── <sub-feature-2>/
│   │   ├── product-brief.md
│   │   ├── user-stories.md
│   │   └── <sub-feature-2>.md
│   └── ...
└── <domain-b>/
    ├── overview.md
    ├── <sub-feature-1>/
    └── ...
```

## Feature Domains

Feature domains are discovered automatically by crawling the codebase. Common patterns include:

- **authentication** - login, signup, session management, protected routes
- **users** - profile management, settings, preferences
- **<domain>** - identify domains based on your `src/components/`, `src/hooks/`, `src/server/` folder structure

## Execution

### Mode 1: Full Crawl (`/document` or `/document all`)

**Phase 1: Domain Discovery**

1. Read `.claude/data/documentation/_index.md` to see what's already documented
2. Launch `Explore` agents in parallel to identify sub-features within each domain:

```
Task(subagent_type="Explore", prompt="Explore src/components/<domain>/, src/hooks/<domain>/, and src/server/<domain>/ to identify distinct sub-features. Return a list where each sub-feature has: name (kebab-case), description (1-2 sentences), related files, and key dependencies.")
```

**Phase 2: Consolidation**

3. Collect sub-feature definitions from all Explore agents
4. Group sub-features by domain
5. Filter out sub-features already documented (check for existing directories)
6. Create consolidated list of domains and their sub-features

**Phase 3: Domain Overview Documentation**

7. Read `.claude/agents/documentation/domain-overview.md` for template guidelines
8. For each domain with undocumented sub-features, create/update `overview.md`:

```
Task(subagent_type="documentation-generator", prompt="Create domain overview for '<domain>'.

## Instructions
Follow the template in .claude/agents/documentation/domain-overview.md

## Sub-features in this domain
<list of sub-features with descriptions>

## Output
Create: .claude/data/documentation/<domain>/overview.md

Include:
- Domain purpose and scope
- Architecture diagram showing how sub-features relate
- Shared patterns (query key factories, real-time events, etc.)
- Common dependencies
- Sub-feature index table with links")
```

**Phase 4: Sub-Feature Documentation**

9. Read `.claude/agents/documentation/product-owner.md` and `.claude/agents/documentation/implementation-expert.md` for templates
10. For each undocumented sub-feature, launch a `documentation-generator` agent:

```
Task(subagent_type="documentation-generator", prompt="Create documentation for '<sub-feature>' in '<domain>'.

## Instructions
Follow templates in:
- .claude/agents/documentation/product-owner.md (for product-brief.md and user-stories.md)
- .claude/agents/documentation/implementation-expert.md (for <sub-feature>.md)

## Sub-feature definition
<paste sub-feature definition with files>

## Output files
- .claude/data/documentation/<domain>/<sub-feature>/product-brief.md
- .claude/data/documentation/<domain>/<sub-feature>/user-stories.md
- .claude/data/documentation/<domain>/<sub-feature>/<sub-feature>.md

IMPORTANT: Focus on THIS specific sub-feature only. Keep documentation focused and concise.")
```

11. Batch up to 5-8 agents in parallel (different directories = no conflicts)

**Phase 5: Index Update**

12. Update `.claude/data/documentation/_index.md` with all new sub-features
13. Report summary of what was documented

### Mode 2: Domain Targeted (`/document <feature-domain>`)

Document all sub-features within a specific domain:

1. Search codebase for files related to `<feature-domain>`
2. Identify all sub-features within the domain
3. Create/update domain `overview.md`
4. Launch parallel agents for each sub-feature
5. Update index

### Mode 3: Sub-Feature Targeted (`/document <domain>/<sub-feature>`)

Document a single sub-feature:

1. Search codebase for files related to `<sub-feature>` within `<domain>`:
   - `src/components/<domain>/**/*<sub-feature>*`
   - `src/hooks/<domain>/**/*<sub-feature>*`
   - `src/server/<domain>/**/*<sub-feature>*`

2. Compile sub-feature definition with found files

3. Launch single `documentation-generator` agent:

```
Task(subagent_type="documentation-generator", prompt="Create documentation for '<sub-feature>' in '<domain>'.

Files:
- <list of found files>

Create these files:
- .claude/data/documentation/<domain>/<sub-feature>/product-brief.md
- .claude/data/documentation/<domain>/<sub-feature>/user-stories.md
- .claude/data/documentation/<domain>/<sub-feature>/<sub-feature>.md")
```

4. Update `_index.md` with the new sub-feature

## Documentation Guidelines

### overview.md (Domain Level)

```markdown
# <Domain> Feature Domain

## Purpose

Brief description of what this domain covers.

## Architecture

Diagram or description of how components interact.

## Sub-Features

| Sub-Feature                         | Description                     | Status |
| ----------------------------------- | ------------------------------- | ------ |
| [send-request](./send-request/)     | Send friend requests to users   | ✓      |
| [accept-request](./accept-request/) | Accept incoming friend requests | ✓      |

## Shared Patterns

- Query key factories
- Common hooks
- Shared utilities

## Dependencies

- Internal: other domains this depends on
- External: npm packages
```

### product-brief.md (Sub-Feature Level)

```markdown
# <Sub-Feature> - Product Brief

## Overview

1-2 sentence description.

## User Problem

What specific problem does this solve?

## Goals

- Primary goal
- Secondary goals

## Success Metrics

How do we measure success?

## Scope

What's in/out of scope for THIS sub-feature.
```

### user-stories.md (Sub-Feature Level)

```markdown
# <Sub-Feature> - User Stories

## Primary Story

As a [user type], I want to [action] so that [benefit].

### Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

### User Flow

1. Step 1
2. Step 2

## Edge Cases

- Edge case 1
- Edge case 2
```

### <sub-feature>.md (Sub-Feature Level)

```markdown
# <Sub-Feature> - Technical Documentation

## Overview

Brief technical description.

## Components

| Component | Purpose |
| --------- | ------- |

## Hooks

| Hook | Purpose |
| ---- | ------- |

## Server Functions

| Function | Purpose |
| -------- | ------- |

## Data Flow

Diagram or description.

## Code Examples

Key patterns with snippets.
```

## Example Usage

```bash
# Document all undocumented features (full discovery)
/document

# Document everything (explicit)
/document all

# Document all friends sub-features
/document friends

# Document only the send-request sub-feature
/document friends/send-request

# Document messaging conversation list
/document messaging/conversation-list
```

## Notes

- Sub-features already documented (directory exists) will be skipped in full crawl mode
- Use targeted mode to regenerate specific documentation
- Domain overview.md is created/updated when any sub-feature in domain is documented
- Keep sub-feature documentation focused - if it's getting too long, it might need to be split further
