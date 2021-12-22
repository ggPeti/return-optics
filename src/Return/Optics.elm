module Return.Optics
    exposing
        ( modell
        , msgl
        , refractl
        , refracto
        )

{-|
`Return.Optics` is a utility library extending `Return` with
`Monocle` making a clean, concise API for doing Elm component updates
in the context of other updates.

The signatures abbreviations

- `pmod` is Parent Model
- `pmsg` is Parent Msg
- `cmod` is Child Model
- `cmsg` is Child Msg

# Optics
@docs modell, msgl

# Utilities
@docs refractl, refracto
-}

import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Return exposing (Return, ReturnF)
import Tuple


{-| `Lens` to the model, the first element of the `Return` tuple.
-}
modell : Lens (Return x model) model
modell =
    Lens Tuple.first (always >> Tuple.mapFirst)


{-| `Lens` to the msg, the second element of the `Return` tuple.
-}
msgl : Lens (Return msg x) (Cmd msg)
msgl =
    Lens Tuple.second (always >> Tuple.mapSecond)


{-| Refract in a component's update via a `Lens` and a way to merge
the message back along a parent return in the update function.

    Return.singleton model
        |> case msg of
            ...

            MyComponentMsg msg ->
                refractl Model.myComponent MyComponentMsg <|
                    MyComponent.update msg

-}
refractl : Lens pmod cmod -> (cmsg -> pmsg) -> (cmod -> Return cmsg cmod) -> ReturnF pmsg pmod
refractl lens mergeBack fx ( model, cmd ) =
    lens.get model
        |> fx
        |> Return.mapBoth mergeBack (flip lens.set model)
        |> Return.command cmd


{-| Refract in a component's update via an `Optional` and a way to merge
the message back along a parent return in the update function. If the
getter returns `Nothing` then the `Return` will not be modified.

    Return.singleton model
        |> case msg of
            ...

            MyComponentMsg msg ->
                refracto Model.myComponent MyComponentMsg <|
                    MyComponent.update msg
-}
refracto : Optional pmod cmod -> (cmsg -> pmsg) -> (cmod -> Return cmsg cmod) -> ReturnF pmsg pmod
refracto opt mergeBack fx (( model, cmd ) as return) =
    opt.getOption model
        |> Maybe.map
            (fx
                >> Return.mapBoth mergeBack (flip opt.set model)
                >> Return.command cmd
            )
        |> Maybe.withDefault return


flip : (a -> b -> c) -> b -> a -> c
flip f a b = f b a
