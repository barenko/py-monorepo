Write-Host "`n+-------------------------------------------------------------------+"
Write-Host "    Pytest"
Write-Host "+-------------------------------------------------------------------+"

py -m poetry run pytest -s -x --cov=fast_zero -vv
