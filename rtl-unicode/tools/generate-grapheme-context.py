#!/usr/bin/env python3
# Copyright (c) 2026 Kevin Collins.
# SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
"""Generate the orthogonal Unicode 17 grapheme properties from pinned inputs."""
from pathlib import Path
import zipfile


def ranges(text, property_name, value=None):
    result = []
    for line in text.splitlines():
        fields = [part.strip() for part in line.split('#', 1)[0].split(';')]
        if len(fields) < 2 or fields[1] != property_name:
            continue
        if value is not None and (len(fields) < 3 or fields[2] != value):
            continue
        bounds = fields[0].split('..')
        first, last = int(bounds[0], 16), int(bounds[-1], 16)
        if result and first == result[-1][1] + 1:
            result[-1] = (result[-1][0], last)
        else:
            result.append((first, last))
    return result


def emit_ranges(items, result):
    values = [f'${first:X}' if first == last else f'${first:X}..${last:X}'
              for first, last in items]
    return ['    ' + value + (',' if index < len(values) - 1 else ':')
            for index, value in enumerate(values)] + ['      Result := ' + result + ';']


def main():
    package = Path(__file__).resolve().parent.parent
    with zipfile.ZipFile(package / 'tests/data/Unicode17.zip') as archive:
        emoji = archive.read('emoji-data.txt').decode('utf-8')
        derived = archive.read('DerivedCoreProperties.txt').decode('utf-8')
    lines = [
        '{ Generated from Unicode 17.0.0 emoji-data.txt and DerivedCoreProperties.txt.',
        '  Copyright Unicode, Inc. Unicode-3.0; original notices and inputs are',
        '  preserved in tests/data/Unicode17.zip. See root ATTRIBUTIONS.md.',
        '  Regenerate with tools/generate-grapheme-context.py. }', '',
        'function IsExtendedPictographic(ACodePoint: UCS4Char): Boolean;',
        'begin', '  case ACodePoint of']
    lines += emit_ranges(ranges(emoji, 'Extended_Pictographic'), 'True')
    lines += ['  else Result := False;', '  end;', 'end;', '',
              'function GetIndicConjunctBreak(ACodePoint: UCS4Char): TIndicConjunctBreak;',
              'begin', '  case ACodePoint of']
    for value in ['Consonant', 'Extend', 'Linker']:
        lines += emit_ranges(ranges(derived, 'InCB', value), 'icb' + value)
    lines += ['  else Result := icbNone;', '  end;', 'end;', '']
    (package / 'src/inc/graphemecontext_code.inc').write_text('\n'.join(lines))


if __name__ == '__main__':
    main()
