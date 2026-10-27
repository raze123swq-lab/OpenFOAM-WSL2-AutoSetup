import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('benchmark', ROOT / 'scripts/linux/benchmark.py')
benchmark = importlib.util.module_from_spec(spec)
spec.loader.exec_module(benchmark)


class BenchmarkTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / 'tutorial'
        self.source.mkdir()
        self.root = self.base / 'runs'
        self.calls = []

    def runner(self, command, case, log):
        self.calls.append(command)
        if command == 'blockMesh':
            mesh = case / 'constant/polyMesh'
            mesh.mkdir(parents=True)
            for name in ('points', 'faces', 'owner', 'neighbour', 'boundary'):
                (mesh / name).write_text('fixture mesh')
            log.write(b'End\n')
        elif command == 'checkMesh':
            log.write(b'Mesh OK.\n')
        else:
            final = case / '285'
            final.mkdir()
            for field in ('U', 'p'):
                (final / field).write_text('fixture field')
            log.write(b'sigFpe: Enabling floating point exception trapping\nSIMPLE solution converged in 285 iterations\nEnd\n')
        return 0

    def test_repeat_skips_solver_only_with_valid_hashes(self):
        first = benchmark.run_benchmark(self.root, self.source, self.runner)
        second = benchmark.run_benchmark(self.root, self.source, self.runner)
        self.assertEqual(first['case'], second['case'])
        self.assertTrue(second['reused'])
        self.assertEqual(len(self.calls), 3)

    def test_failure_stops_and_recovers_in_new_attempt(self):
        def fail(command, case, log):
            self.calls.append(command)
            log.write(b'failure\n')
            return 17
        with self.assertRaisesRegex(RuntimeError, 'blockMesh failed'):
            benchmark.run_benchmark(self.root, self.source, fail)
        failed = list(self.root.glob('attempt-*'))[0]
        self.assertEqual(self.calls, ['blockMesh'])
        result = benchmark.run_benchmark(self.root, self.source, self.runner)
        self.assertTrue((failed / 'failure.txt').exists())
        self.assertNotEqual(Path(result['case']).parent, failed)

    def test_checkmesh_quality_failure_blocks_solver(self):
        def bad_mesh(command, case, log):
            if command == 'checkMesh':
                self.calls.append(command)
                log.write(b'Failed 1 mesh checks\n')
                return 0
            return self.runner(command, case, log)
        with self.assertRaisesRegex(RuntimeError, 'quality'):
            benchmark.run_benchmark(self.root, self.source, bad_mesh)
        self.assertNotIn('foamRun', self.calls)

    def test_changed_results_not_reused_or_overwritten(self):
        first = benchmark.run_benchmark(self.root, self.source, self.runner)
        field = Path(first['case']) / '285/U'
        field.write_text('modified')
        second = benchmark.run_benchmark(self.root, self.source, self.runner)
        self.assertNotEqual(first['case'], second['case'])
        self.assertEqual(field.read_text(), 'modified')

    def test_unowned_directory_is_refused(self):
        self.root.mkdir()
        with self.assertRaisesRegex(RuntimeError, 'unowned'):
            benchmark.run_benchmark(self.root, self.source, self.runner)

    def test_latest_time_numeric_and_nonfinite(self):
        for name in ('9', '10', 'nan', 'inf', 'constant'):
            (self.source / name).mkdir()
        self.assertEqual(benchmark.latest_time(self.source).name, '10')

    def test_missing_field_rejected(self):
        result = benchmark.run_benchmark(self.root, self.source, self.runner)
        (Path(result['case']) / '285/p').unlink()
        with self.assertRaisesRegex(RuntimeError, 'Missing final field'):
            benchmark.validate(result['case'])

    def test_corrupt_checkpoint_preserved_and_recovered(self):
        first = benchmark.run_benchmark(self.root, self.source, self.runner)
        record = Path(first['case']).parent / 'success.json'
        record.write_text('{broken')
        second = benchmark.run_benchmark(self.root, self.source, self.runner)
        self.assertNotEqual(first['case'], second['case'])
        self.assertEqual(record.read_text(), '{broken')


if __name__ == '__main__':
    unittest.main()
