# Documentation policy

Documentation is part of every AeroMirror patch, not a post-release cleanup.
This policy applies to product behavior, managed or native code, installer and
update logic, build and packaging scripts, security rules, and release assets.

## Required for every patch

Before a patch is handed off, committed, tagged, or published, update all of
the following:

1. `CHANGELOG.md`
   - Add an English, user-visible entry under the patch version.
   - Describe outcomes and limitations rather than listing commits.
   - State whether an installed user should update when that is not obvious.
2. `docs/PROJECT_STATE.md`
   - Record the candidate or public version, current verification status,
     remaining blockers, and the immediate next step.
   - Distinguish automated checks from physical Windows and iPhone results.
3. `docs/releases/<version>/RELEASE_NOTES.md`
   - Keep the curated English text used as the GitHub Release body.
   - Include a short summary, `Should I update?`, changes, and known
     limitations.
4. `docs/releases/<version>/TEST_PLAN.md`
   - Cover the changed behavior and the regression paths it can affect.
   - Define the test environment, evidence to retain, expected results,
     failure conditions, and the acceptance gate.

Create the version directory when work on a new patch begins. Continue to
update the same files as the implementation and evidence change. Never reuse
the directory of an already published version for a correction; create a new
patch version instead.

Historical 0.11 documents currently use names such as
`docs/TEST_PLAN_0.11.3.md` and `docs/BUILD_REPORT_0.11.3.md`. They remain valid
release history until the planned 0.12 documentation move. New versioned
documents should use the directory layout above.

## Required after publication

After GitHub publication and public-asset verification, add or update:

`docs/releases/<version>/BUILD_REPORT.md`

The report must record:

- the exact tag and source commit;
- release URL and channel state;
- commands or automated gates that passed;
- public asset names, byte sizes, and SHA-256 digests;
- re-download verification results;
- physical tests completed and still pending;
- known limitations and the rule that published assets are immutable.

Update `docs/PROJECT_STATE.md` again in the same post-release documentation
change. A tag may remain at the reviewed source commit while the subsequent
documentation commit records hashes that only became available after asset
publication.

## Conditional documentation matrix

Update these files whenever the corresponding area changes:

| Changed area | Required documentation |
|---|---|
| Installation, setup, first-run, settings, updates, troubleshooting, or supported behavior | `README.md` |
| Component boundaries, lifecycle, IPC, network/discovery state, persistence, or security model | `docs/ARCHITECTURE.md` |
| Durable product, compatibility, distribution, or architecture choice | `docs/DECISIONS.md` |
| Backlog, deferred work, acceptance target, or roadmap priority | `docs/TODO.md` |
| Release channel, asset contract, signing, upgrade, or publication procedure | `docs/RELEASE_AND_SIGNING.md` |
| Diagnostics, log location, privacy, recovery, or report workflow | `docs/TROUBLESHOOTING.md`, and `CONTRIBUTING.md` when reporter guidance changes |
| Dependency, upstream commit, native patch, runtime, license, or redistribution scope | `THIRD_PARTY_NOTICES.md`, `UPSTREAM.lock`, `native-core/source-provenance.json`, and the relevant native build documentation |
| Security boundary, vulnerability scope, secret handling, or supported security version | `SECURITY.md` |
| Repository layout or standard agent workflow | `AGENTS.md` and the source-layout section of `README.md` |

Do not edit provenance or license records merely to make their dates look
current. Update them only when their recorded inputs or obligations change,
then run all provenance validation required by the release pipeline.

## Writing and status rules

- Release communication and new maintainer documentation are English.
- Use three-part public semantic versions such as `0.12.0`.
- Use past tense only for work that is complete and verified.
- Say `pending` for physical-device tests that have not run.
- Do not claim Windows or iPhone compatibility solely from source inspection
  or automated checks.
- Link durable decisions from the release notes when a patch changes one.
- Keep volatile status in `docs/PROJECT_STATE.md`; do not turn `AGENTS.md` or
  `docs/ARCHITECTURE.md` into a release diary.

## Patch handoff checklist

Before handoff or commit:

- [ ] `CHANGELOG.md` describes the patch.
- [ ] `docs/PROJECT_STATE.md` reflects the current state and next action.
- [ ] `docs/releases/<version>/RELEASE_NOTES.md` is current.
- [ ] `docs/releases/<version>/TEST_PLAN.md` covers the changed risk.
- [ ] Every applicable conditional document above is updated.
- [ ] Automated and physical results are clearly separated.
- [ ] Links and version references are valid.
- [ ] `git diff --check` passes.

Before and after publication, also follow the gates in
`docs/RELEASE_AND_SIGNING.md` and the publication rules in `AGENTS.md`.
