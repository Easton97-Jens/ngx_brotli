# CI Security Audit & Hardening Plan for ngx_brotli

## 1) CI-Blueprint

### PR Pipeline (schnelle Rückmeldung für Maintainer)
- **Static Analysis**: `ci-static-analysis.yml` (clang-tidy + cppcheck, Security-Regeln, Fehler = Build-Fail).
- **Build gegen mehrere NGINX-Versionen**: `ci-build.yml` (z. B. LTS + aktuell, `-Wall -Wextra -Werror`).

### Nightly Pipeline (tiefergehende Checks)
- **Sanitizer Builds**: `ci-sanitizers.yml` (ASAN/UBSAN/LSAN, clang).
- **Optionales Fuzzing**: sinnvoll, wenn dedizierte Harnesses für NGINX-Parser & Brotli-Streams vorliegen; aktuell nicht im Repo vorhanden und deshalb im Workflow-Set nicht aktiviert (Details in Abschnitt 2D).

### Release Pipeline (veröffentlichungsrelevante Artefakte)
- **Hardened Build**: Release-Build mit Hardening-Flags (siehe Abschnitt 3).
- **Deterministische Artefakte**: reproduzierbare Build-Umgebung und stabile Build-Metadaten (siehe Abschnitt 4).

---

## 2) GitHub Actions Workflows (vollständig lauffähig)

### A) `ci-build.yml`
- **Zweck**: PR- und Push-Builds gegen mehrere NGINX-Versionen.
- **Flags**: `-Wall -Wextra -Werror` erzwingen warnungsfreies Kompilieren.
- **Matrix**: LTS (1.24.x) + aktuell (1.27.x).

### B) `ci-static-analysis.yml`
- **clang-tidy**: Fokus auf `clang-analyzer-*`, `bugprone-*`, `cert-*`, `security-*`.
- **cppcheck**: Security-Addon (CERT) + `--error-exitcode=1`.
- **Ergebnis**: Jede neue Finding-Klasse blockiert den PR.

### C) `ci-sanitizers.yml`
- **ASAN**: Heap/Stack/UAF/Out-of-bounds.
- **UBSAN**: Undefined Behavior (z. B. Integer-Overflow, misaligned access).
- **LSAN**: Memory-Leaks (separater Lauf, um Signal klar zu halten).
- **Bekannte NGINX False Positives**:
  - **LSAN**: NGINX Memory-Pools werden absichtlich bis Prozessende gehalten → Leak-Meldungen möglich.
  - **ASAN/LSAN**: Worker-Prozess-Lifecycle führt zu „leaks on exit“, die keine echten Leaks in Requests sind.

### D) `ci-fuzz.yml` (nur wenn sinnvoll)
- **Bewertung**: Fuzzing ist sinnvoll für
  - **HTTP Request Parsing** (NGINX interner Parser) und
  - **Brotli Stream Input** (Decoder/Encoder APIs).
- **Status**: Derzeit **kein** Workflow im Repo, da keine Fuzz-Harnesses vorhanden sind. Sobald Harnesses ergänzt werden, sollte `ci-fuzz.yml` integriert werden (z. B. libFuzzer + clang) und nightly laufen.

---

## 3) Compiler & Linker Hardening

### Pflicht (CI & Release)
**Compiler-Flags**
- `-Wall -Wextra -Werror` – blockiert PRs bei Warnungen.
- `-fno-omit-frame-pointer` – bessere Crash-Diagnostik und Sanitizer-Qualität.
- `-fstack-protector-strong` – schützt vor klassischen Stack-Overflows.
- `-D_FORTIFY_SOURCE=2` – verstärkte Checks für libc-Funktionen (bei `-O1+`).

**Linker-Flags**
- `-Wl,-z,relro` – schreibgeschützte Relocation-Sektionen (Härtung).
- `-Wl,-z,now` – bindet Symbole früh, reduziert ROP/PLT-Angriffe.
- `-Wl,-z,noexecstack` – verhindert ausführbaren Stack.

### Optional (Release, abhängig von Performance/Kompatibilität)
**Compiler-Flags**
- `-fPIE` – ASLR-Unterstützung für Hauptbinary (bei statisch gelinkten NGINX-Builds).
- `-fstack-clash-protection` – Schutz vor Stack-Clash-Angriffen (Compiler/Platform abhängig).
- `-fno-common` – verhindert Mehrfachdefinitionen und Linker-Overlaps.

**Linker-Flags**
- `-Wl,-z,defs` – erzwingt vollständige Symbolauflösung (early fail).
- `-Wl,--as-needed` – reduziert unnötige Abhängigkeiten (kleinerer Attack-Surface).

---

## 4) Reproducible Builds

**Konkrete Maßnahmen**
1. **Toolchain-Fixierung**
   - Pin `clang`/`gcc` Versionen in CI (z. B. `ubuntu-24.04` + explizite Pakete).
2. **SOURCE_DATE_EPOCH**
   - `SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct)` exportieren.
3. **Timestamp/Path-Determinismus**
   - `-ffile-prefix-map=$PWD=.` und `-fdebug-prefix-map=$PWD=.` setzen.
   - `TZ=UTC` und `LC_ALL=C` setzen.
4. **Deterministisches Archivieren**
   - `ARFLAGS=rcD` und `RANLIBFLAGS=` für stabile Archive.
5. **NGINX ./configure**
   - Immer **identische** `./configure` Flags verwenden (z. B. in Release-Workflow fixieren).
   - `--with-cc-opt`/`--with-ld-opt` zentral definieren und nicht dynamisch erzeugen.

---

## 5) Security Gates (Blocker-Regeln)

Ein PR **muss** blockiert werden, wenn:
1. **Static Analysis** neue High-Severity Findings meldet (clang-tidy/cppcheck).
2. **Sanitizer** einen Crash oder UB reportet (ASAN/UBSAN/LSAN).
3. **Hardened Build** fehlschlägt (Hardening-Flags nicht kompatibel).
4. **Compiler Warnings** auftreten (`-Werror` aktiv).

Diese Regeln werden in den bereitgestellten Workflows als harte Exit-Codes umgesetzt.
