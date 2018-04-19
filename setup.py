from __future__ import print_function

import os
import sys

from pyd.support import setup, Extension
import distutils

def get_system():
    system = sys.platform
    if system.lower().startswith('java'):
        import java.lang.System
        system = java.lang.System.getProperty('os.name').lower()
    if system.startswith('linux'):
        system = 'linux'
    elif system.startswith('win'):
        system = 'windows'
    elif system.startswith('mac'):
        system = 'darwin'
    return system


def get_lib_build_dir():
    path = os.path.dirname(os.path.abspath(__file__))
    libDir = os.path.join(path, 'build', 'lib.%s-%s' % (distutils.util.get_platform(),'.'.join(str(v) for v in sys.version_info[:2])))
    return libDir

def build_psipy(force=False):
    if get_system() == 'windows':
        print('The psipy library is not yet available for Windows.')
        return

    system = get_system()
    python = 'python{}'.format(sys.version_info[0])
    root_path = os.path.dirname(os.path.realpath(__file__))


    lib_dir = os.path.abspath(os.path.join(root_path, 'psipy', system))

    lib_build_dir = get_lib_build_dir()
    filename = os.path.join(lib_build_dir, 'psipy.so')
    if force and os.path.exists(filename):
        os.remove(filename)

    psipy_module = Extension(
        'psipy',
        sources=['psipy/psipy.d'],
        build_deimos=True,
        d_lump=True,
        include_dirs=['psipy/psi'],
        library_dirs=[lib_dir],
        libraries=['psi'],
    )

    setup(
        name='psipy',
        version='0.1',
        author='Pedro Zuidberg Dos Martires',
        ext_modules = [psipy_module],
        description='python wrapper for PSI',
        script_args=['build', "--compiler=dmd", "--build-lib={}".format(lib_build_dir)],
        packages=['psipy']
    )



if __name__ == '__main__':
    build_psipy(force=True)
    print("\n")
    print("psipy library is now available")
    print("\n")
    print('''Add the folowing line to your .bashrc script:\nexport "PYTHONPATH={}:${{{}}}"'''.format(get_lib_build_dir(), "PYTHONPATH"))
