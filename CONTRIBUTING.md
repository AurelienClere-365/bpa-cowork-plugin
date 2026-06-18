# Contributing to the BPA Analytics Cowork Plugin

Thank you for your interest in contributing! This plugin helps CFO, Finance, and Procurement teams
get instant financial insights from Dynamics 365 Business Performance Analytics.

---

## Ways to contribute

| Type | How |
|---|---|
| New skill | Add a new `SKILL.md` for a BPA domain not yet covered (e.g. Supply Chain, Inventory, Fixed Assets) |
| Skill improvement | Improve an existing skill's DAX examples, trigger phrases, or workflow steps |
| Bug fix | Fix a validation issue, packaging error, or documentation gap |
| Documentation | Improve README, add examples, clarify setup steps |
| Translation | Add locale-specific DAX patterns or persona descriptions |

---

## Adding a new skill

### 1. Create the folder

```
skills/bpa-your-skill-name/
└── SKILL.md
```

The folder name must be lowercase, hyphen-separated, and start with `bpa-`.

### 2. Write the SKILL.md

Use this frontmatter template:

```yaml
---
name: bpa-your-skill-name
description: >
  WHEN: <list at least 5 trigger phrases, e.g. "show inventory levels",
  "stock on hand", "reorder point", "inventory turnover", "slow-moving items">
license: MIT
metadata:
  version: 1.0.0
  author: Your Name
  tags: [bpa, finance, <domain>]
---
```

**Body requirements (P007):**

- Minimum 200 characters
- Include at least one complete DAX query example
- Document the exact MCP tool call sequence (always `get_bpa_dataset_schema` first, then `execute_dax_query`)
- Show a sample result table

### 3. Add to manifest.json

Add an entry to the `agentSkills` array:

```json
{"folder": "./skills/bpa-your-skill-name"}
```

### 4. Validate

```powershell
.\package.ps1
```

All ASKILL P001–P008 checks must pass with no `[FAIL]` lines.

### 5. Update CHANGELOG.md

Add your skill under `[Unreleased]` → `Added`.

### 6. Update EXAMPLES.md

Add at least one worked example for your new skill (prompt → what happens → result).

---

## Code style

- **PowerShell scripts**: `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`, UTF-8 with BOM
- **JSON files**: 2-space indent, no trailing commas, UTF-8 without BOM
- **Markdown**: ATX headings (`#`, `##`, ...), GitHub Flavored Markdown tables, fenced code blocks with language tag
- **DAX examples**: `EVALUATE` form, table name and column name in full square-bracket notation

---

## Pull request checklist

Before submitting a PR, confirm:

- [ ] `.\package.ps1` runs with no `[FAIL]` lines
- [ ] New/updated skill has a `description:` trigger with at least 5 WHEN phrases
- [ ] `manifest.json` updated if a new skill was added
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] At least one example added/updated in `EXAMPLES.md`
- [ ] No secrets, PATs, environment IDs, or credentials in any committed file

---

## Running validation locally

```powershell
# Full validation + ZIP
.\package.ps1

# Validation only (no ZIP, no SkillsOnly install) — pipe to Out-Host for colour
.\package.ps1 | Out-Host

# Install skills to VS Code prompts folder (Option A)
.\package.ps1 -SkillsOnly
```

---

## Questions?

Open a [Discussion](https://github.com/AurelienClere-365/bpa-cowork-plugin/discussions)
or a [GitHub Issue](https://github.com/AurelienClere-365/bpa-cowork-plugin/issues).
