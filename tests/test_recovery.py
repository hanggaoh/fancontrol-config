import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RecoveryTests(unittest.TestCase):
    def test_mapping_and_idempotence(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'fancontrol'
            config.write_text((ROOT / 'fancontrol.conf').read_text().replace('hwmon3', 'hwmon999'))
            command = ['bash', str(ROOT / 'update-hwmon-path.sh'), str(config)]
            subprocess.run(command, check=True, capture_output=True)
            first = config.read_bytes()
            self.assertNotIn(b'hwmon999', first)
            subprocess.run(command, check=True, capture_output=True)
            self.assertEqual(first, config.read_bytes())

    def test_wrong_physical_device_is_rejected_without_edit(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'fancontrol'
            config.write_text((ROOT / 'fancontrol.conf').read_text().replace('nct6775.656', 'wrong-device'))
            original = config.read_bytes()
            result = subprocess.run(['bash', str(ROOT / 'update-hwmon-path.sh'), str(config)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(original, config.read_bytes())

    def test_sleep_actions_and_disabled_service(self):
        with tempfile.TemporaryDirectory() as directory:
            mock = Path(directory) / 'systemctl'
            mock.write_text('#!/bin/bash\nprintf "%s\\n" "$*" >> "$CALL_LOG"\n'
                            'if [[ "$1" == is-enabled ]]; then exit "${DISABLED:-0}"; fi\n')
            mock.chmod(0o755)
            log = Path(directory) / 'calls'
            env = dict(os.environ, PATH=directory + ':' + os.environ['PATH'], CALL_LOG=str(log))
            for action, expected in [('pre', 'stop fancontrol.service'),
                                     ('post', '--no-block restart fancontrol.service')]:
                log.write_text('')
                subprocess.run(['bash', str(ROOT / 'fancontrol-sleep'), action], env=env, check=True)
                self.assertEqual(log.read_text().splitlines(), ['is-enabled --quiet fancontrol.service', expected])
                log.write_text('')
                subprocess.run(['bash', str(ROOT / 'fancontrol-sleep'), action], env=dict(env, DISABLED='1'), check=True)
                self.assertEqual(log.read_text().splitlines(), ['is-enabled --quiet fancontrol.service'])


if __name__ == '__main__':
    unittest.main()
