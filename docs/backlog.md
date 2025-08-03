Below is a **coding-first product backlog** for **URL Miner**.
It walks through every file in the repo, one at a time, in the order that will minimise re-work and let you ship usable slices quickly.
Each item lists → *goal · key work · tests/docs · definition of done (DoD)*.

---

### 0 · Bootstrap & Tooling (Sprint 0)

1. **`pyproject.toml`**
   *Goal* – pin runtime + dev deps (`typer[all]`, `pydantic`, `httpx`, `beautifulsoup4`, `lxml`, `sqlalchemy`, `pymongo`, `pytest`, `mypy`, `black`, `isort`).
   *Work* – create file, set package name/entry-points, add `[tool.black]`, `[tool.isort]`, `[tool.mypy]`.
   *Tests/Docs* – none yet.
   *DoD* – `poetry install` / `pip install -e .` succeeds; `python -m url_miner --help` still empty but runs.

2. **`.pre-commit-config.yaml`**
   *Work* – hooks for black, isort, flake8, mypy, trailing-whitespace, end-of-file-fixer.
   *DoD* – `pre-commit run --all-files` passes on the empty repo.

3. **GitHub Action `ci.yml`** (optional now; required before first release)
   Runs: lint → type-check → test.

---

### 1 · Foundations (Sprint 1)

4. **`src/url_miner/logger.py`** – *single source of truth*
   *Work* – factory that (a) reads `config/logging.ini` if present else sane defaults, (b) exposes `get_logger(name)`.
   *Tests* – unit: logger returns same instance, honours level.
   *DoD* – `logger = get_logger(__name__)` works across modules.

5. **`config/logging.ini`** – default INI per Logging Protocol.
   *DoD* – picked up automatically.

6. **`src/url_miner/exceptions.py`**
   *Work* – `class AppError(Exception)`, plus `ConfigError`, `InputError`, `ExtractionError`, `OutputError`.
   *Tests* – pytest: raising & catching keeps message.
   *DoD* – type hinted, pydocstring, 100 % branch cover.

7. **`src/url_miner/utils.py`**
   *Work* – helpers: `normalize_url`, `slugify`, `timed_async` decorator.
   *Tests* – edge-case URL normalisation.
   *DoD* – utils can be imported with no side effects.

---

### 2 · Configuration subsystem (Sprint 2)

8. **`src/url_miner/config.py`**
   *Work* – `pydantic.BaseModel` + `ConfigLoader.from_path()` that accepts `.yml | .yaml | .json | .ini`.
   *Tests* – valid/invalid files; env var override.
   *DoD* – `ConfigLoader("config/default.yml").model` returns validated object.

9. **`config/default.yml`** – mirrors the pydantic schema; minimal run-able values.
   *DoD* – `url_miner run --config config/default.yml` (CLI later) won’t crash.

---

### 3 · CLI & Orchestrator skeleton (Sprint 3)

10. **`src/url_miner/__init__.py`**
    *Work* – `__version__`, export `Pipeline`.
    *DoD* – `python -c "import url_miner, sys; print(url_miner.__version__)"` prints semantic version.

11. **`src/url_miner/core.py`**
    *Work* – `class Pipeline:` with `run()` stub doing: load config → NO-OP for now → return empty list.
    *Tests* – unit: pipeline initialises with config.
    *DoD* – coverage ≥ 95 % on this file.

12. **`src/url_miner/cli.py`** (Typer)
    *Work* – commands: `run`, `config init`, `validate`.
    *Tests* – CLI runner (`typer.testing`) asserts exit code 0.
    *DoD* – `url-mine run --config config/default.yml` executes stub pipeline.

> 🎯 **Milestone A delivered:** users can invoke CLI, pipeline loads config and exits cleanly.

---

### 4 · Input layer (Sprint 4)

13. **`src/url_miner/input/base.py`**
    *Work* – `class AbstractLoader(ABC)` with `load() -> str | bytes` + async support flags.
    *Tests* – subclass dummy passes `isinstance`.
    *DoD* – 100 % abstract coverage.

14. **`src/url_miner/input/url_loader.py`**
    *Work* – sync+async HTTP fetch via `httpx`; retries, timeout, User-Agent.
    *Tests* – mock httpx `get`; asserts HTML returned.
    *DoD* – raises `InputError` on non-200.

