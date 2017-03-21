# RemoteData.Http

A collection of helper functions for loading JSON data from a server using [`RemoteData`](http://package.elm-lang.org/packages/krisajenkins/remotedata/latest).


## API Documentation

There is an example for each of the functions in the [module documentation](http://package.elm-lang.org/packages/ohanhi/remotedata-http/latest/RemoteData-Http).

A simple full usage example can be found right here on this readme.


## Introduction

`RemoteData` is a type representing the state of some remote server data. It looks like this:

```elm
type RemoteData e a
    = NotAsked
    | Loading
    | Failure e
    | Success a
```

In this package, we deal with the more specialized version of the type, called `WebData`:

```elm
type alias WebData a =
    RemoteData Http.Error a
```

This means the `Failure` case will always have an error from the [elm-lang/http](http://package.elm-lang.org/packages/elm-lang/http/latest) package.

For more information, please refer to the package documentation for [`RemoteData`](http://package.elm-lang.org/packages/krisajenkins/remotedata/latest/RemoteData).


## Example usage

Using `RemoteData.Http` looks like this. Play with the code on [Ellie](https://embed.ellie-app.com/GgZxVXgpMda1/0).

```elm
module Main exposing (..)

import Html exposing (Html, button, text)
import Html.Events exposing (onClick)
import Json.Decode
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Http


{-| Store the data as a `WebData a` type in your model
-}
type alias Model =
    { cat : WebData Cat
    }


{-| Add a message with a `WebData a` parameter
-}
type Msg
    = HandleCatResponse (WebData Cat)
    | GetCat


init : ( Model, Cmd Msg )
init =
    ( { cat = NotAsked }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleCatResponse data ->
            ( { model | cat = data }
            , Cmd.none
            )

        GetCat ->
            ( { model | cat = Loading }
            , RemoteData.Http.get "/api/cats/1" HandleCatResponse catDecoder
            )


view : Model -> Html Msg
view model =
    case model.cat of
        Loading ->
            text "Loading cat data, please stand by..."

        Success cat ->
            text ("Received cat: " ++ toString cat)

        Failure error ->
            text ("Oh noes, cat loading failed with error: " ++ toString error)

        NotAsked ->
            button [ onClick GetCat ] [ text "Get cat data from the server" ]


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


{- This stuff is just to make it compile...
Replace with your real type and decoder.
-}
type alias Cat =
    {}


catDecoder =
    Json.Decode.fail "this isn't a real decoder"
```


There is a function to make a command or a task for each of the HTTP verbs, and also the same with some additional configuration.

Take a look at the [module documentation](http://package.elm-lang.org/packages/ohanhi/remotedata-http/latest/RemoteData-Http).

# License

This is made by Ossi Hanhinen and licensed under [BSD (3-clause)](LICENSE).
