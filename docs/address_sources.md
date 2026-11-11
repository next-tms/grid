# Address Sources

This document lists the address sources that Grid uses or can use later. It ranks each source by its authority. Authority is how close the source is to the organization that assigns addresses.

## Roles

Each adapter declares every role that its data supports, so any mix of enabled providers still gives useful answers. The authority order decides which answer wins, not which provider can answer.

| Role | Answers | Endpoint |
| --- | --- | --- |
| `business_details` | Place types and open or closed status | `GET /v1/places/{placeId}` |
| `dock` | Whether the building has a loading dock | GraphQL `verifyAddress` only |
| `geocode` | Latitude and longitude | `POST /v1:validateAddress` |
| `time_zone` | IANA time zone name and offsets | `GET /maps/api/timezone/json` |
| `verification` | Standardized address, deliverability, residential or business | `POST /v1:validateAddress` |

Google never verifies addresses in Grid, because its verification is weak. It geocodes only from the coordinates that the place search already returns.

## Authority Levels

Each adapter declares one authority level and one cost tier. Grid asks the enabled providers in authority order, from the most official to the least official. Between providers at the same level, Grid asks the cheaper provider first. The cost tiers are `free`, `low`, `medium`, and `high`, by list price for each lookup. A provider that reads a file or a free API is `free`, Smarty is `low`, and Google is `high`. `GRID_PROVIDERS` sets which providers are enabled. If a provider in `GRID_PROVIDERS` has no credentials, for example no `SMARTY_AUTH_ID`, Grid leaves it out and logs one warning. The order of `GRID_PROVIDERS` only breaks ties between providers with the same level and the same cost tier.

When Grid has a verification and a geocode for an address, it stops. Grid also skips a provider when every role that the provider can add is already answered. For example, if Smarty returns a city and state for a ZIP code but no coordinates, Grid asks GeoNames for the coordinates. If OpenStreetMap geocodes an address, Grid does not call Google for a second geocode. Grid asks OpenStreetMap for the `dock` role even after another provider verifies and geocodes the address, because no other provider has dock data.

1. `postal_operator`: the national postal service, or its official API.
2. `government`: a national address register that a government agency keeps.
3. `certified`: a commercial service that a postal operator certifies. Smarty is CASS-certified and returns DPV (Delivery Point Validation) data.
4. `open_data`: a community or open dataset, for example OpenStreetMap or OpenAddresses.
5. `commercial`: a commercial service with no postal certification, for example Google.
6. `local`: Grid's own normalizer. It is not a provider and calls no API.

## Normalization

