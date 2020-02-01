import os
import sys
import subprocess


def get_system():
    system = sys.platform
    if system.lower().startswith("java"):
        import java.lang.System

        system = java.lang.System.getProperty("os.name").lower()
    if system.startswith("linux"):
        system = "linux"
    elif system.startswith("win"):
        system = "windows"
    elif system.startswith("mac"):
        system = "darwin"
    return system


def rename_PSIutil():
    path = os.path.dirname(os.path.abspath(__file__))

    psipath = os.path.join(path, "psi")
    for f_in in os.listdir(psipath):
        if f_in[-2:] == ".d" or f_in[-3:] == ".sh":
            f = open(os.path.join(psipath, f_in), "r")

            filedata = f.read()
            f.close()

            filedata = filedata.replace(" util", " dutil")
            filedata = filedata.replace(" util;", " dutil;")
            filedata = filedata.replace(",util;", ",dutil;")
            filedata = filedata.replace("||util", "||dutil")
            filedata = filedata.replace("=util", "=dutil")
            filedata = filedata.replace("(util", "(dutil")
            filedata = filedata.replace("!util", "!dutil")
            filedata = filedata.replace(">util", ">dutil")
            filedata = filedata.replace("&util", "&dutil")
            filedata = filedata.replace("\nutil", "\ndutil")

            f = open(os.path.join(psipath, f_in), "w")
            f.write(filedata)
            f.close()

            f = open(os.path.join(psipath, f_in), "r")
            for line in f:
                if "util" in line and not "dutil" in line:
                    print(line)
            filedata = f.read()
            f.close()

            if f_in == "util.d":
                os.rename(
                    os.path.join(psipath, "util.d"), os.path.join(psipath, "dutil.d")
                )
                subprocess.call(["chmod", "+x", os.path.join(psipath, "dutil.d")])
            else:
                subprocess.call(["chmod", "+x", os.path.join(psipath, f_in)])


def build_psi():
    if get_system() == "windows":
        print("The PSI library is not yet available for Windows.")
        return

    path = os.path.dirname(os.path.abspath(__file__))

    lib_dir = os.path.abspath(os.path.join(path, os.uname()[0].lower()))
    lib_name = os.path.join(lib_dir, "libpsi")

    subprocess.call(
        "dmd -O -release -inline -boundscheck=off -J./library *.d -fPIC -lib -of={lib_name}".format(
            lib_name=lib_name
        ),
        shell=True,
        cwd=os.path.join(path, "psi"),
    )


if __name__ == "__main__":
    rename_PSIutil()
    build_psi()
