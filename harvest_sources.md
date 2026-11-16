<!--
SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
SPDX-FileContributor: PNED G.I.E.

SPDX-License-Identifier: AGPL-3.0-only
-->

List of harvest sources: one record per source, with four lines in this order:

1. the URL of the source;
2. the name of the organization that publishes it;
3. the type of the source: `FAIR` for a FAIR Data Point, `DCAT RDF` for an RDF catalogue;
4. the source configuration as JSON. `profile` names the RDF profile chain and `rdf_format` the
   serialization; `metadata_profile` selects a metadata profile (see `docs/metadata-profiles.md`).

Records are separated by two blank lines. No script or document in this repository reads this file.

https://fdp.gdi.biodata.pt
IST
FAIR
{"profile":"fairdatapoint_dcat_ap"}


http://195.148.23.230
CSFI
FAIR
{"profile":"fairdatapoint_dcat_ap","rdf_format":"text/turtle"}


https://tryggve.tsd.usit.uio.no/GDI_Norway_test_data_catalog_rdf.ttl
University of Oslo
DCAT RDF
{"profile":"fairdatapoint_dcat_ap","rdf_format":"text/turtle"}


https://gdi.test.ega-archive.org/catalog/catalog.ttl
EGA
DCAT RDF
{"profile":"fairdatapoint_dcat_ap","rdf_format":"text/turtle"}


https://fairdata.dev.gdi.lu/api/fdp
LNDS FDP
FAIR
{ "profile":"fairdatapoint_dcat_ap" }


https://staging-fdp.gdi.nbis.se/
NBIS
FAIR
{"profile":"fairdatapoint_dcat_ap"}
