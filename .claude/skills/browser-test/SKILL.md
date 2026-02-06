---
name: browser-test
description: Test implemented features using Claude in Chrome extension
user-invocable: true
allowed-tools: Bash(npm run *), Read, mcp__browser__*
---

# Browser Testing with Claude in Chrome

Automated testing using browser tools via the Claude in Chrome extension.

**Requirement:** Claude Code must be running with `--chrome` flag to enable browser tools.

## Testing Workflow

### 1. Ensure Dev Server is Running

Start the dev server if not already running.

### 2. Open the Application

Navigate to the application URL and the relevant route for the feature being tested.

### 3. Execute Test Checks

#### Console Check

Read the browser console and identify:

- JavaScript errors (critical)
- Framework warnings (React, Vue, etc.)
- Failed network requests
- Unhandled promise rejections

Report issues with full error messages and stack traces.

#### Visual Verification

- Take a screenshot of the current state
- Verify UI elements render correctly
- Test interactive elements by clicking them
- Check for layout issues or visual bugs

#### Network Inspection

Check network activity for:

- Failed HTTP requests (4xx/5xx status codes)
- CORS errors
- Timeout issues
- Unexpected request patterns

#### Application State (when applicable)

Inspect browser storage:

- Read localStorage entries
- Check IndexedDB data
- Verify session/cookie state

### 4. Interactive Testing

For the feature being tested:

1. Fill any required form fields
2. Click buttons/links to trigger actions
3. Verify the expected behavior occurs
4. Check console for new errors after each action

## Issue Resolution Loop

When issues are found:

1. Capture the exact error message
2. Note the component/file from stack trace
3. Document reproduction steps
4. Fix the issue in the codebase
5. Re-run the specific failing check

## Test Checklists by Feature Type

### UI Components

- [ ] Renders without console errors
- [ ] Visual appearance matches design
- [ ] Hover/focus states work
- [ ] Responsive at different viewports
- [ ] No layout shifts on load

### Forms

- [ ] Validation triggers on blur/submit
- [ ] Error messages display correctly
- [ ] Successful submission works
- [ ] Loading state shows during submit
- [ ] Error handling for failed submissions

### Data Features

- [ ] Initial data loads correctly
- [ ] Loading skeleton/spinner shows
- [ ] Data updates persist
- [ ] Empty states render properly
- [ ] Error states handle gracefully

### WebSocket/Real-time

- [ ] Connection establishes
- [ ] Messages send and receive
- [ ] Reconnection after disconnect
- [ ] Connection status indicators update

### State Persistence

- [ ] Data saves to localStorage/IndexedDB
- [ ] State survives page refresh
- [ ] Clear/reset functions work
- [ ] No stale data after updates
