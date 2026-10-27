# Release preparation / 发布准备清单

MIT, repository name and public scope are owner-approved. Consult the actual remote for publication status; this checklist does not assert a Release or successful remote CI run.

## Before publication

- [x] Owner confirms repository name, public scope, license and copyright holder.
- [x] Add the approved LICENSE and update both READMEs.
- [ ] Recheck connected account for an existing repository immediately before creation. Current search found none visible; direct lookup returned 404, which is not proof of nonexistence for inaccessible repositories.
- [ ] Create a private repository first; no force push or overwrite of an existing repository.
- [ ] Run static tests, fixtures and release scan on the exact proposed commit.
- [ ] Have an owner review the file manifest and privacy scan; pattern scans cannot prove absence of secrets.
- [ ] Execute GitHub Actions; do not report local tests as remote CI success.
- [ ] Validate clean Windows provisioning, first-run account/password interaction, pending-restart handoff and resume on a second PC.
- [ ] Validate new GUI launch and full window contents on a real Windows host.
- [ ] Review physical CFD acceptance separately if making numerical accuracy claims.
- [ ] Keep an initial release marked pre-release until its stated acceptance scope is met.

## Release contents

Only Git-tracked generic code, documentation, tests, workflow YAML and placeholder examples. Do not attach runtime ZIPs, `.vhdx`, installer packages, credentials, screenshots of unrelated desktop content, complete solver fields or original diagnostics. A source-only archive may be prepared from the reviewed commit after licensing.

## Risk register

| Risk | Status / mitigation |
|---|---|
| License scope | MIT approved for new code/docs/tests; upstream software remains separately licensed |
| No second-PC evidence | Explicitly unverified in both READMEs |
| Clean install branch not executed | Current machine already installed; no reinstall performed |
| Pending Windows restart | Installation gate tested to stop; no restart performed |
| New GUI fresh launch not tested | Existing-window reuse + API render tested; real-host checklist remains |
| Third-party apt repository changes | Scoped signed-by key; existing sources preserved; explicit install confirmation |
| Local runtime logs disclose paths | Kept outside Git; raw logs never included |
| CI dependency tags | checkout@v4 uses a major tag; pin reviewed full commit SHA before hardened production release |
| Secret scanner false negatives | Automated patterns plus manual review; not a security certification |
| CFD suitability | Solver completion is not mass-conservation or engineering validation |
| Cross-host path/locale/GPU variation | Only original-PC data; second host still required |

## Suggested release notes

`v0.1.0-preview` (not created): reproducibility candidate for Windows 11 x64 / Ubuntu 22.04 / Foundation 14. Describe exact verified checks and all unverified installation/GUI paths. Do not use a blanket "all tests passed" or "production ready" claim.
