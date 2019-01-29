module RemoteData.Http exposing
    ( get, post, put, patch, delete
    , Config, defaultConfig, noCacheConfig
    , noCache, acceptJson
    , getWithConfig, postWithConfig, putWithConfig, patchWithConfig, deleteWithConfig
    )

{-| Friendly abstraction over remote API communication in JSON.


# Commands

@docs get, post, put, patch, delete


# Additional configuration

@docs Config, defaultConfig, noCacheConfig

@docs noCache, acceptJson


# Commands with configuration

@docs getWithConfig, postWithConfig, putWithConfig, patchWithConfig, deleteWithConfig

-}

import Http exposing (Error, Header, Response)
import Json.Decode exposing (Decoder)
import Json.Encode
import RemoteData exposing (RemoteData(..), WebData)
import Task exposing (Task)


{-| Header that makes sure the response doesn't come from a cache.
Only relevant for GET requests.
-}
noCache : Header
noCache =
    Http.header "Cache-Control" "no-store, must-revalidate, no-cache, max-age=0"


{-| Header for explicitly stating we are expecting JSON back.
-}
acceptJson : Header
acceptJson =
    Http.header "Accept" "application/json"


{-| If you need more control over the request, you can use the
`<verb>WithConfig` function with a record like this.

    specialConfig : Config
    specialConfig =
        { defaultConfig | headers = [ specialHeader, anotherHeader ] }

    postCat : Cat -> Cmd Msg
    postCat cat =
        postWithConfig specialConfig "/api/cats/" HandlePostCat catDecoder (encodeCat cat)

-}
type alias Config =
    { headers : List Header
    , timeout : Maybe Float
    , tracker : Maybe String
    , risky : Bool
    }


{-| The default configuration for all requests besides `GET`:

  - accept application/json
  - no timeout
  - no tracker
  - not a risky request

-}
defaultConfig : Config
defaultConfig =
    { headers = [ acceptJson ]
    , timeout = Nothing
    , tracker = Nothing
    , risky = False
    }


{-| The default configuration for `GET` requests:

  - a `no-cache` header
  - accept application/json
  - without credentials
  - no timeout
  - no tracker
  - not a risky request

-}
noCacheConfig : Config
noCacheConfig =
    { defaultConfig | headers = noCache :: defaultConfig.headers }


{-| `GET` request as a command, with cache. _NB._ allowing cache in API `GET` calls can lead
to strange conditions.

    getWithConfig noCacheConfig "http://example.com/users.json" userDecoder
        == get "http://example.com/users.json" userDecoder

For a request without any headers, you can use:

    getWithConfig defaultConfig url decoder

-}
getWithConfig : Config -> String -> (WebData success -> msg) -> Decoder success -> Cmd msg
getWithConfig config url tagger decoder =
    request "GET" config url tagger decoder Http.emptyBody


{-| `GET` request as a command.
Has a `no-cache` header to ensure data integrity.

    type Msg
        = HandleGetCat (WebData Cat)

    getCat : Cmd Msg
    getCat =
        get "/api/cats/1" HandleGetCat catDecoder

-}
get : String -> (WebData success -> msg) -> Decoder success -> Cmd msg
get =
    getWithConfig noCacheConfig


performRequest { risky } =
    if risky then
        Http.riskyRequest

    else
        Http.request


request : String -> Config -> String -> (WebData success -> msg) -> Decoder success -> Http.Body -> Cmd msg
request method config url tagger decoder body =
    performRequest config
        { method = method
        , headers = config.headers
        , url = url
        , body = body
        , expect = Http.expectJson (RemoteData.fromResult >> tagger) decoder
        , timeout = config.timeout
        , tracker = config.tracker
        }


requestWithJson : String -> Config -> String -> (WebData success -> msg) -> Decoder success -> Json.Encode.Value -> Cmd msg
requestWithJson method config url tagger decoder body =
    request method config url tagger decoder (Http.jsonBody body)


{-| `POST` request as a command, with additional `Config`.

    postWithConfig defaultConfig == post

-}
postWithConfig :
    Config
    -> String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Encode.Value
    -> Cmd msg
postWithConfig =
    requestWithJson "POST"


{-| `POST` request as a command.

    type Msg
        = HandlePostCat (WebData Cat)

    postCat : Cat -> Cmd Msg
    postCat cat =
        post "/api/cats/" HandlePostCat catDecoder (encodeCat cat)

-}
post :
    String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Encode.Value
    -> Cmd msg
post =
    postWithConfig defaultConfig



----


{-| `PUT` request as a command, with additional `Config`.

    putWithConfig defaultConfig == putTask

-}
putWithConfig :
    Config
    -> String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Encode.Value
    -> Cmd msg
putWithConfig =
    requestWithJson "PUT"


{-| `PUT` request as a command.

    type Msg
        = HandlePutCat (WebData Cat)

    putCat : Cat -> Cmd Msg
    putCat cat =
        put "/api/cats/" HandlePutCat catDecoder (encodeCat cat)

-}
put :
    String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Encode.Value
    -> Cmd msg
put =
    putWithConfig defaultConfig



----


{-| `PATCH` request as a command, with additional `Config`.

    patchWithConfig defaultConfig == patchTask

-}
patchWithConfig :
    Config
    -> String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Encode.Value
    -> Cmd msg
patchWithConfig =
    requestWithJson "PATCH"


{-| `PATCH` request as a command.

    type Msg
        = HandlePatchCat (WebData Cat)

    patchCat : Cat -> Cmd Msg
    patchCat cat =
        patch "/api/cats/" HandlePatchCat catDecoder (encodeCat cat)

-}
patch :
    String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Encode.Value
    -> Cmd msg
patch =
    patchWithConfig defaultConfig



----


{-| `DELETE` request as a command, with additional `Config`.

    deleteWithConfig defaultConfig == deleteTask

-}
deleteWithConfig :
    Config
    -> String
    -> (WebData String -> msg)
    -> Json.Encode.Value
    -> Cmd msg
deleteWithConfig config url tagger body =
    performRequest config
        { method = "DELETE"
        , headers = config.headers
        , url = url
        , body = Http.jsonBody body
        , expect = Http.expectString (RemoteData.fromResult >> tagger)
        , timeout = config.timeout
        , tracker = config.tracker
        }


{-| `DELETE` request as a command, expecting a `String` response.

In many APIs, the response for successful delete requests has an empty
HTTP body, so decoding it as JSON will always fail. This is why `delete` and
`deleteTask` don't have a decoder argument. If you really want to decode the
response, use `Json.Decode.decodeString`.

    type Msg
        = HandleDeleteCat (WebData String)

    deleteCat : Cat -> Cmd Msg
    deleteCat cat =
        delete "/api/cats/" HandleDeleteCat (encodeCat cat)

-}
delete :
    String
    -> (WebData String -> msg)
    -> Json.Encode.Value
    -> Cmd msg
delete =
    deleteWithConfig defaultConfig
