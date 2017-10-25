module RemoteData.Http
    exposing
        ( Config
        , acceptJson
        , defaultConfig
        , delete
        , deleteTask
        , deleteTaskWithConfig
        , deleteWithConfig
        , get
        , getTask
        , getTaskWithConfig
        , getWithConfig
        , noCache
        , noCacheConfig
        , patch
        , patchTask
        , patchTaskWithConfig
        , patchWithConfig
        , post
        , postTask
        , postTaskWithConfig
        , postWithConfig
        , put
        , putTask
        , putTaskWithConfig
        , putWithConfig
        , url
        )

{-| Friendly abstraction over remote API communication in JSON.


# Commands

@docs get, post, put, patch, delete


# Tasks

@docs getTask, postTask, putTask, patchTask, deleteTask


# Additional configuration

@docs Config, defaultConfig, noCacheConfig

@docs noCache, acceptJson


# Commands with configuration

@docs getWithConfig, postWithConfig, putWithConfig, patchWithConfig, deleteWithConfig


# Tasks with configuration

@docs getTaskWithConfig, postTaskWithConfig, putTaskWithConfig, patchTaskWithConfig, deleteTaskWithConfig


# Helpers

@docs url

-}

import Http exposing (Error, Header, Response)
import Json.Decode exposing (Decoder, Value)
import RemoteData exposing (RemoteData(..), WebData)
import Task exposing (Task)
import Time


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


{-| Convert an apiCall `Task` to a `Cmd msg` with the help of a
tagger function (`WebData success -> msg`).
-}
toCmd : (WebData success -> msg) -> Http.Request success -> Cmd msg
toCmd tagger =
    Http.send (tagger << RemoteData.fromResult)


toTask : Http.Request success -> Task Never (WebData success)
toTask request =
    request
        |> Http.toTask
        |> Task.map Success
        |> Task.onError (Task.succeed << Failure)


request :
    Config
    -> String
    -> String
    -> Decoder success
    -> Http.Body
    -> Http.Request success
request config method url successDecoder body =
    Http.request
        { method = method
        , headers = config.headers
        , url = url
        , body = body
        , expect = Http.expectJson successDecoder
        , timeout = config.timeout
        , withCredentials = config.withCredentials
        }


{-| If you need more control over the request, you can use the
`<verb>WithConfig` function with a record like this.

    specialConfig : Config
    specialConfig =
        { headers = [ specialHeader, anotherHeader ]
        , withCredentials = True
        , timeout = Nothing
        }

    postCat : Cat -> Cmd Msg
    postCat cat =
        postWithConfig specialConfig "/api/cats/" HandlePostCat catDecoder (encodeCat cat)

-}
type alias Config =
    { headers : List Header
    , withCredentials : Bool
    , timeout : Maybe Time.Time
    }


{-| The default configuration for all requests besides `GET`:

  - accept application/json
  - without credentials
  - no timeout

-}
defaultConfig : Config
defaultConfig =
    { headers = [ acceptJson ]
    , withCredentials = False
    , timeout = Nothing
    }


{-| The default configuration for `GET` requests:

  - a `no-cache` header
  - accept application/json
  - without credentials
  - no timeout

-}
noCacheConfig : Config
noCacheConfig =
    { defaultConfig | headers = noCache :: defaultConfig.headers }


getRequest : Config -> String -> Decoder success -> Http.Request success
getRequest config url decoder =
    request config "GET" url decoder Http.emptyBody


{-| `GET` request as a task, with additional `Config`. _NB._ allowing cache in API `GET` calls can lead
to strange conditions.

    getTaskWithConfig noCacheConfig "http://example.com/users.json" userDecoder
      == getTask "http://example.com/users.json" userDecoder

For a request without any headers, you can use:

    getTaskWithConfig defaultConfig url decoder

-}
getTaskWithConfig : Config -> String -> Decoder success -> Task Never (WebData success)
getTaskWithConfig config url decoder =
    getRequest config url decoder
        |> toTask


{-| `GET` request as a command, with cache. _NB._ allowing cache in API `GET` calls can lead
to strange conditions.

    getWithConfig noCacheConfig "http://example.com/users.json" userDecoder
      == get "http://example.com/users.json" userDecoder

For a request without any headers, you can use:

    getWithConfig defaultConfig url decoder

-}
getWithConfig : Config -> String -> (WebData success -> msg) -> Decoder success -> Cmd msg
getWithConfig config url tagger decoder =
    getRequest config url decoder
        |> toCmd tagger


{-| `GET` request as a task.
Has a `no-cache` header to ensure data integrity.

    getCatTask : Task Never (WebData Cat)
    getCatTask =
        getTask "/api/cats/1" catDecoder

-}
getTask : String -> Decoder success -> Task Never (WebData success)
getTask =
    getTaskWithConfig noCacheConfig


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


{-| `POST` request as a task, with additional `Config`.

    postTaskWithConfig defaultConfig == postTask

-}
postTaskWithConfig :
    Config
    -> String
    -> Decoder success
    -> Json.Decode.Value
    -> Task Never (WebData success)
postTaskWithConfig config url decoder body =
    request config "POST" url decoder (Http.jsonBody body)
        |> toTask


{-| `POST` request as a command, with additional `Config`.

    postWithConfig defaultConfig == postTask

-}
postWithConfig :
    Config
    -> String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Decode.Value
    -> Cmd msg
postWithConfig config url tagger decoder body =
    request config "POST" url decoder (Http.jsonBody body)
        |> toCmd tagger


