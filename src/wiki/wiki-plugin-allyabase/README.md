# Federated Wiki - allyabase plugin

allyabase is a Backend as a Service (BaaS) similar to Firebase and Supabase except it is open, and interoperable with other systems that utilize the [Sessionless] protocol.
allyabase has many features, but the few that are exposed at this time in wiki are enable the signing of smart contracts, and the subsequent creation and/or transfer of nineum tokens upon completed parameters from the contracts.

## Configuration

### Required Environment Variables

The allyabase plugin requires the following environment variables to be set:

- **ADDIE_STRIPE_URL** (required): The URL for the Addie Stripe payment processing service. This must be set for the allyabase instance to start. No default value is provided.

Example configuration:
```bash
export ADDIE_STRIPE_URL=https://addie.planetnine.app
```

If `ADDIE_STRIPE_URL` is not set, the plugin will fail to start with an error message.

## API Routes

To facilitate this, the plugin exposes the following routes to the client:

<details>
 <summary><code>GET</code> <code><b>/plugin/allyabase/user/:pubKey</b></code> <code>Gets an existing user by public key</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | pubKey       |  true     | string (hex)            | the publicKey of the user's keypair  |


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `USER`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

</details>

<details>
 <summary><code>GET</code> <code><b>/plugin/allyabase/bdo</b></code> <code>Gets the user's BDO</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | pubKey       |  true     | string (hex)            | the publicKey of the user's keypair  |


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `USER`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

</details>

<details>
 <summary><code>PUT</code> <code><b>/plugin/allyabase/bdo</b></code> <code>Puts a new bdo or updates the bdo for the user</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | pubKey       |  true     | string (hex)            | the publicKey of the user's keypair  |
> | bdo          |  true     | object                  | the signature from sessionless for the message  |


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `USER`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

</details>

<details>
 <summary><code>POST</code> <code><b>/plugin/allyabase/grant-nineum</b></code> <code>grants a nineum to a user. Requires the wiki owner to have an admin or galactic nineum</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | toUUID       |  true     | string (hex)            | the uuid of the user to grant the nineum  |
> | flavor       |  true     | string (hex)            | the flavor of nineum to grant |


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `USER`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

</details>

<details>
 <summary><code>POST</code> <code><b>/plugin/allyabase/grant-admin-nineum</b></code> <code>grants an admin nineum to a user</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | toUUID       |  true     | string (hex)            | the uuid of the user to grant the nineum  |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `USER`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

</details>

<details>
 <summary><code>POST</code> <code><b>/plugin/allyabase/transfer</b></code> <code>transfer nineum to another user</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | toUUID       |  true     | string (hex)            | the uuid of the user to grant the nineum  |
> | nineum       |  true     | array of nineum hex strings | the nineum to transfer |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `USER`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

</details>

<details>
 <summary><code>GET</code> <code><b>/plugin/allyabase/sign/:thing</b></code> <code>creates a signature from the thing to sign</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | thing        |  true     | string                  | the uuid of the user to grant the nineum  |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `{signature: <signature>}`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

</details>

<details>
 <summary><code>GET</code> <code><b>/plugin/allyabase/verify</b></code> <code>verifies a signature</code></summary>

##### Parameters

> | name         |  required     | data type               | description                                                           |
> |--------------|-----------|-------------------------|-----------------------------------------------------------------------|
> | signature    |  true     | string (hex)            | the signature to verify  |
> | message      |  true     | string                  | the message to check |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `application/json`                | `USER`   |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`
|

</details>

## License

MIT

[Sessionless]: https://github.com/freyja-love-and-magic/sessionless

