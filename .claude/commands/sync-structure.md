---
description: Update CLAUDE.md to reflect current project structure in pipelines/ and tasks/ directories
---

# Update Project Documentation

Check if the project structure has changed in the `pipelines/` and `tasks/` directories and update CLAUDE.md accordingly.

## Instructions

1. **Scan Current Structure**:
   - Use Glob to discover all first-level directories under `pipelines/` (e.g., test/, deploy/, infra/, misc/, and any new types)
   - For each pipeline type directory, list all second-level pipeline directories
   - Use Glob to discover all first-level directories under `tasks/` (e.g., test/, deploy/, infra/, login/, misc/, and any new types)
   - For each task type directory, list all YAML files

2. **Read Current Documentation**:
   - Read CLAUDE.md and extract the current documented structure from:
     - "Pipeline Organization" section (lines around 11-29)
     - "Task Organization" section (lines around 31-59)

3. **Compare and Identify Changes**:
   - Identify new pipeline type directories that aren't documented
   - Identify new pipeline directories within each type that aren't documented
   - Identify removed pipelines that are still documented
   - Identify new task type directories that aren't documented
   - Identify new tasks that should be documented (only important/core tasks)
   - Identify removed tasks that should be removed from docs

4. **Update CLAUDE.md**:
   - Add new pipeline type categories if they don't exist
   - Add new pipeline directories with brief descriptions (infer purpose from directory name and pipeline YAML if needed)
   - Remove pipeline entries that no longer exist
   - Add new task type categories if they don't exist
   - Add new important task files with brief descriptions
   - Remove task entries that no longer exist
   - Keep the format consistent with existing documentation
   - Only add tasks that are important enough to mention (core functionality, not trivial utilities)

5. **Report Changes**:
   - Summarize what was added, removed, or needs manual description updates

## Guidelines for Task Importance

Include tasks that:
- Are core to pipeline functionality (run-tests, helm-deploy, provision-*, delete-*)
- Have significant impact on pipeline behavior
- Are frequently used across multiple pipelines

Skip tasks that:
- Are simple utilities or helpers
- Are rarely used or experimental
- Have obvious/trivial functionality