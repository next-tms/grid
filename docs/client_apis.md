# Client APIs

Grid copies the wire formats of the provider APIs. A client that has a Google or Smarty integration can point it at Grid and keep its code. Grid answers every format from the same provider priority in [address_sources.md](address_sources.md), so the client format and the upstream provider are independent.

Grid is single-tenant. Each company that runs Grid uses its own provider accounts, only for itself. Grid ignores the auth values that clients send, for example `key`, `auth-id`, and `auth-token`.

## Google

| Endpoint | Google API |
| --- | --- |
| `POST /v1:validateAddress` | Address Validation API |
| `GET /v1/places/{placeId}` | Places API (New), Place Details |
| `GET /maps/api/timezone/json` | Time Zone API |

The `placeId` that Grid returns in the Google format is the Grid address ID with a `grid:` prefix, for example `grid:0193a8f2-7c4e-7b1a-9f3d-2e5c8b6a4d10`. Place Details also takes a Google place ID without the prefix, if Grid stored that ID for an address. Otherwise it returns `NOT_FOUND`.

## Smarty

| Endpoint | Smarty API | Inputs |
| --- | --- | --- |
| `GET /street-address` | US Street API | `addressee`, `city`, `input_id`, `lastline`, `match`, `secondary`, `state`, `street`, `street2`, `zipcode` |
| `GET /lookup` | US ZIP Code API | `input_id`, `zipcode` |

Each Smarty API has its own host, so a client sets one base URL per API. POST batches, city and state ZIP lookups, and more than one candidate are not built.

If the Smarty provider answered the lookup, Grid returns the Smarty response unchanged. If another provider answered, Grid builds the response from the stored result. Then Grid returns only the fields that it knows, and leaves out the others, for example `delivery_point_barcode`, `smarty_key`, and the county fields.

The default match mode is `strict`. In this mode, the US Street endpoint returns `[]` unless the DPV match code is `Y`, `S`, or `D`. In `invalid` and `enhanced` mode, it always returns one candidate.

The US ZIP Code endpoint returns a `blank` status for an empty ZIP code. It returns an `invalid_zipcode` status for a malformed ZIP code or a ZIP code that no provider knows.

## GraphQL

