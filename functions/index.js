const {setGlobalOptions} = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const Stripe = require("stripe");

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
admin.initializeApp();

const db = admin.firestore();

setGlobalOptions({
  maxInstances: 10,
  region: "europe-west1",
});

/**
 * Sends a Firebase Cloud Messaging notification to all registered
 * devices belonging to one Euro Habesha user.
 */
async function sendPushToUser({
  recipientId,
  title,
  body,
  data = {},
}) {
  if (!recipientId) {
    logger.warn("Push ignored: recipientId is empty.");
    return;
  }

  const tokensSnapshot = await db
      .collection("users")
      .doc(recipientId)
      .collection("fcmTokens")
      .get();

  const tokens = [];

  for (const tokenDoc of tokensSnapshot.docs) {
    const token = tokenDoc.data().token;

    if (typeof token === "string" && token.trim() !== "") {
      tokens.push(token.trim());
    }
  }

  // Compatibility with the previous single-token system.
  if (tokens.length === 0) {
    const userSnapshot = await db
        .collection("users")
        .doc(recipientId)
        .get();

    const legacyToken = userSnapshot.data()?.fcmToken;

    if (
      typeof legacyToken === "string" &&
      legacyToken.trim() !== ""
    ) {
      tokens.push(legacyToken.trim());
    }
  }

  const uniqueTokens = [...new Set(tokens)];

  if (uniqueTokens.length === 0) {
    logger.warn("No FCM token found.", {
      recipientId,
    });

    throw new Error(
        `No FCM token found for recipient ${recipientId}.`,
    );
  }

  const safeData = {};

  for (const [key, value] of Object.entries(data)) {
    if (value !== null && value !== undefined) {
      safeData[key] = String(value);
    }
  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens: uniqueTokens,
    notification: {
      title: title || "Euro Habesha",
      body: body || "",
    },
    data: safeData,
    android: {
      priority: "high",
      notification: {
        channelId: "euro_habesha_high_importance",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  });

  logger.info("Push sent.", {
    recipientId,
    successCount: response.successCount,
    failureCount: response.failureCount,
  });

  const cleanupPromises = [];

  response.responses.forEach((result, index) => {
    if (result.success) {
      return;
    }

    const errorCode = result.error?.code;

    logger.warn("FCM delivery failed.", {
      recipientId,
      errorCode,
    });

    if (
      errorCode === "messaging/registration-token-not-registered" ||
      errorCode === "messaging/invalid-registration-token"
    ) {
      const invalidToken = uniqueTokens[index];

      cleanupPromises.push(
          removeInvalidToken(recipientId, invalidToken),
      );
    }
  });

  await Promise.all(cleanupPromises);
}

/**
 * Removes an invalid FCM token from the user's device-token collection.
 *
 * @param {string} recipientId Firebase UID of the notification recipient.
 * @param {string} invalidToken Invalid FCM registration token.
 * @return {Promise<void>} Completes after the invalid token is removed.
 */
async function removeInvalidToken(recipientId, invalidToken) {
  const tokensSnapshot = await db
      .collection("users")
      .doc(recipientId)
      .collection("fcmTokens")
      .where("token", "==", invalidToken)
      .get();

  const batch = db.batch();

  for (const document of tokensSnapshot.docs) {
    batch.delete(document.ref);
  }

  if (!tokensSnapshot.empty) {
    await batch.commit();
  }

  const userReference = db.collection("users").doc(recipientId);
  const userSnapshot = await userReference.get();

  if (userSnapshot.data()?.fcmToken === invalidToken) {
    await userReference.set(
        {
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenUpdatedAt:
            admin.firestore.FieldValue.delete(),
        },
        {merge: true},
    );
  }
}

/**
 * Central Euro Habesha notification dispatcher.
 *
 * Creating:
 * notifications/{notificationId}
 *
 * automatically sends the corresponding FCM push.
 */
exports.sendNotificationPush = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const notification = snapshot.data();

      const recipientId =
        notification.recipientId?.toString().trim() || "";

      if (!recipientId) {
        logger.warn("Notification has no recipientId.", {
          notificationId: event.params.notificationId,
        });
        return;
      }

      if (notification.pushSent === true) {
        return;
      }

      const title =
        notification.title?.toString().trim() ||
        "Euro Habesha";

      const body =
        notification.body?.toString().trim() || "";

      const type =
        notification.type?.toString().trim() || "general";

      const routeType =
        notification.routeType?.toString().trim() || type;

      const resourceId =
        notification.resourceId?.toString().trim() ||
        notification.orderId?.toString().trim() ||
        notification.chatId?.toString().trim() ||
        notification.postId?.toString().trim() ||
        "";

      try {
        await sendPushToUser({
          recipientId,
          title,
          body,
          data: {
            notificationId: event.params.notificationId,
            type,
            routeType,
            resourceId,
            orderId: notification.orderId || "",
            chatId: notification.chatId || "",
            postId: notification.postId || "",
            commentId: notification.commentId || "",
            eventId: notification.eventId || "",
            professionalId:
              notification.professionalId || "",
          },
        });

        await snapshot.ref.update({
          pushSent: true,
          pushSentAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (error) {
        logger.error("Unable to send Euro Habesha push.", {
          notificationId: event.params.notificationId,
          recipientId,
          error: error?.message || String(error),
        });

        await snapshot.ref.update({
          pushSent: false,
          pushError: error?.message || String(error),
          pushLastAttemptAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    },
);
/**
 * Creates a notification when a new chat message is created.
 */
exports.onChatMessageCreatedNotifyRecipient = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const message = snapshot.data();
      const chatId = event.params.chatId;

      const senderId =
        message.senderId?.toString().trim() || "";

      if (!senderId) {
        logger.warn("Chat message has no senderId.", {
          chatId,
          messageId: event.params.messageId,
        });
        return;
      }

      const chatSnapshot = await admin
          .firestore()
          .collection("chats")
          .doc(chatId)
          .get();

      if (!chatSnapshot.exists) {
        logger.warn("Chat does not exist.", {
          chatId,
        });
        return;
      }

      const chat = chatSnapshot.data() || {};

      const participants = Array.isArray(chat.participants) ?
        chat.participants :
        [];

      const recipients = participants.filter(
          (uid) => uid && uid !== senderId,
      );

      if (recipients.length === 0) {
        return;
      }

      const participantNames =
        chat.participantNames || {};

      const senderName =
        participantNames[senderId]?.toString().trim() ||
        "Euro Habesha member";

      const messageText =
        message.text?.toString().trim() || "";

      const preview = messageText.length > 120 ?
        `${messageText.substring(0, 117)}...` :
        messageText;

      const batch = admin.firestore().batch();
      const chatRef = admin
          .firestore()
          .collection("chats")
          .doc(chatId);

      for (const recipientId of recipients) {
        batch.set(
            chatRef,
            {
              unreadCounts: {
                [recipientId]:
            admin.firestore.FieldValue.increment(1),
              },
            },
            {merge: true},
        );
      }
      for (const recipientId of recipients) {
        const notificationRef = admin
            .firestore()
            .collection("notifications")
            .doc();

        batch.set(notificationRef, {
          recipientId,
          title: senderName,
          body: preview || "New message",
          type: "message",
          routeType: "chat",
          resourceId: chatId,
          chatId,
          senderId,
          messageId: event.params.messageId,
          read: false,
          pushSent: false,
          createdAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      logger.info("Chat notification created.", {
        chatId,
        messageId: event.params.messageId,
        recipientCount: recipients.length,
      });

      // Professional welcome message:
      // sent only once per professional conversation.
      const isProfessionalChat =
        chat.chatType === "professional";

      const isAutomaticMessage =
        message.isAutomatic === true;

      const welcomeAlreadySent =
        chat.professionalWelcomeSent === true;

      if (
        isProfessionalChat &&
  chat.professionalAutoReplyEnabled === true &&
  !isAutomaticMessage &&
  !welcomeAlreadySent &&
  senderId !== chat.professionalId
      ) {
        const professionalId =
  chat.professionalId?.toString().trim() || "";

        if (professionalId) {
          const professionalName =
            participantNames[professionalId]
                ?.toString()
                .trim() ||
            "Professional";

          const welcomeText =
            `Hello! Thank you for contacting ${professionalName}. ` +
            "Your message has been received. " +
            "I will reply to you as soon as possible.";

          await admin.firestore().runTransaction(
              async (transaction) => {
                const freshChat =
                  await transaction.get(chatSnapshot.ref);

                const freshData =
                  freshChat.data() || {};

                if (
                  freshData.professionalWelcomeSent === true
                ) {
                  return;
                }

                const replyRef =
                  chatSnapshot.ref
                      .collection("messages")
                      .doc();

                transaction.set(replyRef, {
                  senderId: professionalId,
                  text: welcomeText,
                  createdAt:
                    admin.firestore.FieldValue
                        .serverTimestamp(),
                  readBy: [professionalId],
                  isAutomatic: true,
                  messageType: "professional_welcome",
                });

                transaction.update(chatSnapshot.ref, {
                  professionalWelcomeSent: true,
                  professionalWelcomeSentAt:
                    admin.firestore.FieldValue
                        .serverTimestamp(),
                  lastMessage: welcomeText,
                  updatedAt:
                    admin.firestore.FieldValue
                        .serverTimestamp(),
                });
              },
          );
        }
      }
    },
);
/**
 * Creates a notification when a new cash-on-delivery order is created.
 */
exports.onCashOrderCreatedNotifySeller = onDocumentCreated(
    "cashOnDeliveryOrders/{orderId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const order = snapshot.data();
      const sellerId = order.sellerId?.toString().trim() || "";

      if (!sellerId) {
        logger.warn("New order has no sellerId.", {
          orderId: event.params.orderId,
        });
        return;
      }

      const buyerName =
        order.buyerName?.toString().trim() || "Un client";

      const itemTitle =
        order.itemTitle?.toString().trim() || "Commande";

      await db.collection("notifications").add({
        recipientId: sellerId,
        title: "Nouvelle commande",
        body: `${buyerName} a commandé : ${itemTitle}`,
        type: "order",
        routeType: "sellerOrder",
        resourceId: event.params.orderId,
        orderId: event.params.orderId,
        read: false,
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Seller order notification created.", {
        orderId: event.params.orderId,
        sellerId,
      });
    },
);


/**
 * Creates the appropriate notification whenever an order status changes.
 */
exports.onCashOrderStatusChanged = onDocumentUpdated(
    "cashOnDeliveryOrders/{orderId}",
    async (event) => {
      const before = event.data?.before.data();
      const after = event.data?.after.data();

      if (!before || !after) {
        return;
      }

      const previousStatus =
        before.status?.toString().trim() || "";

      const newStatus =
        after.status?.toString().trim() || "";

      // Ignore updates that do not change the order status.
      if (previousStatus === newStatus) {
        return;
      }

      const orderId = event.params.orderId;

      const buyerId =
        after.buyerId?.toString().trim() ||
        after.userId?.toString().trim() ||
        "";

      const sellerId =
        after.sellerId?.toString().trim() || "";

      let recipientId = "";
      let title = "Mise à jour de votre commande";
      let body = "";
      let routeType = "buyerOrder";

      switch (newStatus) {
        case "accepted":
          recipientId = buyerId;
          title = "Commande acceptée";
          body =
            "Le professionnel a accepté votre commande.";
          break;

        case "rejected":
          recipientId = buyerId;
          title = "Commande refusée";
          body =
            "Le professionnel n'a pas pu accepter votre commande.";
          break;

        case "preparing":
          recipientId = buyerId;
          title = "Commande en préparation";
          body =
            "Votre commande est maintenant en préparation.";
          break;

        case "ready":
          recipientId = buyerId;
          title = "Commande prête";
          body =
            "Votre commande est prête.";
          break;

        case "completed":
          recipientId = buyerId;
          title = "Commande terminée";
          body =
            "Votre commande a été marquée comme terminée.";
          break;

        case "cancelled":
          recipientId = sellerId;
          title = "Commande annulée";
          body =
            `${after.buyerName || "Le client"} a annulé la commande.`;
          routeType = "sellerOrder";
          break;

        default:
          logger.info("Order status does not require notification.", {
            orderId,
            previousStatus,
            newStatus,
          });
          return;
      }

      if (!recipientId) {
        logger.warn("Order notification has no recipient.", {
          orderId,
          previousStatus,
          newStatus,
        });
        return;
      }

      await db.collection("notifications").add({
        recipientId,
        title,
        body,
        type: "order",
        routeType,
        resourceId: orderId,
        orderId,
        read: false,
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Order status notification created.", {
        orderId,
        recipientId,
        previousStatus,
        newStatus,
      });
    },
);
/**
 * Creates a Stripe PaymentIntent for an Euro Habesha event ticket.
 * The price is always read from Firestore.
 */
exports.createTicketPaymentIntent = onCall(
    {
      region: "europe-west1",
      secrets: [stripeSecretKey],
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "You must be signed in.",
        );
      }

      const eventId =
        request.data?.eventId?.toString().trim() || "";

      const ticketTypeId =
        request.data?.ticketTypeId?.toString().trim() || "";

      const quantity = Number(request.data?.quantity || 1);

      const attendeeName =
        request.data?.attendeeName?.toString().trim() || "";

      const buyerEmail =
        request.data?.buyerEmail?.toString().trim() || "";

      const nonRefundable =
        request.data?.nonRefundable === true;

      const nonTransferable =
        request.data?.nonTransferable === true;

      if (!eventId || !ticketTypeId) {
        throw new HttpsError(
            "invalid-argument",
            "Event and ticket type are required.",
        );
      }

      if (!attendeeName || !buyerEmail) {
        throw new HttpsError(
            "invalid-argument",
            "Name and email are required.",
        );
      }

      if (
        !Number.isInteger(quantity) ||
        quantity < 1 ||
        quantity > 10
      ) {
        throw new HttpsError(
            "invalid-argument",
            "Invalid ticket quantity.",
        );
      }

      const eventSnapshot = await db
          .collection("events")
          .doc(eventId)
          .get();

      if (!eventSnapshot.exists) {
        throw new HttpsError(
            "not-found",
            "Event not found.",
        );
      }

      const eventData = eventSnapshot.data();

      const status =
        eventData.status?.toString().trim().toLowerCase() || "";

      if (status !== "approved" && status !== "published") {
        throw new HttpsError(
            "failed-precondition",
            "Event is not available.",
        );
      }

      const ticketTypes =
        Array.isArray(eventData.ticketTypes) ?
          eventData.ticketTypes :
          [];

      const ticketType = ticketTypes.find(
          (item) =>
            item?.id?.toString() === ticketTypeId,
      );

      if (!ticketType || ticketType.active === false) {
        throw new HttpsError(
            "not-found",
            "Ticket type is not available.",
        );
      }

      const unitPrice = Number(ticketType.price);
      const capacity = Number(ticketType.capacity || 0);
      const sold = Number(ticketType.sold || 0);

      if (
        capacity > 0 &&
        sold + quantity > capacity
      ) {
        throw new HttpsError(
            "failed-precondition",
            "Not enough tickets are available.",
        );
      }

      if (!Number.isFinite(unitPrice) || unitPrice <= 0) {
        throw new HttpsError(
            "failed-precondition",
            "This ticket does not require Stripe payment.",
        );
      }

      // ----------------------------------------------------------
      // SUBTOTAL
      // ----------------------------------------------------------

      const subtotalCents = Math.round(
          unitPrice * quantity * 100,
      );

      // ----------------------------------------------------------
      // PLATFORM SERVICE FEE
      // Firestore: platformSettings/fees
      // ----------------------------------------------------------

      let serviceFeeCents = 0;
      let feeType = "fixed";
      let feeValue = 0;
      let feeEnabled = false;

      const feesSnapshot = await db
          .collection("platformSettings")
          .doc("fees")
          .get();

      if (feesSnapshot.exists) {
        const feesData = feesSnapshot.data() || {};
        const eventTicketFee =
          feesData.eventTicket || {};

        feeEnabled =
          eventTicketFee.enabled === true;

        feeType =
          eventTicketFee.type?.toString() === "percentage" ?
            "percentage" :
            "fixed";

        feeValue =
          Number(eventTicketFee.value || 0);

        if (
          !Number.isFinite(feeValue) ||
          feeValue < 0
        ) {
          feeValue = 0;
        }

        if (feeEnabled && feeValue > 0) {
          if (feeType === "percentage") {
            serviceFeeCents = Math.round(
                subtotalCents * feeValue / 100,
            );
          } else {
            // Frais fixes appliqués par billet.
            serviceFeeCents = Math.round(
                feeValue * quantity * 100,
            );
          }
        }
      }

      const totalCents =
        subtotalCents + serviceFeeCents;

      if (totalCents < 50) {
        throw new HttpsError(
            "failed-precondition",
            "Payment amount is too small.",
        );
      }

      const stripe = new Stripe(
          stripeSecretKey.value(),
      );

      try {
        const paymentIntent =
          await stripe.paymentIntents.create({
            amount: totalCents,
            currency: "eur",

            receipt_email: buyerEmail,

            automatic_payment_methods: {
              enabled: true,
            },

            metadata: {
              firebaseUid: request.auth.uid,
              eventId,
              ticketTypeId,
              quantity: String(quantity),
              attendeeName,
              buyerEmail,
              nonRefundable: String(nonRefundable),
              nonTransferable: String(nonTransferable),

              // Snapshot financier créé côté serveur.
              subtotalCents: String(subtotalCents),
              serviceFeeCents: String(serviceFeeCents),
              totalCents: String(totalCents),
              feeEnabled: String(feeEnabled),
              feeType,
              feeValue: String(feeValue),
            },
          });

        return {
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,

          subtotal: subtotalCents,
          serviceFee: serviceFeeCents,
          amount: totalCents,

          currency: "eur",
        };
      } catch (error) {
        logger.error(
            "Stripe PaymentIntent creation failed.",
            {
              uid: request.auth.uid,
              eventId,
              error: error?.message || String(error),
            },
        );

        throw new HttpsError(
            "internal",
            "Unable to initialize payment.",
        );
      }
    },
);
/**
 * Stripe webhook for Euro Habesha ticket payments.
 * Stripe signature is verified before processing the event.
 */
exports.stripeTicketWebhook = onRequest(
    {
      region: "europe-west1",
      secrets: [
        stripeSecretKey,
        stripeWebhookSecret,
      ],
    },
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      const stripe = new Stripe(stripeSecretKey.value());
      const signature = req.headers["stripe-signature"];

      if (!signature) {
        res.status(400).send("Missing Stripe signature.");
        return;
      }

      let stripeEvent;

      try {
        stripeEvent = stripe.webhooks.constructEvent(
            req.rawBody,
            signature,
            stripeWebhookSecret.value(),
        );
      } catch (error) {
        logger.error("Stripe webhook signature failed.", {
          error: error?.message || String(error),
        });

        res.status(400).send("Invalid Stripe signature.");
        return;
      }

      if (stripeEvent.type !== "payment_intent.succeeded") {
        res.status(200).send("Event ignored.");
        return;
      }

      const paymentIntent = stripeEvent.data.object;
      const metadata = paymentIntent.metadata || {};

      const eventId =
        metadata.eventId?.toString().trim() || "";

      const ticketTypeId =
        metadata.ticketTypeId?.toString().trim() || "";

      const buyerId =
        metadata.firebaseUid?.toString().trim() || "";

      const attendeeName =
        metadata.attendeeName?.toString().trim() || "";

      const buyerEmail =
        metadata.buyerEmail?.toString().trim() ||
        paymentIntent.receipt_email ||
        "";

      const quantity =
        Number(metadata.quantity || 1);

      const nonRefundable =
        metadata.nonRefundable === "true";

      const nonTransferable =
        metadata.nonTransferable === "true";

      // Snapshot financier créé par notre callable.
      const subtotalCents =
        Number(metadata.subtotalCents);

      const serviceFeeCents =
        Number(metadata.serviceFeeCents);

      const totalCents =
        Number(metadata.totalCents);

      const feeEnabled =
        metadata.feeEnabled === "true";

      const feeType =
        metadata.feeType?.toString() || "fixed";

      const feeValue =
        Number(metadata.feeValue || 0);

      if (
        !eventId ||
        !ticketTypeId ||
        !buyerId ||
        !attendeeName ||
        !buyerEmail ||
        !Number.isInteger(quantity) ||
        quantity < 1 ||
        quantity > 10 ||
        !Number.isInteger(subtotalCents) ||
        subtotalCents <= 0 ||
        !Number.isInteger(serviceFeeCents) ||
        serviceFeeCents < 0 ||
        !Number.isInteger(totalCents) ||
        totalCents <= 0
      ) {
        logger.error("Stripe payment metadata is invalid.", {
          paymentIntentId: paymentIntent.id,
        });

        res.status(400).send("Invalid payment metadata.");
        return;
      }

      if (paymentIntent.currency !== "eur") {
        logger.error("Unexpected Stripe currency.", {
          paymentIntentId: paymentIntent.id,
          currency: paymentIntent.currency,
        });

        res.status(400).send("Invalid payment currency.");
        return;
      }

      if (
        subtotalCents + serviceFeeCents !== totalCents
      ) {
        logger.error("Invalid Stripe fee calculation.", {
          paymentIntentId: paymentIntent.id,
        });

        res.status(400).send("Invalid payment calculation.");
        return;
      }

      const receivedAmount =
        Number(paymentIntent.amount_received || 0);

      const stripeAmount =
        Number(paymentIntent.amount || 0);

      if (
        receivedAmount !== totalCents ||
        stripeAmount !== totalCents
      ) {
        logger.error("Stripe amount mismatch.", {
          paymentIntentId: paymentIntent.id,
          receivedAmount,
          stripeAmount,
          totalCents,
        });

        res.status(400).send("Invalid payment amount.");
        return;
      }

      const paymentRef = db
          .collection("stripeTicketPayments")
          .doc(paymentIntent.id);

      try {
        await db.runTransaction(async (transaction) => {
          const previousPayment =
            await transaction.get(paymentRef);

          // Stripe peut renvoyer le même webhook.
          // On ne crée jamais les billets deux fois.
          if (
            previousPayment.exists &&
            previousPayment.data()?.processed === true
          ) {
            return;
          }

          const eventRef =
            db.collection("events").doc(eventId);

          const eventSnapshot =
            await transaction.get(eventRef);

          if (!eventSnapshot.exists) {
            throw new Error("Event does not exist.");
          }

          const eventData = eventSnapshot.data();

          const status =
            eventData.status?.toString().trim().toLowerCase() || "";

          if (
            status !== "approved" &&
            status !== "published"
          ) {
            throw new Error("Event is not available.");
          }

          const ticketTypes =
            Array.isArray(eventData.ticketTypes) ?
              [...eventData.ticketTypes] :
              [];

          const ticketIndex = ticketTypes.findIndex(
              (item) =>
                item?.id?.toString() === ticketTypeId,
          );

          if (ticketIndex < 0) {
            throw new Error("Ticket type not found.");
          }

          const ticketType = {
            ...ticketTypes[ticketIndex],
          };

          if (ticketType.active === false) {
            throw new Error("Ticket type is not active.");
          }

          const unitPrice = Number(ticketType.price);
          const capacity = Number(ticketType.capacity || 0);
          const sold = Number(ticketType.sold || 0);

          if (
            !Number.isFinite(unitPrice) ||
            unitPrice <= 0
          ) {
            throw new Error("Invalid ticket price.");
          }

          // Le prix du billet doit toujours correspondre
          // au snapshot enregistré au moment du paiement.
          const authoritativeSubtotalCents =
            Math.round(
                unitPrice * quantity * 100,
            );

          if (
            authoritativeSubtotalCents !== subtotalCents
          ) {
            throw new Error(
                "Ticket subtotal does not match current ticket price.",
            );
          }

          if (
            capacity > 0 &&
            sold + quantity > capacity
          ) {
            throw new Error(
                "Not enough tickets available.",
            );
          }

          ticketType.sold = sold + quantity;
          ticketTypes[ticketIndex] = ticketType;

          transaction.update(eventRef, {
            ticketTypes,
            ticketSalesUpdatedAt:
              admin.firestore.FieldValue.serverTimestamp(),
          });

          const ticketIds = [];

          for (let index = 0; index < quantity; index++) {
            const ticketRef =
              db.collection("tickets").doc();

            const ticketId = ticketRef.id;
            ticketIds.push(ticketId);

            transaction.set(ticketRef, {
              ticketId,
              eventId,
              eventName:
                eventData.title?.toString() || "Event",
              ticketTypeId,
              ticketTypeName:
                ticketType.name?.toString() || "Standard",
              buyerId,
              buyerEmail,
              attendeeName,

              unitPrice,
              price: unitPrice,

              purchaseQuantity: quantity,

              // Prix des billets sans frais.
              ticketSubtotal:
                subtotalCents / 100,

              // Frais totaux de cette commande.
              serviceFeeTotal:
                serviceFeeCents / 100,

              // Total réellement payé.
              purchaseTotal:
                totalCents / 100,

              paymentStatus: "purchased",
              paymentMethod: "Stripe",
              stripePaymentIntentId:
                paymentIntent.id,

              checkedIn: false,
              nonRefundable,
              nonTransferable,

              createdAt:
                admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          transaction.set(paymentRef, {
            processed: true,
            stripeEventId: stripeEvent.id,
            paymentIntentId: paymentIntent.id,

            eventId,
            ticketTypeId,
            buyerId,
            buyerEmail,
            attendeeName,
            quantity,

            subtotalCents,
            serviceFeeCents,
            totalCents,

            subtotal:
              subtotalCents / 100,

            serviceFee:
              serviceFeeCents / 100,

            total:
              totalCents / 100,

            feeSnapshot: {
              enabled: feeEnabled,
              type: feeType,
              value: feeValue,
            },

            amount: receivedAmount,
            currency: paymentIntent.currency,
            ticketIds,

            createdAt:
              admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        res.status(200).send("Payment processed.");
      } catch (error) {
        logger.error("Stripe ticket processing failed.", {
          paymentIntentId: paymentIntent.id,
          error: error?.message || String(error),
        });

        res.status(500).send("Ticket processing failed.");
      }
    },
);
