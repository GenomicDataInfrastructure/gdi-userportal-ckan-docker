# Metadata profiles

One CKAN deployment can load the existing metadata model (`gdi_current`), HealthDCAT-AP Release 8
(`healthdcat_r8`) or both, chosen when the container starts. A FAIR Data Point harvest source can
say which profile its FDP uses; if it says nothing, the deployment's main profile applies. The
design and its decisions are in ADR 0001.

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
| `GDI_METADATA_FORM_LANGUAGES` | The languages the edit form offers for the multilingual fields (titles, descriptions, keywords, agent names, ...), in this order, separated by commas and/or whitespace, for datasets, distributions and dataset series. The main language of the plain title and description, and the fallback of a text, is a separate CKAN setting, `CKAN__LOCALE_DEFAULT`; keep it equal to the first form language (the generator warns when it is not). | unset or empty: `en nl` |

```
GDI_METADATA_PROFILES=gdi_current                    # the existing model (the default)
GDI_METADATA_PROFILES=healthdcat_r8                  # R8 only
GDI_METADATA_PROFILES="gdi_current healthdcat_r8"    # both; gdi_current is the main profile
GDI_METADATA_PROFILES="healthdcat_r8 gdi_current" GDI_METADATA_MAIN_PROFILE=gdi_current
                                                     # both; R8 wins the shared fields it extends
```

Recreate the container (`sh bin/compose up -d --force-recreate ckan-dev`): a plain `restart` reruns
the generator too, but only a recreate picks up a changed `.env`.

The generator runs in `start_ckan.sh` and `start_ckan_development.sh`, **before** `prerun.py`
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
[`healthdcat_r8.yaml`](../src/ckanext-gdi-userportal/ckanext/gdi_userportal/profile_packs/packs/healthdcat_r8.yaml)
names them; the contact point, the location, the agents, the activity, the relationship and the data
service are the structural ones, and
[the pack README](../src/ckanext-gdi-userportal/ckanext/gdi_userportal/profile_packs/README.md)
describes each. What only `gdi_current` has (the HealthDCAT-AP publisher type and note, the dataset
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

The dev compose mounts a named volume at `/srv/app`, so `start_ckan_development.sh` and `ckan.ini`
inside the container are the volume's copies, **not** the ones the image was built with. Rebuilding
the image does not apply an edit of the start script. To test one, bind-mount the working-tree
script over `/srv/app/start_ckan_development.sh` with a compose override (kept outside the repo),
and recreate the container. Do not use `down -v`: it also deletes the dev database.

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

Only the FAIR Data Point harvester reads the key. The `dcat_rdf` and S3 harvesters use the
deployment's main profile (`ckanext.dcat.rdf.profiles`).

## Conformance

Conformance is **computed, never stored**: no profile label is saved on a dataset and no
`dct:conformsTo` marker is written (`conforms_to` keeps meaning data standards such as DICOM or
FHIR). A dataset conforms to an enabled profile when every property that profile makes mandatory
at the dataset's access layer has a value. The layer (`PUBLIC`, `RESTRICTED`, `NON_PUBLIC`) comes
from the last segment of `access_rights`. Nothing is ever blocked on the outcome.

API action (anonymous access, subject to the same read rules as `package_show`):

```
GET /api/3/action/gdi_metadata_profile_conformance?id=<dataset id or name>
```

```json
{
  "id": "…", "name": "…", "main_profile": "gdi_current",
  "access_layer": "NON_PUBLIC",
  "profiles": {
    "healthdcat_r8": { "conformant": false, "mandatory": 14,
                       "missing": [{ "property": "keyword", "fields": ["tags_translated", "tags"] }] },
    "gdi_current":   { "conformant": true, "mandatory": 0, "missing": [] }
  },
  "conformant_profiles": ["gdi_current"]
}
```

- Missing or malformed values on old datasets never raise: the profile is "not conformant". With
  no usable `access_rights` there is no layer, and a profile with mandatory properties answers
  `conformant: false` with a `reason` instead of a list.
- `gdi_current` has no mandatory properties, so every dataset satisfies it.
- Only the presence of a value is checked: not the maximum cardinality, the vocabulary, the shape of
  a nested node, or R8's rule that structured data needs variables.
- Dataset series are rejected (the rules are for datasets).
- A harvested dataset that does not conform to its source's profile also gets a WARNING in the
  harvest log (FAIR Data Point harvester); it never fails the import.

The mandatory properties of `healthdcat_r8` are **generated** from R8's own
`healthdcat-cardinality-rules.json`, not copied by hand: see *Add a profile*.

## Add a profile

Details and the merge rules are in `src/ckanext-gdi-userportal/ckanext/gdi_userportal/profile_packs/README.md`.

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
   fails if a mandatory property has no fields or a mapped property is not mandatory.
5. **Tests** (host, no CKAN needed):
   `uv run --no-project --with pyyaml --with sqlalchemy --with pytest python -I -m pytest ckanext/gdi_userportal/tests/profile_packs`
6. Enable it with `GDI_METADATA_PROFILES`, recreate the container and check the schema (below).

## Remove a profile

1. Take it out of `GDI_METADATA_PROFILES` (and `GDI_METADATA_MAIN_PROFILE` if it was the main one)
   and recreate the container. The schema regenerates without the pack's fields.
2. Nothing else breaks: datasets keep the values they had saved for the retired fields, as extras
   that no schema describes. They are harmless, and CKAN and the search keep working.
3. **Optionally prune** those extras. The command is a **dry run unless `--delete` is given**:

   ```
   sh bin/ckan gdi-userportal profiles prune             # list what would go
   sh bin/ckan gdi-userportal profiles prune --delete    # remove it, after confirmation (-y skips)
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
- The RDF harvester (`dcat_rdf`) does not yet parse with the chain of the profile a source names; it uses the
  main profile's. The key only decides what is hidden there.

## Solr schema

The Solr core is created once from the image and lives in a volume, so rebuilding the image does not
update an existing core. At every start the start scripts run `solr_schema sync`: it adds the dataset
fields of the enabled profiles to the core as explicit fields (multi valued when the field is a list)
and applies changes of `solr/schema.xml` through the Solr Schema API.
The sync never deletes a field and a failure does not stop CKAN (see the `[solr-schema]` lines of the
container log). After it reports changes, run `sh bin/ckan search-index rebuild` so that datasets indexed
earlier get the new fields. Preview with `--dry-run`; details in
`src/ckanext-gdi-userportal/ckanext/gdi_userportal/profile_packs/README.md`.

## Verify a deployment

After the container starts:

```
sh bin/compose logs ckan-dev | grep metadata-profiles       # the generator's lines and the profiles
sh bin/ckan search-index rebuild                            # then compare the package_search count
curl -s "http://localhost:5500/api/3/action/scheming_dataset_schema_show?type=dataset"   # the field list
curl -s "http://localhost:5500/api/3/action/gdi_metadata_profile_conformance?id=<dataset>"
```

Then run a Discovery Service search against it. Harvest with `sh bin/ckan harvester job <source id>`,
not `harvester run-test`, which races the supervisor's consumers. Run tests on the host, never in the
`ckan-dev` container (step 8 of *Updating an existing deployment*).

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
  the form and a harvest can hold, and is off by default.
- The export selector `?metadata_profile=<pack>` of ADR 0001 is not implemented: exports use the main
  profile's chain, or a raw `?profiles=`.
- Concept and ConceptScheme and the licence type are not covered (see the R8 gap analysis).
  `odrl:hasPolicy` of a distribution is kept as the IRI of the policy (`resources[].has_policy`); the
  policy itself is not modelled.
