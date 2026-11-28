# Grid

Grid is an address and business classification service. It verifies and geocodes addresses, finds the businesses at an address, and finds the time zone of a place. Grid asks a set of providers for each answer, keeps the best answer, and stores it for the next request.

## Providers

A provider is an external source of address data, for example an API or a data file. You enable providers with `GRID_PROVIDERS`. Grid asks the enabled providers in order of authority, from the most official source to the least official. Between two providers with the same authority, Grid asks the cheaper provider first.

| Provider | Key | Countries | Roles | Authority | Cost |
| --- | --- | --- | --- | --- | --- |
| [GeoNames](https://www.geonames.org) postal codes and time zones | `geo_names` | All | Verification, geocode, time zone | `open_data` | Free |
| [Google](https://developers.google.com/maps/documentation/places/web-service/text-search) Places API (New) Text Search | `google` | All | Geocode, business details | `commercial` | High |
| [OpenStreetMap](https://www.openstreetmap.org) Nominatim | `open_street_map` | All | Geocode, business details, loading docks | `open_data` | Free |
| [Overture Maps](https://overturemaps.org) Places | `overture` | US | Verification, geocode, business details, place search | `open_data` | Free |
| [Smarty](https://www.smarty.com) US Street and US ZIP Code APIs | `smarty` | US and territories | Verification, geocode, time zone | `certified` | Low |

GeoNames and Overture are built in. Their data ships as SQLite files in the Docker image, so they need no credentials and no network. If `GEONAMES_USERNAME` is set, GeoNames also uses its API for time zones, because the API knows the time zone borders. The other providers call an external API.

Google never verifies addresses in Grid. Grid calls Google only when no open data provider has businesses at the address, and never for a residential address.

Some answers need no provider. Without any provider, Grid still answers from its own normalizer. The normalizer applies the abbreviations of USPS Publication 28, but it does not verify that the address exists. Grid finds time zones by IANA name in tzdata, and countries in the ISO 3166 data of the `countries` gem. It also calculates the Plus Code of each point itself.

Each provider has its own terms for caching and attribution. Grid follows them, for example it stores only the place IDs from Google. [Address Sources](docs/address_sources.md) gives the authority levels, the caching limits, and the providers that Grid can add later.

## Client APIs

Grid copies the wire formats of the Google and Smarty APIs. A client that already uses one of these APIs can change its base URL to Grid and keep its code. Grid also has a GraphQL API that shows all of its data.

Grid answers every client format from the same providers. So a client that sends the Smarty format can get an answer from GeoNames, and a client that sends the Google format can get an answer from Smarty.

| Endpoint | Format |
| --- | --- |
| `POST /v1:validateAddress` | Google Address Validation API |
| `GET /v1/places/{placeId}` | Google Places API (New), Place Details |
| `GET /maps/api/timezone/json` | Google Time Zone API |
| `GET /street-address` | Smarty US Street API |
| `GET /lookup` | Smarty US ZIP Code API |
| `POST /graphql` | Grid GraphQL API |

The GraphQL API has these queries:

| Query | Returns |
| --- | --- |
| `fetchCountries` | The ISO 3166 countries and their regions, with postal code formats |
| `fetchPlace` | One business by its Grid ID or its provider ID |
| `fetchPlaces` | The businesses at an address, or all businesses that match a filter, for example all restaurants in one state |
| `fetchTimeZone` | The time zone of an address, a point, or an IANA name |
| `fetchTimeZones` | The time zones that match a name or a country |
| `verifyAddress` | The verified address, its geocode, time zone, businesses, and loading dock |

GraphiQL, a browser editor for GraphQL queries, is at `/graphiql`. [Client APIs](docs/client_apis.md) gives the inputs, the fields, and the HTTP caching headers of each endpoint.

### Access

Grid has no authentication, and it ignores the API keys that clients send. Run it on a private network that only your own applications can reach. The provider accounts belong to the operator of Grid, and all callers share one cache. Do not give another company access to Grid, because the provider terms do not let you share or resell an account.

## Configuration

| Variable | Use |
| --- | --- |
| `DATABASE_URL` | The Postgres database |
| `GEONAMES_USERNAME` | GeoNames API account. Without it, GeoNames uses only the data file. |
| `GOOGLE_API_KEY` | Google credentials |
| `GRID_PROVIDERS` | The enabled providers, separated by commas, for example `geo_names,open_street_map,smarty` |
| `NOMINATIM_URL` | Your own Nominatim server. The public server allows one request a second. |
| `SECRET_KEY_BASE` | The Rails secret key |
| `SENTRY_DSN` | Optional error reporting |
| `SMARTY_AUTH_ID`, `SMARTY_AUTH_TOKEN` | Smarty credentials |

If an enabled provider has no credentials, Grid leaves it out and logs one warning. `.env.example` lists every variable.

## Development

Grid is a Rails application. It needs Ruby 4.0 and Postgres. To install the gems, prepare the database, and start the server, run this command:

```sh
bin/setup
```

The server listens on port 4743. The GeoNames and Overture providers read SQLite files in `db/`. [Data Files in Development](docs/address_sources.md#data-files-in-development) tells you how to copy them from the data image or build them.

To run the tests, RuboCop, and the security checks, run this command:

```sh
bin/ci
```

To run Grid and Postgres in Docker, run `docker compose up`. Compose builds the production image and mounts `db/` read-only for the data files.

## Deployment

Each push to `main` builds the image `ghcr.io/next-tms/grid` with the data files. The workflows do not deploy. You deploy the image to your own host. [Data Image](docs/address_sources.md#data-image) gives the details.

## License

Grid is free software under the [GNU Affero General Public License v3.0](LICENSE).
