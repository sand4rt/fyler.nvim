import os
import sys
import importlib
from pathlib import Path
from types import FunctionType


class Test:
    def __init__(self, run: FunctionType) -> None:
        self.run = run


class Runner:
    def __init__(self, test: Test) -> None:
        self.test = test

    def start(self) -> None:
        self.test.run()


if __name__ == "__main__":
    spec_dir = Path(os.getcwd()).joinpath("spec")

    sys.path.insert(0, str(spec_dir))

    for path in spec_dir.glob("*.py"):
        if path.stem == "__init__":
            continue

        module = importlib.import_module(path.stem)

        if hasattr(module, "spec"):
            Runner(module.spec(Test)).start()
