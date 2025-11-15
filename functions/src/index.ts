// Import các hàm V2
import { onDocumentCreated } from "firebase-functions/v2/firestore"; 
import * as admin from "firebase-admin";
import * as functions from "firebase-functions"; // Dùng để log (ghi nhật ký)

// Khởi tạo Firebase Admin SDK
admin.initializeApp();

// Đây là function sẽ được kích hoạt (viết theo cú pháp v2)
export const sendNewMessageNotification = onDocumentCreated(
  "chat_rooms/{chatRoomId}/messages/{messageId}", // Cú pháp v2
  async (event) => { // 'event' thay vì (snapshot, context)
    // 1. Lấy dữ liệu của tin nhắn mới
    const snapshot = event.data; // Dữ liệu nằm trong event.data
    if (!snapshot) {
      return functions.logger.log("Không có dữ liệu tin nhắn");
    }
    const message = snapshot.data();

    const senderUid = message.senderUid;
    const receiverUid = message.receiverUid;
    const messageText = message.text;

    // 2. Lấy thông tin người gửi (để hiển thị tên)
    const senderDoc = await admin
      .firestore()
      .collection("users")
      .doc(senderUid)
      .get();
    const senderName = senderDoc.data()?.displayName ?? "Một người bạn";

    // 3. Lấy thông tin người nhận (để lấy FCM Token)
    const receiverDoc = await admin
      .firestore()
      .collection("users")
      .doc(receiverUid)
      .get();
      
    if (!receiverDoc.exists || !receiverDoc.data()?.fcmToken) {
      return functions.logger.log("Không tìm thấy FCM token của người nhận.");
    }
    const receiverToken = receiverDoc.data()?.fcmToken;

    // 4. Tạo nội dung thông báo
    const payload: admin.messaging.MessagingPayload = {
      notification: {
        title: `${senderName}`, // Tên người gửi
        body: messageText, // Nội dung tin nhắn
        sound: "default", // Tiếng chuông mặc định
      },
      data: {
        "chatRoomId": event.params.chatRoomId, // Lấy params từ event
        "senderUid": senderUid,
      },
    };

    // 5. Gửi thông báo đến token của người nhận
    try {
      await admin.messaging().sendToDevice(receiverToken, payload);
      functions.logger.log("Gửi thông báo thành công!");
    } catch (error) {
      functions.logger.log("Lỗi khi gửi thông báo:", error);
    }

    return null;
  }
);