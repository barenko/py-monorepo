py -m venv .venv --prompt pkg_a

.\.venv\Scripts\activate

pip install -r (Join-Path (git rev-parse --show-toplevel) "pip-requirements.txt")

pip install -r (Join-Path (git rev-parse --show-toplevel) "pip-dev-requirements.txt") -r requirements.txt

pyright .