Grid normalizes every address before it asks a provider, even when a provider is enabled. The normalizer makes the text uppercase and removes punctuation and extra spaces. For the US and its territories, it also applies the abbreviations of [USPS Publication 28](https://pe.usps.com/text/pub28/welcome.htm): street suffixes such as `PKWY`, directionals such as `N`, secondary unit designators such as `STE`, and state codes. It abbreviates a word only in the position where Publication 28 uses the abbreviation, so `100 NORTH ST` keeps `NORTH` as the street name. It never removes a word, so two different addresses never get the same key.

The normalized address is the key of the Grid address. Two spellings of one address, for example `1600 amphitheatre parkway` and `1600 Amphitheatre Pkwy.`, share one Grid address and one `addressId`. The normalizer does not know city aliases, for example `MTN VIEW` for `MOUNTAIN VIEW`, because only providers have that data.

For each answer, Grid uses the best source among the enabled providers. A stored result from a provider that is not enabled is ignored, but it is kept until it expires. So if you disable Smarty, Grid answers from the normalizer with authority `local`. If you enable Smarty again, Grid uses the stored Smarty result if it has not expired, or asks Smarty again. Without any provider, `verifyAddress` still answers, with authority `LOCAL`, no `expiresAt`, and `verified` false.

When a provider returns its own ID for an address, Grid stores it in `provider_identifiers`, for example the Smarty `smarty_key`. Each provider ID belongs to one Grid address. If a second Grid address gets the same provider ID, Grid keeps the ID on the first address only.

`config/usps_publication_28.yml` holds the tables. They come from the [StreetAddress](https://github.com/street-address-rb/street-address) gem, which copies them from Publication 28. The gem is under the MIT license, copyright (c) 2007-2026 Derrek Long and Contributors. The secondary unit designators come directly from Publication 28, appendix C2.

## Current Providers

| Provider | Key | Country | Lookups | Roles | Authority | Cache |
| --- | --- | --- | --- | --- | --- | --- |
| Smarty US Street API | `smarty` | US and territories | Street address, with the IANA time zone | `geocode`, `time_zone`, `verification` | `certified` | 90 days |
| Smarty US ZIP Code API | `smarty` | US and territories | ZIP code to city, state, and coordinates | `geocode`, `verification` | `certified` | 90 days |
| GeoNames | `geo_names` | All | Postal code to place and coordinates from the GeoNames file, and coordinates to time zone from the API or the file | `geocode`, `time_zone`, `verification` | `open_data` | 90 days |
| Overture Maps Places | `overture` | US | Places at a street address, with their city, state, and coordinates | `business_details`, `geocode`, `verification` | `open_data` | 1 day |
| OpenStreetMap Nominatim | `open_street_map` | All | Street address or postal code to coordinates, named businesses at the address, and loading docks | `business_details`, `dock`, `geocode` | `open_data` | 90 days |
| Google Places API (New) Text Search | `google` | All | Places at a street address, with their coordinates | `business_details`, `geocode` | `commercial` | Place IDs only |

A lookup that has a street line goes to the street APIs. A lookup that has only a postal code goes to the postal code APIs. Smarty asks for the IANA time zone (`features=iana-timezone`), so an address that Smarty verifies needs no second time zone lookup. Overture verifies an address when at least one place in the file has the same street and ZIP code. Its granularity is `PREMISE`, and `verified` stays false because Overture is not an official source. Overture and Google give a geocode near the address (`PREMISE_PROXIMITY`) when they find only businesses. The `fake` provider exists only in development and test. It accepts every street address as valid, at fixed coordinates.

Caching limits:

- Smarty: the [Subscription Agreement](https://www.smarty.com/legal/terms-of-service) lets you keep output data as the Sales Order permits (section 2.5). You must delete rooftop geocodes within 30 days after the subscription ends, unless you buy a retention right (section 6.6). Do not use output data to construct independent datasets (section 7.2.5).
- GeoNames: the data is CC BY 4.0. Give attribution to GeoNames where Grid shows its data. The GB postal codes also carry the notice "Contains Royal Mail data © Royal Mail copyright and database right". The free API account allows 10,000 credits a day and 1,000 an hour. Grid uses the API only for time zones and, without the file, for postal codes. Without a username, Grid finds time zones in the file.
- Google: the [Service Specific Terms](https://cloud.google.com/maps-platform/terms/maps-service-terms) let you store place IDs with no time limit, and coordinates for up to 30 days. Do not store other Places content, for example names, types, or business status. So Grid stores only the place IDs, and it does not store the coordinates either, and asks Google again for the content each time. A Google answer has an `expiresAt` equal to its fetch time, and HTTP responses get `max-age=0`.
- OpenStreetMap: the data is ODbL. Give attribution to OpenStreetMap where Grid shows its data. The [public Nominatim server](https://operations.osmfoundation.org/policies/nominatim/) allows one request a second and no heavy use. For production, run your own Nominatim server and set `NOMINATIM_URL`.
- Overture: places from Foursquare are Apache 2.0, and all other places are CDLA Permissive 2.0. Both licenses let Grid keep the data.

## Places

Grid asks the `business_details` providers in authority order, so the open data providers come before Google. OpenStreetMap returns a place for each result that has a name and the same street number as the address, and that has a business category such as `amenity`, `office`, or `shop` or a tag with a FreightKit location type, such as `military=base`. Its types are the OpenStreetMap tag, for example `office=it`. Grid calls Google only when no open data provider has places at the address. Grid skips all place lookups for an address that an enabled provider marks as residential, for example by the Smarty RDI (residential delivery indicator). These two rules keep the number of paid Google calls low.

## Loading Docks

Only OpenStreetMap has loading dock data. A mapper marks a dock as a point tagged [`amenity=loading_dock`](https://wiki.openstreetmap.org/wiki/Tag:amenity%3Dloading_dock) on the outline of the building, and Nominatim gives the point the address of the building. So the Nominatim search that Grid already sends returns the dock points with the building, and Grid needs no other request. `dock` is true when a result is a dock point with the same street number. It is false when the building has the tag `loading_dock=no`, which Grid reads from the Nominatim `extratags`. In other cases, `dock` is null, which means unknown. OpenStreetMap has about 42,000 dock points in the world, so most addresses get null. Grid reads `dock` only for a geocode at the `PREMISE` level, not for a street or a city.

Grid does not use the public Overpass API, which can find the docks on any building. Its servers say that they are for browser-based and human-operated tools, and that automated use needs its own server.

Google bills each Text Search by the most expensive field in the field mask. Grid asks for `businessStatus`, `displayName`, `formattedAddress`, `id`, `location`, and `types`, which is the Text Search Pro SKU. The `location` field is in the same SKU, so the coordinates cost nothing extra. Grid keeps only the results whose `formattedAddress` contains every number in the first address line. A result with the type `premise`, `street_address`, or `subpremise` is the address itself, so Grid stores its ID as the Google ID of the address and does not return it as a place.

## Data Files

Some providers read a SQLite file that ships in the Docker image, in `/usr/share/grid/`, instead of calling an API. Grid opens each file read-only as its own database. It does not import the rows into Postgres, and it never changes a file at runtime. Each file keeps the columns of its source, as the source names them.

## Overture Places File

The Overture provider reads `/usr/share/grid/overture.sqlite3` through the `Overture::Place` model. The file keeps the Overture columns, for example `basic_category` and `operating_status`. It adds one column, `address_key`, with an index. It also has indexes for the `overturePlaces` search, from `Overture::Schema::INDEXES`. Grid finds the places at an address by this key: the first normalized address line, the postal code without a ZIP+4, and the country code, for example `1600 AMPHITHEATRE PKWY, 94043, US`.

Overture publishes the places as Parquet files, a column-based file format, on S3. Parquet has no index for a lookup by one address, and Overture has no normalized address key. So the build task uses the [DuckDB](https://duckdb.org) command line tool to read only the US rows and the columns that Grid needs. Then the task computes the key for each place and writes the rows to the file through ActiveRecord. DuckDB is necessary only to build the file, so it is not in the Docker image.

## GeoNames File

The GeoNames provider reads `/usr/share/grid/geo_names.sqlite3` through the `GeoNames::PostalCode` and `GeoNames::City` models. The `postal_codes` table has the 12 columns of the [GeoNames postal code files](https://download.geonames.org/export/zip/readme.txt), for example `place_name` and `admin_code1`, with an index on `country_code` and `postal_code`. It has about 5 million rows.

The `cities` table has each place with at least 500 people from the [GeoNames `cities500.zip` file](https://download.geonames.org/export/dump/readme.txt), with its coordinates and IANA time zone. It has about 230,000 rows, with an index on `latitude` and `longitude`. To find the time zone of a point without the API, Grid uses the time zone of the nearest city. It searches a box of 0.25 degrees around the point first, then 1 degree, then 4 degrees. Near a time zone border, the nearest city can be in the other zone. So if `GEONAMES_USERNAME` is set, Grid asks the API instead, because the API uses the zone boundaries.

`allCountries.zip` has only the first part of the postal codes for Canada, the United Kingdom, and the Netherlands. So the build task also reads `CA_full.csv.zip`, `GB_full.csv.zip`, and `NL_full.csv.zip`. A lookup tries the full code first, with a space before the last part, for example `T2P 1J9` for `T2P1J9`. Then it tries the first part, for example `T2P`. The build takes about five minutes and needs `unzip`. GeoNames changes the files every day, so the release name is the month, for example `2026-11`, and the file is built again each month.

Without the file, the provider uses the GeoNames API for postal codes and time zones, if `GEONAMES_USERNAME` is set.

## Schema Version

Each data file has a schema version: a short hash of the files that decide its tables and, for Overture, its address key. For Overture, these files are `app/services/address_key.rb`, `app/services/address_normalizer.rb`, `app/services/overture/schema.rb`, and `config/usps_publication_28.yml`. For GeoNames, the file is `app/services/geo_names/schema.rb`. The build task writes the release name and the schema version to the `releases` table of the file.

Grid uses a file only if its schema version matches the version of the running code, and the file is not empty. If you change the normalizer, an old Overture file has keys that no longer match, so lookups would find nothing. Instead, Grid skips the provider and logs one warning until you build a new file.

## Data Image

The data files ship in one Docker image, `ghcr.io/next-tms/grid-data`, on the GitHub container registry. The image holds only the files, in `/data/`. The Grid Dockerfile copies each file to `/usr/share/grid/` from the image that the `DATA_IMAGE` build argument names. Without the argument, the Dockerfile uses empty files, and Grid skips the providers that need them. To add a data file, add it to `DataImage::DATASETS` and add one `COPY` line to the Dockerfile.

Docker stores each file as its own layer, and identifies the layer by its content. The data image and the Grid Dockerfile use `COPY --link`, so a layer does not depend on the layers before it. So when only the GeoNames file changes, the Overture layer keeps its digest, and neither GitHub nor Fly moves those bytes again.

The data image has two tags. `latest` is the newest image. The data version, for example `8cd9f35f59b2`, is a hash of the schema versions of all files, and it points to the newest image for those schema versions. `bin/rails data:version` prints it. Labels on the image record the release and the schema version of each file, for example `com.next-tms.grid-data.overture.release`.

These GitHub Actions workflows keep the image current:

- `data.yml` runs every day, after a push to `main` that changes a schema file, and on demand. It reads the labels of `latest`, the newest Overture release on S3, and the current month for GeoNames. `bin/rails data:plan` then lists the files to build again and writes the Dockerfile of the image. That Dockerfile copies each unchanged file from `latest`. If any file changed, the workflow builds it, pushes the image, and deploys Grid. An Overture build takes more than two hours, and a GeoNames build takes about five minutes.
- `push.yml` deploys Grid after each push to `main`. It looks up the image for the data version of the code and passes its digest as `DATA_IMAGE`. If no image exists yet, for example while `data.yml` builds after a schema change, it deploys without the data and shows a warning. The deploy at the end of `data.yml` adds the data again.
- `checks.yml` runs `bin/ci` on each push to a branch other than `main`, and before each deploy.

GitHub turns off a scheduled workflow after 60 days without activity in the repository. If that happens, enable `data.yml` again on the Actions page. The first push creates the `grid-data` package. Make sure that the package is public, because Fly's builder pulls it without a token.

## Data Files in Development

In development, Grid reads `db/geo_names.sqlite3` and `db/overture.sqlite3`. Git and Docker ignore them. A file can be an old release, but it must have the schema version of your code.

`docker compose up` mounts `db/` read-only at `/usr/share/grid/`, so the production image in Compose uses your local data files too.

To copy the files from the newest image, run these commands with Docker:

```sh
docker create --name grid-data "ghcr.io/next-tms/grid-data:$(bin/rails data:version)" none
docker cp grid-data:/data/geo_names.sqlite3 db/geo_names.sqlite3
docker cp grid-data:/data/overture.sqlite3 db/overture.sqlite3
docker rm grid-data
```

To build the files on your computer instead, run the build tasks. For Overture, install DuckDB first, for example with `brew install duckdb`, and use the release name from the [Overture release page](https://docs.overturemaps.org/release/latest/):

```sh
bin/rails geo_names:build
bin/rails "overture:build[2026-10-22.0]"
```

If you already downloaded the source files, set `SOURCE` to their folder or path, for example `SOURCE='/data/places/*.parquet'` for Overture. For GeoNames, the folder must have the same `dump/` and `zip/` folders as the download site. Without a file, Grid skips the provider that needs it, or GeoNames uses its API.

## Official and Government Sources to Evaluate

This list records candidates only. Before you build an adapter, make sure that the license allows Grid's use, and record its caching limit in the adapter.

| Country | Source | Operator | Authority | Access | Notes |
| --- | --- | --- | --- | --- | --- |
| AU | G-NAF | Geoscape Australia | `government` | Open dataset (CC BY 4.0 based) and a paid API | You cannot use the open data to generate addresses or to compile lists. The terms say that G-NAF alone is not suitable for mail. |
| BR | API Busca CEP | Correios | `postal_operator` | Commercial contract required | Only customers with a Correios contract can use it. |
| CA | AddressComplete | Canada Post | `postal_operator` | Paid API key | Find and Retrieve methods. |
| FR | Base Adresse Nationale | IGN | `government` | Free API and downloads | House-number level. It has no unit or floor data. |
| GB | Postcode Address File | Royal Mail | `postal_operator` | Paid license | No public API. Resellers and Ordnance Survey license it. |
| MX | Catálogo Nacional de Códigos Postales | Correos de México | `postal_operator` | Free download | Postal codes only. The terms forbid commercial use and redistribution. |

Nobody has made sure of the Netherlands (BAG), New Zealand (LINZ), or other national registers yet.

## Sources

- [AddressComplete web services](https://www.canadapost-postescanada.ca/ac/support/api/)
- [Base Adresse Nationale](https://www.data.gouv.fr/datasets/base-adresse-nationale)
- [Correios API Busca CEP manual](https://www.correios.com.br/atendimento/developers/manuais/manual-api-busca-cep)
- [G-NAF use restriction fact sheet](https://www.data.gov.au/data/dataset/geoscape-geocoded-national-address-file-g-naf-previous-versions/resource/49404ddd-377d-432d-b9ee-84ec7f264eef)
- [Mexico postal code catalog (community mirror)](https://github.com/d3249/mexico_zipcodes)
- [PAF licensing](https://www.poweredbypaf.com/about-paf-licencing/)
