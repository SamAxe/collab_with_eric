

let determine_greeting request : string =
  match Dream.session_field request "user" with
  | Some username ->
      Printf.sprintf "Welcome back, %s" username
  | None -> "Welcome, you'll need to log in first"

let show_form ?message request =
  let open Dream_html in
  let open HTML in
  html []
  [ body []
    [ begin
        match message with
        | None -> p [] []
        | Some message ->
            p [] [ txt "You entered: %s" message ]
      end
    ; p [] [ txt "%s" (determine_greeting request) ]
    ; form [ method_ `POST; action "/"]
      [ csrf_tag request
      ; label [ for_ "msg_id"] [ txt "Message" ]
      ; input [ name "message"; id "msg_id"; autofocus]
      ; input [ type_ "submit"; value "Send" ]
      ]
    ; a [ href "/login" ] [txt "Log in"]
    ; a [ href "/logout" ] [txt "Log out"]
    ]
  ]
  |> respond


let message_form_request_decoder =
  let open Dream_html.Form in
  let+ greeting = required string "message" in
  greeting


let message_form_handler request =
  match%lwt Dream_html.form message_form_request_decoder request with
  | `Ok message -> show_form ~message request

  | `Invalid errors ->
      (* `errors` is a list of (field_name * error_key) *)
      let msg =
        errors
        |> List.map (fun (field, err) ->
            Printf.sprintf "Field %s: %s" field err
          )
        |> String.concat "<br />"
      in
      Dream.html ("Form errors:<br />" ^ msg)
  | `No_form -> Dream.html "No form data received"
  | `Missing_token _ -> Dream.html "Missing token"
  | `Many_tokens _ -> Dream.html "Many token"
  | `Invalid_token _ -> Dream.html "Invalid_token token"
  | `Wrong_session _ -> Dream.html "Wrong session"
  | `Expired _ -> Dream.html "Expired"
  | `Wrong_content_type -> Dream.html "Wrong content"



let not_logged_in_greet_handler request =
  let open Dream_html in
  let open HTML in
  html []
  [ body []
    [ form [ method_ `POST; action "/login"]
      [ csrf_tag request
      ; table []
        [ tr []
          [ td [] [ label [ for_ "username_id"] [ txt "Username" ] ]
          ; td [] [ input [ type_ "text"; name "username"; id "username_id"; placeholder "Enter username"; autofocus] ]
          ]
        ; tr []
          [ td [] [ label [ for_ "password_id"] [ txt "Password" ] ]
          ; td [] [ input [ type_ "password"; name "password"; id "password_id"; placeholder "Enter password"] ]
          ]
        ; tr []
          [ td [] [ ]
          ; td []
            [ input [ type_ "submit"; name "action"; value "Log in" ]
            ; input [ type_ "submit"; name "action"; value "Create" ]
            ]
          ]
        ]

      ]
    ]
  ]
  |> respond

let logout_handler request =
  let%lwt () = Dream.drop_session_field request "user" in
  let%lwt () = Dream.invalidate_session request in
   Dream.redirect request "/"

(*
  let open Dream_html in
  let open HTML in
  html []
  [ body []
    [ form [ method_ `GET; action "/login"]
      [ csrf_tag request
      ; input [ type_ "submit"; value "Log out" ]
      ]
    ]
  ]
  |> respond
*)

let login_form_request_decoder =
  let open Dream_html.Form in
  let+ username = required string "username"
  and+ password = required string "password"
  and+ action   = required string "action" in
  (username,password,action)


let login_form_handler request =
  match%lwt Dream_html.form login_form_request_decoder request with
  | `Ok (username,password,action) ->
      begin
        match action with
        | "Log in" ->
          let%lwt result = Dream.sql request (User.get_by_username username ) in
          begin
            match result with
            | Ok (Some (_db_username, db_password_hash)) ->
                begin
                if Pwd.verify db_password_hash password
                then
                  let%lwt () = Dream.invalidate_session request in
                  let%lwt () = Dream.set_session_field request "user" username in
                    Dream.redirect request "/"
                else
                  show_form ~message:"Login failed, invalid username or password" request
                end
            | Ok None ->
                Dream.log "User login failed %s" username;
                Dream.redirect request "/"
            | Error e ->
                Dream.log "User login error (%s) %s" username (Caqti_error.show e);
                Dream.redirect request "/"
            end;

        | "Create" ->
            let hashed_pwd = Result.get_ok (Pwd.hash_password password) in
(*             Dream.log "Hashed pwd is %s" hashed_pwd; *)
            let%lwt result = Dream.sql request (User.register_user username hashed_pwd) in
            begin
              match result with
              | Ok () -> Dream.log "User created!"
              | Error e -> Dream.log "User creation error %s" e
              end;

            let%lwt () = Dream.invalidate_session request in
            let%lwt () = Dream.set_session_field request "user" username in
             Dream.redirect request "/"
        | _ ->
            Dream.log "Unknown action: '%s'" action;
            Dream.redirect request "/"
      end

  | `Invalid errors ->
      (* `errors` is a list of (field_name * error_key) *)
      let msg =
        errors
        |> List.map (fun (field, err) ->
            Printf.sprintf "Field %s: %s" field err
          )
        |> String.concat "<br />"
      in
      Dream.html ("Form errors:<br />" ^ msg)
  | `No_form -> Dream.html "No form data received"
  | `Missing_token _ -> Dream.html "Missing token"
  | `Many_tokens _ -> Dream.html "Many token"
  | `Invalid_token _ -> Dream.html "Invalid_token token"
  | `Wrong_session _ -> Dream.html "Wrong session"
  | `Expired _ -> Dream.html "Expired"
  | `Wrong_content_type -> Dream.html "Wrong content"


let require_login handler request =
  match Dream.session_field request "user" with
  | Some _username -> handler request
  | None -> Dream.redirect request "/login"

let () =
  Dream.run
    ~port:8081
    ~error_handler:Dream.debug_error_handler
    ~tls:true
  @@ Dream.logger
  @@ Dream.sql_pool "sqlite3:test.db"
  @@ Dream.memory_sessions
  @@ Dream.router
    [ Dream.get  "/" show_form
    ; Dream.post "/" (require_login message_form_handler)

    ; Dream.get "/login" not_logged_in_greet_handler
    ; Dream.post "/login" login_form_handler
    ; Dream.get "/logout" logout_handler


    ]
