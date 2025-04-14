<!--
SPDX-FileCopyrightText: 2024 PNED G.I.E.

SPDX-License-Identifier: CC-BY-4.0
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [v1.3.14] - 2025-04-14

### Changed
- Bump fairdatapoint 136 (#180) by @Hans-Christian in 3d587ee


## [v1.3.12] - 2025-04-04

### Changed
- Onlky focus HealthDCAT by @Hans-Chrstian in 36e9479
- Only focus HealthDCAP AP by @Hans-Chrstian in 66d4e17
- Initial commit of Health DCAT FDP support + Dataseries support by @Hans-Chrstian in f1a76a3



## [v1.3.9] - 2025-04-04

### Changed
- chore(deps): update ckan/ckan-dev docker tag to v2.11.2 by @Renovate Bot in 1e9057a
- chore(deps): update ckan/ckan-base docker tag to v2.11.2 by @Renovate Bot in caaf560



## [v1.3.8] - 2025-04-04

### Changed
- chore(deps): upgrade ckanext-gdi-userportal by @Bruno Pacheco in ceedbf2
- chore: update secrets in ckan.ini by @jadz94 in 3793540
- chore: addd s3harvester by @jadz94 in 2c98ec2
- chore: update dockerfile by @jadz94 in 3edeff9
- chore: upgrade extension version by @jadz94 in 6d54700
- Revert "chore: upgrade extension version" by @jadz94 in 1408099
- chore: upgrade extension version by @jadz94 in 43dfb12
- Ckan 211 (#158) by @Hans-Christian in 4089575
- chore: upgrade extension version by @jadz94 in 8a4e6f7
- Applied review comments by @Hans-Chrstian in 34b259f
- docs(README): add local ckan instance hostname and default sysadmin credentials by @Antoine Dorard in 08a7f5e
- Sonarcloud recomendations by @Hans-Chrstian in b3eca9b
- Revert x64 by @Hans-Chrstian in 96bc753
- Correct readme by @Hans-Chrstian in 57f3c3d
- Add license by @Hans-Chrstian in 7216518
- Adjust dockerfile by @Hans-Chrstian in fd38196
- Current status of 2.11.1 upgrade by @Hans-Chrstian in 0cd04b8
- chore: improve logs of database upgrades by @Bruno Pacheco in 3e85f54
- Clarify and clean up Dockerfile by @Mark Janse in 0a3e002
- Explicitly add linux/amd64 platform to docker as there are no other images by @Mark Janse in fadd140
- chore(deps): update dependencies and settings for CKAN 2.11 compatibility by @Mark Janse in d4a5e0c


### Fixed
- fix(ART-12367): update dcat ext version by @jadz94 in 452363d
- fix(reuse): Add reuse header to scripts by @Hans-Chrstian in 729a425
- fix(redis): remove unnecessary redis password  in environment file by @Hans-Chrstian in 8a75cc1
- fix: resolve startup issues with supervisor and harvester configuration by @Hans-Chrstian in ee4ca92
- fix Civity reference to scheming by @Hans-Chrstian in 906b52f
- fix permission issues by @Hans-Chrstian in db58059



## [v1.3.7] - 2025-04-04

### Changed
- chore(deps): upgrade CKAN to 2.10.6 by @Bruno Pacheco in 34713e6
- chore(deps): revert CKAN upgrade by @Bruno Pacheco in be2c5a8
- chore(deps): update docker.io/ckan/ckan-dev docker tag to v2.10.6 by @Renovate Bot in 05c35a5
- chore(deps): update docker.io/ckan/ckan-base docker tag to v2.10.6 by @Renovate Bot in 516ec09



## [v1.3.6] - 2025-04-04

### Changed
- FDP 1.3.2 by @Hans-Chrstian in 316fbc3
- Fix FDP by @Hans-Chrstian in d78701d
- chore: initialize harvest db by @Bruno Pacheco in 825ce18
- chore(deps): upgrade ckan extensions by @Bruno Pacheco in ab77b39
- chore(deps): update aquasecurity/trivy-action action to v0.29.0 by @Renovate Bot in 0b1cf02
- chore(deps): update fsfe/reuse-action action to v5 by @Renovate Bot in 85895d6


### Fixed
- Hotfix 1.4.0 by @Hans-Chrstian in 7f632ce
- fix: reuse CKAN_SQLALCHEMY_URL in upload_vocabulary.sh by @Bruno Pacheco in 873828b



## [v1.3.5] - 2025-04-04

### Changed
- chore(deps): upgrade opentelemetry components by @Bruno Pacheco in 3500557



## [v1.3.4] - 2025-04-04

### Changed
- chore(deps): upgrade ckanext-gdi-userportal by @Bruno Pacheco in 4850d5f
- chore: update ckanext-gdi-userportal HEAD commit by @Bruno Pacheco in 4a16fc9
- chore: use cached trivy db by @Bruno Pacheco in d9caea7
- chore: cache trivy db by @Bruno Pacheco in a870d4f
- chore: update ckanext-gdi-userportal HEAD commit by @Bruno Pacheco in 7289ccc
- Prepare for release v1.3.3 (#143) by @Hans-Christian in ba6f8c9


### Fixed
- fix: revert severity of trivy scanner to CRITICAL only by @Bruno Pacheco in b3720b6




## [v1.3.3] - 2024-10-16

### Fixed
* fix(language): Set fallback language to English when Dutch for example is not available

## [v1.3.2] - 2024-10-14

### Changed
* docs: clean up Keycloak section from README by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/141

## [v1.3.1] - 2024-10-11

### Added
* feat(language): add Dutch facet translations to translations table by @Markus92 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/129

### Changed
* chore(deps): update aquasecurity/trivy-action action to v0.26.0 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/128
* chore(deps): update redis docker tag to v7 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/134
* chore(deps): update aquasecurity/trivy-action action to v0.27.0 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/140

### Fixed
* fix: bugfix on harvesters by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/131
* fix: reduce cron job for harvesting to every 15min by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/139

## [v1.3.0] - 2024-10-07

## Changed
* chore(deps): update ckan/ckan-base docker tag to v2.10.5 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/115
* chore(deps): update ckan/ckan-dev docker tag to v2.10.5 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/116
* feat(scheming): set up GDI presets (for datetime scheming) by @Markus92 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/119
* chore(deps): update postgres docker tag to v17 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/124
* feat: Upgrade to DCAT AP 3 by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/125
* chore(deps): update aquasecurity/trivy-action action to v0.25.0 by @LNDS-Sysadmins in https://
github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/127

### Removed
* feat(auth): remove Keycloak integration from CKAN and user portal by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/121


### Fixed
* fix: user permissions error causes oidc plugin to error by @Markus92 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/114

### Security
* chore(deps): remove vulnerable packages by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/126

## [v1.2.2] - 2024-05-12

### Added
* Vulnscan by @sehaartuc in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/76
* feat: renovate integration by @sehaartuc in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/77

### Changed
* chore(deps): update fsfe/reuse-action action to v4 - autoclosed by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/83
* chore(deps): update docker/build-push-action action to v6 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/82
* chore(deps): update docker/login-action digest to 0d4c9c5 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/79
* chore(deps): update docker/metadata-action digest to a64d048 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/80
* chore(deps): update oss-review-toolkit/ort-ci-github-action digest to 81698a9 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/81
* chore(deps): update postgres docker tag to v16 by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/84
* chore(deps): update azure/webapps-deploy digest to 5c1d76e by @LNDS-Sysadmins in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/78
* chore: setup default user permissions by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/109
* chore: change from Catalogues to Organizations by @nolliia in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/110
* chore: merge RUN commands by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/111
* Update fairdatapoint extension  by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/113

### Fixed
* fix: Set compatibility_mode to false to map correctly publisher close… by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/74

## [v1.2.1] - 2024-06-12

### Changed

- chore: change versions of fairdatapoint harvester and gdi extensions by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/66
- chore: update vocabulary by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/68
- chore: update fairdatapoint by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/69

### Fixed

- fix(cron): Run harvester cron job in background (run and clean up log… by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/71
- fix(csv): resolve "extra data after last expected column" error by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/70

## [v1.2.0] - 2024-05-19

### Changed

chore: change versions of fairdatapoint harvester and gdi extensions

## [v1.1.3] - 2024-05-19

### Fixed

- fix: fix harvester issues

## [v1.1.2] - 2024-05-12

### Changed

- chore: preload CKAN term translation by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/56
- chore: remove keycloak from localhost by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/58
- chore(deps): bump 2.10 version to 2.10.4 by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/57
- chore: update gdi-userportal reference by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/60
- chore: add more labels by @brunopacheco1 in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/62

### Fixed

- fix(azure-deployment): Trigger repull on new CKAN version by updating… by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/52
- fix: point to fairdatapoint extension tag by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/54
- fix: #51 bug report by @hcvdwerf in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/55
- fix: set up profiles to fix parsing from file bug by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/59
- fix: update gdi-userportal reference by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/61
- enable multilingual plugins; pre-populate ckan db with labels by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/53
- fix: update fairdatapoint harvester reference by @a-nayden in https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/pull/63

## [v1.1.1] - 2024-03-01

### Added

- chore: #15 add REUSE headers by @brunopacheco1 in #44
- feat(harvester): Configure automatic CRON job for CKAN Harvester #25 by @hcvdwerf in #45

### Fixed

- fix: Re-add ckanext scheming extension from Civity to solved harvester issues
- fix(theme-fetcher): handle empty iterable in theme reduction process #36 by @hcvdwerf in #48

## [v1.0.0] - 2024-01-30

### Added

- ckanext-scheming v3.0.0.
- ckanext-dcat v1.5.1.
- ckanext-harvest v1.5.6.
- ckanext-gdi-userportal v1.0.0.
- ckanext-oidc-pkce v0.3.1.
- minimal default scheming for GDI User Portal.

### Removed

- Unused datastore dependencies.

### Fixed

- Replaced all non-GDI extension locations by their original ones.
