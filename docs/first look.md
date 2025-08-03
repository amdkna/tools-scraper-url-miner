
## 1 · High-Level Architecture

| Stage                  | Responsibility                                             | Key Modules         | Extensible Via                                 |
| ---------------------- | ---------------------------------------------------------- | ------------------- | ---------------------------------------------- |
| **Input**              | Read a source (URL, local HTML/text, or DB record)         | `input/` package    | New *Loader* subclasses                        |
| **Extraction**         | Parse HTML / text and collect raw links                    | `extract/` package  | Swappable parsers (BeautifulSoup, lxml, regex) |
| **Filter & Cleanse**   | Deduplicate, whitelist/blacklist, normalize                | `filter/` package   | User-defined rule plugins                      |
| **Output**             | Persist results (file or DB)                               | `output/` package   | Writer plugins (CSV, JSON, MySQL, …)           |
| **Core Orchestration** | Glue the steps together, expose **CLI** and **Python API** | `core.py`, `cli.py` | Pipelines / hooks                              |

All layers share **common utilities** (`logger.py`, `exceptions.py`, `config.py`) and follow the protocols you supplied.

---

## 2 · Repository Layout

```
url-miner/
├── src/
│   └── url_miner/
│       ├── __init__.py
│       ├── cli.py              # Click/Typer CLI entry-point
│       ├── core.py             # High-level pipeline
│       ├── config.py           # INI/YAML/JSON loader (pydantic)
│       ├── logger.py           # Central logging per Logging Protocol
│       ├── exceptions.py       # Custom errors per Error-Handling Protocol
│       ├── input/
│       │   ├── base.py         # AbstractLoader
│       │   ├── url_loader.py
│       │   ├── file_loader.py
│       │   └── db_loader.py
│       ├── extract/
│       │   ├── base.py         # AbstractExtractor
│       │   ├── html_extractor.py
│       │   └── text_extractor.py
│       ├── filter/
│       │   ├── rules.py        # Built-in filters (domains, schemes…)
│       │   └── plugin_loader.py
│       ├── output/
│       │   ├── base.py         # AbstractWriter
│       │   ├── file_writer.py
│       │   └── db_writer.py
│       └── utils.py
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/
│   ├── architecture.md
│   ├── usage.md
│   ├── protocols/              # Copies of the seven protocols for traceability
│   └── diagrams/
├── config/
│   ├── default.yml
│   └── logging.ini
├── examples/
│   ├── sample_input.html
│   └── demo_config.yml
├── scripts/                     # Dev & ops helpers
├── .pre-commit-config.yaml
├── pyproject.toml               # Black, isort, mypy, pytest, build
├── README.md                    # Conforms to README-Standards-Guide
└── LICENSE
```

### Why this mirrors the protocols

* **Python Coding Protocol** – `src/` layout, type-hints, Black/isort, `pyproject.toml`.
* **Logging Protocol** – single `logger.py`, INI config under `config/logging.ini`.
* **Error-Handling Protocol** – all custom exceptions inherit `AppError` in `exceptions.py`.
* **Testing Protocol** – `tests/` pyramid with pytest & coverage gates.
* **Document-Writing Protocol** – every markdown file starts with emoji, version, location.
* **README & Template Guides** – README.md following badge/emoji/TOC rules.

---

## 3 · Configuration Strategy

* **One declarative file per run** (any of INI / YAML / JSON).
* Parsed by **pydantic-based `Config` class** for validation + environment overrides.

```yaml
# demo_config.yml
run_name: example-scan
input:
  kind: url           # url | file | db
  source: https://example.com
extract:
  html_parser: "lxml" # or "bs4"
filter:
  allow_schemes: [http, https]
  deny_domains: [facebook.com, twitter.com]
output:
  kind: csv           # csv | json | txt | mysql | sqlite | mongo | pg
  destination: out/urls-{{run_name}}.csv
logging:
  level: INFO
```

The same schema can be represented in **INI** sections or **JSON** keys; `config.py` picks parser by file extension.

---

## 4 · Modularity & Customization Hooks

| Extension Point | Mechanism                                                           | Example Use                    |
| --------------- | ------------------------------------------------------------------- | ------------------------------ |
| *Loader*        | Register subclass of `AbstractLoader`                               | New S3-log loader              |
| *Extractor*     | Strategy pattern in `extract/`                                      | Regex-only extractor for speed |
| *Filter Rule*   | `filter.plugin_loader` discovers entry points (`url_miner.filters`) | Geo-IP blocklist               |
| *Writer*        | Subclass of `AbstractWriter`                                        | Kafka topic producer           |

Users enable plugins via **config file** or **CLI flag** (e.g., `--writer kafka.Writer`).

---

## 5 · Implementation Roadmap (Steps)

1. **Bootstrap repo**

   ```bash
   gh repo create url-miner --template python
   poetry init        # or pip + pyproject.toml
   pre-commit install
   ```

2. **Core skeleton**

   * Add `cli.py` with sub-commands: `run`, `config init`, `version`.
   * Implement `Config` class + validation.

3. **Logging & Error baseline**

   * Drop in `logger.py`, `exceptions.py`; wire them in `core.py`.

4. **Input loaders** (iterate)

   * URL HTTP fetch (requests/httpx)
   * Local file (pathlib)
   * DB cursor loader (for BLOB/CLOB fields)

5. **Extractors**

   * HTML → BeautifulSoup or lxml.
   * Plain text → regex (`r"https?://\S+"`).

6. **Filter engine**

   * Dedup set, urllib.parse normalization, rule chain.

7. **Output writers**

   * CSV/JSON/TXT via pandas / stdlib.
   * SQLAlchemy layer for MySQL/SQLite/PostgreSQL.
   * PyMongo for MongoDB.

8. **Testing harness**

   * Unit tests per module, mock network I/O.
   * Integration tests with Dockerised databases.
   * e2e test hitting a static HTML fixture.

9. **Documentation**

   * Fill `docs/architecture.md` with sequence diagram.
   * Author user guide in `docs/usage.md`.
   * Generate API docs with `pdoc` or `Sphinx`.

10. **Release workflow**

    * GitHub Actions: lint → type-check → tests → build wheel.
    * Version & changelog automation (`semantic-release`).

---

## 6 · Sample User Journeys

### CLI quick run

```bash
url-miner run --config config/demo_config.yml
```

Produces `out/urls-example-scan.csv` and `logs/run.log`.

### Embedded in another program

```python
from url_miner import Pipeline, Config

cfg = Config.from_file("myjob.json")
urls = Pipeline(cfg).run()
```

---

## 7 · Next Actions for You

1. **Review** this layout—does it match the breadth you need?
2. **Confirm** preferred package manager (`poetry`, `pip-tools`, …).
3. **Prioritise** first “happy-path” (e.g., URL → CSV) before widening plugin set.

Once you give the green light, we can flesh out concrete code modules following the same protocol-driven standards.
