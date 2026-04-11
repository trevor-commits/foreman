## GitHub Actions Hosted Runner Validation

Run this once to confirm `foreman-trailer-check.yml` works on GitHub's infrastructure.

### Test A — Valid commit passes
1. Create a branch: `git checkout -b test/trailer-check-valid`
2. Make a trivial change, for example add a blank line to `README.md`
3. Commit with all required trailers:

```bash
git commit -m "chore: trailer check validation

Agent: codex-manual
Thread: manual-test
Task: Validate trailer-check workflow on hosted runner
Verified-By: manual
Reviewed-By: none-yet"
```

4. Push and open a PR to `main`
5. Confirm the GitHub Actions check passes
6. Close the PR without merging and delete the branch

### Test B — Missing trailer fails
1. Create a branch: `git checkout -b test/trailer-check-missing`
2. Make a trivial change
3. Commit without the `Agent:` trailer:

```bash
git commit --no-verify -m "chore: missing trailer test"
```

4. Push and open a PR to `main`
5. Confirm the GitHub Actions check fails on the trailer validation step
6. Close the PR without merging and delete the branch

### Record results

Add a `Test Evidence Log` entry in `todo.md` with the date, PR links, and pass/fail outcome.
Once both tests pass, mark `[Phase 2.1] Validate trailer-check GitHub Actions workflow from a real hosted runner` as complete in `todo.md`.
