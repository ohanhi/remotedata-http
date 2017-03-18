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

Say we have a module called `Cat`, which has a definition for the type `Cat`, and a JSON decoder for that type. Using that module with `RemoteData.Http` looks like this:

```elm
import Html exposing (button, text)
import Html.Events exposing (onClick)
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Http
import Cat exposing (Cat) -- This is the module


-- Store the data as a `WebData a` type in your model
type alias Model =
    { cat : WebData Cat
    }


type Msg
    = HandleCatResponse (WebData Cat)
    | GetCat


init : (Model, Cmd Msg)
init =
    ( { cat = NotAsked }
    , Cmd.none
    )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        HandleCatResponse data ->
            ( { model | cat = data }
            , Cmd.none
            )

        GetCat ->
            ( model
            , RemoteData.Http.get "/api/cats/1" HandleGetCat Cat.decoder
            )


view : Model -> Html msg
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
```


There is a function to make a command or a task for each of the HTTP verbs, and also the same with some additional configuration.

Take a look at the [module documentation](http://package.elm-lang.org/packages/ohanhi/remotedata-http/latest/RemoteData-Http).

# License

This is made by Ossi Hanhinen and licensed under [BSD (3-clause)](LICENSE).
