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
    response = messaging.send(message)
    print(response)