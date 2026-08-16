# Artifact policy

This repository is a sanitized engineering portfolio, not a redistributable foundry design kit or a turnkey commercial-EDA environment.

## Published

| Artifact | Why it is included |
|---|---|
| Synthesizable RTL | Original controller implementation |
| Self-checking testbench | Reproducible functional test |
| Mapped structural netlist | Demonstrates custom-cell mapping without the Liberty database |
| Selected screenshots | Visual evidence of implementation and verification stages |
| Sanitized result summaries | Preserves key metrics without machine paths or vendor boilerplate |
| Open-source simulation script and CI | Makes the public RTL portion reproducible |

## Intentionally excluded

| Artifact | Reason |
|---|---|
| GF65 PDK, models, layer maps, and rule decks | Foundry/academic licensing |
| Liberty `.lib`/`.db`, technology LEF, and extraction models | Licensed technology data |
| Calibre result databases and raw reports | Rule-deck detail and machine-specific content |
| OpenAccess libraries and native Innovus databases | Tool-specific generated data and process geometry |
| GDS/OASIS exports | Distribution rights not established; not needed for RTL review |
| PEX/DSPF/SPICE netlists and binary waveforms | Process-derived data and large generated artifacts |
| Raw vendor transcripts and command histories | User/host paths, boilerplate, and nonportable state |
| Course-provided setup/analysis scripts | Third-party instructional material |
| Original course report | Replaced by repository-native documentation with personal identifiers removed |

The private archive should be retained separately for personal recovery. It should not be committed wholesale to a public Git repository.
