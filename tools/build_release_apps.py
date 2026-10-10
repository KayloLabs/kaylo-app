#!/usr/bin/env python3
"""Build Kaylo release APKs sequentially after checking disk and memory.

Run from any directory: python3 tools/build_release_apps.py [partner|customer|both]
Additional Flutter build arguments follow --, for example --dart-define-from-file.
No credentials, local.properties or build output is committed by this script.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
GIB = 1024 ** 3
MIN_DISK = 6 * GIB
MIN_RAM = 6 * GIB


def total_memory():
    if sys.platform == 'darwin':
        return int(subprocess.check_output(['sysctl', '-n', 'hw.memsize']))
    if hasattr(os, 'sysconf'):
        return os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES')
    return None


def check_resources(path):
    free = shutil.disk_usage(path).free
    if free < MIN_DISK:
        raise RuntimeError(f'Release build stopped: {free / GIB:.1f} GiB free; at least 6 GiB is required. Free disk space and rerun. Nothing was deleted.')
    memory = total_memory()
    if memory is not None and memory < MIN_RAM:
        raise RuntimeError(f'Release build stopped: {memory / GIB:.1f} GiB RAM; at least 6 GiB is required.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', choices=['partner', 'customer', 'both'], nargs='?', default='both')
    parser.add_argument('--check-only', action='store_true')
    args, extra = parser.parse_known_args()
    if extra and extra[0] == '--':
        extra = extra[1:]
    flutter = shutil.which('flutter')
    if not flutter:
        parser.error('Flutter is not on PATH.')
    try:
        check_resources(ROOT)
        if args.check_only:
            print('Disk and memory checks passed.')
            return 0
        env = dict(os.environ)
        # Applied to both apps without modifying developer Gradle properties.
        env['GRADLE_OPTS'] = ' '.join([
            env.get('GRADLE_OPTS', ''),
            '-Dorg.gradle.workers.max=1', '-Dorg.gradle.parallel=false',
            '-Dorg.gradle.jvmargs="-Xmx2G -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m"',
            '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process',
        ])
        apps = ['partner', 'customer'] if args.app == 'both' else [args.app]
        for app in apps:
            check_resources(ROOT)
            subprocess.run([flutter, 'build', 'apk', '--release', '--no-pub', *extra],
                           cwd=ROOT / 'apps' / app, env=env, check=True)
            source = ROOT / 'apps' / app / 'build/app/outputs/flutter-apk/app-release.apk'
            destination = ROOT / 'build/releases' / f'kaylo-{app}-release.apk'
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
            print(f'Release APK: {destination}')
        return 0
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
