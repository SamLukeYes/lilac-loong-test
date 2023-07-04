from types import SimpleNamespace

from lilaclib import *

g = SimpleNamespace()

def pre_build():
    g.files = download_official_pkgbuild('bat')
    add_into_array('arch', ['loong64'])

def post_build():
    git_add_files(g.files)
    git_commit()