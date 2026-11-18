# Catalog data files

All files use UTF-8 and tab-separated values (TSV), with one record per line.

| File | Columns | Purpose |
|---|---|---|
| `apps.tsv` | `id`, `category_id`, `display_name` | 970 catalog entries. The display name is not a guaranteed package identifier. |
| `categories.tsv` | `category_id`, `name_es`, `name_en`, `name_ru` | Translated category labels. |
| `search-hints.tsv` | `display_name`, `query_term` | Preferred runtime search term for applications whose display name is ambiguous or differs from the likely package search name. |
| `initial-catalog.txt` | Original source document | Original 970-entry source catalog supplied for this project. |

Package candidates are still queried from the local system at runtime. Search hints are not installation instructions and must not be interpreted as package IDs.
