# The psipy package
The `psipy` python package wraps around the [PSI-Solver](http://psisolver.org/) and allows you to to access its functionality in python.

### Preliminary requirements ###
1. Install the [pyd package](https://github.com/ariovistus/pyd). Clone the repo, cd into it and type `python setup.py install`
2. Install the dmd comiler from here: [DMD compiler](https://dlang.org/download.html#dmd)

### Installation (tested on Ubuntu 16.04) ###


1. Clone now the psipy repo to your designated directory (first command from below)
```
git clone --recursive https://github.com/ML-KULeuven/psipy.git
```
2. Built the PSI-Solver:
```
cd psipy
python psipy/build_psi.py
```
3. Build the python library for the PSI-Solver:
```
python setup.py install
```
4. Copy paste the final print-out line of this command (starts with export) into your .bashrc. This will add the path to the psipy library to the PYTHONPATH.

### Test ###
```
python
> import psipy
> a = psipy.S("3")
> b = psipy.S("2")
> c = psipy.add(a,b)
```
`c` should now return `5`.
