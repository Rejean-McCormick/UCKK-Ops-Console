"""Independent read-only intake tests; no PowerShell, Moodle or SSH required."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from inspect_ekole_pack import inspect, IntakeRefusal


class IntakeTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        (self.root/'cours').mkdir()
        self.manifest={'format':'ekole.content-pack/0.1','id':'fake-curriculum','nom':'Synthetic fixture',
                       'cours':[{'id':'fake-001','titre':'Demo','fichier':'cours/fake-001.json','prerequis':[]}],
                       'parcours':[{'id':'demo','titre':'Demo','cours_ids':['fake-001']}]}
        (self.root/'cours/fake-001.json').write_text(json.dumps({'id':'fake-001','modules':[{'texte':'PRIVATE COURSE TEST'}]}),encoding='utf8')
        self.save()

    def save(self):
        (self.root/'pack.json').write_text(json.dumps(self.manifest),encoding='utf8')

    def test_valid_input_never_implies_moodle_authority(self):
        result=inspect(self.root)
        self.assertEqual(result['course_count'],1)
        self.assertTrue(result['institutional_review_required'])
        self.assertFalse(result['moodle_write_permitted'])
        self.assertFalse(result['moodle_applied'])
        self.assertNotIn('PRIVATE COURSE TEST',json.dumps(result))

    def test_path_traversal_denied(self):
        self.manifest['cours'][0]['fichier']='../secret'
        self.save()
        with self.assertRaises(IntakeRefusal): inspect(self.root)

    def test_missing_course_denied(self):
        (self.root/'cours/fake-001.json').unlink()
        with self.assertRaises(IntakeRefusal): inspect(self.root)

    def test_duplicate_json_key_denied(self):
        (self.root/'pack.json').write_text('{"format":"ekole.content-pack/0.1","format":"evil"}')
        with self.assertRaises(IntakeRefusal):inspect(self.root)

    def test_unapproved_symlink_denied(self):
        original=self.root/'cours/fake-001.json'
        original.rename(self.root/'elsewhere.json')
        try:original.symlink_to(self.root/'elsewhere.json')
        except OSError:self.skipTest('No symlink privilege')
        with self.assertRaises(IntakeRefusal): inspect(self.root)

    def test_course_and_pathway_identity_denied(self):
        self.manifest['parcours'][0]['cours_ids']=['unknown'];self.save()
        with self.assertRaises(IntakeRefusal):inspect(self.root)
        self.manifest['parcours'][0]['cours_ids']=['fake-001']
        self.manifest['cours'][0]['prerequis']=['unknown'];self.save()
        with self.assertRaises(IntakeRefusal):inspect(self.root)


if __name__=='__main__':unittest.main()
