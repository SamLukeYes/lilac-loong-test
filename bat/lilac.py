from types import SimpleNamespace

from lilaclib import *

g = SimpleNamespace()

def pre_build():
    g.files = download_official_pkgbuild('bat')
    add_into_array('arch', ['loong64'])
    for line in edit_file('PKGBUILD'):
        if line.lstrip().startswith('cargo fetch --locked'):
            line = line.replace(
                'cargo fetch --locked', 'cargo update'
            )
        print(line)

def post_build():
    git_add_files(g.files)
    git_commit()