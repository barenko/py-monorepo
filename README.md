# Monorepo

This project is the monorepo for python.

We choose to use monorepo to simplify the team communication. A monorepo provides:

- Visibility: all team members can see and be informed about what others members are doing (using pull request approach)
- Uniformity: It is easier to share the configuration of linters, formatters, and others with one central repository
- CI/CD: One only pipeline to handle all the code, with easier maintenance and uniformity
- Atomic changes: A large change can be implemented in one PR because all libraries and dependencies are in one place

> This project uses `Living at HEAD` approach. Living at HEAD means that all code in a monorepo depends on the code that is currently in disk, as opposed to depending on released versions in the same repository.

I used the [Python Monorepo](https://www.tweag.io/blog/2023-04-04-python-monorepo-1/) blog post (mostly) to based this solution but the implementation itself was distinct in some main points.

## Project structure

This project is divided in the follow structure. This structure will be described in details.

<pre>
MONOREPO
+-- packages
    +-- package1
        | pyproject.toml
+-- services
    +-- service1
        | pyproject.toml
+-- scripts
| pip-dev-requirements.txt 
| pip-requirements.txt 
| pyproject.toml
</pre>

#### Root layer

The Root handles the common and shared dependencies and configurations. 

The `pip-requirements.txt` and `pip-dev-requirements.txt` are installed in all packages and services enforcing their versions ALWAYS.
The `pip-requirements.txt` has the common way to handle with environment variables and logs (maybe).
The `pip-dev-requirements.txt` has the choose tools to handle with code maintainability, as linter, formatters, test tools, semver, etc.

The `poetry.toml` has the monorepo configuration. The develop tooling configurations (aka. ruff) should be there.

#### Package layer

The package has the libraries of the project. A package is a standalone functionality that solve a single problem, like a helper or utils or even an implementation of a specific client or a LLM agent.

The package has their specific dependencies and configurations. These specificities are described in their `pyproject.toml` file. Their dependencies and packages needs to be described in this file. 

>Caution: All dependencies described in the root layer will ALWAYS be precedence over the dependencies described in this project. This was a chosen decision to simplify the dependency tree among the packages and services.


###### How to create a new package

A new package needs to have the follow structure:

<pre>
MONOREPO
+-- packages
    +-- my_new_package
    |   __init__.py
    |   poetry.toml
    |   pyproject.toml
    |   README.md
    |   +-- tests
</pre>

The `__init__.py` is a empty file to specify that `my_new_package` is a package (python convention). 
The `poetry.toml` has the specific poetry configuration for this project. It needs to have `POETRY_VIRTUALENVS_IN_PROJECT` set as true:

```toml
[virtualenvs]
in-project = true
```

The `pyproject.toml` has the itself package description and their own dependencies (The root dependencies not needs to be specified here, because the `deps-sync` script will do it for us).

```toml
[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.poetry]
name = "my_new_package"
version = "0.0.1"
description = "My new package"
authors = ["teapod <teapod@i.am>"]
packages = [{ include = "../my_new_package" }]

[tool.poetry.dependencies]
python = "^3.12"
```

After create these files, runs the `scripts/deps-sync` to install the shared dependencies (this script will create the .venv if it not exists yet). 

To add your own dependencies, runs the command:

```sh
py -m poetry shell
py -m poetry add <my_dependencies>
```

If you needs specify a package dependence, read about it in the "How to create a new service" session.

#### Service layer

The service has the services of the project. A service is as entrypoint that provides a functionality to a user (the user can by a human or other system). The service can be a HTTP/S server, a pubsub service, even a command line tool.

The service has their specific dependencies and configurations. These specificities are described in their `pyproject.toml` file. Their dependencies and packages needs to be described in this file. 

>Caution: All dependencies described in the root layer will ALWAYS be precedence over the dependencies described in this project. This was a chosen decision to simplify the dependency tree among the packages and services.


###### How to create a new service

A new service needs to have the follow structure:

<pre>
MONOREPO
+-- services
    +-- my_new_service
    |   __init__.py
    |   poetry.toml
    |   pyproject.toml
    |   README.md
    |   +-- tests
</pre>

The `__init__.py` is a empty file to specify that `my_new_service` is a service (python convention). 
The `poetry.toml` has the specific poetry configuration for this project. It needs to have `POETRY_VIRTUALENVS_IN_PROJECT` set as true:

```toml
[virtualenvs]
in-project = true
```

The `pyproject.toml` has the itself service description and their own dependencies (The root dependencies not needs to be specified here, because the `deps-sync` script will do it for us).

```toml
[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.poetry]
name = "my_new_service"
version = "0.1.0"
description = "My new thing"
authors = ["teapod <teapod@i.am>"]
readme = "README.md"
packages = [{ include = "../my_new_service" }]

[tool.poetry.dependencies]
python = "^3.12"
my_new_package = { path = "../../packages/my_new_package", develop = true }
python-dotenv = "1.0.1"


[tool.poetry.dependencies]
python = "^3.12"
```

If the service uses a package as dependence, it needs to be declared in dependencies using the relative path and the develop option set to true. This develop option allows that any change made in the dependency affect the service immediately (using a symlink instead of copy the files).

After create these files, runs the `scripts/deps-sync` to install the shared dependencies (this script will create the .venv if it not exists yet). 

To add your own dependencies, runs the command:

```sh
py -m poetry shell
py -m poetry add <my_dependencies>
```

###### How to run a service

In the root monorepo folder, runs: `py -m services.<service name>.<service main entrypoint file>`. Example:

    py -m services.my_new_service.main


#### Scripts layer

The `script` folder keeps all maintenance scripts needs by CI/CD and to development use.

| Scriptname | Description |
|---|---|
|*deps-sync*| Scans all packages and services and resync the project with the root `pip-requirements.txt` and `pip-dev-requirements.txt` dependencies |
|*deps-hard-cleaner*| Remove all .venv folders and `poetry.lock` files. Useful to solve some dependence issues. Avoid to use it. |

### How to config and build this project

Let's start in the project root path (path that contains the `pip-requirements.txt`) and runs the command:

    ./scripts/deps-sync

