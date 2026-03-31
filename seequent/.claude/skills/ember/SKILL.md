---
name: ember
description: Ember.js conventions for imago-portal (Ember 5.12 Octane, TypeScript) and imago-admin (Ember 3.28 LTS). Use when working with Glimmer components, ember-data, services, routing, or ember-qunit tests.
---

# Ember.js Guide

## Quick Reference

| Topic | Reference file |
|---|---|
| Glimmer components, @tracked, @action, getters, modifiers, named blocks | references/1-octane-components.md |
| ember-data models, adapters, serializers, store API, relationships | references/2-ember-data.md |
| Services, DI, session, SQID auth, LaunchDarkly, imago-api service | references/3-services.md |
| Route hooks, navigation, query params, route-driven data loading | references/4-routing.md |
| ember-qunit, setupRenderingTest, DOM queries, mocking services/store | references/5-testing.md |

---

## Apps

| App | Version | Language | Notes |
|---|---|---|---|
| imago-portal | Ember 5.12 Octane | TypeScript | Primary app; @glimmer/component, decorators, CSS modules |
| imago-admin | Ember 3.28 LTS | JavaScript | Mix of Classic + Glimmer; Bootstrap 4; model-support.js mixin |

---

## Core Rules

- **imago-portal uses Glimmer components exclusively** — no Classic patterns (this.set, this.get, @computed)
- **Args are read-only** — never mutate this.args.*; use callback props to request parent changes
- **Getters replace @computed** — plain getters auto-track their @tracked dependencies
- **Reassign tracked arrays/objects** — this.items = [...this.items, x], never .push(x)
- **All HTTP outside ember-data goes through imago-api service** — it adds the auth token header
- **Guard session.data.authenticated** — it is {} when unauthenticated; always check session.isAuthenticated first
- **Use data-test-* selectors in tests** — never couple to CSS classes or element tags

---

## When to Read Reference Files

- **Building or editing a Glimmer component** → read references/1-octane-components.md
- **Working with ember-data models, relationships, or adapters** → read references/2-ember-data.md
- **Using or creating a service, or working with auth/session** → read references/3-services.md
- **Adding routes, route hooks, query params, or navigation** → read references/4-routing.md
- **Writing or reviewing ember-qunit tests** → read references/5-testing.md
- **Migrating a component from Ember to React** → read references/1-octane-components.md + references/5-testing.md, then use the jest-rtl skill for the React side

---

## Classic vs Octane Quick Reference

| Pattern | imago-admin (3.28) | imago-portal (5.12) |
|---|---|---|
| Component base | Mix of Classic + Glimmer | @glimmer/component only |
| Reactive state | @tracked + @computed (legacy) | @tracked + getters |
| Args | Two-way binding possible | One-way only, read via this.args |
| Language | JavaScript | TypeScript |
