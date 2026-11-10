#!/usr/bin/env python3
"""Offline, read-only intake check for a sibling Ekole content-pack/0.1.

This is a bounded source inspection to prepare owner discussion. It is NOT a
Moodle adapter, authorization, simulation of Moodle changes, or apply command.
No network, subprocess, external service, database, or file mutation is used.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

MAX_MANIFEST = 1_048_576
MAX_COURSE = 1_048_576
ID = re.compile(r'[A-Za-z0-9_-]{1,80}\Z')


class IntakeRefusal(ValueError):
    pass


def _object_pairs(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise IntakeRefusal('Duplicate JSON key: ' + key)
        result[key] = value
    return result


def _read_json(path: Path, root: Path, limit: int) -> tuple[dict, bytes]:
    if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root.resolve()):
        raise IntakeRefusal('Invalid or outside-root file: ' + str(path))
    if not 1 <= path.stat().st_size <= limit:
        raise IntakeRefusal('File size outside permitted range: ' + path.name)
    raw = path.read_bytes()
    try:
        data = json.loads(raw.decode('utf-8-sig'), object_pairs_hook=_object_pairs,
                          parse_constant=lambda x: (_ for _ in ()).throw(IntakeRefusal('Non-finite JSON')))
    except (UnicodeError, json.JSONDecodeError) as e:
        raise IntakeRefusal('Invalid UTF-8 JSON') from e
    if type(data) is not dict:
        raise IntakeRefusal('Expected JSON object')
    return data, raw


def inspect(root: Path) -> dict:
    root = Path(root).expanduser()
    if root.is_symlink() or not root.is_dir():
        raise IntakeRefusal('A regular, existing content directory is required')
    manifest, raw = _read_json(root / 'pack.json', root, MAX_MANIFEST)
    if manifest.get('format') != 'ekole.content-pack/0.1':
        raise IntakeRefusal('Unsupported Ekole content-pack version')
    if not isinstance(manifest.get('id'), str) or not ID.fullmatch(manifest['id']):
        raise IntakeRefusal('Invalid content pack identity')
    if not isinstance(manifest.get('nom'), str) or not manifest['nom'].strip():
        raise IntakeRefusal('Missing content pack name')
    courses = manifest.get('cours')
    paths = manifest.get('parcours')
    if type(courses) is not list or type(paths) is not list or len(courses) > 2000 or len(paths) > 2000:
        raise IntakeRefusal('Invalid or unbounded courses/pathways')
    refs=set(); course_hashes=[]
    for item in courses:
        if type(item) is not dict:
            raise IntakeRefusal('Invalid course descriptor')
        cid=item.get('id')
        if not isinstance(cid,str) or not ID.fullmatch(cid) or cid in refs:
            raise IntakeRefusal('Duplicate/invalid course identifier')
        refs.add(cid)
        if item.get('fichier') != 'cours/' + cid + '.json':
            raise IntakeRefusal('Course path must be owner-local and deterministic')
        course, course_raw = _read_json(root/'cours'/(cid+'.json'),root,MAX_COURSE)
        if course.get('id') != cid:
            raise IntakeRefusal('Course identity mismatch')
        prereqs=item.get('prerequis',[])
        if type(prereqs) is not list or any(not isinstance(p,str) or not ID.fullmatch(p) for p in prereqs):
            raise IntakeRefusal('Invalid prerequisites')
        course_hashes.append({'course_id':cid,'sha256':hashlib.sha256(course_raw).hexdigest()})
    if any(not set(item.get('prerequis',[])).issubset(refs) for item in courses):
        raise IntakeRefusal('Unrecognized course prerequisite')
    seen_paths=set()
    for path in paths:
        if type(path) is not dict or not isinstance(path.get('id'),str) or not ID.fullmatch(path['id']) or path['id'] in seen_paths:
            raise IntakeRefusal('Invalid pathway identifier')
        seen_paths.add(path['id'])
        links=path.get('cours_ids')
        if type(links) is not list or any(not isinstance(link,str) or link not in refs for link in links):
            raise IntakeRefusal('Invalid pathway references')
    # Only opaque references/hashes are returned. No course text, learner identity,
    # teacher token or media bytes are placed in the report.
    return {'format':'uckk.ekole-pack-inspection/0.1', 'mode':'read_only_source_inspection',
            'source_format':'ekole.content-pack/0.1', 'source_id':manifest['id'],
            'pack_sha256':hashlib.sha256(raw).hexdigest(), 'course_count':len(refs),
            'pathway_count':len(seen_paths), 'course_hashes':course_hashes,
            'institutional_review_required':True, 'course_mapping_verified':False,
            'moodle_write_permitted':False, 'moodle_applied':False,
            'real_students_involved':False,
            'note':'Not a Moodle diff/plan/confirmation/authorization or a published-content release'}


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('content_directory',type=Path,help='Extracted independent Ekole content pack root')
    args=parser.parse_args(argv)
    try:
        result=inspect(args.content_directory)
    except (OSError, IntakeRefusal, ValueError, TypeError) as exc:
        print('[REFUSED]',str(exc),file=sys.stderr)
        return 2
    print(json.dumps(result,ensure_ascii=False,indent=2,sort_keys=True))
    return 0


if __name__=='__main__':
    raise SystemExit(main())
