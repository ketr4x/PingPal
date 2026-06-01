import firebase_admin
from firebase_admin import messaging, firestore
from firebase_functions import firestore_fn
from firebase_functions.options import set_global_options

set_global_options(max_instances=10)
firebase_admin.initialize_app()

@firestore_fn.on_document_created(document="Pings/{pingId}")
def on_ping(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    receiver = event.data.get("receiver")
    if not receiver:
        return

    doc = firestore.client().collection("Users").document(receiver).get()
    if not doc.exists:
        return

    fcm_token = doc.to_dict().get("fcm_token")
    if not fcm_token:
        return

    message = messaging.Message(
        notification=messaging.Notification(
            title="PingPal",
            body="You have been paged!"
        ),
        token=fcm_token
    )

    try:
        messaging.send(message)
    except Exception:
        firestore.client().collection("Users").document(receiver).update({
            "fcm_token": firestore.DELETE_FIELD
        })

    print(f"Notification send for {receiver}")

@firestore_fn.on_document_deleted(document="Users/{userId}")
def on_user_deleted(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    deleted_uid = event.params["userId"]
    db = firestore.client()

    batch = db.batch()
    batch_count = 0

    users_with_friend = db.collection("Users").where("friends", "array_contains", deleted_uid).get()
    for user_doc in users_with_friend:
        user_ref = db.collection("Users").document(user_doc.id)
        batch.update(user_ref, {
            "friends": firestore.ArrayRemove([deleted_uid])
        })
        batch_count += 1

        if batch_count >= 450:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    print(f"Friends deleted for {deleted_uid}")