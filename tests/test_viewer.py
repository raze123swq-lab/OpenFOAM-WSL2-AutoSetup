import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('viewer', Path(__file__).resolve().parents[1] / 'scripts/linux/launch-viewer.py')
viewer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(viewer)


class ViewerTests(unittest.TestCase):
    def test_same_case_detected_and_unrelated_process_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            case = root / 'case'
            case.mkdir()
            proc = root / '123'
            proc.mkdir()
            (proc / 'cmdline').write_bytes(b'/usr/bin/paraview\0--script=view.py\0')
            (proc / 'cwd').symlink_to(case, target_is_directory=True)
            pid, unknown = viewer.find_existing(case, root)
            self.assertEqual(pid, '123')
            (proc / 'cmdline').write_bytes(b'/usr/bin/python3\0paraview\0')
            self.assertEqual(viewer.find_existing(case, root), (None, []))

    def test_unknown_case_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            proc = root / '456'
            proc.mkdir()
            (proc / 'cmdline').write_bytes(b'paraview\0')
            (proc / 'cwd').symlink_to(root, target_is_directory=True)
            self.assertEqual(viewer.find_existing(root / 'other', root), (None, ['456']))


if __name__ == '__main__':
    unittest.main()