`GET /graphql` and `POST /graphql` take `query`, `variables` (JSON), and `operationName`, as in the [GraphQL over HTTP](https://graphql.github.io/graphql-over-http/) specification. Grid rejects a mutation sent by GET with `405 Method Not Allowed`.

| Query | Returns |
| --- | --- |
| `verifyAddress(address: AddressInput!)` | `addressId`, `addressLines`, `administrativeArea`, `authority`, `business`, `dock`, `expiresAt`, `locality`, `location`, `places`, `poBox`, `postalCode`, `residential`, `timeZone`, `verified` |
| `fetchPlace(id: IdentifierInput!)` | One `Place`: `authority`, `expiresAt`, `freightKitLocationTypes`, `id`, `name`, `permanentlyClosed`, `provider`, `types` |
| `fetchPlaces(address: AddressInput!)` | A list of `Place` |
| `fetchTimeZone(address: AddressInput, id: String, location: LocationInput)` | One `TimeZone`: `authority`, `expiresAt`, `id` |
| `fetchTimeZones(name: String, regionCode: String)` | A list of `TimeZone` |
| `overturePlaces(filter: OverturePlaceFilterInput, sort: [OverturePlaceSort!], first: Int, after: String)` | A page of `OverturePlace`. See [Overture Places Search](#overture-places-search). |

`AddressInput` uses the field names of `google.type.PostalAddress`: `addressLines`, `administrativeArea`, `locality`, `postalCode`, and `regionCode`. Each query returns `null` when Grid has no answer, for example an unknown country or place.

`Location` and `LocationInput` have `latitude` and `longitude` in degrees. `Location` also has `authority`, `granularity`, and `plusCode`. `granularity` tells how precise a geocode is, from `SUB_PREMISE` (a unit) through `PREMISE`, `PREMISE_PROXIMITY` (near the address, for example a business point), `BLOCK`, and `ROUTE`, to `OTHER` (a postal code or a city). `plusCode` is the [Plus Code](https://maps.google.com/pluscodes/) of the point, for example `849VCWC7+XQ`. Grid calculates the Plus Code itself, so it calls no provider. `LocationInput` takes either `latitude` and `longitude` or `plusCode`. A Plus Code must be a full code, such as `849VCWC7+XQ`. Grid uses the center of its area, which is about 14 by 14 meters. A short code, such as `CWC7+XQ Mountain View`, needs a reference place, so Grid does not accept it. `fetchTimeZone` takes exactly one of its arguments. With an address, Grid verifies it first. If the verification has a time zone, for example from Smarty, Grid uses it. If not, Grid asks the time zone providers at the geocoded point. With a location, Grid asks the time zone providers. With an IANA name, for example `America/Chicago`, Grid answers from tzdata.

`fetchTimeZones` searches tzdata by name and by country. A name matches part of an IANA name, an Active Support name such as "Pacific Time (US & Canada)", or a current abbreviation such as `PST`. Answers from tzdata call no provider, so their `authority` and `expiresAt` are `null`.

`authority` on a `Place`, a `Location`, or a `TimeZone` is the authority level of its provider, from [address_sources.md](address_sources.md). For `verifyAddress`, Grid combines its sources to get the most accurate answer, and `authority` is an `AuthorityRange` of the sources of the address fields:

- `highest`: the authority of the best source.
- `lowest`: the authority of the weakest source. Rank Grid's answer against other providers by this level.
- `quality`: a number from 0 to 1, like an HTTP q-value (RFC 9110, section 12.4.2), where 1 is the best. Each level has a value: `POSTAL_OPERATOR` 1.0, `GOVERNMENT` 0.8, `CERTIFIED` 0.6, `OPEN_DATA` 0.4, `COMMERCIAL` 0.2, and `LOCAL` 0.0. `quality` is the average of the values of `highest` and `lowest`, rounded to three decimal places.

When `highest` and `lowest` differ, the answer mixes strong and weak data. For example, Overture verifies an address and gives the city, but it has no standardized street lines, so the lines come from the Grid normalizer: `highest` is `OPEN_DATA`, `lowest` is `LOCAL`, and `quality` is 0.2. If no provider verified the address, every field comes from the normalizer, so both levels are `LOCAL`. See [Normalization](address_sources.md#normalization). The range does not include the geocode, because `location.authority` gives its level. `expiresAt` is the time when the first stored result in the answer expires, or `null` for a `LOCAL` answer. `verified` is true when an official source confirms the address. An official source is a `GOVERNMENT` or `POSTAL_OPERATOR` provider, or the postal delivery data that Smarty returns. The Google format sends `addressComplete` by the same rule. `dock` is true when the building has a loading dock, false when it has none, and null when Grid does not know. Today it comes only from OpenStreetMap, so it is true or null for almost every address. See [Loading Docks](address_sources.md#loading-docks).

One address can have many places, for example the businesses in one building. `addressId` and each place `id` are Grid IDs, not provider IDs. A Grid ID is a UUIDv7. Grid stores the provider ID of each place, for example a Google Place ID, so a place keeps its Grid ID when Grid fetches it again.

`types` holds the place types in the vocabulary of the provider, unchanged: Google types such as `cafe`, Overture categories such as `coffee_shop`, or OpenStreetMap tags such as `amenity=cafe`. `freightKitLocationTypes` holds the same place in FreightKit's vocabulary. Each value is the location in the FreightKit accessorials `<type>_delivery` and `<type>_pickup`, for example `RESTAURANT` for `restaurant_delivery`. A more specific source type maps to the FreightKit type that covers it, so a coffee shop is a `RESTAURANT`. `config/freight_kit_location_types.yml` holds the mapping for each provider. A source type without a mapping only appears in `types`.

`IdentifierInput` has a `value` and an optional `provider`. Without `provider`, `value` is a Grid ID. With `provider`, for example `{ value: "ChIJ...", provider: GOOGLE }`, `value` is that provider's ID, and Grid finds the place from its stored provider IDs. `fetchPlace` returns `null` for a provider ID that Grid has not stored. `places` and `fetchPlaces` come from the first business details provider that returns places at the address, and they are empty when no provider does or when the address is residential. Google terms do not let Grid store the name, types, or status of a Google place, so Grid asks Google for them on each request, and their `expiresAt` is the time of that request. A client must not store them either. It can tell them apart by `provider: GOOGLE`. See [Places](address_sources.md#places).

## Overture Places Search

`overturePlaces` searches the Overture places file, for example for all restaurants in one state. It reads only the Overture file, because the provider APIs do not allow this kind of search. Google Text Search stops after 60 results and charges for each request, and the OpenStreetMap usage policy forbids bulk queries. Each result is an `OverturePlace` with the Overture data unchanged: `id` (the Overture ID), `name`, `basicCategory`, `primaryCategory`, `operatingStatus`, and `types`. It also has `freightKitLocationTypes`, `permanentlyClosed`, `authority` (`OPEN_DATA`), and `location`. The address fields use the Grid names: `addressLines`, `administrativeArea`, `locality`, `postalCode`, and `regionCode`. Grid does not store these places, so they have no Grid ID.

The query is a [GraphQL connection](https://relay.dev/graphql/connections.htm). A client asks for a page with `first`, and for the next page with `after` set to `pageInfo.endCursor`. `pageInfo.hasNextPage` is false on the last page. `first` is 20 by default and 100 at most. Grid returns 100 items when a client asks for more. `totalCount` is the number of matches in all pages. Grid counts them only when the query asks for `totalCount`, because a count of a large match, such as all places in a state, takes time.

```graphql
query {
  overturePlaces(first: 100, filter: { regionCodeEq: "US", administrativeAreaEq: "CA", freightKitLocationTypesIn: [RESTAURANT] }) {
    totalCount
    pageInfo { endCursor hasNextPage }
    nodes { id name freightKitLocationTypes locality postalCode location { latitude longitude } }
  }
}
```

`filter` has one argument for each field and predicate, in the form of [Ransack](https://activerecord-hackery.github.io/ransack/) predicates, for example `localityEq`, `postalCodeStart`, `nameCont`, and `latitudeGteq`. The text fields have `Cont`, `End`, `Eq`, `In`, `NotEq`, `NotIn`, `Null`, and `Start`. `latitude` and `longitude` have `Gt`, `Gteq`, `Lt`, and `Lteq`, so four of them make a box around a point. A place must match all the arguments. `or` takes a list of filters, and a place must match at least one of them. `freightKitLocationTypesIn` matches the Overture basic categories that `config/freight_kit_location_types.yml` maps to the types. A type without Overture categories, for example `MOTEL`, matches nothing. Grid ignores an empty list, for example `localityIn: []`.

`sort` takes a list such as `[ADMINISTRATIVE_AREA_ASC, NAME_ASC]`. Grid always sorts by the Overture ID last, so the pages are stable.

The file has indexes on the category with the country and state, on the country with the postal code, on the country, state, and city, and on the point. A filter that uses one of them, for example a state with a category, is fast. When a filter has a `latitude` argument at the top level, Grid always uses the point index, because SQLite cannot estimate how few places a box holds. On the full US file, a box with a category took 0.01 seconds, the 100 places after the first 170,000 restaurants in California took about 1 second, and `totalCount` for those restaurants took about 4 seconds. A filter without one, for example only `nameCont`, reads the whole file for `totalCount` and for a rare match. The places file has US places only.

## Caching Headers

Grid adds HTTP caching headers to the GET endpoints, even though Google and Smarty do not send them. Clients that do not read the headers get the same body as before. Grid does not add the headers to POST requests, because HTTP clients do not cache POST responses. A GraphQL response gets the headers only if it has no errors and every query in it has an answer.

- `Cache-Control: max-age=<seconds>, public`: the time until the first stored provider result in the answer expires. Grid uses no API keys, so shared caches can keep the response.
- `Last-Modified`: the time when Grid last fetched a provider result in the answer.
- `ETag`: an ID of the stored results in the answer. If a client sends it back in `If-None-Match` and the results did not change, Grid returns `304 Not Modified` with no body.

If the answer has content that a provider does not let Grid store, for example a Google place name, Grid sends `Cache-Control: no-store` and no `Last-Modified`, and clients must not cache the response.

The Place Details endpoint also sends `Vary: X-Goog-FieldMask`, because the field mask changes the body. Error responses, an empty answer, and the `blank` and `invalid_zipcode` ZIP statuses keep the Rails default, `Cache-Control: max-age=0, private, must-revalidate`.
