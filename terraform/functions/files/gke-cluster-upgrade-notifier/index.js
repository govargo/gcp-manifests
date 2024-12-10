const functions = require('@google-cloud/functions-framework');
const fetch = require('node-fetch');

const webhookURL = process.env.WEBHOOK_URL;

// Allowed notification type URLs (empty array allows all types)
const allowedTypeURLs = [];

// Register a CloudEvent callback
functions.cloudEvent('sendNotificationForGKEClussterUpgradeToChat', async (cloudEvent) => {
  try {
    const message = cloudEvent.data.message;
    const attributes = message.attributes;
    const dataPayload = Buffer.from(message.data, 'base64').toString();

    if (isAllowedType(attributes)) {
      const cardMessage = JSON.stringify(createChatCard(dataPayload, attributes));

      const response = await fetch(webhookURL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: cardMessage,
      });

      console.log(`Card response status: ${response.status}`);
    }
  } catch (error) {
    console.error("Error processing CloudEvent:", error);
  }
});

// Filters message types based on allowedTypeURLs
const isAllowedType = (attributes) => {
  return allowedTypeURLs.length === 0 || allowedTypeURLs.includes(attributes.type_url);
};

// Creates a Google Chat card message
const createChatCard = (dataPayload, attributes) => {
  // Extract attributes using destructuring and default values
  const {
    project_id: projectId = "",
    cluster_name: clusterName = "",
    cluster_location: location = "",
    type_url: eventName = "",
    payload: detail = "",
  } = attributes;

  return {
    cardsV2: [{
      cardId: 'gke-cluster-upgrade-notifier',
      card: {
        name: 'GKE Cluster Upgrade',
        header: {
          title: dataPayload,
          imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJKUMkuqNwND4ITLcurk8rjF1VgDX0sR5yUw&s",
          imageType: "CIRCLE",
        },
        sections: [{
          header: "Upgrade detail",
          collapsible: false,
          uncollapsibleWidgetsCount: 1,
          widgets: [
            { decoratedText: { startIcon: { knownIcon: "STAR" }, text: projectId } },
            { decoratedText: { startIcon: { knownIcon: "CONFIRMATION_NUMBER_ICON" }, text: clusterName } },
            { decoratedText: { startIcon: { knownIcon: "MAP_PIN" }, text: location } },
            { decoratedText: { startIcon: { knownIcon: "INVITE" }, text: eventName } },
            { decoratedText: { startIcon: { knownIcon: "DESCRIPTION" }, text: detail, wrapText: true } },
          ],
        }],
      },
    }],
  };
};
