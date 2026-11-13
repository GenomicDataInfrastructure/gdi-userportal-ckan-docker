# Metadata profiles

One CKAN deployment can load the existing metadata model (`gdi_current`), HealthDCAT-AP Release 8
(`healthdcat_r8`) or both, chosen when the container starts. A FAIR Data Point harvest source can
say which profile its FDP uses; if it says nothing, the deployment's main profile applies. Already
running the stack? Start at [Updating an existing deployment](#updating-an-existing-deployment).

## Design decisions

- A profile is a *pack*: a manifest plus the scheming fragments it uses. The generator merges the
  enabled packs into one dataset schema before `prerun.py` loads CKAN. A wrong configuration stops
  the container before CKAN starts.
- Packs are ordered by precedence. A field that two packs define differently must be listed in the
  `redefines` of the later pack, and the earlier pack wins. An undeclared difference stops the start.
- The harvest source key `metadata_profile` selects a pack. The older `profile` key stays a raw RDF
  profile chain. A source with both keys is rejected.
- Conformance is computed from each enabled profile's mandatory properties when someone asks for it.
  It is never stored and never enforces anything.
- Retiring a profile hides its datasets; it does not delete them. Pruning is a dry run unless
  `--delete` is given.
- The export selector `?metadata_profile=<pack>` is not implemented. See *Known limits*.

How it works: each profile is a *pack* in `ckanext-gdi-userportal`. When the
container starts, a generator merges the schema fragments of the enabled packs into one scheming
`dataset` schema (scheming 3.1.0 cannot compose schemas at runtime) and writes the CKAN config the
rest of the stack reads. CKAN and Solr field names are the same in every profile; only the RDF
mapping differs per profile ([field mapping](../src/ckanext-dcat/docs/mapping-healthdcat.md)).

## Select profiles

Set these in `.env` (or the environment of the CKAN container) and recreate the container:

| Variable | Meaning | Default |
|---|---|---|
| `GDI_METADATA_PROFILES` | Pack names separated by commas and/or whitespace. **The order is the precedence order**: the first pack wins where two packs define a field differently. | unset or empty: `gdi_current` |
| `GDI_METADATA_MAIN_PROFILE` | The deployment's main profile: used by a harvest source that names none, and as the default RDF chain. Must be one of the enabled packs. | the first enabled pack |
| `GDI_METADATA_FORM_LANGUAGES` | The languages the edit form offers for the multilingual fields (titles, descriptions, keywords, agent names, ...), in this order, separated by commas and/or whitespace, for datasets, distributions and dataset series. The main language of the plain title and description, and the fallback of a text, is a separate CKAN setting, `CKAN__LOCALE_DEFAULT`; keep it equal to the first form language (the generator warns when it is not). | unset or empty: the languages in `CKAN__LOCALES_OFFERED` (the languages the catalogue offers) when that is set, else `en nl` |

```
GDI_METADATA_PROFILES=gdi_current                    # the existing model (the default)
GDI_METADATA_PROFILES=healthdcat_r8                  # R8 only
GDI_METADATA_PROFILES="gdi_current healthdcat_r8"    # both; gdi_current is the main profile
GDI_METADATA_PROFILES="healthdcat_r8 gdi_current" GDI_METADATA_MAIN_PROFILE=gdi_current
                                                     # both; R8 wins the shared fields it extends
```

Recreate the container (`bin/compose up -d --force-recreate ckan-dev`): a plain `restart` reruns
the generator too, but only a recreate picks up a changed `.env`.

The generator runs from the two start scripts (`start_ckan.sh` and `start_ckan_development.sh`, through
`start_ckan_common.sh`), **before** `prerun.py`
(prerun loads CKAN and with it the schema). It writes `dataset.yaml` and `provenance.json` to
`/srv/app/generated` and these CKAN options, which runtime code reads instead of the environment:

```
ckanext.dcat.metadata_profiles = healthdcat_r8 gdi_current
ckanext.dcat.metadata_profiles.main = gdi_current
ckanext.dcat.metadata_profiles.<pack>.rdf_profiles = <RDF profile chain of the pack>
ckanext.dcat.rdf.profiles = <chain of the main profile>      # the existing key, so every current path keeps working
scheming.dataset_schemas = file:///srv/app/generated/dataset.yaml <series schema of the first listed pack that has one>
```

The container does not start when the configuration is wrong: an unknown pack (the message lists
the known ones), a pack listed twice, a main profile that is not enabled, a field two packs define
differently without a declared precedence, or a pack that names an RDF profile that is not
installed.

**The order matters for the fields R8 defines differently.** The `redefines` list of
`healthdcat_r8.yaml` (in `ckanext/gdi_userportal/profile_packs/packs/` of `ckanext-gdi-userportal`)
names them; the contact point, the location, the agents, the activity, the relationship and the data
service are the structural ones, and the `profile_packs` README in the same package describes each. What only `gdi_current` has (the HealthDCAT-AP publisher type and note, the dataset
license, the identifier and country of an agent, the name of a contact point, the label of a location)
is left out of R8. With both packs enabled the pack listed first decides: list `healthdcat_r8` first to
get the R8 versions. The main profile is independent of the order.

**Plugin order.** `gdi_userportal` has to be listed before `scheming_datasets` in `ckan.plugins`
(`CKAN__PLUGINS`). CKAN gives the plugin listed first the precedence for templates, and the
dataset, series and distribution pages only show the properties that have a value, without CKAN's
bookkeeping rows, through templates that replace the ones of scheming. In the other order the pages
still work, but show the scheming defaults: empty rows, raw language maps and the dump of every
key of a distribution.

**Solr.** The dataset fields of the enabled profiles are added to the Solr core at every start; see
[Solr schema](#solr-schema).

### Development stack

The dev compose mounts a named volume at `/srv/app`, so `ckan.ini` inside the container is the
volume's copy, not the one the image was built with. The start script is the exception: the compose
file bind-mounts `ckan/setup/start_ckan_development.sh` and its shared steps
(`start_ckan_common.sh`) over the volume's copies, so a recreate always runs the scripts of the
checkout, including the generator and the Solr sync. It mounts `requirements-pins.txt` the same way.
A volume that predates a mount keeps its old file until the container is recreated once with it. Do not use
`down -v`: it also deletes the dev database.

## Select a profile per harvest source

Add `metadata_profile` to the config JSON of a FAIR Data Point source:

```json
{ "metadata_profile": "healthdcat_r8" }
```

| Config | Effect |
|---|---|
| key absent, `null` or `""` | the deployment's main profile |
| `metadata_profile: <pack>` | that pack's RDF chain; rejected when the source is saved if the pack is not enabled (the message lists the enabled ones) |
| `profile: "<rdf profiles>"` | the older key: a raw, space-separated RDF profile chain, used as written; checked against the installed RDF profiles |
| both keys | rejected: ambiguous |

If a pack is retired after a source was saved with it, the source's harvest jobs fail with a gather
error naming the source and the profile. Nothing is harvested and there is no silent fallback to
the main profile, because that would change the shape of the data unnoticed. Edit the source to
fix it. Each job logs the effective profile at INFO.

The FAIR Data Point, `dcat_rdf` and S3 harvesters all read the key (and the older `profile` key), and a
source config that names an enabled profile, or both keys, is checked when the source is saved. The
`dcat_json` harvester does not parse RDF and ignores them.

## Conformance

Conformance is **computed, never stored**: no profile label is saved on a dataset and no
`dct:conformsTo` marker is written (`conforms_to` keeps meaning data standards such as DICOM or
FHIR). A dataset conforms to an enabled profile when every property that profile makes mandatory
at the dataset's access layer has a value. The layer (`PUBLIC`, `RESTRICTED`, `NON_PUBLIC`) comes
from the last segment of `access_rights`. Nothing is ever blocked on the outcome.

**A record is checked against the profile it comes from**, not against every enabled one: the
`metadata_profile` of the harvest source that created it (basis `source`), the main profile when that
source names none (`main`), and every enabled profile when no source created it, as for a dataset made by
hand or through the API (`enabled`). A dataset of an `fdp-test` source on `gdi_current` is therefore never
judged against R8, and the R8 example only against R8. A source whose profile is not enabled leaves nothing
to check: its datasets are hidden anyway.

Three kinds of record are checked:

| Record | Mandatory in R8 | Depends on the access layer |
| --- | --- | --- |
| Dataset | the properties of R8's cardinality rules (10 in `PUBLIC` and `RESTRICTED`, 14 in `NON_PUBLIC`) | yes |
| Distribution: a resource, a sample and an analytics distribution included | applicable legislation | no |
| Dataset series | applicable legislation | no |

A **sample** (`adms:sample`) and an **analytics** distribution (`healthdcatap:analytics`) are distributions:
the RDF profile stores them as resources of the dataset, R8's shapes apply the distribution shape to them,
and they are checked like any other. A resource is labelled `sample` or `analytics` when its `uri` is in the
dataset's `sample` or `analytics` list. They also count as the dataset's distributions for the dataset's own
"dataset distribution" property. The result of a dataset does not include the results of its distributions or
its series: those are shown separately.

API action (anonymous access, subject to the same read rules as `package_show`; it takes a dataset or a
dataset series):

```
GET /api/3/action/gdi_metadata_profile_conformance?id=<dataset or series id or name>
```

```json
{
  "id": "…", "name": "…", "type": "dataset", "main_profile": "gdi_current",
  "source_profile": "healthdcat_r8", "applicable_profiles": ["healthdcat_r8"], "basis": "source",
  "access_layer": "NON_PUBLIC",
  "profiles": {
    "healthdcat_r8": { "conformant": false, "mandatory": 14,
                       "missing": [{ "property": "keyword", "fields": ["tags_translated", "tags"] }] },
    "gdi_current":   { "conformant": true, "mandatory": 0, "missing": [] }
  },
  "conformant_profiles": ["gdi_current"],
  "distributions": [
    { "id": "…", "name": "Synthetic sample", "kind": "sample",
      "profiles": { "healthdcat_r8": { "conformant": true, "mandatory": 1, "missing": [] } },
      "conformant_profiles": ["healthdcat_r8"] }
  ]
}
```

`profiles` answers for every enabled profile, so a caller can read any of them; `applicable_profiles` is the
list that counts for this record. A series has `access_layer: null` and no `distributions`.

- Missing or malformed values on old datasets never raise: the profile is "not conformant". With
  no usable `access_rights` there is no layer, and a profile with mandatory properties answers
  `conformant: false` with a `reason` instead of a list.
- `gdi_current` has no mandatory properties, so every dataset satisfies it.
- Only the presence of a value is checked: not the maximum cardinality, the vocabulary, the shape of
  a nested node, or R8's rule that structured data needs variables.
- Records of other types (such as a showcase) are rejected.
- The rules for distributions and series come from R8's SHACL shapes, which R8's cardinality file does not
  cover. They are kept in `conformance/healthdcat_r8_fields.yaml` under `classes` and carried into the
  generated file by the same builder; see *Add a profile*.
- A harvested dataset that does not conform to its source's profile also gets a WARNING in the
  harvest log (FAIR Data Point harvester); it never fails the import. The `dcat_rdf` and S3 harvesters
  log nothing about conformance: use the indicator or the report below.

### Where conformance shows

Nothing is stored for any of these; each is computed from the dataset when you ask.

- **Dataset and series page**: under the description, one badge per profile the record is checked
  against, with a line saying why (its harvest source, the main profile, or every enabled profile). Green
  when it conforms, amber with the missing properties when it does not (or the reason, when a dataset has
  no access layer).
- **Distribution list of a dataset**: a grey "Sample" or "Analytics" label on those distributions, and an
  amber "Not conformant: `<profile>` (n missing)" badge on a distribution that misses a mandatory property.
  A conforming distribution gets no badge.
- **Distribution page**: the kind ("Distribution", "Sample distribution" or "Analytics distribution") and
  one badge per profile of the dataset it belongs to.
- **Dataset and series lists** (search, organization, group and harvest-source pages): an amber
  "Not conformant: `<profile>` (n missing)" badge, only on a record that misses a mandatory property of a
  profile it is checked against. The tooltip names the missing properties. A record that conforms gets no
  badge. It is computed from the result dicts of the page, so there is no extra search query and no index
  field; the sources of the page are looked up once per request.
- **Report of what does not conform** (sysadmins; private records are included, datasets of a hidden
  profile are not, because the search does not return them):

  ```
  GET /api/3/action/gdi_metadata_profile_conformance_report[?profile=<pack>]
  bin/ckan gdi-userportal profiles conformance [--profile <pack>] [--json]
  ```

  For each profile it counts what was checked against it and lists what does not conform, in three
  sections: `datasets` (with access layer and missing properties), `series` and `distributions` (each with
  its dataset, its kind and the missing properties). The command is read-only.

  ```
  Checked 30 dataset(s), 2 series and 10 distribution(s)
  gdi_current: all conform (29 dataset(s), 2 series, 6 distribution(s))
  healthdcat_r8: 1 of 2 dataset(s) do not conform
    invalid-value-probe-two: access rights is missing
  ```

The mandatory properties of `healthdcat_r8` are **generated** from R8's own
`healthdcat-cardinality-rules.json`, not copied by hand: see *Add a profile*.

## Add a profile

Details and the merge rules are in the `profile_packs` README of `ckanext-gdi-userportal`
(`ckanext/gdi_userportal/profile_packs/README.md` in that submodule).

1. **Fragments**: put the scheming fields the pack needs under `profile_packs/fragments/`. Reuse the
   neutral fragments; a fragment is a contiguous slice of the form, because field order is the form
   order.
2. **Manifest** `profile_packs/packs/<name>.yaml`: `fragments`, `rdf_profiles` (installed
   `ckan.rdf.profiles` entry points, in order), `redefines` for any shared field the pack defines
   differently, optionally `conformance` and `keep_extras`.
3. **RDF profile**: add the profile class and register it in the `ckan.rdf.profiles` entry points
   of `ckanext-dcat`; run `pip install -e` for the extension in a running container after adding an entry
   point. Keep field names profile-neutral: only the mapping may depend on the version.
4. **Conformance** (optional): run `conformance_build.py` on the profile's cardinality rules, after
   mapping each mandatory property to its CKAN fields in `conformance/<name>_fields.yaml`. The build
   fails if a mandatory property has no fields or a mapped property is not mandatory. The same file can carry
   `classes: {distribution, series}` for the properties a profile makes mandatory on those classes (R8 takes
   them from its SHACL shapes, not from the cardinality rules); they are copied into the generated file.
5. **Tests** (host, no CKAN needed):
   From the root of the `ckanext-gdi-userportal` submodule:
   `uv run --no-project --with pyyaml --with sqlalchemy --with pytest python -I -m pytest ckanext/gdi_userportal/tests/profile_packs`
6. Enable it with `GDI_METADATA_PROFILES`, recreate the container and check the schema (below).

## Remove a profile

1. Take it out of `GDI_METADATA_PROFILES` (and `GDI_METADATA_MAIN_PROFILE` if it was the main one)
   and recreate the container. The schema regenerates without the pack's fields.
2. Nothing else breaks: datasets keep the values they had saved for the retired fields, as extras
   that no schema describes. They are harmless, and CKAN and the search keep working.
3. **Optionally prune** those extras. The command is a **dry run unless `--delete` is given**:

   ```
   bin/ckan gdi-userportal profiles prune             # list what would go
   bin/ckan gdi-userportal profiles prune --delete    # remove it, after confirmation (-y skips)
   ```

   It lists, per dataset, the extras whose field only a retired pack defines (keys only, never
   values), and the harvest sources that still name a retired profile (listed, never changed).
   With `--delete` it removes those extras and reindexes the datasets it touched; if the reindex
   fails it says so and the fix is `ckan search-index rebuild`. A deletion cannot be undone: take a
   database backup first. It reads the enabled profiles from the generated config and refuses to run
   when that is missing.
   - Extras a pack lists under `keep_extras` are never pruned: `related_resource` and `source` stay,
     because the shared DCAT-AP code keeps them as free extras in every profile.
   - Only whole dataset extras go. A subfield a retired pack added to a shared field (the opening
     hours of a contact point, say) stays inside that field's value.
4. Edit the harvest sources that named the retired profile.

## Rollback

- **Back to the previous profiles**: restore `GDI_METADATA_PROFILES` and recreate the container.
  Nothing else is needed: the generator changes no database state, there is no migration and no
  Solr schema removal. Values saved while a profile was enabled stay in the database until pruned.
- **FDP sources saved with a profile the rollback retired** fail their jobs until edited; the prune
  dry run lists them.
- Datasets of a source whose profile is no longer enabled are hidden, not removed (see
  *Datasets of a profile that is not enabled*); enable the profile again and they are back.

## Datasets of a profile that is not enabled

Profiles can be added and removed without reharvesting or pruning. A harvest source names its profile
with `metadata_profile` (see *Select a profile per harvest source*). When that profile is not in `GDI_METADATA_PROFILES`, the datasets the source harvested are hidden: they are
left out of the search (so of every count, facet and organization or group listing built on it), and the
dataset page and `package_show` answer "not found" to everyone but a sysadmin, who can still open and edit
them by their URL. The data stays in the database untouched and comes back as soon as the profile is enabled
again, with no reindex. A source without `metadata_profile` uses the main profile and is never hidden, and a
dataset that no harvest source created is never hidden either: nothing says which profile it follows.

- A series or dataset created by hand, or by an API client, has no source and stays visible, whatever it holds.
- The datasets of a hidden source show as "0 datasets" on its harvest page, because that count is a search.
- `package_list` still names a hidden dataset: it reads the database, not the search.

## Solr schema

The Solr core is created once from the image and lives in a volume, so rebuilding the image does not
update an existing core. At every start the start scripts run `solr_schema sync`, which adds the
dataset fields of the enabled profiles to the core and removes the fields that no configured schema
describes any more. A failure does not stop CKAN; the `[solr-schema]` lines of the container log say
what happened. After the sync reports changes, run `bin/ckan search-index rebuild` so that datasets
indexed earlier get the new fields. The options (`--dry-run`, `--keep-leftovers`) and the details are
in the `profile_packs` README of `ckanext-gdi-userportal`.

## Updating an existing deployment

For a developer or operator updating a running stack. It touches three extensions
(`ckanext-gdi-userportal`, `ckanext-dcat`, `ckanext-fairdatapoint`), the start scripts and the Solr
core, so do the steps in this order:

1. **Check out the submodules** at the pinned revisions with `git submodule update --init`. To move an
   extension to a newer revision, check that revision out inside `src/<extension>` and commit the
   new pointer in this repository. Then run `bin/compose restart`: the start script reinstalls the
   extensions in `src/` with the pins applied (README, section 5).
2. **Set the profiles** in `.env` (see *Select profiles*). Unset keeps the existing model
   (`gdi_current`).
3. **Recreate the container** (`bin/compose up -d --force-recreate ckan-dev`). The start script
   regenerates the schema and syncs the Solr core. In the dev stack the start script lives in the
   `/srv/app` volume, so an image rebuild does not apply it: see *Development stack*. Check the log
   with `bin/compose logs ckan-dev | grep -E "metadata-profiles|solr-schema"`.
4. **Reindex when the Solr sync reports changes**: `bin/ckan search-index rebuild`. Without it,
   datasets indexed earlier lack the new fields.
5. **Reharvest the sources.** There is no backfill: a stored dataset keeps the shape it was
   harvested in until its source is harvested again. That matters when a schema was regenerated
   (a field that became a list, a new field, the series link) and is the first thing to try when a
   field looks empty or wrong after an update. Use `bin/ckan harvester job <source id>`, then let
   the supervisor's consumers finish it. Calling `harvester run` again while a gather is still
   running starts a second gather.
6. **Give each source its profile** (`metadata_profile`, see *Select a profile per harvest source*).
   A source whose profile is not enabled is hidden, not deleted.
7. **Check the Discovery Service.** R8 widens several fields to lists (see *Known limits*) and the
   Discovery Service still reads one value of each. With R8 enabled first it fails on such datasets
   until it is updated. `gdi_current` is unaffected.
8. **Run the tests on the host, not in the container.** The ckanext-dcat and ckanext-fairdatapoint
   suites reset the dev database; run the pure-Python tests with
   `uv run --no-project --with <deps> python -I -m pytest ...` (the profile pack suite is in *Add a
   profile*). Tests that need a database (for example `test_import_stage_success_*`) do not run on
   the host.

## Dataset series in a harvest

The RDF harvester (`dcat_rdf`) reads `dcat:DatasetSeries` and links each dataset to the series it
names with `dcat:inSeries`. The rules:

- **A series belongs to the harvest source that defines it.** A dataset links to a series of its
  own source only, wherever the series sits in the file or in the pages of a paged source, and
  whether it comes before or after the dataset. A dataset is never linked to a series of another
  source or to a series created by hand.
- **Two sources can define a series with the same URI.** Each gets its own series package, found
  again at the next harvest through the harvest objects of that source, with the same id and name.
  When a source stops listing its series, that series is deleted and the other source's series is
  not touched.
- **A reference that points at nothing is skipped silently.** An unknown URI, a URI of another
  source, a blank node or a literal in `dcat:inSeries` imports the dataset without that link. A
  dataset with no valid reference has no `in_series` key at all, not an empty list, and no warning is
  written.
- **The first harvest links too.** A new series gets its id while the source is gathered, so the
  datasets of the same harvest can point at it before the series exists in CKAN.

## Harvest sources keep their datasets apart

A dataset is identified by its URI *within the harvest source* that imported it, the same way a series is.
Two sources that define a dataset with the same URI get two packages, and each source updates, replaces and
deletes only its own. The FAIR Data Point, `dcat_rdf`, S3 and `dcat_json` harvesters all work this way.

- A package is found at the next harvest through the harvest objects of its source, not through the `guid`
  extra. A dataset (or series) created by hand with a matching `guid` extra is therefore not taken over by a
  harvest: the harvest creates its own package and gives it a free name.
- **Packages that two sources already shared stay shared.** They were created when a second source with
  the same dataset URI updated the first source's package, so both sources' harvest objects point at it.
  If one of the sources drops the dataset the shared package is deleted. To separate them, clear one of
  the two sources (`ckan harvester source clear <id>`) and harvest it again.
- The scoping by source needs the database, so it has no host unit test.

## Verify a deployment

After the container starts:

```
bin/compose logs ckan-dev | grep metadata-profiles       # the generator's lines and the profiles
bin/ckan search-index rebuild                            # then compare the package_search count
curl -s "http://localhost:5500/api/3/action/scheming_dataset_schema_show?type=dataset"   # the field list
curl -s "http://localhost:5500/api/3/action/gdi_metadata_profile_conformance?id=<dataset>"
```

Then run a Discovery Service search against it. Harvest with `bin/ckan harvester job <source id>`,
not `harvester run-test`, which races the supervisor's consumers. For the tests, see step 8 of
*Updating an existing deployment*.

## Invalid values in a harvested dataset

A remote catalogue can hold a value the schema rejects (a status that is not one of the choices, a number
that is not an integer). The FAIR Data Point and the RDF harvester import the dataset anyway, without that
value, and save a warning on the harvest object: `Warning: imported without the invalid value: <field> =
'<value>' (<what CKAN said>)`. Warnings are listed with the errors of the harvest job in the harvest source
page. This applies to the dataset and to each distribution (and to subfields and resources at any depth).
Only the value is dropped: a dataset that still does not validate (no title, an unknown organization) is
rejected with its original error. The value is not kept anywhere else, so fix it in the source
and harvest again. A number that is not an integer (the number of records, the typical ages, the byte size
of a distribution) is kept by the RDF profiles as it is, so that it is reported like any other invalid
value.

## Known limits

- The landing page and the type of a dataset, and the access URL, the download URL and the rights of a
  distribution, are lists in the R8 pack (R8 gives them 0..*; the rights are a list of statements with an
  optional IRI and a label per language). The Discovery Service still reads one value of each: with R8
  first it fails on a dataset until it is updated. Solr keeps the first value in `url` and `dcat_type`,
  and every type in `vocab_dcat_type`.
- The title, description and endpoint description of a data service (`access_services`) hold a text per
  language in the R8 pack.
- R8 fields that allow several values where `gdi_current` holds one and are not lists (`identifier`) stay
  single-valued; the R8 profile keeps the first value and logs a warning.
- The fields of the schemas (dataset, dataset series, distribution, data service) are ordered
  alphabetically by label, with the title and the description first (`field_order: alphabetical` in the
  pack manifests of `gdi_current` and `healthdcat_r8`). Nested entities (agents, contact point, ...) keep
  the order of the model. With both packs enabled the pack listed first decides.
- `CKANEXT__GDI_USERPORTAL__SHOW_EMPTY_PROPERTIES=true` makes the dataset and distribution pages list
  every property of the schema, with a dash for the empty ones. It is for looking at what the schema,
  the form and a harvest can hold, and is off by default. With more than one profile enabled the
  schema holds the fields of all of them, so a dataset only gets a dash for the fields of the profile
  of its harvest source (the main profile when the source names none): an R8 dataset shows no dash for
  `trusted_data_holder`, a `gdi_current` one none for `source`. A dataset without a known harvest
  source gets every field, and a field that has a value is always shown. A distribution, sample or
  analytics page follows the profile of its dataset. A dataset series is not restricted: its schema is
  the series schema of the first pack that has one, not built from the packs.
- The export selector `?metadata_profile=<pack>` is not implemented: exports use the main profile's
  chain, or a raw `?profiles=`.
- Concept and ConceptScheme and the licence type are not covered (see `healthdcat-ap-r8-gap-analysis.md`
  in the docs of `ckanext-dcat`).
  `odrl:hasPolicy` of a distribution is kept as the IRI of the policy (`resources[].has_policy`); the
  policy itself is not modelled.
