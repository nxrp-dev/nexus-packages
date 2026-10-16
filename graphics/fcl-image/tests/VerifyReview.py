# Copyright (c) 2026 Kevin Collins.
# SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
import pathlib
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parents[5]
fpc = root.parent / 'nexus-fpc'
sdk = root.parent.parent / 'toolchain/nexus-fpc/x86_64-linux/current'
mode = sys.argv[1] if len(sys.argv) > 1 else 'fixed'
if mode not in ('baseline', 'baseline-plain', 'fixed', 'plain'):
    raise SystemExit('Use baseline, baseline-plain, fixed or plain')
if len(sys.argv) > 2:
    sdk = pathlib.Path(sys.argv[2]).resolve()
if len(sys.argv) > 3:
    fpc = pathlib.Path(sys.argv[3]).resolve()
out = root / 'output/fcl-image-tests' / mode
out.mkdir(parents=True, exist_ok=True)
package = root / 'packages/nexus-packages/graphics/fcl-image'
baseline = root / 'output/fcl-image-tests/baseline-package'
if mode.startswith('baseline'):
    import hashlib, json, tarfile
    inventory = json.loads((package / 'review/baseline-hashes.json').read_text())
    with tarfile.open(package / 'review/baseline-source.tar.gz') as archive:
        for name, digest in inventory.items():
            relative = pathlib.PurePosixPath(name)
            if relative.is_absolute() or '..' in relative.parts:
                raise SystemExit('Invalid baseline path')
            data = archive.extractfile(name).read()
            if hashlib.sha256(data).hexdigest() != digest:
                raise SystemExit('Baseline hash mismatch: ' + name)
            target = baseline / name
            if target.exists() and target.read_bytes() != data:
                raise SystemExit('Existing baseline differs: ' + name)
            if not target.exists():
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
src = baseline / 'src' if mode.startswith('baseline') else package / 'src'
paths = [sdk / 'units/x86_64-linux/rtl', src, package / 'tests',
         root / 'packages/nexus-packages/nxtest/src', fpc / 'packages/iconvenc/src', fpc / 'rtl/inc', fpc / 'packages/paszlib/src', fpc / 'packages/hash/src',
         root / 'packages/nexus-packages/fcl-process/src',
         fpc / 'packages/rtl-objpas/src/inc', fpc / 'packages/rtl-objpas/src/unix',
         fpc / 'packages/fcl-base/src', fpc / 'packages/fcl-base/src/unix']
includes = [root / 'packages/nexus-packages/fcl-process/src/unix',
            fpc / 'packages/rtl-objpas/src/unix', fpc / 'packages/rtl-objpas/src/x86_64',
            fpc / 'packages/fcl-base/src/unix', fpc / 'packages/fcl-base/src/dummy']
for name in ['FCLImageFixture', 'FCLImageTests']:
    cmd = [str(sdk / 'bin/ppcx64'), '-n', '-MObjFPC', '-Aas-clang', '-XLL', '-Sc',
           '-FU' + str(out), '-FE' + str(out)]
    if not mode.endswith('plain'):
        cmd.extend(['-gt', '-Cr'])
    cmd.extend('-Fu' + str(p) for p in paths)
    cmd.extend('-Fi' + str(p) for p in includes)
    cmd.append(str(package / 'tests' / (name + '.lpr')))
    log = out / (name + '.build.log')
    with log.open('w') as stream:
        result = subprocess.run(cmd, cwd=root, stdout=stream, stderr=subprocess.STDOUT)
    print(name, 'exit', result.returncode, 'log', log, flush=True)
    print('\n'.join(log.read_text().splitlines()[-28:]), flush=True)
    if result.returncode:
        sys.exit(result.returncode)

with (out / 'regression-results.txt').open('w') as stream:
    result = subprocess.run([str(out / 'FCLImageTests')], cwd=root,
                            stdout=stream, stderr=subprocess.STDOUT, timeout=600)
print((out / 'regression-results.txt').read_text())
sys.exit(result.returncode)
