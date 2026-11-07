#!/usr/bin/env python3
"""Check every ports/<cat>/<port>/Makefile against its upstream (GitHub) source.

* GH_TAGNAME is a 40-hex commit  -> compare with upstream HEAD (or the branch
  from update-check.json).
* Otherwise                      -> compare DISTVERSION/PORTVERSION with the
  newest stable upstream tag.

Only stdlib + git are used (`git ls-remote`, no API tokens, no rate limits).
Overrides live in scripts/update-check.json, keyed by port name:
  {"port": {"skip": "reason", "repo": "https://...git", "branch": "main",
            "tag_prefix": "v"}}
"""
import argparse, glob, json, os, re, subprocess, sys

HEX40 = re.compile(r'^[0-9a-f]{40}$')
PRE = re.compile(r'(rc|alpha|beta|pre|dev|snapshot|nightly|test)', re.I)
VAR = re.compile(r'^([A-Z_]+)\??=\s*(.*?)\s*$')


def parse_makefile(path):
    v = {}
    for line in open(path, encoding='utf-8', errors='replace'):
        m = VAR.match(line)
        if m and m.group(1) not in v:
            v[m.group(1)] = m.group(2)
    return v


def expand(s, v):
    for _ in range(5):
        s = re.sub(r'\$\{(\w+)\}', lambda m: v.get(m.group(1), m.group(0)), s)
    return s


def ls_remote(*args):
    r = subprocess.run(['git', 'ls-remote', *args], capture_output=True, text=True,
                       timeout=90, env={**os.environ, 'GIT_TERMINAL_PROMPT': '0'})
    if r.returncode:
        raise RuntimeError((r.stderr.strip().splitlines() or ['ls-remote failed'])[0][:140])
    return [l.split('\t') for l in r.stdout.splitlines()]


def vtuple(s):
    return tuple(int(x) for x in re.findall(r'\d+', s))


def check(portdir, overrides):
    name = os.path.basename(portdir)
    ov = overrides.get(name, {})
    if 'skip' in ov:
        return dict(port=name, status='skip', note=ov['skip'])
    v = parse_makefile(os.path.join(portdir, 'Makefile'))
    v.setdefault('PORTNAME', name)
    v = {k: expand(x, v) for k, x in v.items()}
    repo = ov.get('repo')
    if not repo and 'GH_ACCOUNT' in v:
        repo = f"https://github.com/{v['GH_ACCOUNT']}/{v.get('GH_PROJECT', v['PORTNAME'])}.git"
    if not repo:
        return dict(port=name, status='skip', note='no GH_ACCOUNT and no repo override')
    try:
        tag = v.get('GH_TAGNAME', '')
        if HEX40.match(tag):
            ref = f"refs/heads/{ov['branch']}" if 'branch' in ov else 'HEAD'
            rows = ls_remote(repo, ref)
            if not rows:
                return dict(port=name, status='error', note=f'{ref} not found')
            head = rows[0][0]
            return dict(port=name, status='ok' if head == tag else 'outdated',
                        current=tag[:12], latest=head[:12], kind='commit')
        cur = v.get('DISTVERSION') or v.get('PORTVERSION', '')
        prefix = ov.get('tag_prefix', v.get('DISTVERSIONPREFIX', ''))
        best = None
        for _, ref in ls_remote('--tags', '--refs', repo):
            t = ref.removeprefix('refs/tags/')
            if PRE.search(t) or not t.startswith(prefix):
                continue
            ver = t[len(prefix):].lstrip('vV') if not prefix else t[len(prefix):]
            if vtuple(ver) and (best is None or vtuple(ver) > vtuple(best)):
                best = ver
        if best is None:
            return dict(port=name, status='error', note='no stable tags found')
        return dict(port=name, status='outdated' if vtuple(best) > vtuple(cur) else 'ok',
                    current=cur, latest=best, kind='tag')
    except Exception as e:
        return dict(port=name, status='error', note=str(e))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--json'); ap.add_argument('--markdown')
    a = ap.parse_args()
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    overrides = json.load(open(os.path.join(root, 'scripts', 'update-check.json')))
    res = [check(d, overrides) for d in sorted(glob.glob(os.path.join(root, 'ports', '*', '*')))
           if os.path.isfile(os.path.join(d, 'Makefile'))]
    out = [r for r in res if r['status'] == 'outdated']
    md = ['## Upstream updates', '']
    if out:
        md += ['| Port | Current | Upstream | Type |', '|---|---|---|---|']
        md += [f"| {r['port']} | `{r['current']}` | `{r['latest']}` | {r['kind']} |" for r in out]
    else:
        md.append('All ports are up to date.')
    other = [r for r in res if r['status'] in ('error', 'skip')]
    if other:
        md += ['', '### Not checked', '']
        md += [f"- {r['port']}: {r['status']} - {r.get('note', '')}" for r in other]
    text = '\n'.join(md) + '\n'
    print(text)
    if a.json: json.dump(res, open(a.json, 'w'), indent=2)
    if a.markdown: open(a.markdown, 'w').write(text)
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
            f.write(f"count={len(out)}\npackages={' '.join(r['port'] for r in out)}\n")


if __name__ == '__main__':
    main()