{-| `POST` request as a task.

    postCatTask : Cat -> Task Never (WebData Cat)
    postCatTask cat =
        postTask "/api/cats/" catDecoder (encodeCat cat)

-}
postTask :
    String
    -> Decoder success
    -> Json.Decode.Value
    -> Task Never (WebData success)
postTask =
    postTaskWithConfig defaultConfig


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
    -> Json.Decode.Value
    -> Cmd msg
post =
    postWithConfig defaultConfig



----


{-| `PUT` request as a task, with additional `Config`.

    putTaskWithConfig defaultConfig == putTask

-}
putTaskWithConfig :
    Config
    -> String
    -> Decoder success
    -> Json.Decode.Value
    -> Task Never (WebData success)
putTaskWithConfig config url decoder body =
    request config "PUT" url decoder (Http.jsonBody body)
        |> toTask


{-| `PUT` request as a command, with additional `Config`.

    putWithConfig defaultConfig == putTask

-}
putWithConfig :
    Config
    -> String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Decode.Value
    -> Cmd msg
putWithConfig config url tagger decoder body =
    request config "PUT" url decoder (Http.jsonBody body)
        |> toCmd tagger


{-| `PUT` request as a task.

    putCatTask : Cat -> Task Never (WebData Cat)
    putCatTask cat =
        putTask "/api/cats/" catDecoder (encodeCat cat)

-}
putTask :
    String
    -> Decoder success
    -> Json.Decode.Value
    -> Task Never (WebData success)
putTask =
    putTaskWithConfig defaultConfig


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
    -> Json.Decode.Value
    -> Cmd msg
put =
    putWithConfig defaultConfig



----


{-| `PATCH` request as a task, with additional `Config`.

    patchTaskWithConfig defaultConfig == patchTask

-}
patchTaskWithConfig :
    Config
    -> String
    -> Decoder success
    -> Json.Decode.Value
    -> Task Never (WebData success)
patchTaskWithConfig config url decoder body =
    request config "PATCH" url decoder (Http.jsonBody body)
        |> toTask


{-| `PATCH` request as a command, with additional `Config`.

    patchWithConfig defaultConfig == patchTask

-}
patchWithConfig :
    Config
    -> String
    -> (WebData success -> msg)
    -> Decoder success
    -> Json.Decode.Value
    -> Cmd msg
patchWithConfig config url tagger decoder body =
    request config "PATCH" url decoder (Http.jsonBody body)
        |> toCmd tagger


{-| `PATCH` request as a task.

    patchCatTask : Cat -> Task Never (WebData Cat)
    patchCatTask cat =
        patchTask "/api/cats/" catDecoder (encodeCat cat)

-}
patchTask :
    String
    -> Decoder success
    -> Json.Decode.Value
    -> Task Never (WebData success)
patchTask =
    patchTaskWithConfig defaultConfig


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
    -> Json.Decode.Value
    -> Cmd msg
patch =
    patchWithConfig defaultConfig



----


{-| `DELETE` request as a task, with additional `Config`.

    deleteTaskWithConfig defaultConfig == deleteTask

-}
deleteTaskWithConfig :
    Config
    -> String
    -> Json.Decode.Value
    -> Task Never (WebData String)
deleteTaskWithConfig config url body =
    Http.request
        { method = "DELETE"
        , headers = config.headers
        , url = url
        , body = Http.jsonBody body
        , expect = Http.expectString
        , timeout = config.timeout
        , withCredentials = config.withCredentials
        }
        |> toTask


{-| `DELETE` request as a task, expecting a `String` response.

In many APIs, the response for successful delete requests has an empty
HTTP body, so decoding it as JSON will always fail. This is why `delete` and
`deleteTask` don't have a decoder argument. If you really want to decode the
response, use `Json.Decode.decodeString`.

    deleteCatTask : Cat -> Task Never (WebData String)
    deleteCatTask cat =
        deleteTask "/api/cats/" (encodeCat cat)

-}
deleteTask :
    String
    -> Json.Decode.Value
    -> Task Never (WebData String)
deleteTask =
    deleteTaskWithConfig defaultConfig


{-| `DELETE` request as a command, with additional `Config`.

    deleteWithConfig defaultConfig == deleteTask

-}
deleteWithConfig :
    Config
    -> String
    -> (WebData String -> msg)
    -> Json.Decode.Value
    -> Cmd msg
deleteWithConfig config url tagger body =
    Http.request
        { method = "DELETE"
        , headers = config.headers
        , url = url
        , body = Http.jsonBody body
        , expect = Http.expectString
        , timeout = config.timeout
        , withCredentials = config.withCredentials
        }
        |> toCmd tagger


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
    -> Json.Decode.Value
    -> Cmd msg
delete =
    deleteWithConfig defaultConfig


{-| This is the old `url` function from evancz/elm-http.

Create a properly encoded URL with a [query string][qs]. The first argument is
the portion of the URL before the query string, which is assumed to be
properly encoded already. The second argument is a list of all the
key/value pairs needed for the query string. Both the keys and values
will be appropriately encoded, so they can contain spaces, ampersands, etc.
[qs]: <http://en.wikipedia.org/wiki/Query_string>

    url "<http://example.com/users"> [ ("name", "john doe"), ("age", "30") ]
    --> "http://example.com/users?name=john+doe&age=30"

-}
url : String -> List ( String, String ) -> String
url baseUrl args =
    case args of
        [] ->
            baseUrl

        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)


queryPair : ( String, String ) -> String
queryPair ( key, value ) =
    queryEscape key ++ "=" ++ queryEscape value


queryEscape : String -> String
queryEscape string =
    String.join "+" (String.split "%20" (Http.encodeUri string))
