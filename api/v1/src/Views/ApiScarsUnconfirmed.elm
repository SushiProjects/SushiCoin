module Views.ApiScarsUnconfirmed exposing (..)

import Html.Events exposing (onClick, onInput)
import Json.PrettyPrint
import Views.TableHelper exposing (docTable)
import Views.ApiLeftNav exposing (apiLeftNav)
import Html exposing (..)
import Html.Attributes exposing (..)
import Models exposing (Model)
import Bootstrap.Navbar as Navbar
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Button as Button
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.Table as Table
import Bootstrap.Alert as Alert
import Bootstrap.Form.Textarea as TextArea
import Bootstrap.Form.Input as Input
import Messages exposing (Method(GET), Msg(..), Page(..))
import Views.ApiDocumentationHelper exposing (documentation)


pageApiScarsUnconfirmed : Model -> List (Html Msg)
pageApiScarsUnconfirmed model =
    let
        description =
            div [] [ Html.text "This retrieves the unconfirmed status of the scars domain as Json" ]

        ex = """ x """
    in
        [ br [] []
        , Grid.row []
            [ apiLeftNav ApiScarsUnconfirmed
            , Grid.col [ Col.md9 ]
                [ documentation ApiScarsUnconfirmed model.apiUrlS3 model.apiResponse "Scars Confirmed" description "GET" "v1/scars/{:domain}/unconfirmed" "curl -X GET -H 'Content-Type: application/json' http://testnet.sushichain.io:3000/v1/scars/{:domain}/unconfirmed" ex
                ]
            ]
        ]
