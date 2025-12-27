
module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type

type user =
  { id            : int
  ; username      : string
  ; password_hash : string
  ; created_at    : string
  }

let user_codec =
  let encode { id; username; password_hash; created_at } = Ok (id, username, password_hash, created_at ) in
  let decode ( id, username, password_hash, created_at ) = Ok {id; username; password_hash; created_at } in
  Caqti_type.(custom (t4 int string string string) ~encode ~decode)

let user_pwd_codec =
  let encode ( username, password_hash ) = Ok (username, password_hash) in
  let decode ( username, password_hash ) = Ok (username, password_hash) in
  Caqti_type.(custom (t2 string string) ~encode ~decode)


module Q = struct
  open Caqti_request.Infix

  let insert =
    let open Caqti_type in
      (t2 string string ->. unit)
      "INSERT INTO users (username, password_hash) VALUES (?,?)"

  let find_by_username =
    let open Caqti_request.Infix in
    (Caqti_type.string ->? user_pwd_codec)
    "SELECT username, password_hash FROM users WHERE username = ? LIMIT 1"

  let update_password =
    let open Caqti_request.Infix in
    (Caqti_type.(t2 string string) ->. Caqti_type.unit)
    "UPDATE users SET password_hash = ? WHERE username = ?"

  let exists =
    let open Caqti_request.Infix in
    (Caqti_type.string ->! Caqti_type.bool)
    "SELECT EXISTS(SELECT 1 FROM users WHERE username = ?)"

  let delete =
    let open Caqti_request.Infix in
    (Caqti_type.string ->. Caqti_type.unit)
    "DELETE FROM users WHERE username = ?"
end

(* module User = struct *)
  let create (module Db : Caqti_lwt.CONNECTION) ~username ~password_hash =
    Db.exec Q.insert (username, password_hash)

  let delete (module Db : Caqti_lwt.CONNECTION) ~username =
    Db.exec Q.delete (username )

  let get_by_username username (module Db : Caqti_lwt.CONNECTION) =
    Db.find_opt Q.find_by_username username

  let change_password (module Db : Caqti_lwt.CONNECTION) ~username ~new_hash =
    Db.exec Q.update_password (new_hash, username)

  let exists (module Db : Caqti_lwt.CONNECTION) username =
    Db.find Q.exists username
(* end *)

let register_user username password (module Db : Caqti_lwt.CONNECTION) =
  let open Lwt.Syntax in

  let* already_exists = exists (module Db : Caqti_lwt.CONNECTION) username in
  match already_exists with
  | Ok true ->
      Lwt.return (Error "Username already taken")
  | Ok false ->
      let hash = Result.get_ok (Pwd.hash_password password) in
      let*r = create (module Db : Caqti_lwt.CONNECTION) ~username ~password_hash:hash in
      Lwt.return (Result.map_error Caqti_error.show r)
  | Error e ->
      Lwt.return (Error (Caqti_error.show e))
