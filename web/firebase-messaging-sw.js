importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCjx8NKcbMyVsH6Hp_3ODxwHbrd1IN906w",
  appId: "1:714464476418:web:bb1b2ae84898c5c97d961b",
  messagingSenderId: "714464476418",
  projectId: "beastmodeapp-7dec9",
  authDomain: "beastmodeapp-7dec9.firebaseapp.com",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  console.log("Background message received:", message);
});