15. **`src/url_miner/input/file_loader.py`**
    *Work* – read `.html`, `.txt`, or arbitrary file into memory.
    *Tests* – tmp file fixtures.
    *DoD* – respects encoding detected by chardet.

16. **`src/url_miner/input/db_loader.py`**
    *Work* – SQLAlchemy session loader (`sqlite://`, `mysql+pymysql://`, `postgresql://`); fetches CLOB field.
    *Tests* – sqlite in-memory DB fixture.
    *DoD* – param-driven through config.

Update **`core.Pipeline`** to call the selected loader and return raw content.

---

### 5 · Extraction layer (Sprint 5)

17. **`src/url_miner/extract/base.py`**
    *Work* – `class AbstractExtractor(ABC)` with `extract(html_or_text:str) -> list[str]`.
    *Tests* – dummy subclass.

18. **`src/url_miner/extract/html_extractor.py`**
    *Work* – BeautifulSoup/lxml parse `<a href>`; optional include `src` attrs.
    *Tests* – sample HTML fixture → list of URLs.

19. **`src/url_miner/extract/text_extractor.py`**
    *Work* – regex `https?://[^\s"'<>]+`.
    *Tests* – log snippet fixture → links.

Pipeline now: **loader → extractor**; returns raw-URL list.

---

### 6 · Filter engine (Sprint 6)

20. **`src/url_miner/filter/rules.py`**
    *Work* – built-in: dedup, scheme allowlist, domain blocklist, strip fragments, normalise trailing / .
    *Tests* – property-based test: duplicates drop, denylist works.

21. **`src/url_miner/filter/plugin_loader.py`**
    *Work* – dynamic discovery via `importlib.metadata.entry_points(group="url_miner.filters")`.
    *Tests* – plug dummy filter in test package.
    *DoD* – pipeline can receive extra callable list.

Pipeline now: **loader → extractor → filters**; returns cleaned URLs.

---

### 7 · Output layer (Sprint 7)

22. **`src/url_miner/output/base.py`**
    *Work* – `class AbstractWriter(ABC)` with `write(urls: list[str])`.
    *Tests* – dummy subclass.

23. **`src/url_miner/output/file_writer.py`**
    *Work* – write CSV, JSON, TXT (switch by path suffix or config).
    *Tests* – tmp dir, assert file contents.

24. **`src/url_miner/output/db_writer.py`**
    *Work* – SQLAlchemy upsert, or PyMongo `insert_many`.
    *Tests* – sqlite + pymongo-memory.

Update Pipeline: **loader → extractor → filters → writer**; CLI prints summary (#links, path).

> 🎯 **Milestone B delivered:** end-to-end run: URL ⇒ cleaned links ⇒ CSV.

---

### 8 · Quality Gates (continuous across sprints)

* **Unit tests:** every public function/method.
* **Integration tests:**

  * Pipeline against live httpbin.org page.
  * SQLite + HTML file.
* **E2E tests:** docker-compose (mysql, mongo) + sample HTML.
* **Coverage gate ≥ 90 %** (pytest-cov).
* **Static typing:** `mypy --strict` CI stage.
* **Docs:** update `docs/usage.md`, `docs/architecture.md` per feature.
* **Diagrams:** add sequence diagram in `docs/diagrams/pipeline.png` (draw\.io).

---

### 9 · Packaging & Release (Sprint 8)

25. **Finalize `README.md`** to match Standards Guide, add badge matrix.
26. **Versioning policy:** semantic-release or bump-my-version.
27. **Publish**: `python -m build && twine upload` to internal index / PyPI.

> 🎯 **Milestone C delivered:** first tagged release `v0.1.0`.

---

## Working Rhythm Recommended

| Day     | Action                                                                          |
| ------- | ------------------------------------------------------------------------------- |
| **Mon** | Pick next backlog item (one file), write *empty* implementation + failing test. |
| **Tue** | Fill implementation, make test pass, add docstring.                             |
| **Wed** | Run static checks, refine API, push PR for review.                              |
| **Thu** | Merge, cut incremental tag, update CHANGELOG.                                   |
| **Fri** | End-to-end test run, capture lessons, plan next file.                           |

Following this **one-file-per-PR cadence** keeps surface area small, lets CI enforce protocols immediately, and makes rollback painless.

---

### Next concrete step for you

Start **Sprint 1 / Item 4**: implement `logger.py`.
When you’re ready for the actual code, tell me **“Create logger.py”** (or whichever file) and we’ll generate that file—with unit tests—before moving to the next backlog entry.
