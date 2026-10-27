# Actual acceptance record / 实际验收记录

Date: 2026-10-27, Asia/Shanghai. Host identities, absolute private paths and original logs are deliberately omitted. This record distinguishes source-project evidence, newly executed tests and untested branches.

## Original workstation evidence

- Windows 11 x64; Ubuntu-22.04 registered as WSL2; normal Linux user exists.
- Installed Foundation package: openfoam14; environment version 14; ParaView 5.10.0-RC1.
- Final source-project environment run: 22 checks passed, zero failed. Both interactive shell and explicit non-interactive loading worked.
- Original official tutorial: blockMesh=0, checkMesh=0, foamRun=0; 12,225 cells; SIMPLE convergence at 285 iterations; U and p present.
- Original ParaView desktop was inspected directly: visible pipeline, time 285, U Magnitude, full channel and scalar bar. Repeated original launcher did not duplicate the process.
- Source project's mass balance parser could not obtain inlet/outlet values. Mass conservation remains **unverified**.

## New repository tests executed locally

| Required test | Method | Result and limit |
|---|---|---|
| Windows environment | Unified `-VerifyOnly` under Windows PowerShell 5.1 | PASS; Windows 11 required |
| WSL2 state | Real list + exact parsing; WSL1/absent fixtures | PASS |
| Ubuntu version | `/etc/os-release`, x86_64 check | PASS, Ubuntu 22.04 |
| OpenFOAM version | Explicit environment and package status | PASS, 14 |
| blockMesh/checkMesh/foamRun | Each `-help`, followed by independent real tutorial run | PASS |
| Bash environment | `bash --noprofile --norc`, explicit source and strict-option handling | PASS; no `.bashrc` changes |
| Official CFD case | New isolated attempt, three commands, Mesh OK, convergence and final fields | PASS, final time 285 |
| ParaView launch checks | New launcher recognized original live instance; new Python renderer via pvpython | PASS for reuse and API render; fresh GUI launch NOT TESTED |
| Repeat execution | Second real benchmark call | PASS, `reused=true`, same case |
| Fault recovery | 10 Python fixture tests including nonzero stage, mesh quality, corrupt checkpoint, changed output, missing field, unknown viewer | PASS; fixtures are not real power-loss/reboot tests |
| Native boundary | Real WSL argv round trip: space, double quote, trailing slash, literal substitution text and Unicode | PASS in PowerShell 5.1 |
| PowerShell | Parser, ASCII, stderr isolation, scalar return, failure propagation and argument quoting | PASS |
| Source syntax | `bash -n`, Python AST; no Bash CRLF/BOM | PASS |
| GitHub Actions config | YAML parsed; events, permissions, OS jobs and PowerShell shell checked | PASS; first remote run succeeded on commit `be681c0` (run 40526077817). Check the latest commit separately. |

New ParaView render receipt: time=285, cells=12225, color=U Magnitude, scalar_bar=true, velocity range approximately 0.00636788 to 10.18406837. This receipt explicitly retains `gui_visual_acceptance=required`. An API render is not a desktop screenshot.

During development, tests exposed and corrected: quoted WSL option parsing, a PowerShell 5.1 JSON-array fixture issue, broad floating-point-marker matching, and Ubuntu pvpython missing its installed dist-packages path. Initial failures were not reported as passes; results above refer to corrected code after rerun.

## Not tested / 尚未验证

1. Second computer: no access or evidence supplied.
2. New installer on a clean system: no reinstall or system configuration changes performed.
3. Administrator/password/reboot interactions: implemented prompts, not executed end to end.
4. Pending-restart gate: observed on this host; mutating orchestration correctly stops. Read-only checks allowed. No restart performed.
5. New GUI process creation and full installer success path: original GUI left running; new fresh-launch branch and automatic shortcut branch were not exercised as a whole because of the restart gate.
6. GitHub repository is Public. No tagged GitHub Release has been created. Later commits require their own Actions result.
7. Physical validity, conservation and mesh independence: outside this deployment acceptance.

## Repeatable real-host checklist

On a second Windows 11 PC, record OS/WSL/Ubuntu/package versions, run the entry point with a disposable runtime directory, complete requested manual handoffs, rerun after restart, verify the final fields and logs, launch the shortcut twice and count windows, then visually check the five GUI criteria in `paraview.md`. Record failures with sanitized excerpts. Never replace the second-PC row with PASS based on fixture CI.
